import 'package:flutter/foundation.dart';
import 'dart:js_interop';

@JS('updateThemeBranding')
external void _updateThemeBranding(JSString themeColor, JSString bgColor);

class PwaThemeSync {
  static void update(String themeColor, String bgColor) {
    if (!kIsWeb) return;
    try {
      _updateThemeBranding(themeColor.toJS, bgColor.toJS);
    } catch (e) {
      debugPrint('PWA Theme Sync failed: $e');
    }
  }
}
