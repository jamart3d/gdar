// lib/providers/theme_provider.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode_preference';

  // 0 = System, 1 = Light, 2 = Dark
  int _themeModeIndex;
  final bool isTv;

  ThemeMode get currentThemeMode {
    switch (_themeModeIndex) {
      case 1:
        return ThemeMode.light;
      case 2:
        return ThemeMode.dark;
      case 0:
      default:
        return ThemeMode.system;
    }
  }

  // Convenience getter for the SegmentedButton
  ThemeMode get selectedThemeMode => currentThemeMode;

  // We still need a way to know if we are CURRENTLY resolving as dark mode
  // for the rest of the app (like SystemUiOverlayStyle).
  // We'll expose a getter that checks the brightness if it's system.
  // HOWEVER, we don't have BuildContext here. So we should only use
  // this for places that *must* know without context, or we refactor them.
  // For now, let's keep a simplified `isDarkMode` that assumes Dark if System & TV,
  // but true dynamic resolution requires BuildContext.

  // A helper that returns the *intended* dark mode status if strictly light/dark.
  // We'll rename this or adapt where it's used.
  bool get isDarkMode {
    if (_themeModeIndex == 2) return true;
    if (_themeModeIndex == 1) return false;
    return isTv; // Fallback for System mode if context isn't available
  }

  ThemeProvider({this.isTv = false}) : _themeModeIndex = isTv ? 2 : 0 {
    unawaited(_loadThemePreference());
  }

  void setThemeMode(ThemeMode mode) {
    if (mode == ThemeMode.system) {
      _themeModeIndex = 0;
    } else if (mode == ThemeMode.light) {
      _themeModeIndex = 1;
    } else if (mode == ThemeMode.dark) {
      _themeModeIndex = 2;
    }

    unawaited(_saveThemePreference());
    notifyListeners();
  }

  // Backwards compatibility for the old toggle switch just in case it's used elsewhere
  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeModeIndex);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to TV mode setting (2=Dark) or System (0)
    _themeModeIndex = prefs.getInt(_themeModeKey) ?? (isTv ? 2 : 0);
    notifyListeners();
  }
}
