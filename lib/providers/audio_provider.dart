import 'dart:async';
import 'dart:math';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:shakedown/utils/share_link_parser.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:shakedown/services/buffer_agent.dart';
import 'package:shakedown/services/random_show_selector.dart';
import 'package:shakedown/services/audio_cache_service.dart';

class AudioProvider with ChangeNotifier {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();
  final _bufferAgentNotificationController = StreamController<
      ({String message, VoidCallback? retryAction})>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;
  BufferAgent? _bufferAgent;

  AudioPlayer get audioPlayer => _audioPlayer;
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
    if (index == null || index < 0 || index >= sequence.length) {
      return null;
    }

    // Fix: Use the MediaItem tag to find the LOCAL index within the source,
    // instead of using the GLOBAL playlist index.
    final sourceItem = sequence[index];
    if (sourceItem.tag is MediaItem) {
      final item = sourceItem.tag as MediaItem;
      // 1. Try extras (future proofing)
      if (item.extras != null && item.extras!.containsKey('track_index')) {
        final localIndex = item.extras!['track_index'] as int;
        if (localIndex >= 0 && localIndex < _currentSource!.tracks.length) {
          return _currentSource!.tracks[localIndex];
        }
      }

      try {
        final parts = item.id.split('_');
        if (parts.isNotEmpty) {
          final localIndex = int.tryParse(parts.last);
          if (localIndex != null &&
              localIndex >= 0 &&
              localIndex < _currentSource!.tracks.length) {
            return _currentSource!.tracks[localIndex];
          }
        }
      } catch (e) {
        // ignore
      }
    }

    // Fallback to global index if all else fails (only valid for single show)
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
  Stream<String> get playbackErrorStream => _errorController.stream;
  Stream<({Show show, Source source})> get randomShowRequestStream =>
      _randomShowRequestController.stream;
  Stream<({String message, VoidCallback? retryAction})>
      get bufferAgentNotificationStream =>
          _bufferAgentNotificationController.stream;

  /// Proxy for cached track count from [AudioCacheService]
  int get cachedTrackCount => _audioCacheService.cachedTrackCount;

  bool _isTransitioning = false;

  // Flag to ignore player stream events while we are manually loading a new source.
  bool _isSwitchingSource = false;

  // Dependency Injection for easier testing
  final CatalogService _catalogService;
  final AudioCacheService _audioCacheService;

  AudioProvider({
    AudioPlayer? audioPlayer,
    CatalogService? catalogService,
    AudioCacheService? audioCacheService,
  })  : _catalogService = catalogService ?? CatalogService(),
        _audioCacheService = audioCacheService ?? AudioCacheService() {
    _audioPlayer = audioPlayer ?? AudioPlayer();
    _listenForPlaybackProgress();
    _listenForErrors();
    _listenForProcessingState();

    // Listen to cache updates
    _audioCacheService.addListener(notifyListeners);
  }

  void _listenForProcessingState() {
    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        final shouldPlay = _settingsProvider?.playRandomOnCompletion ?? false;
        if (shouldPlay) {
          logger.i('Playback completed. Triggering fallback random show...');
          // Use playRandomShow (Stop & Load) as fallback
          playRandomShow();
        }
      }
    });
  }

  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
  ) {
    _showListProvider = showListProvider;
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
          _isTransitioning = true; // Block duplicates
          logger.i(
              'Started last track (Index $index). Pre-queueing next random show...');
          await queueRandomShow();
        } else {
          logger.d(
              'Last track reached (Index $index), but skipping queue. Transitioning: $_isTransitioning, AutoPlay: $shouldPlay');
        }
      }

      final currentSource = sequence[index];
      if (currentSource.tag is MediaItem) {
        final item = currentSource.tag as MediaItem;
        final sourceId = item.extras?['source_id'] as String?;

        // If the source ID has changed, we need to update our internal "Current Show"
        // This handles the transition from Show A -> Show B automatically.
        if (sourceId != null && _currentSource?.id != sourceId) {
          // If we are currently MANUALLY switching sources, ignore any mismatch
          // (which is likely due to the player stream reporting the old source during teardown).
          if (_isSwitchingSource) {
            logger.d(
                'Ignoring source mismatch during manual switch (Player: $sourceId, App: ${_currentSource?.id})');
          } else {
            _updateCurrentShowFromSourceId(sourceId);
          }
        }
      }
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
    _errorController.close();
    _randomShowRequestController.close();
    _bufferAgentNotificationController.close();
    _bufferAgent?.dispose();
    _audioPlayer.dispose();
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

  Future<Show?> playRandomShow(
      {bool filterBySearch = true, bool animationOnly = false}) async {
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

    await playSource(show, source);
    return show;
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
    _audioCacheService.performCacheCleanup(maxFiles: dynamicLimit);

    final show = selection.show;
    final source = selection.source;

    logger.i('Queueing next show: ${show.date} (${source.id})');
    Uri? artUri;
    try {
      artUri = await _getAlbumArtUri();
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
      _isTransitioning = false;
    } catch (e) {
      // If this fails (e.g. native Shuffle Order bug), we just log it and abort pre-queueing.
      // The app will fall back to "Load on End" behavior naturally when the current track finishes.
      logger.w(
          'Failed to pre-queue next show (addAudioSources failed). Will load normally on track end. Error: $e');
      _isTransitioning = false;
    }
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
    Uri? artUri;
    try {
      artUri = await _getAlbumArtUri();
    } catch (e) {
      logger.w('Failed to get album art URI: $e');
    }

    // Explicitly stop before switching sources to prevent native crashes (MediaCodec/ExoPlayer).
    // releasing the decoder is safer than just pausing.
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
        initialPosition: initialPosition,
        preload: _settingsProvider?.offlineBuffering ?? false,
      );

      _audioPlayer.play();
    } catch (e, stackTrace) {
      // Only handle errors if this request corresponds to the current source.
      if (_currentSource?.id == source.id) {
        logger.e('Error playing source', error: e, stackTrace: stackTrace);
        _error = 'Error playing source: ${e.toString()}';
        _errorController.add(_error!);
        notifyListeners();
        stopAndClear();
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

  void play() => _audioPlayer.play();

  void resume() => _audioPlayer.play();

  void pause() => _audioPlayer.pause();

  void stop() => _audioPlayer.stop();

  void seekToNext() => _audioPlayer.seekToNext();

  void seekToPrevious() => _audioPlayer.seekToPrevious();

  void seek(Duration position) => _audioPlayer.seek(position);

  void seekToTrack(int localIndex) {
    if (_currentSource == null) return;

    // Find the global index that corresponds to this local index for the current source
    final sequence = _audioPlayer.sequence;

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
      logger.w(
          'seekToTrack: Could not find global index for local seek (Source: ${_currentSource!.id}, Track: $localIndex). Fallback to local index.');
      // Fallback (mostly for single-show scenarios)
      _audioPlayer.seek(Duration.zero, index: localIndex);
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
    }
  }

  Future<Uri?> _getAlbumArtUri() async {
    if (_settingsProvider?.showGlobalAlbumArt != true) {
      return null;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/album_art.png');

      if (!await file.exists()) {
        final byteData = await rootBundle.load('assets/images/t_steal.webp');
        await file.writeAsBytes(byteData.buffer.asUint8List(
          byteData.offsetInBytes,
          byteData.lengthInBytes,
        ));
      }

      return Uri.file(file.path);
    } catch (e) {
      logger.e('Error preparing album art', error: e);
      return null;
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
    await service.clearAudioCache();
    service.dispose();
  }
}
