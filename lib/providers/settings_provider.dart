import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  // Preference Keys
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';
  static const String _playRandomOnStartupKey = 'play_random_on_startup';
  static const String _dateFirstInShowCardKey = 'date_first_in_show_card';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _useHandwritingFontKey = 'use_handwriting_font';
  static const String _uiScaleKey = 'ui_scale';
  static const String _seedColorKey = 'seed_color';
  static const String _showGlowBorderKey = 'show_glow_border';
  static const String _highlightPlayingWithRgbKey =
      'highlight_playing_with_rgb';
  static const String _showPlaybackMessagesKey = 'show_playback_messages';

  static const String _showSplashScreenKey = 'show_splash_screen';
  bool _showSplashScreen = true;
  bool get showSplashScreen => _showSplashScreen;

  void toggleShowSplashScreen() => _updatePreference(
      _showSplashScreenKey, _showSplashScreen = !_showSplashScreen);

  // Hard-coded setting.
  bool showExpandIcon = false;

  // Private state
  bool _showTrackNumbers = false;
  bool _playOnTap = false;
  bool _showSingleShnid = false;
  bool _playRandomOnCompletion = false;
  bool _playRandomOnStartup = false;
  bool _dateFirstInShowCard = true;
  bool _useDynamicColor = true;
  bool _useHandwritingFont = true;
  bool _uiScale = false;
  bool _showGlowBorder = false;
  bool _highlightPlayingWithRgb = false;
  bool _showPlaybackMessages = false;

  Color? _seedColor;

  // Public getters
  bool get showTrackNumbers => _showTrackNumbers;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => true;
  bool get playRandomOnCompletion => _playRandomOnCompletion;
  bool get playRandomOnStartup => _playRandomOnStartup;
  bool get dateFirstInShowCard => _dateFirstInShowCard;
  bool get useDynamicColor => _useDynamicColor;
  bool get useSliverAppBar => true;
  bool get useSharedAxisTransition => true;
  bool get useHandwritingFont => _useHandwritingFont;
  bool get uiScale => _uiScale;
  bool get showGlowBorder => _showGlowBorder;
  bool get highlightPlayingWithRgb => _highlightPlayingWithRgb;
  bool get showPlaybackMessages => _showPlaybackMessages;
  bool get highlightCurrentShowCard => true;
  bool get useMaterial3 => true;

  Color? get seedColor => _seedColor;

  SettingsProvider() {
    _loadPreferences();
  }

  // Toggle methods
  void toggleShowTrackNumbers() => _updatePreference(
      _trackNumberKey, _showTrackNumbers = !_showTrackNumbers);
  void togglePlayOnTap() =>
      _updatePreference(_playOnTapKey, _playOnTap = !_playOnTap);
  void toggleShowSingleShnid() => _updatePreference(
      _showSingleShnidKey, _showSingleShnid = !_showSingleShnid);

  void togglePlayRandomOnCompletion() => _updatePreference(
      _playRandomOnCompletionKey,
      _playRandomOnCompletion = !_playRandomOnCompletion);
  void togglePlayRandomOnStartup() => _updatePreference(
      _playRandomOnStartupKey, _playRandomOnStartup = !_playRandomOnStartup);
  void toggleDateFirstInShowCard() => _updatePreference(
      _dateFirstInShowCardKey, _dateFirstInShowCard = !_dateFirstInShowCard);
  void toggleUseDynamicColor() => _updatePreference(
      _useDynamicColorKey, _useDynamicColor = !_useDynamicColor);
  void toggleUseHandwritingFont() => _updatePreference(
      _useHandwritingFontKey, _useHandwritingFont = !_useHandwritingFont);
  void toggleUiScale() => _updatePreference(_uiScaleKey, _uiScale = !_uiScale);
  void toggleShowGlowBorder() =>
      _updatePreference(_showGlowBorderKey, _showGlowBorder = !_showGlowBorder);
  void toggleHighlightPlayingWithRgb() => _updatePreference(
      _highlightPlayingWithRgbKey,
      _highlightPlayingWithRgb = !_highlightPlayingWithRgb);
  void toggleShowPlaybackMessages() => _updatePreference(
      _showPlaybackMessagesKey, _showPlaybackMessages = !_showPlaybackMessages);
  static const String _halfGlowDynamicKey = 'half_glow_dynamic';
  bool _halfGlowDynamic = false;
  bool get halfGlowDynamic => _halfGlowDynamic;
  void toggleHalfGlowDynamic() => _updatePreference(
      _halfGlowDynamicKey, _halfGlowDynamic = !_halfGlowDynamic);

  static const String _rgbAnimationSpeedKey = 'rgb_animation_speed';
  double _rgbAnimationSpeed = 1.0;
  double get rgbAnimationSpeed => _rgbAnimationSpeed;
  void setRgbAnimationSpeed(double speed) => _updateDoublePreference(
      _rgbAnimationSpeedKey, _rgbAnimationSpeed = speed);

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

    // Check if this is the first run (or if we haven't checked screen size yet)
    bool firstRunCheckDone = prefs.getBool('first_run_check_done') ?? false;

    if (!firstRunCheckDone) {
      // Get physical screen size
      // We use the first view, which is standard for mobile apps
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalWidth = view.physicalSize.width;

      if (physicalWidth <= 720) {
        // Small screen: Default scale settings to false
        _uiScale = false;

        // Save these defaults immediately so they persist
        await prefs.setBool(_uiScaleKey, false);
      } else {
        // Normal/Large screen: Default to false (as requested)
      }

      // Mark check as done
      await prefs.setBool('first_run_check_done', true);
    }

    _showTrackNumbers = prefs.getBool(_trackNumberKey) ?? false;
    _playOnTap = prefs.getBool(_playOnTapKey) ?? false;
    _showSingleShnid = prefs.getBool(_showSingleShnidKey) ?? false;
    _showSingleShnid = prefs.getBool(_showSingleShnidKey) ?? false;
    _playRandomOnCompletion =
        prefs.getBool(_playRandomOnCompletionKey) ?? false;
    _playRandomOnStartup = prefs.getBool(_playRandomOnStartupKey) ?? false;
    _dateFirstInShowCard = prefs.getBool(_dateFirstInShowCardKey) ?? true;
    _useDynamicColor = prefs.getBool(_useDynamicColorKey) ?? true;
    _useHandwritingFont = prefs.getBool(_useHandwritingFontKey) ?? true;

    // Load scale settings. If they were set above during first run, these will pick up the saved values.
    // If it's a large screen first run, they won't be in prefs, so they default to true.
    // Load scale settings.
    _uiScale = prefs.getBool(_uiScaleKey) ?? false;
    _showGlowBorder = prefs.getBool(_showGlowBorderKey) ?? false;
    _highlightPlayingWithRgb =
        prefs.getBool(_highlightPlayingWithRgbKey) ?? false;
    _halfGlowDynamic = prefs.getBool(_halfGlowDynamicKey) ?? false;
    _rgbAnimationSpeed = prefs.getDouble(_rgbAnimationSpeedKey) ?? 1.0;

    _showSplashScreen = prefs.getBool(_showSplashScreenKey) ?? true;

    final seedColorValue = prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    } else {
      _seedColor = null;
    }

    notifyListeners();
  }

  Future<void> _updateDoublePreference(String key, double value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(key, value);
    notifyListeners();
  }
}
