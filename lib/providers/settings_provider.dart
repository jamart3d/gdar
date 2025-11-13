import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Preference Keys
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _hideTrackCountKey = 'hide_track_count_in_source_list';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _useSliverAppBarKey = 'use_sliver_app_bar';
  static const String _useSharedAxisTransitionKey = 'use_shared_axis_transition';
  static const String _useHandwritingFontKey = 'use_handwriting_font';
  static const String _scaleShowListKey = 'scale_show_list';
  static const String _scaleTrackListKey = 'scale_track_list';
  static const String _scalePlayerKey = 'scale_player';

  // Hard-coded setting.
  static const bool showExpandIcon = false;

  // Private state
  bool _showTrackNumbers = true;
  bool _playOnTap = false;
  bool _showSingleShnid = false;
  bool _hideTrackCountInSourceList = false;
  bool _playRandomOnCompletion = false;
  bool _useDynamicColor = false;
  bool _useSliverAppBar = false;
  bool _useSharedAxisTransition = false;
  bool _useHandwritingFont = false;
  bool _scaleShowList = false;
  bool _scaleTrackList = false;
  bool _scalePlayer = false;

  // Public getters
  bool get showTrackNumbers => _showTrackNumbers;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => _hideTrackCountInSourceList;
  bool get playRandomOnCompletion => _playRandomOnCompletion;
  bool get useDynamicColor => _useDynamicColor;
  bool get useSliverAppBar => _useSliverAppBar;
  bool get useSharedAxisTransition => _useSharedAxisTransition;
  bool get useHandwritingFont => _useHandwritingFont;
  bool get scaleShowList => _scaleShowList;
  bool get scaleTrackList => _scaleTrackList;
  bool get scalePlayer => _scalePlayer;

  SettingsProvider() {
    _loadPreferences();
  }

  // Toggle methods
  void toggleShowTrackNumbers() =>
      _updatePreference(_trackNumberKey, _showTrackNumbers = !_showTrackNumbers);
  void togglePlayOnTap() =>
      _updatePreference(_playOnTapKey, _playOnTap = !_playOnTap);
  void toggleShowSingleShnid() =>
      _updatePreference(_showSingleShnidKey, _showSingleShnid = !_showSingleShnid);
  void toggleHideTrackCountInSourceList() => _updatePreference(
      _hideTrackCountKey, _hideTrackCountInSourceList = !_hideTrackCountInSourceList);
  void togglePlayRandomOnCompletion() => _updatePreference(
      _playRandomOnCompletionKey, _playRandomOnCompletion = !_playRandomOnCompletion);
  void toggleUseDynamicColor() =>
      _updatePreference(_useDynamicColorKey, _useDynamicColor = !_useDynamicColor);
  void toggleUseSliverAppBar() =>
      _updatePreference(_useSliverAppBarKey, _useSliverAppBar = !_useSliverAppBar);
  void toggleUseSharedAxisTransition() => _updatePreference(
      _useSharedAxisTransitionKey, _useSharedAxisTransition = !_useSharedAxisTransition);
  void toggleUseHandwritingFont() => _updatePreference(
      _useHandwritingFontKey, _useHandwritingFont = !_useHandwritingFont);
  void toggleScaleShowList() =>
      _updatePreference(_scaleShowListKey, _scaleShowList = !_scaleShowList);
  void toggleScaleTrackList() =>
      _updatePreference(_scaleTrackListKey, _scaleTrackList = !_scaleTrackList);
  void toggleScalePlayer() =>
      _updatePreference(_scalePlayerKey, _scalePlayer = !_scalePlayer);

  // Persistence
  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? true;
    _playOnTap = prefs.getBool(_playOnTapKey) ?? false;
    _showSingleShnid = prefs.getBool(_showSingleShnidKey) ?? false;
    _hideTrackCountInSourceList = prefs.getBool(_hideTrackCountKey) ?? false;
    _playRandomOnCompletion =
        prefs.getBool(_playRandomOnCompletionKey) ?? false;
    _useDynamicColor = prefs.getBool(_useDynamicColorKey) ?? false;
    _useSliverAppBar = prefs.getBool(_useSliverAppBarKey) ?? false;
    _useSharedAxisTransition =
        prefs.getBool(_useSharedAxisTransitionKey) ?? false;
    _useHandwritingFont = prefs.getBool(_useHandwritingFontKey) ?? false;
    _scaleShowList = prefs.getBool(_scaleShowListKey) ?? false;
    _scaleTrackList = prefs.getBool(_scaleTrackListKey) ?? false;
    _scalePlayer = prefs.getBool(_scalePlayerKey) ?? false;

    notifyListeners();
  }
}
