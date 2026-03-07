import 'dart:js_interop';
import 'package:flutter/foundation.dart';

@JS('updateThemeBranding')
external void _updateThemeBranding(JSString themeColor, JSString bgColor);

class PwaThemeSyncInternal {
  static void updateEffect(String themeColor, String bgColor) {
    try {
      _updateThemeBranding(themeColor.toJS, bgColor.toJS);
    } catch (e) {
      debugPrint('PWA Theme Sync failed: $e');
    }
  }
}
