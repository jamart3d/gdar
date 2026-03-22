import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/utils/pwa_theme_sync.dart';
import 'package:shakedown_core/providers/settings_provider.dart';

enum ThemeStyle { android, fruit }

enum NeumorphicStyle { convex, concave }

enum FruitColorOption { sophisticate, minimalist, creative }

class ThemeProvider with ChangeNotifier {
  static ThemeProvider? _instance;
  static ThemeProvider? get getInstance => _instance;

  static const String _themeModeKey = 'theme_mode_preference';
  static const String _themeStyleKey = 'theme_style_preference';
  static const String _fruitColorOptionKey = 'fruit_color_option_preference';
  static const String _webFruitThemeInitKey = 'web_fruit_theme_init_v1';
  static const String _webAndroidThemeInitKey = 'web_android_theme_init_v1';

  // 0 = System, 1 = Light, 2 = Dark
  int _themeModeIndex;
  // 0 = Android, 1 = Fruit
  int _themeStyleIndex;
  // 0 = Sophisticate, 1 = Minimalist, 2 = Creative
  int _fruitColorOptionIndex;

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationComplete => _initCompleter.future;

  final bool isTv;

  @visibleForTesting
  bool testOnlyOverrideFruitAllowed = false;

  /// Whether the Fruit theme is allowed on this platform/configuration.
  /// Strictly follows the "Walled Architecture" policy:
  /// - Web/PWA: Allowed (Exclusive Domain).
  /// - Native (Any): Forbidden.
  /// - TV: Forbidden.
  bool get isFruitAllowed => testOnlyOverrideFruitAllowed || (kIsWeb && !isTv);

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

  /// Convenience getter to check if the active theme is Fruit (Apple Liquid Glass).
  /// This automatically respects the platform gates (Web only, non-TV).
  bool get isFruit => themeStyle == ThemeStyle.fruit;

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
      _themeStyleIndex = 0, // Default to Android on all platforms
      _fruitColorOptionIndex = 0 {
    _instance = this;
    _init();
  }

  Future<void> _init() async {
    await _loadThemePreference();
    if (!_initCompleter.isCompleted) {
      _initCompleter.complete();
    }
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
    _syncPwaBranding();
    notifyListeners();
  }

  SettingsProvider? _settingsProvider;

  void setSettingsProvider(SettingsProvider provider) {
    if (_settingsProvider != null) {
      _settingsProvider!.removeListener(_syncPwaBranding);
    }
    _settingsProvider = provider;
    _settingsProvider!.addListener(_syncPwaBranding);
    _syncPwaBranding();
  }

  void setThemeStyle(ThemeStyle style) {
    // Audit check: Don't allow Fruit theme where forbidden by spec.
    if (!isFruitAllowed && style == ThemeStyle.fruit) return;

    bool wasFruit = themeStyle == ThemeStyle.fruit;
    _themeStyleIndex = style == ThemeStyle.fruit ? 1 : 0;

    // One-time reset when switching TO fruit theme
    if (style == ThemeStyle.fruit && !wasFruit) {
      _fruitColorOptionIndex = Random().nextInt(3);

      _checkAndResetFruitSettings();
    }

    // One-time reset when switching TO android theme
    if (style == ThemeStyle.android && wasFruit) {
      _checkAndResetAndroidSettings();
    }

    unawaited(_saveThemePreference());
    _syncPwaBranding();
    notifyListeners();
  }

  void _checkAndResetFruitSettings() {
    final prefs = _settingsProvider?.prefs;
    if (prefs == null) return;
    if (!prefs.containsKey(_webFruitThemeInitKey) ||
        prefs.getBool(_webFruitThemeInitKey) == false) {
      _settingsProvider?.resetFruitFirstTimeSettings();
      prefs.setBool(_webFruitThemeInitKey, true);
    }
  }

  void _checkAndResetAndroidSettings() {
    final prefs = _settingsProvider?.prefs;
    if (prefs == null) return;
    if (!prefs.containsKey(_webAndroidThemeInitKey) ||
        prefs.getBool(_webAndroidThemeInitKey) == false) {
      _settingsProvider?.resetAndroidFirstTimeSettings();
      prefs.setBool(_webAndroidThemeInitKey, true);
    }
  }

  void setFruitColorOption(FruitColorOption option) {
    _fruitColorOptionIndex = option.index;
    unawaited(_saveThemePreference());
    _syncPwaBranding();
    notifyListeners();
  }

  // Backwards compatibility for the old toggle switch
  void toggleTheme({Brightness? currentBrightness}) {
    bool currentlyDark = isDarkMode;
    if (_themeModeIndex == 0 && currentBrightness != null) {
      currentlyDark = currentBrightness == Brightness.dark;
    }
    setThemeMode(currentlyDark ? ThemeMode.light : ThemeMode.dark);
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
    _themeStyleIndex = prefs.getInt(_themeStyleKey) ?? 0;

    // Safety check for existing preferences: Force back to Android if it drifted
    if (!isFruitAllowed && _themeStyleIndex == 1) {
      _themeStyleIndex = 0;
    }

    _fruitColorOptionIndex = prefs.getInt(_fruitColorOptionKey) ?? 0;
    _syncPwaBranding();
    notifyListeners();
  }

  void _syncPwaBranding() {
    if (!kIsWeb) return;

    String themeColor = '#000000';
    String bgColor = '#000000';

    final bool useTrueBlack = _settingsProvider?.useTrueBlack ?? false;

    if (isDarkMode) {
      if (useTrueBlack) {
        themeColor = '#000000';
        // bgColor = '#000000'; // Leaving background_color alone as requested
      } else if (themeStyle == ThemeStyle.fruit) {
        switch (fruitColorOption) {
          case FruitColorOption.sophisticate:
            themeColor = '#0F172A';
            break;
          case FruitColorOption.minimalist:
            themeColor = '#1C1C1E';
            break;
          case FruitColorOption.creative:
            themeColor = '#1A1A1A';
            break;
        }
      } else {
        themeColor = '#000000';
      }
    } else {
      if (themeStyle == ThemeStyle.fruit) {
        switch (fruitColorOption) {
          case FruitColorOption.sophisticate:
            themeColor = '#E0E5EC';
            break;
          case FruitColorOption.minimalist:
            themeColor = '#FFFFFF';
            break;
          case FruitColorOption.creative:
            themeColor = '#FFF9F9';
            break;
        }
      } else {
        themeColor = '#F5F5F5'; // Scaffold background
      }
    }

    // Keep active bgColor from existing logic for now
    if (isDarkMode) {
      if (themeStyle == ThemeStyle.fruit) {
        switch (fruitColorOption) {
          case FruitColorOption.sophisticate:
            bgColor = '#0F172A';
            break;
          case FruitColorOption.minimalist:
            bgColor = '#1C1C1E';
            break;
          case FruitColorOption.creative:
            bgColor = '#1A1A1A';
            break;
        }
      } else {
        bgColor = '#000000';
      }
    } else {
      if (themeStyle == ThemeStyle.fruit) {
        switch (fruitColorOption) {
          case FruitColorOption.sophisticate:
            bgColor = '#E0E5EC';
            break;
          case FruitColorOption.minimalist:
            bgColor = '#FFFFFF';
            break;
          case FruitColorOption.creative:
            bgColor = '#FFF9F9';
            break;
        }
      } else {
        bgColor = '#F5F5F5';
      }
    }

    PwaThemeSync.update(themeColor, bgColor);
  }
}
