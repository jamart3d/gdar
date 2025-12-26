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
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioProvider with ChangeNotifier {
  late final AudioPlayer _audioPlayer;
  StreamSubscription<ProcessingState>? _processingStateSubscription;
  StreamSubscription<PlaybackEvent>? _playbackEventSubscription;
  StreamSubscription<int?>? _indexSubscription;
  final _errorController = StreamController<String>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;

  AudioPlayer get audioPlayer => _audioPlayer;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Source? _currentSource;
  Source? get currentSource => _currentSource;

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
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Show?> playRandomShow({bool filterBySearch = true}) async {
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
        weight = 30;
      } else if (rating == 2) {
        weight = 20;
      } else if (rating == 1) {
        weight = 10;
      } else if (rating == 0) {
        weight = isPlayed ? 5 : 50;
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
      }
      _setError(msg);
      return null;
    }

    // Weighted Random Selection
    int totalWeight = weights.values.fold(0, (sum, w) => sum + w);
    int randomWeight = Random().nextInt(totalWeight);
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
        'Playing random source: ${sourceToPlay.id} (Rating: ${settings.getRating(sourceToPlay.id)}, Played: ${settings.isPlayed(sourceToPlay.id)}, Weight: ${weights[selectedShow]})');

    await playSource(selectedShow, sourceToPlay);
    return selectedShow;
  }

  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0}) async {
    _currentShow = show;
    _currentSource = source;
    // Notify ShowListProvider to ensuring visibility
    _showListProvider?.setPlayingShow(show.name, source.id);
    notifyListeners(); // Notify immediately so the UI can update

    // Start audio loading in the background
    await _loadAndPlayAudio(source, initialIndex: initialIndex);
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

  Future<void> _loadAndPlayAudio(Source source, {int initialIndex = 0}) async {
    logger.i(
        'Loading show: ${_currentShow!.name}, source: ${source.id}, starting at index: $initialIndex');
    Uri? artUri;
    try {
      artUri = await _getAlbumArtUri();
    } catch (e) {
      logger.w('Failed to get album art URI: $e');
    }

    try {
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
