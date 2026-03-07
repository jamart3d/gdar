import 'package:flutter/foundation.dart';

// Conditional import to prevent 'dart:js_interop' from breaking VM tests
import 'pwa_theme_sync_noop.dart'
    if (dart.library.js_interop) 'pwa_theme_sync_web.dart';

class PwaThemeSync {
  static void update(String themeColor, String bgColor) {
    if (!kIsWeb) return;
    PwaThemeSyncInternal.updateEffect(themeColor, bgColor);
  }
}
