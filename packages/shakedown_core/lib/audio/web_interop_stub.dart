import 'dart:async';

class WebInterop {
  static void syncMediaSession(bool isPlaying) {}

  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
  }) {}

  static void updatePositionState({
    required double duration,
    required double position,
    bool playing = true,
  }) {}

  static Stream<dynamic> get onWorkerTick => const Stream.empty();
}
