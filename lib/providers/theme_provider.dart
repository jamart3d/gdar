import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ThemeStyle { android, fruit }

enum NeumorphicStyle { convex, concave }

enum FruitColorOption { sophisticate, minimalist, creative }

class ThemeProvider with ChangeNotifier {
  static const String _themeModeKey = 'theme_mode_preference';
  static const String _themeStyleKey = 'theme_style_preference';
  static const String _fruitColorOptionKey = 'fruit_color_option_preference';
  static const String _webFruitThemeInitKey = 'web_fruit_theme_init_v1';

  // 0 = System, 1 = Light, 2 = Dark
  int _themeModeIndex;
  // 0 = Android, 1 = Fruit
  int _themeStyleIndex;
  // 0 = Sophisticate, 1 = Minimalist, 2 = Creative
  int _fruitColorOptionIndex;
  final bool isTv;

  /// Whether the Fruit theme is allowed on this platform/configuration.
  /// Strictly follows the "Walled Architecture" policy:
  /// - Web/PWA: Allowed (Exclusive Domain).
  /// - Native (Any): Forbidden.
  /// - TV: Forbidden.
  bool get isFruitAllowed => kIsWeb && !isTv;

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

  ThemeStyle get themeStyle {
    if (!isFruitAllowed) return ThemeStyle.android;
    return _themeStyleIndex == 1 ? ThemeStyle.fruit : ThemeStyle.android;
  }

  FruitColorOption get fruitColorOption =>
      FruitColorOption.values[_fruitColorOptionIndex];

  // Convenience getter for the SegmentedButton
  ThemeMode get selectedThemeMode => currentThemeMode;

  // A helper that returns the *intended* dark mode status if strictly light/dark.
  bool get isDarkMode {
    if (_themeModeIndex == 2) return true;
    if (_themeModeIndex == 1) return false;
    return isTv; // Fallback for System mode if context isn't available
  }

  ThemeProvider({this.isTv = false})
      : _themeModeIndex = isTv ? 2 : 0,
        _themeStyleIndex = (kIsWeb && !isTv) ? 1 : 0, // Default to Fruit on Web
        _fruitColorOptionIndex = 0 {
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

  void setThemeStyle(ThemeStyle style) {
    // Audit check: Don't allow Fruit theme where forbidden by spec.
    if (!isFruitAllowed && style == ThemeStyle.fruit) return;

    bool wasFruit = themeStyle == ThemeStyle.fruit;
    _themeStyleIndex = style == ThemeStyle.fruit ? 1 : 0;

    // Randomly select a color option when switching TO fruit theme
    if (style == ThemeStyle.fruit && !wasFruit) {
      _fruitColorOptionIndex = Random().nextInt(3);
    }

    unawaited(_saveThemePreference());
    notifyListeners();
  }

  void setFruitColorOption(FruitColorOption option) {
    _fruitColorOptionIndex = option.index;
    unawaited(_saveThemePreference());
    notifyListeners();
  }

  // Backwards compatibility for the old toggle switch
  void toggleTheme() {
    setThemeMode(isDarkMode ? ThemeMode.light : ThemeMode.dark);
  }

  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeModeKey, _themeModeIndex);
    await prefs.setInt(_themeStyleKey, _themeStyleIndex);
    await prefs.setInt(_fruitColorOptionKey, _fruitColorOptionIndex);
  }

  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();

    // Default to TV mode setting (2=Dark) or System (0)
    _themeModeIndex = prefs.getInt(_themeModeKey) ?? (isTv ? 2 : 0);

    if (!prefs.containsKey(_webFruitThemeInitKey)) {
      _themeStyleIndex = isFruitAllowed ? 1 : 0;
      await prefs.setBool(_webFruitThemeInitKey, true);
      await prefs.setInt(_themeStyleKey, _themeStyleIndex);
    } else {
      _themeStyleIndex =
          prefs.getInt(_themeStyleKey) ?? (isFruitAllowed ? 1 : 0);

      // Safety check for existing preferences: Force back to Android if it drifted
      if (!isFruitAllowed && _themeStyleIndex == 1) {
        _themeStyleIndex = 0;
      }
    }

    _fruitColorOptionIndex = prefs.getInt(_fruitColorOptionKey) ?? 0;
    notifyListeners();
  }
}
