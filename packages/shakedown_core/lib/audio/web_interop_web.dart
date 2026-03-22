import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

@JS('window._gdarMediaSession.updatePlaybackState')
external void _jsUpdatePlaybackState(bool playing);

/// Utility class for JS Interop and Web-specific background stability.
class WebInterop {
  /// Syncs playback state through the centralised JS MediaSession
  /// anchor so there is a single writer with consistent state tracking.
  static void syncMediaSession(bool isPlaying) {
    try {
      _jsUpdatePlaybackState(isPlaying);
    } catch (e) {
      // Anchor or MediaSession might not be available
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
