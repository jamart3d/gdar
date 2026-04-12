import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

@JS('_gdarMediaSession')
external _GdarMediaSession? get _mediaSession;

@JS()
@anonymous
extension type _GdarMediaSession(JSObject _) {
  external void updatePlaybackState(bool playing);
  external void updateMetadata(_MediaMetadataArg metadata);
  external void updatePositionState(_PositionStateArg state);
  external void forceSync();
}

@JS()
@anonymous
extension type _MediaMetadataArg._(JSObject _) implements JSObject {
  external factory _MediaMetadataArg({
    required String title,
    required String artist,
    required String album,
  });
}

@JS()
@anonymous
extension type _PositionStateArg._(JSObject _) implements JSObject {
  external factory _PositionStateArg({
    required double duration,
    required double position,
    required bool playing,
  });
}

/// Utility class for JS Interop and Web-specific background stability.
class WebInterop {
  /// Syncs playback state through the centralised JS MediaSession anchor.
  static void syncMediaSession(bool isPlaying) {
    try {
      _mediaSession?.updatePlaybackState(isPlaying);
    } catch (_) {
      // Anchor not available
    }
  }

  /// Pushes track metadata to the OS notification via the JS MediaSession
  /// anchor.
  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
  }) {
    try {
      _mediaSession?.updateMetadata(
        _MediaMetadataArg(title: title, artist: artist, album: album),
      );
    } catch (_) {
      // Anchor not available
    }
  }

  /// Pushes scrubber position state to the OS notification.
  static void updatePositionState({
    required double duration,
    required double position,
    bool playing = true,
  }) {
    try {
      _mediaSession?.updatePositionState(
        _PositionStateArg(
          duration: duration,
          position: position,
          playing: playing,
        ),
      );
    } catch (_) {
      // Anchor not available
    }
  }

  /// Listens for the custom 'gdar-worker-tick' event, which is fired
  /// by a Web Worker to bypass 1Hz background clamping.
  /// Returns a stream of events.
  static Stream<web.Event> get onWorkerTick {
    final controller = StreamController<web.Event>.broadcast();
    web.window.addEventListener(
      'gdar-worker-tick',
      (web.Event event) {
        controller.add(event);
      }.toJS,
    );
    return controller.stream;
  }
}
