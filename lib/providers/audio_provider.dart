// lib/providers/audio_provider.dart

import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';

class AudioProvider with ChangeNotifier {
  final AudioPlayer _audioPlayer = AudioPlayer();

  // Public getter for the UI to access the player instance
  AudioPlayer get audioPlayer => _audioPlayer;

  Show? _currentShow;
  Show? get currentShow => _currentShow;

  Stream<PlayerState> get playerStateStream => _audioPlayer.playerStateStream;
  Stream<int?> get currentIndexStream => _audioPlayer.currentIndexStream;
  Stream<Duration?> get durationStream => _audioPlayer.durationStream;
  Stream<Duration> get positionStream => _audioPlayer.positionStream;

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> playShow(Show show) async {
    if (_currentShow?.name == show.name) {
      logger.i('Selected show is already loaded.');
      if (!_audioPlayer.playing) {
        _audioPlayer.play();
      }
      return;
    }

    _currentShow = show;
    logger.i('Loading show: ${show.name}');

    try {
      final playlist = ConcatenatingAudioSource(
        children: show.tracks.asMap().entries.map((entry) {
          int index = entry.key;
          Track track = entry.value;

          return AudioSource.uri(
            Uri.parse(track.url),
            tag: MediaItem(
              id: '${show.name}_$index',
              album: show.venue,
              title: track.title,
              artist: show.artist,
              duration: Duration(seconds: track.duration),
            ),
          );
        }).toList(),
      );

      await _audioPlayer.setAudioSource(playlist, initialIndex: 0, preload: false);
      _audioPlayer.play();

      notifyListeners();

    } catch (e, stackTrace) {
      logger.e('Error playing show', error: e, stackTrace: stackTrace);
    }
  }

  // --- Playback Control Methods ---

  void play() {
    _audioPlayer.play();
  }

  void pause() {
    _audioPlayer.pause();
  }

  void seekToNext() {
    _audioPlayer.seekToNext();
  }

  void seekToPrevious() {
    _audioPlayer.seekToPrevious();
  }

  void seek(Duration position) {
    _audioPlayer.seek(position);
  }

  // New method to jump to a specific track in the playlist
  void seekToTrack(int index) {
    _audioPlayer.seek(Duration.zero, index: index);
    if (!_audioPlayer.playing) {
      _audioPlayer.play();
    }
  }
}