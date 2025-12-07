import 'dart:async';
import 'dart:math';

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
  final _errorController = StreamController<String>.broadcast();

  ShowListProvider? _showListProvider;
  SettingsProvider? _settingsProvider;

  AudioPlayer get audioPlayer => _audioPlayer;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Source? _currentSource;
  Source? get currentSource => _currentSource;

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
          final show = _currentShow!;
          final source = _currentSource;
          // Determine key: if multiple sources, rate source ID, else show name
          final ratingKey = (show.sources.length > 1 && source != null)
              ? source.id
              : show.name;

          await _settingsProvider?.markAsPlayed(ratingKey);
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

  @override
  void dispose() {
    _processingStateSubscription?.cancel();
    _playbackEventSubscription?.cancel();
    _errorController.close();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<Show?> playRandomShow({bool filterBySearch = true}) async {
    final settings = _settingsProvider;
    if (settings == null) return null; // Should not happen

    List<Show>? sourceList;
    if (filterBySearch) {
      sourceList = _showListProvider?.filteredShows;
    } else {
      sourceList = _showListProvider?.allShows;
    }

    if (sourceList == null || sourceList.isEmpty) {
      logger.w('Cannot play random show, no shows available.');
      return null;
    }

    // Filter and Weighting Logic
    final List<Show> candidates = [];
    final Map<Show, int> weights = {};

    for (final show in sourceList) {
      final rating = settings.getRating(show.name);
      final isPlayed = settings.isPlayed(show.name);

      // 1. Exclude Red Star Shows (-1)
      if (rating == -1) continue;

      // 2. Check for at least one unblocked source
      bool hasUnblockedSource = false;
      for (final source in show.sources) {
        if (settings.getRating(source.id) != -1) {
          hasUnblockedSource = true;
          break;
        }
      }
      if (!hasUnblockedSource) continue;

      // 3. Filter by Settings
      if (settings.randomOnlyUnplayed && isPlayed) continue;
      if (settings.randomOnlyHighRated && rating < 2) continue;

      // 4. Calculate Weight
      int weight = 10; // Default weight (1 Star or Unrated)

      if (rating == 3) {
        weight = 30;
      } else if (rating == 2) {
        weight = 20;
      } else if (rating == 1) {
        weight = 10;
      } else if (rating == 0) {
        if (!isPlayed) {
          weight = 50; // Unplayed priority
        } else {
          weight = 5; // Played but unrated (low priority)
        }
      }

      candidates.add(show);
      weights[show] = weight;
    }

    if (candidates.isEmpty) {
      logger.w('No shows match the current random playback criteria.');
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

    selectedShow ??= candidates.first; // Should not happen if logic is correct

    // Filter valid sources (neither blocked themselves, nor in a blocked show - though show is already checked)
    final validSources = selectedShow.sources.where((s) {
      return settings.getRating(s.id) != -1;
    }).toList();

    if (validSources.isEmpty) {
      // This technically shouldn't happen because we checked for at least one unblocked source above
      logger.w('Selected show has no unblocked sources. Skipping.');
      return null;
    }

    final randomSource = validSources[Random().nextInt(validSources.length)];

    logger.i(
        'Playing random show: ${selectedShow.name} (Rating: ${settings.getRating(selectedShow.name)}, Played: ${settings.isPlayed(selectedShow.name)}, Weight: ${weights[selectedShow]})');

    // Play the randomly selected source.
    playSource(selectedShow, randomSource);

    // Return the parent show so the UI can scroll to it.
    return selectedShow;
  }

  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0}) async {
    _currentShow = show;
    _currentSource = source;
    notifyListeners(); // Notify immediately so the UI can update

    // Start audio loading in the background
    await _loadAndPlayAudio(source, initialIndex: initialIndex);
  }

  String? _error;
  String? get error => _error;

  void clearError() {
    _error = null;
  }

  Future<void> _loadAndPlayAudio(Source source, {int initialIndex = 0}) async {
    logger.i(
        'Loading show: ${_currentShow!.name}, source: ${source.id}, starting at index: $initialIndex');
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
}
