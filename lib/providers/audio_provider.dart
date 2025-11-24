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
        if (_settingsProvider?.playRandomOnCompletion ?? false) {
          logger.i('Playlist completed, playing random show.');
          await playRandomShow();
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

  Future<Show?> playRandomShow() async {
    final shows = _showListProvider?.filteredShows;
    if (shows == null || shows.isEmpty) {
      logger.w('Cannot play random show, no shows available.');
      return null;
    }

    // Create a flat list of all possible sources (SHNIDs), each paired with its parent show.
    final List<(Show, Source)> allSources = [];
    for (final show in shows) {
      for (final source in show.sources) {
        allSources.add((show, source));
      }
    }

    if (allSources.isEmpty) {
      logger
          .w('Cannot play random source, no sources found in filtered shows.');
      return null;
    }

    // Pick a random (Show, Source) pair.
    final randomPair = allSources[Random().nextInt(allSources.length)];
    final Show showToPlay = randomPair.$1;
    final Source sourceToPlay = randomPair.$2;

    logger.i(
        'Playing random source ${sourceToPlay.id} from show ${showToPlay.name}');

    // Play the randomly selected source.
    // Don't await here so the UI can scroll immediately while audio loads.
    playSource(showToPlay, sourceToPlay);

    // Return the parent show so the UI can scroll to it.
    return showToPlay;
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
