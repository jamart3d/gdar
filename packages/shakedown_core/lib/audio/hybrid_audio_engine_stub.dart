import 'dart:async';
import 'package:just_audio/just_audio.dart';

class HybridAudioEngine {
  HybridAudioEngine();

  bool get playing => false;
  Duration get position => Duration.zero;
  Duration get bufferedPosition => Duration.zero;
  Duration? get duration => null;
  Duration? get nextTrackBuffered => null;
  Duration? get nextTrackTotal => null;
  int? get currentIndex => null;
  List<IndexedAudioSource> get sequence => [];
  ProcessingState get processingState => ProcessingState.idle;
  PlayerState get playerState => PlayerState(false, ProcessingState.idle);
  String get engineName => 'Hybrid Stub (Native)';
  String get selectionReason => 'Stub';
  AudioEngineMode get activeMode => AudioEngineMode.hybrid;
  int? get androidAudioSessionId => null;

  Stream<PlayerState> get playerStateStream => const Stream.empty();
  Stream<PlaybackEvent> get playbackEventStream => const Stream.empty();
  Stream<bool> get playingStream => const Stream.empty();
  Stream<ProcessingState> get processingStateStream => const Stream.empty();
  Stream<Duration> get bufferedPositionStream => const Stream.empty();
  Stream<Duration> get positionStream => const Stream.empty();
  Stream<Duration?> get durationStream => const Stream.empty();
  Stream<int?> get currentIndexStream => const Stream.empty();
  Stream<Duration?> get nextTrackBufferedStream => const Stream.empty();
  Stream<Duration?> get nextTrackTotalStream => const Stream.empty();
  Stream<SequenceState?> get sequenceStateStream => const Stream.empty();
  Stream<String> get contextStateStream => const Stream.empty();

  Future<Duration?> setAudioSources(
    List<AudioSource> children, {
    int initialIndex = 0,
    Duration initialPosition = Duration.zero,
    bool preload = true,
  }) async => null;
  Future<void> addAudioSources(List<AudioSource> sources) async {}
  Future<void> play() async {}
  Future<void> pause() async {}
  Future<void> stop() async {}
  Future<void> seek(Duration? position, {int? index}) async {}
  Future<void> seekToNext() async {}
  Future<void> seekToPrevious() async {}
  void setWebPrefetchSeconds(int seconds) {}
  void setTrackTransitionMode(String mode) {}
  void setCrossfadeDuration(double seconds) {}
  Future<void> dispose() async {}
  void reload() {}
}

enum AudioEngineMode { hybrid, native }
