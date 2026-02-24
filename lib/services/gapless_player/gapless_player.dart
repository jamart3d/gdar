/// Wrapper for various implementations.
library;

export 'gapless_player_native.dart'
    if (dart.library.js_interop) 'gapless_player_web.dart';
