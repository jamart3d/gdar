import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _trackNumberKey = 'show_track_numbers';

  bool _showTrackNumbers = false;
  bool get showTrackNumbers => _showTrackNumbers;

  SettingsProvider() {
    _loadPreference();
  }

  void toggleShowTrackNumbers() {
    _showTrackNumbers = !_showTrackNumbers;
    _savePreference();
    notifyListeners();
  }

  Future<void> _savePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackNumberKey, _showTrackNumbers);
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? false;
    notifyListeners();
  }
}

