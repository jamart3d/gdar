import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _hideTrackCountKey = 'hide_track_count_in_source_list';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';

  // Hard-coded setting, as requested.
  static const bool showExpandIcon = false;

  bool _showTrackNumbers = true;
  bool _playOnTap = false;
  bool _showSingleShnid = false;
  bool _hideTrackCountInSourceList = false;
  bool _playRandomOnCompletion = false;

  bool get showTrackNumbers => _showTrackNumbers;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => _hideTrackCountInSourceList;
  bool get playRandomOnCompletion => _playRandomOnCompletion;

  SettingsProvider() {
    _loadPreferences();
  }

  void toggleShowTrackNumbers() {
    _showTrackNumbers = !_showTrackNumbers;
    _savePreferences();
    notifyListeners();
  }

  void togglePlayOnTap() {
    _playOnTap = !_playOnTap;
    _savePreferences();
    notifyListeners();
  }

  void toggleShowSingleShnid() {
    _showSingleShnid = !_showSingleShnid;
    _savePreferences();
    notifyListeners();
  }

  void toggleHideTrackCountInSourceList() {
    _hideTrackCountInSourceList = !_hideTrackCountInSourceList;
    _savePreferences();
    notifyListeners();
  }

  void togglePlayRandomOnCompletion() {
    _playRandomOnCompletion = !_playRandomOnCompletion;
    _savePreferences();
    notifyListeners();
  }

  Future<void> _savePreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_trackNumberKey, _showTrackNumbers);
    await prefs.setBool(_playOnTapKey, _playOnTap);
    await prefs.setBool(_showSingleShnidKey, _showSingleShnid);
    await prefs.setBool(_hideTrackCountKey, _hideTrackCountInSourceList);
    await prefs.setBool(_playRandomOnCompletionKey, _playRandomOnCompletion);
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? true;
    _playOnTap = prefs.getBool(_playOnTapKey) ?? false;
    _showSingleShnid = prefs.getBool(_showSingleShnidKey) ?? false;
    _hideTrackCountInSourceList = prefs.getBool(_hideTrackCountKey) ?? false;
    _playRandomOnCompletion =
        prefs.getBool(_playRandomOnCompletionKey) ?? false;

    notifyListeners(); // Notify after loading all settings
  }
}
