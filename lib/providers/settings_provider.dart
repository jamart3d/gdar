import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Preference Keys
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _hideTrackCountKey = 'hide_track_count_in_source_list';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';
  static const String _playRandomOnStartupKey = 'play_random_on_startup';
  static const String _dateFirstInShowCardKey = 'date_first_in_show_card';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _useSliverAppBarKey = 'use_sliver_app_bar';
  static const String _useSharedAxisTransitionKey = 'use_shared_axis_transition';
  static const String _useHandwritingFontKey = 'use_handwriting_font';
  static const String _scaleShowListKey = 'scale_show_list';
  static const String _scaleTrackListKey = 'scale_track_list';
  static const String _scalePlayerKey = 'scale_player';
  static const String _seedColorKey = 'seed_color';

  // Hard-coded setting.
  bool showExpandIcon = false;

  // Private state
  bool _showTrackNumbers = false;
  bool _playOnTap = false;
  bool _showSingleShnid = false;
  bool _hideTrackCountInSourceList = false;
  bool _playRandomOnCompletion = false;
  bool _playRandomOnStartup = false;
  bool _dateFirstInShowCard = true;
  bool _useDynamicColor = true;
  bool _useSliverAppBar = true;
  bool _useSharedAxisTransition = true;
  bool _useHandwritingFont = true;
  bool _scaleShowList = true;
  bool _scaleTrackList = true;
  bool _scalePlayer = true;
  Color? _seedColor;

  // Public getters
  bool get showTrackNumbers => _showTrackNumbers;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => _hideTrackCountInSourceList;
  bool get playRandomOnCompletion => _playRandomOnCompletion;
  bool get playRandomOnStartup => _playRandomOnStartup;
  bool get dateFirstInShowCard => _dateFirstInShowCard;
  bool get useDynamicColor => _useDynamicColor;
  bool get useSliverAppBar => _useSliverAppBar;
  bool get useSharedAxisTransition => _useSharedAxisTransition;
  bool get useHandwritingFont => _useHandwritingFont;
  bool get scaleShowList => _scaleShowList;
  bool get scaleTrackList => _scaleTrackList;
  bool get scalePlayer => _scalePlayer;
  Color? get seedColor => _seedColor;

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
  void togglePlayRandomOnStartup() => _updatePreference(
      _playRandomOnStartupKey, _playRandomOnStartup = !_playRandomOnStartup);
  void toggleDateFirstInShowCard() => _updatePreference(
      _dateFirstInShowCardKey, _dateFirstInShowCard = !_dateFirstInShowCard);
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

  Future<void> setSeedColor(Color? color) async {
    _seedColor = color;
    final prefs = await SharedPreferences.getInstance();
    if (color == null) {
      await prefs.remove(_seedColorKey);
    } else {
      await prefs.setInt(_seedColorKey, color.value);
    }
    notifyListeners();
  }

  // Persistence
  Future<void> _updatePreference(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? false;
    _playOnTap = prefs.getBool(_playOnTapKey) ?? false;
    _showSingleShnid = prefs.getBool(_showSingleShnidKey) ?? false;
    _hideTrackCountInSourceList = prefs.getBool(_hideTrackCountKey) ?? false;
    _playRandomOnCompletion =
        prefs.getBool(_playRandomOnCompletionKey) ?? false;
    _playRandomOnStartup = prefs.getBool(_playRandomOnStartupKey) ?? false;
    _dateFirstInShowCard = prefs.getBool(_dateFirstInShowCardKey) ?? false;
    _useDynamicColor = prefs.getBool(_useDynamicColorKey) ?? false;
    _useSliverAppBar = prefs.getBool(_useSliverAppBarKey) ?? true;
    _useSharedAxisTransition =
        prefs.getBool(_useSharedAxisTransitionKey) ?? false;
    _useHandwritingFont = prefs.getBool(_useHandwritingFontKey) ?? true;
    _scaleShowList = prefs.getBool(_scaleShowListKey) ?? true;
    _scaleTrackList = prefs.getBool(_scaleTrackListKey) ?? true;
    _scalePlayer = prefs.getBool(_scalePlayerKey) ?? true;
    final seedColorValue = prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    } else {
      _seedColor = null;
    }

    notifyListeners();
  }
}
