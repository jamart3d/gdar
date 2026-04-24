import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';

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
  GaplessPlayer({AudioPlayer? audioPlayer, bool? useWebGaplessEngine})
    : _player = audioPlayer ?? AudioPlayer();

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

  /// Returns the name of the active audio engine.
  String get engineName => 'Standard Engine (just_audio)';

  /// Returns the reason why the current engine was selected.
  String get selectionReason => 'Native platform (not web)';

  /// Returns the resolved [AudioEngineMode].
  AudioEngineMode get activeMode => AudioEngineMode.standard;

  /// No-op on native.
  void reload() {}

  /// Forces a state resync on web engines. No-op on native.
  void resync({String reason = 'manual'}) {}

  /// Enables a short-lived sync debug probe. No-op on native.
  void startSyncDebugProbe(
    String tag, {
    Duration window = const Duration(seconds: 6),
  }) {}

  /// Whether a short-lived sync debug probe is active.
  bool get syncDebugProbeActive => false;

  /// Current sync debug probe label, if any.
  String? get syncDebugProbeTag => null;

  /// Returns the buffered duration of the next track.
  /// Only applicable to web gapless engine; returns null natively.
  Duration? get nextTrackBuffered => null;

  /// Returns the total duration of the next track.
  /// Only applicable to web gapless engine; returns null natively.
  Duration? get nextTrackTotal => null;

  /// Android audio session ID, if available.
  int? get androidAudioSessionId => _player.androidAudioSessionId;

  /// JS engine tick drift (not applicable natively).
  double get drift => 0.0;

  /// JS engine visibility status (not applicable natively).
  String get visibility => 'N/A';

  /// Raw JS engine state string (not applicable natively).
  String get engineStateString => 'native';

  /// Raw JS context state (not applicable natively).
  String get engineContextState => 'native';

  /// Heartbeat active state (not applicable natively).
  bool get heartbeatActive => false;

  /// Heartbeat needed state (not applicable natively).
  bool get heartbeatNeeded => false;

  /// Heartbeat blocked diagnostics (not applicable natively).
  ({int count, String lastReason}) get heartbeatBlockedDiagnostics {
    return (count: 0, lastReason: '');
  }

  /// Heartbeat blocked count (not applicable natively).
  int get heartbeatBlockedCount => 0;

  /// Heartbeat blocked reason (not applicable natively).
  String get heartbeatLastBlockedReason => '';

  /// Fetch TTFB (not applicable natively).
  double? get fetchTtfbMs => null;

  /// Fetch in-flight flag (not applicable natively).
  bool get fetchInFlight => false;

  /// Last track gap (not applicable natively).
  double? get lastGapMs => null;

  /// JS engine scheduled index (not applicable natively).
  int? get scheduledIndex => null;

  /// JS engine scheduled context time (not applicable natively).
  double? get scheduledStartContextTime => null;

  /// JS engine current AudioContext time (not applicable natively).
  double? get ctxCurrentTime => null;

  /// JS engine output latency (not applicable natively).
  double? get outputLatencyMs => null;

  /// JS engine last decode duration (not applicable natively).
  double? get lastDecodeMs => null;

  /// JS engine last concat duration (not applicable natively).
  double? get lastConcatMs => null;

  /// JS engine failed track count (not applicable natively).
  int? get failedTrackCount => null;

  /// JS engine worker tick count (not applicable natively).
  int? get workerTickCount => null;

  /// JS engine sample rate (not applicable natively).
  int? get sampleRate => null;

  /// JS engine decoded cache size (not applicable natively).
  int? get decodedCacheSize => null;

  /// JS engine handoff state (not applicable natively).
  String? get handoffState => null;

  /// JS engine handoff attempt count (not applicable natively).
  int? get handoffAttemptCount => null;

  /// JS engine last handoff poll count (not applicable natively).
  int? get lastHandoffPollCount => null;

  // ─── Passthrough streams ─────────────────────────────────────────────────

  /// Stream of [PlayerState] changes.
  Stream<PlayerState> get playerStateStream => _player.playerStateStream;

  /// Stream of [PlaybackEvent] changes.
  Stream<PlaybackEvent> get playbackEventStream => _player.playbackEventStream;

  /// Stream of browser play-blocked notifications.
  /// Empty on native platforms.
  Stream<void> get playBlockedStream => const Stream.empty();

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

  /// Stream of heartbeat active state.
  Stream<bool> get heartbeatActiveStream => Stream.value(false);

  /// Stream of heartbeat needed state.
  Stream<bool> get heartbeatNeededStream => Stream.value(false);

  /// Stream of the raw string state from the JS engine (e.g. 'handoff_countdown')
  Stream<String> get engineStateStringStream => const Stream.empty();

  /// Stream of the raw JS contextState (e.g. 'hybrid_foreground').
  Stream<String> get engineContextStateStream => const Stream.empty();

  /// Stream of JS engine tick drift.
  Stream<double> get driftStream => const Stream.empty();

  /// Stream of JS engine visibility status.
  Stream<String> get visibilityStream => const Stream.empty();

  /// Stream of scheduled context time.
  Stream<double?> get scheduledStartContextTimeStream => const Stream.empty();

  /// Stream of output latency.
  Stream<double?> get outputLatencyMsStream => const Stream.empty();

  /// Stream of last decode duration.
  Stream<double?> get lastDecodeMsStream => const Stream.empty();

  /// Stream of last concat duration.
  Stream<double?> get lastConcatMsStream => const Stream.empty();

  /// Stream of failed track count.
  Stream<int?> get failedTrackCountStream => const Stream.empty();

  /// Stream of worker tick count.
  Stream<int?> get workerTickCountStream => const Stream.empty();

  /// Stream of sample rate.
  Stream<int?> get sampleRateStream => const Stream.empty();

  /// Stream of decoded cache size.
  Stream<int?> get decodedCacheSizeStream => const Stream.empty();

  /// Stream of handoff state.
  Stream<String?> get handoffStateStream => const Stream.empty();

  /// Stream of handoff attempt count.
  Stream<int?> get handoffAttemptCountStream => const Stream.empty();

  /// Stream of last handoff poll count.
  Stream<int?> get lastHandoffPollCountStream => const Stream.empty();

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
  }) => _player.setAudioSources(
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

  /// Sets the hybrid handoff mode. No-op on native.
  void setHybridHandoffMode(String mode) {
    // Not applicable natively
  }

  /// Sets the hybrid background mode. No-op on native.
  void setHybridBackgroundMode(String mode) {
    // Not applicable natively
  }

  /// Sets whether Web Audio should remain active while hidden. No-op on native.
  void setHybridAllowHiddenWebAudio(bool enabled) {
    // Not applicable natively
  }

  /// Sets hybrid handoff crossfade in milliseconds. No-op on native.
  void setHandoffCrossfadeMs(int ms) {
    // Not applicable natively
  }

  /// Sets transition mode for web engines. No-op on native.
  void setTrackTransitionMode(String mode) {
    // Not applicable natively
  }

  /// Stops playback and releases resources.
  Future<void> stop() => _player.stop();

  /// Sets the volume (0.0 to 1.0).
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  /// Seeks to [position] in the current track, or to [index] if provided.
  Future<void> seek(Duration? position, {int? index}) =>
      _player.seek(position, index: index);

  /// Sets the prefetch window for JS engines. No-op on native.
  void setPrefetchSeconds(int seconds) {}

  /// Seeks to the next item in the sequence.
  Future<void> seekToNext() => _player.seekToNext();

  /// Seeks to the previous item in the sequence.
  Future<void> seekToPrevious() => _player.seekToPrevious();

  /// Releases all resources held by this player.
  Future<void> dispose() => _player.dispose();

  /// Updates the prefetch window. (Ignored natively; kept for API parity with web).
  void setWebPrefetchSeconds(int seconds) {}
}
