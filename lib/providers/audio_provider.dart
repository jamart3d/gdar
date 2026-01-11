import 'dart:async';
import 'dart:math';

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/utils/logger.dart';
import 'package:gdar/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioProvider with ChangeNotifier {
  static final Random _random = Random();
  late final AudioPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();
  final _randomShowRequestController =
      StreamController<({Show show, Source source})>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;

  AudioPlayer get audioPlayer => _audioPlayer;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Source? _currentSource;
  Source? get currentSource => _currentSource;

  // Track the most recent random show request to ensure UI parity even during race conditions
  ({Show show, Source source})? _pendingRandomShowRequest;
  ({Show show, Source source})? get pendingRandomShowRequest =>
      _pendingRandomShowRequest;

  void clearPendingRandomShowRequest() {
    _pendingRandomShowRequest = null;
    notifyListeners();
  }

  Track? get currentTrack {
    if (_currentSource == null) return null;
    final index = _audioPlayer.currentIndex;
    if (index == null || index < 0 || index >= _currentSource!.tracks.length) {
      return null;
    }
    return _currentSource!.tracks[index];
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

  AudioProvider({AudioPlayer? audioPlayer}) {
    _audioPlayer = audioPlayer ?? AudioPlayer();
    _listenForCompletion();
    _listenForErrors();
    _listenForIndexChanges();
  }

  void update(
    ShowListProvider showListProvider,
    SettingsProvider settingsProvider,
  ) {
    _showListProvider = showListProvider;
    _settingsProvider = settingsProvider;
  }

  void _listenForCompletion() {
    _processingStateSubscription =
        _audioPlayer.processingStateStream.listen((state) async {
      if (state == ProcessingState.completed) {
        // Mark as played
        if (_currentShow != null) {
          final source = _currentSource;
          // Always use the source ID.
          if (source != null) {
            await _settingsProvider?.markAsPlayed(source.id);
          }
        }

        if (_settingsProvider?.playRandomOnCompletion ?? false) {
          logger.i('Playlist completed, playing random show.');
          await playRandomShow(filterBySearch: false);
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

  void _listenForIndexChanges() {
    _indexSubscription = _audioPlayer.currentIndexStream.listen((index) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _processingStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _indexSubscription?.cancel();
    _errorController.close();
    _randomShowRequestController.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  ({Show show, Source source})? pickRandomShow({bool filterBySearch = true}) {
    final settings = _settingsProvider;
    if (settings == null) return null;

    List<Show>? sourceList;
    if (filterBySearch) {
      sourceList = _showListProvider?.filteredShows;
    } else {
      sourceList = _showListProvider?.allShows;
    }

    if (sourceList == null || sourceList.isEmpty) {
      _setError('No shows available for random playback.');
      return null;
    }

    final List<Show> candidates = [];
    final Map<Show, int> weights = {};
    final Map<Show, Source> selectedSourceMap = {};

    // For better feedback
    int totalCount = sourceList.length;
    int blockedCount = 0;
    int unplayedFilterCount = 0;
    int highRatedFilterCount = 0;

    for (final show in sourceList) {
      // Find valid sources for this show
      final validSources = show.sources.where((s) {
        return settings.getRating(s.id) != -1;
      }).toList();

      if (validSources.isEmpty) {
        blockedCount++;
        continue;
      }

      // If Highest SHNID is on, it's already filtered by ShowListProvider.
      // We pick the first valid source as the representative for weighting.
      final source = validSources.first;
      final rating = settings.getRating(source.id);
      final isPlayed = settings.isPlayed(source.id);

      // Filter by Settings
      if (settings.randomOnlyUnplayed && isPlayed) {
        unplayedFilterCount++;
        continue;
      }
      if (settings.randomOnlyHighRated && rating < 2) {
        highRatedFilterCount++;
        continue;
      }

      // Calculate Weight based on Source ID
      int weight = 10;
      if (settings.randomExcludePlayed && isPlayed) {
        weight = 0;
      } else if (rating == 3) {
        weight = 200; // Favorite shows are highly preferred
      } else if (rating == 2) {
        weight = 100; // High rated shows
      } else if (rating == 1) {
        weight = 40; // Rated shows
      } else if (rating == 0) {
        weight =
            isPlayed ? 10 : 60; // Unplayed is preferred over general played
      }

      if (weight > 0) {
        candidates.add(show);
        weights[show] = weight;
        selectedSourceMap[show] = source;
      }
    }

    if (candidates.isEmpty) {
      String msg = 'No shows match criteria.';
      if (highRatedFilterCount > 0 &&
          highRatedFilterCount + blockedCount == totalCount) {
        msg = 'No shows match "High Rated" filter.';
      } else if (unplayedFilterCount > 0 &&
          unplayedFilterCount + blockedCount == totalCount) {
        msg = 'No unplayed shows available.';
      } else if (blockedCount == totalCount) {
        msg = 'All available shows are blocked.';
      } else if (totalCount > 0) {
        msg = 'All shows filtered out by source settings.';
      }

      logger.w(
          'Random Selection: $msg (Filtered: $totalCount, Blocked: $blockedCount, Unplayed: $unplayedFilterCount, HighRated: $highRatedFilterCount)');
      _setError(msg);
      return null;
    }

    // Weighted Random Selection
    int totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    int randomWeight = _random.nextInt(totalWeight);
    int currentWeight = 0;
    Show? selectedShow;

    for (final show in candidates) {
      currentWeight += weights[show]!;
      if (randomWeight < currentWeight) {
        selectedShow = show;
        break;
      }
    }

    selectedShow ??= candidates.first;
    final sourceToPlay = selectedSourceMap[selectedShow]!;

    logger.i(
        'Weighted selection: ${selectedShow.date} (Weight: ${weights[selectedShow]}/$totalWeight) - Sources: ${selectedShow.sources.length}');

    return (show: selectedShow, source: sourceToPlay);
  }

  Future<Show?> playRandomShow({bool filterBySearch = true}) async {
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
    final settings = _settingsProvider!;

    logger.i(
        'Playing random source: ${source.id} (Rating: ${settings.getRating(source.id)}, Played: ${settings.isPlayed(source.id)})');

    // Notify listeners/UI that a random show was requested
    _pendingRandomShowRequest = selection;
    _randomShowRequestController.add(selection);
    await playSource(show, source);
    return show;
  }

  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0, Duration? initialPosition}) async {
    _currentShow = show;
    _currentSource = source;
    // Notify ShowListProvider to ensuring visibility
    _showListProvider?.setPlayingShow(show.name, source.id);
    notifyListeners(); // Notify immediately so the UI can update

    // Start audio loading in the background
    await _loadAndPlayAudio(source,
        initialIndex: initialIndex, initialPosition: initialPosition);
  }

  /// Parses a share string and starts playback if valid.
  /// Format expected:
  /// Line 1: Venue - Date - SHNID
  /// Line 2: Track Title
  /// Line 3: Archive URL
  /// Line 4: Position: MM:SS (Optional)
  Future<bool> playFromShareString(String shareString) async {
    if (_showListProvider == null) return false;
    final cleanShare = shareString.toLowerCase();
    logger
        .i('AudioProvider: playFromShareString hash: ${shareString.hashCode}');
    logger.i(
        'Clipboard Playback: Input preview (first 200 chars): "${shareString.substring(0, shareString.length > 200 ? 200 : shareString.length)}"');

    try {
      Show? targetShow;
      Source? targetSource;
      int trackIndex = 0;

      logger.i('Clipboard Playback: Input: "$shareString"');

      // Parse structure: [venue] - [location] - [date] - [SHNID][track name][URL]
      // Example: "West High Auditorium - Anchorage, AK - Fri, Jun 20, 1980 - 156397[crowd - tuning]https://..."

      // Find the year (4 digits between 1960-2030) as an anchor
      final yearMatch =
          RegExp(r'(19[6-9]\d|20[0-2]\d)').firstMatch(shareString);
      if (yearMatch == null) {
        logger.w('Clipboard Playback: Could not find year in paste');
        return false;
      }

      // Extract everything after the year
      final afterYear = shareString.substring(yearMatch.end);

      // SHNID comes after " - " following the year
      final shnidStart = afterYear.indexOf(' - ');
      if (shnidStart == -1) {
        logger.w('Clipboard Playback: Could not find SHNID separator');
        return false;
      }

      // Extract SHNID: starts after " - ", capture only digits/hyphens/dots until we hit a letter or bracket
      final shnidText = afterYear.substring(shnidStart + 3).trim();
      String shnid = '';
      int shnidEnd = 0;

      for (int i = 0; i < shnidText.length; i++) {
        final char = shnidText[i];
        // SHNID can contain digits, dots, hyphens
        if (RegExp(r'[0-9.\-]').hasMatch(char)) {
          shnid += char;
          shnidEnd = i + 1;
        } else {
          // Stop at first non-SHNID character (letter, bracket, etc)
          break;
        }
      }
      shnid = shnid.trim();

      logger.i('Clipboard Playback: Extracted SHNID: "$shnid"');

      if (shnid.isEmpty) {
        logger.w('Clipboard Playback: SHNID is empty');
        return false;
      }

      // Extract track name: everything after SHNID until "[", "https", or end
      String? trackName;
      if (shnidEnd < shnidText.length) {
        String afterShnid = shnidText.substring(shnidEnd).trim();

        // Try to extract from brackets first: [track name]
        final trackMatch = RegExp(r'\[([^\]]+)\]').firstMatch(afterShnid);
        if (trackMatch != null) {
          trackName = trackMatch.group(1);
        } else {
          // Otherwise, take everything until "https" or end of string
          final urlIndex = afterShnid.indexOf('https');
          if (urlIndex != -1) {
            trackName = afterShnid.substring(0, urlIndex).trim();
          } else {
            trackName = afterShnid.trim();
          }
          // Remove any trailing brackets or special chars
          trackName = trackName.replaceAll(RegExp(r'[\[\]]'), '').trim();
        }

        if (trackName != null && trackName.isNotEmpty) {
          logger.i('Clipboard Playback: Extracted track name: "$trackName"');
        }
      }

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

      // Parse Position (Optional)
      Duration? pos;
      final posIndex = cleanShare.indexOf('position:');
      if (posIndex != -1) {
        final posPart =
            shareString.substring(posIndex + 'position:'.length).trim();
        final timeStr = posPart.split(' ').first.split('\n').first;
        pos = parseDuration(timeStr);
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

    try {
      // ignore: deprecated_member_use
      final playlist = ConcatenatingAudioSource(
        useLazyPreparation: false,
        shuffleOrder: DefaultShuffleOrder(),
        children: source.tracks.asMap().entries.map((entry) {
          int index = entry.key;
          Track track = entry.value;

          // Log the metadata to verify what is being passed to just_audio_background
          logger.i(
              'Creating MediaItem - Title: "${track.title}", Album: "${_currentShow!.venue}", Artist: "${_currentShow!.artist}"');

          return AudioSource.uri(
            Uri.parse(track.url),
            tag: MediaItem(
              id: '${_currentShow!.name}_${source.id}_$index',
              album: _currentShow!.venue,
              title: track.title,
              artist: _currentShow!.artist,
              duration: Duration(seconds: track.duration),
              artUri: artUri,
              extras: {'source_id': source.id},
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(
        playlist,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: true,
      );

      _audioPlayer.play();
    } catch (e, stackTrace) {
      logger.e('Error playing source', error: e, stackTrace: stackTrace);
      _error = 'Error playing source: ${e.toString()}';
      _errorController.add(_error!);
      notifyListeners();
      stopAndClear(); // Clear state on error
    }
  }

  Future<void> stopAndClear() async {
    await _audioPlayer.stop();
    _currentShow = null;
    _currentSource = null;
    _showListProvider?.setPlayingShow(null, null);
    notifyListeners();
  }

  void play() => _audioPlayer.play();

  void pause() => _audioPlayer.pause();

  void seekToNext() => _audioPlayer.seekToNext();

  void seekToPrevious() => _audioPlayer.seekToPrevious();

  void seek(Duration position) => _audioPlayer.seek(position);

  void seekToTrack(int index) {
    _audioPlayer.seek(Duration.zero, index: index);
    if (!_audioPlayer.playing) {
      _audioPlayer.play();
    }
  }

  Future<Uri?> _getAlbumArtUri() async {
    // Check internal setting first
    if (_settingsProvider?.showGlobalAlbumArt != true) {
      return null;
    }

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final file = File('${docsDir.path}/album_art.png');

      if (!await file.exists()) {
        // Load from assets and write to file
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
}
