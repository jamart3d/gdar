import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _sliverViewKey = 'use_sliver_view';

  bool _showTrackNumbers = true;
  bool _useSliverView = false;

  bool get showTrackNumbers => _showTrackNumbers;
  bool get useSliverView => _useSliverView;

  SettingsProvider() {
    _loadPreferences();
  }

  void toggleShowTrackNumbers() {
    _showTrackNumbers = !_showTrackNumbers;
    _savePreferences();
    notifyListeners();
  }

  void toggleSliverView() {
    _useSliverView = !_useSliverView;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackNumberKey, _showTrackNumbers);
    await prefs.setBool(_sliverViewKey, _useSliverView);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? true;
    _useSliverView = prefs.getBool(_sliverViewKey) ?? false;
    notifyListeners();
  }
}

