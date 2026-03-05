import 'dart:async';
import 'dart:math';
import 'package:shakedown/services/wakelock_service.dart';

import 'package:flutter/foundation.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:shakedown/utils/share_link_parser.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/services/buffer_agent.dart';
import 'package:shakedown/services/random_show_selector.dart';
import 'package:shakedown/services/audio_cache_service.dart';

class AudioProvider with ChangeNotifier {
  late final GaplessPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  final _bufferAgentNotificationController = StreamController<
      ({String message, VoidCallback? retryAction})>.broadcast();
  final _notificationController = StreamController<String>.broadcast();
  final _playbackFocusRequestController = StreamController<void>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;
  BufferAgent? _bufferAgent;

  GaplessPlayer get audioPlayer => _audioPlayer;
  bool get isPlaying => _audioPlayer.playing;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Source? _currentSource;
  Source? get currentSource => _currentSource;

  // Track the most recent random show request to ensure UI parity even during race conditions
  ({Show show, Source source})? _pendingRandomShowRequest;
  ({Show show, Source source})? get pendingRandomShowRequest =>
      _pendingRandomShowRequest;

  // Flag to prevent marking as played multiple times for the same source
  bool _hasMarkedAsPlayed = false;

  void clearPendingRandomShowRequest() {
    _pendingRandomShowRequest = null;
    notifyListeners();
  }

  Track? get currentTrack {
    if (_currentSource == null) return null;
    final index = _audioPlayer.currentIndex;
    final sequence = _audioPlayer.sequence;
    if (index == null || index < 0 || index >= sequence.length) return null;

    final sourceItem = sequence[index];
    if (sourceItem.tag is! MediaItem) return null;
    final item = sourceItem.tag as MediaItem;

    // Check if the physical track being played belongs to the logical current show.
    // During transitions (like TV dice roll), the UI looks ahead by updating
    // _currentSource before the player starts the new show.
    final itemSourceId = item.extras?['source_id'] as String?;
    if (itemSourceId != null && itemSourceId != _currentSource!.id) {
      return null;
    }

    // 1. Try resolving local index from extras (most reliable)
    int? localIndex;
    if (item.extras?.containsKey('track_index') ?? false) {
      localIndex = item.extras!['track_index'] as int?;
    }
    // 2. Fallback to parsing from ID
    if (localIndex == null) {
      try {
        final parts = item.id.split('_');
        localIndex = int.tryParse(parts.last);
      } catch (_) {}
    }

    if (localIndex != null &&
        localIndex >= 0 &&
        localIndex < _currentSource!.tracks.length) {
      return _currentSource!.tracks[localIndex];
    }

    // 3. Last resort: global index (only valid if single source loaded)
    if (index < _currentSource!.tracks.length) {
      return _currentSource!.tracks[index];
    }

    return null;
  }

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;
  Stream<Duration> get bufferedPositionStream =>
      _audioPlayer.bufferedPositionStream;
  Stream<Duration?> get nextTrackBufferedStream =>
      _audioPlayer.nextTrackBufferedStream;
  Stream<Duration?> get nextTrackTotalStream =>
      _audioPlayer.nextTrackTotalStream;
  Stream<String> get playbackErrorStream => _errorController.stream;
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;
  Stream<({String message, VoidCallback? retryAction})>
      get bufferAgentNotificationStream =>
          _bufferAgentNotificationController.stream;
  Stream<String> get notificationStream => _notificationController.stream;
  Stream<void> get playbackFocusRequestStream =>
      _playbackFocusRequestController.stream;

  /// Proxy for cached track count from [AudioCacheService]
  int get cachedTrackCount => _audioCacheService.cachedTrackCount;

  bool _isTransitioning = false;

  // Flag to ignore player stream events while we are manually loading a new source.
  bool _isSwitchingSource = false;

  // Dependency Injection for easier testing
  final CatalogService _catalogService;
  AudioCacheService _audioCacheService;
  final WakelockService _wakelockService;
  StreamSubscription<Duration>? _bufferedPositionSubscription;

  AudioProvider({
    GaplessPlayer? audioPlayer,
    CatalogService? catalogService,
    AudioCacheService? audioCacheService,
    WakelockService? wakelockService,
    bool useWebGaplessEngine = true,
  })  : _catalogService = catalogService ?? CatalogService(),
        _audioCacheService = audioCacheService ?? AudioCacheService(),
        _wakelockService = wakelockService ?? WakelockService() {
    _audioPlayer = audioPlayer ?? GaplessPlayer();
    logger
        .i('AudioProvider initialized with Engine: ${_audioPlayer.engineName}');
    logger.i('Engine Selection Reason: ${_audioPlayer.selectionReason}');
    _listenForPlaybackProgress();
    _listenForErrors();
    _listenForProcessingState();

    // Listen to cache updates
    _audioCacheService.addListener(notifyListeners);

    // Listen to buffer updates for real-time reporting
    _bufferedPositionSubscription =
        _audioPlayer.bufferedPositionStream.listen((_) {
      notifyListeners();
    });

    // Listen to raw engine states (for suspension notifications)
    _audioPlayer.engineStateStringStream.listen((state) {
      if (state == 'suspended_by_os') {
        _bufferAgentNotificationController.add((
          message: 'Playback suspended by system. Tap play to resume.',
          retryAction: () => play(),
        ));
      }
    });
  }

  void _listenForProcessingState() {
    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) {
      // Manage Wake Lock based on playback state
      _updateWakeLockState();

      if (state == ProcessingState.completed) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        logger.i(
            'AudioProvider: ProcessingState.completed received. AutoPlay: $shouldPlay');
        if (shouldPlay) {
          logger.i('Playback completed. Triggering fallback random show...');
          // Use playRandomShow (Stop & Load) as fallback
          playRandomShow();
        }
      }
    });

    // Also listen to playing state changes for Wake Lock
    _audioPlayer.playingStream.listen((playing) {
      _updateWakeLockState();
    });
  }

  Future<void> _updateWakeLockState() async {
    final shouldPreventScreensaver = _settingsProvider?.preventSleep ?? true;
    final isPlaying = _audioPlayer.playing;
    // We only care if playing AND processing state is NOT idle/completed/error
    // But checking 'playing' is usually sufficient for user intent.
    // Let's being conservative: Only enable if playing.

    if (shouldPreventScreensaver && isPlaying) {
      try {
        if (!(await _wakelockService.enabled)) {
          await _wakelockService.enable();
          logger.d('AudioProvider: Wake Lock ENABLED (Prevent Sleep)');
        }
      } catch (e) {
        logger.w('Failed to enable Wake Lock: $e');
      }
    } else {
      try {
        if (await _wakelockService.enabled) {
          await _wakelockService.disable();
          logger.d('AudioProvider: Wake Lock DISABLED');
        }
      } catch (e) {
        logger.w('Failed to disable Wake Lock: $e');
      }
    }
  }

  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
    AudioCacheService audioCacheService,
  ) {
    _showListProvider = showListProvider;
    _audioCacheService = audioCacheService;

    // Check if web prefetch seconds changed and sync to player
    if (_settingsProvider != null &&
        settingsProvider.webPrefetchSeconds !=
            _settingsProvider!.webPrefetchSeconds) {
      _audioPlayer.setWebPrefetchSeconds(settingsProvider.webPrefetchSeconds);
    }

    // Sync handoff mode
    if (_settingsProvider != null &&
        settingsProvider.hybridHandoffMode !=
            _settingsProvider!.hybridHandoffMode) {
      _audioPlayer
          .setHybridHandoffMode(settingsProvider.hybridHandoffMode.name);
    }
    _settingsProvider = settingsProvider;
    _updateBufferAgent();
    // Update cache monitoring based on setting
    _audioCacheService
        .monitorCache(_settingsProvider?.offlineBuffering ?? false);
  }

  void _updateBufferAgent() {
    final shouldEnable = _settingsProvider?.enableBufferAgent ?? false;

    if (shouldEnable && _bufferAgent == null) {
      _bufferAgent = BufferAgent(
        _audioPlayer,
        onRecoveryNotification: (message, retryAction) {
          _bufferAgentNotificationController.add(
            (message: message, retryAction: retryAction),
          );
        },
      );
      logger.i('AudioProvider: Buffer Agent enabled');
    } else if (!shouldEnable && _bufferAgent != null) {
      _bufferAgent?.dispose();
      _bufferAgent = null;
      logger.i('AudioProvider: Buffer Agent disabled');
    }
  }

  void _listenForPlaybackProgress() {
    // New Logic: Queue the next show as soon as we start the LAST track.
    // This gives us minutes of buffer time instead of milliseconds.
    _indexSubscription = _audioPlayer.currentIndexStream.listen((index) async {
      final sequence = _audioPlayer.sequence;
      if (index == null || sequence.isEmpty) return;

      // 1. Queueing Trigger
      // If we are on the last track, queue the next show immediately.
      if (index == sequence.length - 1) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        if (!_isTransitioning && shouldPlay) {
          // Safety check: ensure we really are on the last track by verifying sequence length
          logger.i(
              'Started last track (Index $index, Length ${sequence.length}). Pre-queueing next random show...');
          _isTransitioning = true; // Block duplicates
          await queueRandomShow();
        } else {
          logger.d(
              'Last track reached (Index $index, Length ${sequence.length}), but skipping queue. Transitioning: $_isTransitioning, AutoPlay: $shouldPlay');
        }
      }

      final currentSource = sequence[index];
      if (currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;

        // If the source ID has changed, we need to update our internal "Current Show"
        // This handles the transition from Show A -> Show B automatically.
        if (sourceId != null && _currentSource?.id != sourceId) {
          // If we are currently MANUALLY switching sources or have a random roll pending,
          // ignore any mismatch (which is likely due to the player stream reporting
          // the old source during teardown or before the new one starts).
          if (_isSwitchingSource || _pendingRandomShowRequest != null) {
            logger.d(
                'Ignoring source mismatch during manual switch/random roll (Player: $sourceId, App: ${_currentSource?.id})');
          } else {
            _updateCurrentShowFromSourceId(sourceId);
          }
        }
      }

      // Notify listeners on every track index change so that UI components
      // watching AudioProvider (e.g. screensaver banner rings) update the
      // current track title for intra-show track changes.
      notifyListeners();
    });
  }

  void _listenForErrors() {
    _playbackEventSubscription = _audioPlayer.playbackEventStream
        .listen((event) {}, onError: (Object e, StackTrace stackTrace) {
      logger.e('Playback error', error: e, stackTrace: stackTrace);
      _errorController.add('Playback error: $e');
    });
  }

  @override
  void dispose() {
    _audioCacheService.removeListener(notifyListeners);
    _processingStateSubscription?.cancel();
    _positionSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _indexSubscription?.cancel();
    _bufferedPositionSubscription?.cancel();
    _errorController.close();
    _randomShowRequestController.close();
    _bufferAgentNotificationController.close();
    _playbackFocusRequestController.close();
    _bufferAgent?.dispose();
    _audioPlayer.dispose();
    _wakelockService.disable(); // Ensure we don't leave it on
    super.dispose();
  }

  ({Show show, Source source})? pickRandomShow({bool filterBySearch = true}) {
    final settings = _settingsProvider;
    if (settings == null) return null;
    final catalog = _catalogService;

    List<Show>? sourceList;
    if (filterBySearch) {
      sourceList = _showListProvider?.filteredShows;
    } else {
      sourceList = _showListProvider?.allShows;
    }

    if (sourceList == null || sourceList.isEmpty) {
      _setError('No shows available for playback.');
      return null;
    }

    final result = RandomShowSelector.pick(
      candidates: sourceList,
      settings: settings,
      catalog: catalog,
      currentShow: _currentShow,
      isSourceAllowed: (source) {
        if (_showListProvider != null) {
          return _showListProvider!.isSourceAllowed(source);
        }
        return true;
      },
    );

    if (result == null) {
      // The selector logs warnings, but we can set a generic error if silent
      if (_error == null) _setError('No shows found matching criteria.');
    }

    return result;
  }

  Future<Show?> playRandomShow({
    bool filterBySearch = true,
    bool animationOnly = false,
    bool delayPlayback = false,
  }) async {
    // If we're still loading and have no shows, wait for initialization
    if (_showListProvider != null &&
        _showListProvider!.isLoading &&
        _showListProvider!.allShows.isEmpty) {
      logger.i('playRandomShow: Waiting for show list initialization...');
      await _showListProvider!.initializationComplete;
      logger.i('playRandomShow: Initialization complete, proceeding.');
    }

    final selection = pickRandomShow(filterBySearch: filterBySearch);
    if (selection == null) return null;

    final show = selection.show;
    final source = selection.source;
    final catalog = _catalogService;

    logger.i(
        'Playing random source: ${source.id} (Rating: ${catalog.getRating(source.id)}, Played: ${catalog.isPlayed(source.id)})');

    _pendingRandomShowRequest = selection;
    _randomShowRequestController.add(selection);

    if (animationOnly) {
      logger.i(
          'playRandomShow: [TEST MODE] Skipping playback, triggering animation/scroll only.');
      // Ensure UI has time to react to the stream event
      return show;
    }

    if (delayPlayback) {
      logger.i('playRandomShow: Playback delayed as requested.');
      // Update UI state to show WHICH show is pending, but don't start audio yet.
      _currentShow = show;
      _currentSource = source;
      _showListProvider?.setPlayingShow(show.name, source.id);
      notifyListeners();
      return show;
    }

    await playSource(show, source);
    return show;
  }

  /// Triggers playback for the most recent pending random selection.
  Future<void> playPendingSelection() async {
    if (_pendingRandomShowRequest == null) {
      logger.w('playPendingSelection: No pending selection to play.');
      return;
    }

    final show = _pendingRandomShowRequest!.show;
    final source = _pendingRandomShowRequest!.source;

    logger.i('playPendingSelection: Starting playback for ${show.name}');
    await playSource(show, source);
  }

  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {
    _currentShow = show;
    _currentSource = source;
    // Notify ShowListProvider to ensuring visibility
    _showListProvider?.setPlayingShow(show.name, source.id);
    _hasMarkedAsPlayed = false; // Reset for new source
    notifyListeners(); // Notify immediately so the UI can update

    try {
      _isSwitchingSource = true;
      await _loadAndPlayAudio(source,
          initialIndex: initialIndex, initialPosition: initialPosition);
    } finally {
      // Only reset the transition flag AFTER loading is complete (or failed).
      // Resetting it too early allows _listenForPlaybackProgress to trigger AGAIN
      // while we are still loading, causing a double-trigger / race condition.
      _isSwitchingSource = false;
      _isTransitioning = false;
    }

    // Trigger Smart Pre-Load if enabled
    if (_settingsProvider?.offlineBuffering ?? false) {
      // Opportunistic Cache Cleanup (Same logic as queueRandomShow)
      // Ensure we have space for this new show + buffer
      final currentTrackCount = source.tracks.length;
      final dynamicLimit = max(20, currentTrackCount + 5);

      // Fire and forget, but DO IT before preloading starts to clear space
      unawaited(_audioCacheService.performCacheCleanup(maxFiles: dynamicLimit));

      unawaited(
          _audioCacheService.preloadSource(source, startIndex: initialIndex));
    }
  }

  /// Parses a share string and starts playback if valid.
  /// Format expected:
  /// Line 1: Venue - Date - SHNID
  /// Line 2: Track Title
  /// Line 3: Archive URL
  /// Line 4: Position: MM:SS (Optional)
  Future<bool> playFromShareString(String shareString) async {
    if (_showListProvider == null) return false;

    // Use the pure parser utility
    final data = ShareLinkParser.parse(shareString);
    if (data == null) {
      logger.w('Clipboard Playback: Could not parse share string');
      return false;
    }

    final shnid = data.shnid;
    final trackName = data.trackName;
    final pos = data.position;

    logger.i(
        'Clipboard Playback: Extracted SHNID: "$shnid", Track: "$trackName", Position: $pos');

    try {
      Show? targetShow;
      Source? targetSource;
      int trackIndex = 0;

      // Find the matching source by SHNID
      final allShows = _showListProvider!.allShows;
      for (final show in allShows) {
        for (final source in show.sources) {
          if (source.id.toLowerCase() == shnid.toLowerCase()) {
            targetShow = show;
            targetSource = source;
            logger.i('Clipboard Playback: ✓ Matched Source: "${source.id}"');
            break;
          }
        }
        if (targetSource != null) break;
      }

      if (targetShow == null || targetSource == null) {
        logger.w('Clipboard Playback: No source found for SHNID "$shnid"');
        return false;
      }

      // Find track index by name if we extracted one
      if (trackName != null) {
        for (int i = 0; i < targetSource.tracks.length; i++) {
          if (targetSource.tracks[i].title.toLowerCase() ==
              trackName.toLowerCase()) {
            trackIndex = i;
            logger.i('Clipboard Playback: ✓ Matched track at index $i');
            break;
          }
        }
      }

      logger.i(
          'Clipboard Playback: Playing ${targetSource.id}, track $trackIndex');

      await playSource(targetShow, targetSource,
          initialIndex: trackIndex, initialPosition: pos);

      // Ensure UI parity: Trigger the scroll and expand notifications
      _pendingRandomShowRequest = (show: targetShow, source: targetSource);
      _randomShowRequestController
          .add((show: targetShow, source: targetSource));

      return true;
    } catch (e) {
      logger.e('Error preparing clipboard playback: $e');
      return false;
    }
  }

  Future<void> queueRandomShow() async {
    final selection = pickRandomShow(filterBySearch: false);
    if (selection == null) {
      logger.w('Pre-queueing aborted: No show selected.');
      _isTransitioning =
          false; // Reset flag so we can retry if conditions change
      return;
    }

    // Opportunistic Cache Cleanup
    // We run this when queuing a new show to keep storage usage healthy over long sessions.
    // Dynamic Limit: Keep enough for the current show + 5 tracks buffer, but at least 20.
    final currentTrackCount = _currentSource?.tracks.length ?? 0;
    final dynamicLimit = max(20, currentTrackCount + 5);

    // Fire and forget (don't await) to not block the UI.
    unawaited(_audioCacheService.performCacheCleanup(maxFiles: dynamicLimit));

    final show = selection.show;
    final source = selection.source;

    logger.i('Queueing next show: ${show.date} (${source.id})');
    Uri? artUri;
    try {
      artUri = await _audioCacheService.getAlbumArtUri();
    } catch (_) {}

    final nextSources = source.tracks.asMap().entries.map((entry) {
      int index = entry.key;
      Track track = entry.value;

      return _createAudioSource(
        Uri.parse(track.url),
        MediaItem(
          id: '${show.name}_${source.id}_$index',
          album: show.venue,
          title: track.title,
          artist: show.artist,
          duration: Duration(seconds: track.duration),
          artUri: artUri,
          extras: {'source_id': source.id, 'track_index': index},
        ),
      );
    }).toList();

    // Append to the existing playlist directly via AudioPlayer
    try {
      await _audioPlayer.addAudioSources(nextSources);
      logger.i('Successfully appended ${nextSources.length} tracks.');

      // Trigger Smart Pre-Load for the queued show
      if (_settingsProvider?.offlineBuffering ?? false) {
        unawaited(_audioCacheService.preloadSource(source));
      }

      _isTransitioning = false;
    } catch (e) {
      // If this fails (e.g. native Shuffle Order bug), we just log it and abort pre-queueing.
      // The app will fall back to "Load on End" behavior naturally when the current track finishes.
      logger.w(
          'Failed to pre-queue next show (addAudioSources failed). Will load normally on track end. Error: $e');
      _isTransitioning = false;
    }
  }

  void showNotification(String message) {
    _notificationController.add(message);
  }

  void requestPlaybackFocus() {
    _playbackFocusRequestController.add(null);
  }

  void _updateCurrentShowFromSourceId(String sourceId) {
    if (_showListProvider == null) return;

    // Logic: If we are switching TO a new source, the previous one is done.
    if (!_hasMarkedAsPlayed && _currentSource != null) {
      final catalog = _catalogService;
      catalog.markAsPlayed(_currentSource!.id);
      catalog.incrementPlayCount(_currentSource!.id);
      _hasMarkedAsPlayed = true;
    }

    // Find the new show
    Show? foundShow;
    Source? foundSource;

    for (final show in _showListProvider!.allShows) {
      for (final source in show.sources) {
        if (source.id == sourceId) {
          foundShow = show;
          foundSource = source;
          break;
        }
      }
      if (foundSource != null) break;
    }

    if (foundShow != null && foundSource != null) {
      logger.i(
          'Deep Sleep Transition: Detected track change to ${foundShow.date} (${foundSource.id}). Updating UI.');
      _currentShow = foundShow;
      _currentSource = foundSource;
      _showListProvider?.setPlayingShow(foundShow.name, foundSource.id);
      _hasMarkedAsPlayed = false; // Reset for the new show
      _isTransitioning = false; // Ready for the NEXT transition
      notifyListeners();

      // Notify Random Request Stream (For UI Parity causing scroll/expand)
      _pendingRandomShowRequest = (show: foundShow, source: foundSource);
      _randomShowRequestController.add((show: foundShow, source: foundSource));
    }
  }

  String? _error;
  String? get error => _error;

  void _setError(String message) {
    _error = message;
    _errorController.add(message);
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<void> _loadAndPlayAudio(Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {
    logger.i(
        'Loading show: ${_currentShow!.name}, source: ${source.id}, starting at index: $initialIndex');
    logger.i('AudioProvider: Playing with engine: ${_audioPlayer.engineName}');
    Uri? artUri;
    try {
      artUri = await _audioCacheService.getAlbumArtUri();
    } catch (e) {
      logger.w('Failed to get album art URI: $e');
    }

    // On native platforms, explicitly stop before switching sources to prevent
    // MediaCodec/ExoPlayer crashes. On web there are no native decoders to
    // release, so we skip this — the delay would also break the browser's
    // user-gesture context and trigger the autoplay policy.
    if (!kIsWeb) {
      try {
        if (_audioPlayer.playing ||
            _audioPlayer.processingState != ProcessingState.idle) {
          await _audioPlayer.stop();
          // Brief delay to allow native resources (MediaCodec) to fully release.
          await Future.delayed(const Duration(milliseconds: 50));
        }
      } catch (e) {
        logger.w('Error stopping before source switch (non-fatal): $e');
      }
    }

    try {
      final children = source.tracks.asMap().entries.map((entry) {
        int index = entry.key;
        Track track = entry.value;

        return _createAudioSource(
          Uri.parse(track.url),
          MediaItem(
            id: '${_currentShow!.name}_${source.id}_$index',
            album: _currentShow!.venue,
            title: track.title,
            artist: _currentShow!.artist,
            duration: Duration(seconds: track.duration),
            artUri: artUri,
            extras: {'source_id': source.id, 'track_index': index},
          ),
        );
      }).toList();

      // Use setAudioSources directly instead of ConcatenatingAudioSource.
      // This is the recommended replacement for the deprecated ConcatenatingAudioSource.
      await _audioPlayer.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition ?? Duration.zero,
        preload: _settingsProvider?.offlineBuffering ?? false,
      );

      // We call play() after loading for both native and web.
      // GaplessPlayer web engine handles AudioContext suspension internally.
      unawaited(_audioPlayer.play());
    } catch (e, stackTrace) {
      // Only handle errors if this request corresponds to the current source.
      if (_currentSource?.id == source.id) {
        logger.e('Error playing source', error: e, stackTrace: stackTrace);
        _error = 'Error playing source: ${e.toString()}';
        _errorController.add(_error!);
        notifyListeners();
        unawaited(stopAndClear());
      } else {
        logger.w(
            'Ignoring error from superseded playback request (Source: ${source.id}): $e');
      }
    }
  }

  Future<void> stopAndClear() async {
    logger.i('Stopping and cleaning up...');
    await _audioPlayer.stop();
    _currentShow = null;
    _showListProvider?.setPlayingShow(null, null);
    _currentSource = null;
    _error = null;
    _pendingRandomShowRequest = null;
    _isTransitioning = false;
    _hasMarkedAsPlayed = false;
    notifyListeners();
  }

  Future<void> play() => _audioPlayer.play();

  Future<void> resume() => _audioPlayer.play();

  Future<void> pause() => _audioPlayer.pause();

  Future<void> stop() => _audioPlayer.stop();

  Future<void> seekToNext() => _audioPlayer.seekToNext();

  Future<void> seekToPrevious() => _audioPlayer.seekToPrevious();

  Future<void> seek(Duration position) => _audioPlayer.seek(position);

  /// Retries loading the current source, maintaining the current track index.
  Future<void> retryCurrentSource() async {
    if (_currentShow == null || _currentSource == null) {
      logger.w('retryCurrentSource: No current show or source to retry.');
      return;
    }

    // Find local index from the current track if available, else fallback to player index
    int localIndex = 0;
    if (_audioPlayer.currentIndex != null) {
      try {
        final sequence = _audioPlayer.sequence;
        if (sequence.isNotEmpty &&
            _audioPlayer.currentIndex! < sequence.length) {
          final currentItem =
              sequence[_audioPlayer.currentIndex!].tag as MediaItem;
          localIndex = currentItem.extras?['track_index'] as int? ?? 0;
        }
      } catch (e) {
        logger.w('retryCurrentSource: Error resolving local index: $e');
        localIndex = _audioPlayer.currentIndex!;
      }
    }

    logger.i(
        'retryCurrentSource: Retrying ${_currentShow!.name} at local index $localIndex');
    await playSource(_currentShow!, _currentSource!, initialIndex: localIndex);
  }

  void seekToTrack(int localIndex) {
    if (_currentSource == null) return;

    // If the player is stuck loading or buffering and has no sequence yet,
    // we should re-trigger playSource to "force" a fresh start at the new index.
    final playerState = _audioPlayer.processingState;
    final isStuck = playerState == ProcessingState.loading ||
        playerState == ProcessingState.buffering;
    final sequence = _audioPlayer.sequence;

    if (isStuck &&
        (sequence.isEmpty || _audioPlayer.currentIndex != localIndex)) {
      logger.i(
          'seekToTrack: Player is stuck/loading. Re-triggering playSource at index $localIndex');
      if (_currentShow != null) {
        playSource(_currentShow!, _currentSource!, initialIndex: localIndex);
        return;
      }
    }

    int? globalIndex;

    for (int i = 0; i < sequence.length; i++) {
      final source = sequence[i];
      if (source.tag is MediaItem) {
        final item = source.tag as MediaItem;
        // Check identifying tags
        final sourceId = item.extras?['source_id'] as String?;
        final trackIndex = item.extras?['track_index'] as int?;

        if (sourceId == _currentSource!.id && trackIndex == localIndex) {
          globalIndex = i;
          break;
        }
      }
    }

    if (globalIndex != null) {
      _audioPlayer.seek(Duration.zero, index: globalIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    } else {
      // Fallback (mostly for single-show scenarios)
      try {
        _audioPlayer.seek(Duration.zero, index: localIndex);
        if (!_audioPlayer.playing) {
          _audioPlayer.play();
        }
      } catch (e) {
        logger.e('seekToTrack fallback failed: $e');
      }
    }
  }

  AudioSource _createAudioSource(Uri uri, MediaItem tag) {
    return _audioCacheService.createAudioSource(
      uri: uri,
      tag: tag,
      useCache: _settingsProvider?.offlineBuffering ?? false,
    );
  }

  /// Delegates to AudioCacheService to clear cache
  static Future<void> clearAudioCache() async {
    final service = AudioCacheService();
    unawaited(service.init());
    await service.clearAudioCache();
    service.dispose();
  }
}
