import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _trackNumberKey = 'show_track_numbers';
  // The 'hide_gd_shows' key has been removed.

  bool _showTrackNumbers = false;
  bool get showTrackNumbers => _showTrackNumbers;

  // The state and getter for 'hideGdShows' have been removed.

  SettingsProvider() {
    _loadPreferences();
  }

  void toggleShowTrackNumbers() {
    _showTrackNumbers = !_showTrackNumbers;
    _savePreferences();
    notifyListeners();
  }

  // The 'toggleHideGdShows' method has been removed.

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackNumberKey, _showTrackNumbers);
    // Saving for 'hideGdShows' has been removed.
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? false;
    // Loading for 'hideGdShows' has been removed.
    notifyListeners();
  }
}

