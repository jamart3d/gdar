// lib/providers/theme_provider.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider with ChangeNotifier {
  static const String _themePreferenceKey = 'theme_preference';

  bool _isDarkMode;
  bool get isDarkMode => _isDarkMode;

  final bool isTv;

  ThemeMode get currentThemeMode =>
      _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeProvider({this.isTv = false}) : _isDarkMode = isTv {
    _loadThemePreference();
  }

  // Toggles the theme and saves the preference.
  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _saveThemePreference();
    notifyListeners(); // This tells the UI to rebuild.
  }

  // Saves the current theme choice to the device.
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool(_themePreferenceKey, _isDarkMode);
  }

  // Loads the saved theme choice when the app starts.
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_themePreferenceKey) ??
        isTv; // Default to TV mode setting
    notifyListeners();
  }
}
