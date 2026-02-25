import 'dart:async';

import 'package:just_audio/just_audio.dart';

/// Native (Android / TV / desktop) implementation of [GaplessPlayer].
///
/// This is a transparent delegate to [AudioPlayer] from `just_audio`.
/// It exposes an identical API so that [AudioProvider] and [BufferAgent]
/// have zero native-platform changes.
class GaplessPlayer {
  final AudioPlayer _player;

  /// Creates a [GaplessPlayer] wrapping an [AudioPlayer].
  ///
  /// An existing [AudioPlayer] can be injected for testing.
  /// [useWebGaplessEngine] is ignored natively but kept for API parity.
  GaplessPlayer({
    AudioPlayer? audioPlayer,
    bool useWebGaplessEngine = true,
  }) : _player = audioPlayer ?? AudioPlayer();

  // ─── Passthrough getters ─────────────────────────────────────────────────

  /// Whether the player is currently playing.
  bool get playing => _player.playing;

  /// The current playback position.
  Duration get position => _player.position;

  /// The current buffered position.
  Duration get bufferedPosition => _player.bufferedPosition;

  /// The duration of the current track, if known.
  Duration? get duration => _player.duration;

  /// The index of the currently playing item in the sequence.
  int? get currentIndex => _player.currentIndex;

  /// The current ordered sequence of [IndexedAudioSource]s.
  List<IndexedAudioSource> get sequence => _player.sequence;

  /// The current [ProcessingState].
  ProcessingState get processingState => _player.processingState;

  /// The current synchronous [PlayerState] snapshot.
  PlayerState get playerState => _player.playerState;

  /// Returns the buffered duration of the next track.
  /// Only applicable to web gapless engine; returns null natively.
  Duration? get nextTrackBuffered => null;

  /// Returns the total duration of the next track.
  /// Only applicable to web gapless engine; returns null natively.
  Duration? get nextTrackTotal => null;

  /// Android audio session ID, if available.
  int? get androidAudioSessionId => _player.androidAudioSessionId;

  // ─── Passthrough streams ─────────────────────────────────────────────────

  /// Stream of [PlayerState] changes.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of [PlaybackEvent] changes.
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  /// Stream of playing state (bool) changes.
  Stream<bool> get playingStream => _player.playingStream;

  /// Stream of [ProcessingState] changes.
  Stream<ProcessingState> get processingStateStream =>
      _player.processingStateStream;

  /// Stream of buffered position changes.
  Stream<Duration> get bufferedPositionStream => _player.bufferedPositionStream;

  /// Stream of position changes.
  Stream<Duration> get positionStream => _player.positionStream;

  /// Stream of duration changes.
  Stream<Duration?> get durationStream => _player.durationStream;

  /// Stream of next track buffered duration.
  /// Only applicable to web gapless engine; empty stream natively.
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();

  /// Stream of next track total duration.
  /// Only applicable to web gapless engine; empty stream natively.
  Stream<Duration?> get nextTrackTotalStream => const Stream.empty();

  /// Stream of current index changes.
  Stream<int?> get currentIndexStream => _player.currentIndexStream;

  /// Stream of [SequenceState] changes (current sequence + index).
  Stream<SequenceState?> get sequenceStateStream => _player.sequenceStateStream;

  // ─── Passthrough methods ─────────────────────────────────────────────────

  /// Loads a list of audio sources, optionally preloading them.
  Future<Duration?> setAudioSources(
    List<AudioSource> children, {
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool preload = true,
  }) =>
      _player.setAudioSources(
        children,
        initialIndex: initialIndex,
        initialPosition: initialPosition,
        preload: preload,
      );

  /// Appends additional audio sources to the existing playlist.
  Future<void> addAudioSources(List<AudioSource> sources) =>
      _player.addAudioSources(sources);

  /// Begins or resumes playback.
  Future<void> play() => _player.play();

  /// Pauses playback.
  Future<void> pause() => _player.pause();

  /// Stops playback and releases resources.
  Future<void> stop() => _player.stop();

  /// Seeks to [position] in the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) =>
      _player.seek(position, index: index);

  /// Seeks to the next item in the sequence.
  Future<void> seekToNext() => _player.seekToNext();

  /// Seeks to the previous item in the sequence.
  Future<void> seekToPrevious() => _player.seekToPrevious();

  /// Releases all resources held by this player.
  Future<void> dispose() => _player.dispose();

  /// Updates the prefetch window. (Ignored natively; kept for API parity with web).
  void setWebPrefetchSeconds(int seconds) {}
}
