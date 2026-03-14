import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;


/// Utility class for JS Interop and Web-specific background stability.
class WebInterop {
  /// Sets the MediaSession playback state to 'playing' or 'paused'.
  /// This helps the OS/Browser understand the process priority.
  static void syncMediaSession(bool isPlaying) {
    try {
      final mediaSession = web.window.navigator.mediaSession;
      mediaSession.playbackState = isPlaying ? 'playing' : 'paused';
    } catch (e) {
      // MediaSession might not be available in all browsers/contexts
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
