import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioProvider with ChangeNotifier {
  late final AudioPlayer _audioPlayer;

  AudioPlayer get audioPlayer => _audioPlayer;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Source? _currentSource;
  Source? get currentSource => _currentSource;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  AudioProvider() {
    _audioPlayer = AudioPlayer();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playShow(Show show) async {
    if (show.sources.isNotEmpty) {
      await playSource(show, show.sources.first);
    } else {
      logger.w('Show ${show.name} has no sources to play.');
    }
  }

  Future<void> playSource(Show show, Source source,
      {int initialIndex = 0}) async {
    _currentShow = show;
    _currentSource = source;
    logger.i(
        'Loading show: ${show.name}, source: ${source.id}, starting at index: $initialIndex');

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
              id: '${show.name}_${source.id}_$index',
              album: show.venue,
              title: track.title,
              artist: show.artist,
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

      notifyListeners();
    } catch (e, stackTrace) {
      logger.e('Error playing source', error: e, stackTrace: stackTrace);
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
