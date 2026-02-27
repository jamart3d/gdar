/// Wrapper for various implementations.
library;

export 'gapless_player_native.dart'
    if (dart.library.js_interop) 'gapless_player_web.dart';

/// Explicit audio engine modes.
enum AudioEngineMode {
  auto,
  webAudio,
  html5,
  standard,
  passive,
  hybrid;

  /// Parses a string into an [AudioEngineMode].
  static AudioEngineMode fromString(String? value) {
    if (value == 'webAudio') return AudioEngineMode.webAudio;
    if (value == 'html5') return AudioEngineMode.html5;
    if (value == 'standard') return AudioEngineMode.standard;
    if (value == 'passive') return AudioEngineMode.passive;
    if (value == 'hybrid') return AudioEngineMode.hybrid;
    return AudioEngineMode.auto;
  }
}
