import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/config/default_settings.dart';
import 'package:shakedown/utils/logger.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;

  // Preference Keys
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _hideTrackDurationKey = 'hide_track_duration';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';

  static const String _playRandomOnStartupKey = 'play_random_on_startup';
  static const String _dateFirstInShowCardKey = 'date_first_in_show_card';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _useTrueBlackKey = 'use_true_black';
  static const String _appFontKey = 'app_font';
  static const String _showDayOfWeekKey = 'show_day_of_week';
  static const String _abbreviateDayOfWeekKey = 'abbreviate_day_of_week';
  static const String _abbreviateMonthKey = 'abbreviate_month';
  String _appFont = 'default';
  String get appFont => _appFont;
  void setAppFont(String font) =>
      _updateStringPreference(_appFontKey, _appFont = font);

  static const String _uiScaleKey = 'ui_scale';
  static const String _seedColorKey = 'seed_color';
  static const String _glowModeKey = 'glow_mode'; // 0=Off, 1=On, 2=Half
  static const String _showGlowBorderKey = 'show_glow_border'; // Deprecated
  static const String _halfGlowDynamicKey = 'half_glow_dynamic'; // Deprecated
  static const String _highlightPlayingWithRgbKey =
      'highlight_playing_with_rgb';
  static const String _showPlaybackMessagesKey = 'show_playback_messages';
  static const String _sortOldestFirstKey = 'sort_oldest_first';
  static const String _useStrictSrcCategorizationKey =
      'use_strict_src_categorization';
  static const String _offlineBufferingKey = 'offline_buffering';

  static const String _marqueeEnabledKey =
      'marquee_enabled'; // Logic for disabling marquee in tests

  static const String _showSplashScreenKey = 'show_splash_screen';
  late bool _showSplashScreen;
  bool get showSplashScreen => _showSplashScreen;
  bool get isFirstRun => _isFirstRun;

  // Onboarding
  static const String _onboardingCompletedVersionKey =
      'onboarding_completed_version';
  static const int kCurrentOnboardingVersion = 1;

  int _onboardingCompletedVersion = 0;
  bool get showOnboarding =>
      _onboardingCompletedVersion < kCurrentOnboardingVersion;

  Future<void> completeOnboarding() async {
    _onboardingCompletedVersion = kCurrentOnboardingVersion;
    await _prefs.setInt(
        _onboardingCompletedVersionKey, _onboardingCompletedVersion);
    notifyListeners();
  }

  void toggleShowSplashScreen() => _updatePreference(
      _showSplashScreenKey, _showSplashScreen = !_showSplashScreen);

  // Hard-coded setting.
  bool showExpandIcon = false;

  // Private state
  late bool _showTrackNumbers;
  late bool _hideTrackDuration;
  bool _isFirstRun = false; // Initialize explicitly
  late bool _playOnTap;
  late bool _showSingleShnid;
  late bool _playRandomOnCompletion;
  late bool _playRandomOnStartup;
  late bool _dateFirstInShowCard;
  late bool _useDynamicColor;
  late bool _useTrueBlack;
  late bool _uiScale;
  late int _glowMode;
  late bool _highlightPlayingWithRgb;
  late bool _showPlaybackMessages;
  late bool _sortOldestFirst;
  late bool _useStrictSrcCategorization;
  late bool _offlineBuffering;
  late bool _showDayOfWeek;
  late bool _abbreviateDayOfWeek;
  late bool _abbreviateMonth;
  late bool _marqueeEnabled;

  Color? _seedColor;

  // Ratings & Played Status moved to CatalogService (Hive)
  static const String _randomOnlyUnplayedKey = 'random_only_unplayed';
  static const String _randomOnlyHighRatedKey = 'random_only_high_rated';
  static const String _randomExcludePlayedKey = 'random_exclude_played';

  bool _randomOnlyUnplayed = false;
  bool _randomOnlyHighRated = false;
  bool _randomExcludePlayed = false;

  // Public getters
  bool get showTrackNumbers => _showTrackNumbers;
  bool get hideTrackDuration => _hideTrackDuration;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => true;
  bool get playRandomOnCompletion => _playRandomOnCompletion;
  bool get playRandomOnStartup => _playRandomOnStartup;
  bool get dateFirstInShowCard => _dateFirstInShowCard;
  bool get useDynamicColor => _useDynamicColor;
  bool get useTrueBlack => _useTrueBlack;
  bool get useSliverAppBar => true;
  bool get useSharedAxisTransition => true;
  bool get uiScale => _uiScale;
  int get glowMode => _glowMode;
  bool get highlightPlayingWithRgb => _highlightPlayingWithRgb;
  bool get showPlaybackMessages => _showPlaybackMessages;
  bool get sortOldestFirst => _sortOldestFirst;
  bool get useStrictSrcCategorization => _useStrictSrcCategorization;
  bool get offlineBuffering => _offlineBuffering;
  bool get highlightCurrentShowCard => true;
  bool get useMaterial3 => true;
  bool get showDayOfWeek => _showDayOfWeek;
  bool get abbreviateDayOfWeek => _abbreviateDayOfWeek;
  bool get abbreviateMonth => _abbreviateMonth;
  bool get marqueeEnabled => _marqueeEnabled;

  Color? get seedColor => _seedColor;

  bool get randomOnlyUnplayed => _randomOnlyUnplayed;
  bool get randomOnlyHighRated => _randomOnlyHighRated;
  bool get randomExcludePlayed => _randomExcludePlayed;

  // Internal setting: Global Album Art
  bool get showGlobalAlbumArt => true;

  // Session state for suggestions
  bool _hasShownAdvancedCacheSuggestion = false;
  bool get hasShownAdvancedCacheSuggestion => _hasShownAdvancedCacheSuggestion;
  void markAdvancedCacheSuggestionShown() {
    _hasShownAdvancedCacheSuggestion = true;
    notifyListeners();
  }

  static const String _showDebugLayoutKey = 'show_debug_layout';
  late bool _showDebugLayout;
  bool get showDebugLayout => _showDebugLayout;
  void toggleShowDebugLayout() => _updatePreference(
      _showDebugLayoutKey, _showDebugLayout = !_showDebugLayout);

  // Shakedown Tween Setting (Internal)
  static const String _enableShakedownTweenKey = 'enable_shakedown_tween';
  late bool _enableShakedownTween;
  bool get enableShakedownTween => _enableShakedownTween;
  void toggleEnableShakedownTween() => _updatePreference(
      _enableShakedownTweenKey, _enableShakedownTween = !_enableShakedownTween);

  // MethodChannel for ADB UI scale testing
  static const MethodChannel _uiScaleChannel =
      MethodChannel('com.jamart3d.shakedown/ui_scale');

  SettingsProvider(this._prefs) {
    _init();
    _setupUiScaleChannel();
  }

  /// Set up MethodChannel listener for ADB UI scale testing
  void _setupUiScaleChannel() {
    _uiScaleChannel.setMethodCallHandler((call) async {
      if (call.method == 'setUiScale') {
        final bool enabled = call.arguments as bool;
        if (enabled != _uiScale) {
          _uiScale = enabled;
          await _prefs.setBool(_uiScaleKey, enabled);

          // Smart Abbreviation for ADB
          if (_uiScale) {
            if (!_abbreviateDayOfWeek) {
              _abbreviateDayOfWeek = true;
              await _prefs.setBool(_abbreviateDayOfWeekKey, true);
            }
            if (!_abbreviateMonth) {
              _abbreviateMonth = true;
              await _prefs.setBool(_abbreviateMonthKey, true);
            }
          }

          notifyListeners();
          logger.i(
              'SettingsProvider: UI Scale set to $enabled via ADB (Smart Abbreviation applied)');
        }
      }
    });
  }

  void _init() {
    // Check if this is the first run (or if we haven't checked screen size yet)
    bool firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;

    // Default values
    _uiScale =
        _prefs.getBool(_uiScaleKey) ?? DefaultSettings.uiScaleDesktopDefault;

    if (!firstRunCheckDone) {
      // Get physical screen size
      // We use the first view, which is standard for mobile apps
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalWidth = view.physicalSize.width;

      if (physicalWidth <= 720) {
        // Small screen: Default scale settings to false
        _uiScale = DefaultSettings.uiScaleMobileDefault;
        // Save these defaults immediately so they persist
        _prefs.setBool(_uiScaleKey, DefaultSettings.uiScaleMobileDefault);
      }

      _isFirstRun = true; // Mark as first run for Splash Screen

      // Mark check as done
      _prefs.setBool('first_run_check_done', true);
    }

    _onboardingCompletedVersion =
        _prefs.getInt(_onboardingCompletedVersionKey) ?? 0;

    _showTrackNumbers =
        _prefs.getBool(_trackNumberKey) ?? DefaultSettings.showTrackNumbers;
    _hideTrackDuration = _prefs.getBool(_hideTrackDurationKey) ??
        DefaultSettings.hideTrackDuration;
    _playOnTap = _prefs.getBool(_playOnTapKey) ?? DefaultSettings.playOnTap;
    _showSingleShnid =
        _prefs.getBool(_showSingleShnidKey) ?? DefaultSettings.showSingleShnid;
    _playRandomOnCompletion = _prefs.getBool(_playRandomOnCompletionKey) ??
        DefaultSettings.playRandomOnCompletion;
    _playRandomOnStartup = _prefs.getBool(_playRandomOnStartupKey) ??
        DefaultSettings.playRandomOnStartup;
    _dateFirstInShowCard = _prefs.getBool(_dateFirstInShowCardKey) ??
        DefaultSettings.dateFirstInShowCard;
    _useDynamicColor =
        _prefs.getBool(_useDynamicColorKey) ?? DefaultSettings.useDynamicColor;
    _showDayOfWeek =
        _prefs.getBool(_showDayOfWeekKey) ?? DefaultSettings.showDayOfWeek;
    _abbreviateDayOfWeek = _prefs.getBool(_abbreviateDayOfWeekKey) ??
        DefaultSettings.abbreviateDayOfWeek;
    _abbreviateMonth =
        _prefs.getBool(_abbreviateMonthKey) ?? DefaultSettings.abbreviateMonth;
    // Font Migration Logic
    if (_prefs.containsKey('use_handwriting_font')) {
      bool oldHandwriting = _prefs.getBool('use_handwriting_font') ?? false;
      if (oldHandwriting) {
        _appFont = 'caveat';
        _prefs.setString(_appFontKey, 'caveat');
      } else {
        _appFont = 'default';
      }
      _prefs.remove('use_handwriting_font');
    } else {
      _appFont = _prefs.getString(_appFontKey) ?? DefaultSettings.appFont;
    }
    logger.i(
        'SettingsProvider: Active App Font = $_appFont (Default: ${DefaultSettings.appFont})');

    // Glow Border Migration Logic
    // New system: 0=Off, 10-100=Intensity percentage
    if (_prefs.containsKey(_glowModeKey)) {
      _glowMode = _prefs.getInt(_glowModeKey) ?? DefaultSettings.glowMode;
      // Migrate from old values to percentage
      if (_glowMode == 1) {
        _glowMode = 25; // Old "Quarter" becomes 25%
        _prefs.setInt(_glowModeKey, _glowMode);
      } else if (_glowMode == 2) {
        _glowMode = 50; // Old "Half" becomes 50%
        _prefs.setInt(_glowModeKey, _glowMode);
      } else if (_glowMode == 3) {
        _glowMode = 100; // Old "Full" becomes 100%
        _prefs.setInt(_glowModeKey, _glowMode);
      }
    } else {
      // Migrate from old boolean keys
      bool oldShow = _prefs.getBool(_showGlowBorderKey) ?? false;
      bool oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
      if (oldHalf) {
        _glowMode = 50; // Half = 50%
      } else if (oldShow) {
        _glowMode = 100; // Full = 100%
      } else {
        _glowMode = DefaultSettings.glowMode; // Off
      }
      // Save matched value to new key
      _prefs.setInt(_glowModeKey, _glowMode);
    }

    // True Black Migration: if user had halfGlowDynamic, they likely wanted True Black
    bool oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
    if (oldHalf && !_prefs.containsKey(_useTrueBlackKey)) {
      _useTrueBlack = true;
      _prefs.setBool(_useTrueBlackKey, true);
    } else {
      _useTrueBlack =
          _prefs.getBool(_useTrueBlackKey) ?? DefaultSettings.useTrueBlack;
    }

    _highlightPlayingWithRgb = _prefs.getBool(_highlightPlayingWithRgbKey) ??
        DefaultSettings.highlightPlayingWithRgb;
    _rgbAnimationSpeed = _prefs.getDouble(_rgbAnimationSpeedKey) ??
        DefaultSettings.rgbAnimationSpeed;

    _showSplashScreen = _prefs.getBool(_showSplashScreenKey) ??
        DefaultSettings.showSplashScreen;
    _showPlaybackMessages = _prefs.getBool(_showPlaybackMessagesKey) ??
        DefaultSettings.showPlaybackMessages;
    _sortOldestFirst =
        _prefs.getBool(_sortOldestFirstKey) ?? DefaultSettings.sortOldestFirst;
    _useStrictSrcCategorization =
        _prefs.getBool(_useStrictSrcCategorizationKey) ??
            DefaultSettings.useStrictSrcCategorization;
    _offlineBuffering = _prefs.getBool(_offlineBufferingKey) ??
        DefaultSettings.offlineBuffering;

    _marqueeEnabled = _prefs.getBool(_marqueeEnabledKey) ?? true;
    _showDebugLayout = _prefs.getBool(_showDebugLayoutKey) ?? false;
    _enableShakedownTween =
        _prefs.getBool(_enableShakedownTweenKey) ?? true; // Default OFF

    final seedColorValue = _prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    } else {
      _seedColor = null;
    }

    // Ratings initialized in CatalogService now.
    _initSourceFilters();
  }

  // Renamed from _initRatings to just init filters since ratings are gone
  void _initSourceFilters() {
    // Restore random settings
    _randomOnlyUnplayed = _prefs.getBool(_randomOnlyUnplayedKey) ??
        DefaultSettings.randomOnlyUnplayed;
    _randomOnlyHighRated = _prefs.getBool(_randomOnlyHighRatedKey) ??
        DefaultSettings.randomOnlyHighRated;
    _randomExcludePlayed = _prefs.getBool(_randomExcludePlayedKey) ??
        DefaultSettings.randomExcludePlayed;

    // Restore source filters
    _filterHighestShnid = _prefs.getBool(_filterHighestShnidKey) ?? true;

    final String? catsJson = _prefs.getString(_sourceCategoryFiltersKey);
    if (catsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(catsJson);
        // Merge with defaults to handle any new keys in future
        decoded.forEach((key, value) {
          if (_sourceCategoryFilters.containsKey(key) && value is bool) {
            _sourceCategoryFilters[key] = value;
          }
        });
      } catch (e) {
        // use defaults
      }
    } else {
      // First run or no saved filters: Default to ONLY Matrix enabled
      _sourceCategoryFilters = Map.from(DefaultSettings.sourceCategoryFilters);
    }
  }

  // Toggle methods
  void toggleShowTrackNumbers() => _updatePreference(
      _trackNumberKey, _showTrackNumbers = !_showTrackNumbers);

  void toggleHideTrackDuration() => _updatePreference(
      _hideTrackDurationKey, _hideTrackDuration = !_hideTrackDuration);

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
  void toggleUseTrueBlack() =>
      _updatePreference(_useTrueBlackKey, _useTrueBlack = !_useTrueBlack);
  void toggleShowDayOfWeek() =>
      _updatePreference(_showDayOfWeekKey, _showDayOfWeek = !_showDayOfWeek);
  void toggleAbbreviateDayOfWeek() => _updatePreference(
      _abbreviateDayOfWeekKey, _abbreviateDayOfWeek = !_abbreviateDayOfWeek);
  void toggleAbbreviateMonth() => _updatePreference(
      _abbreviateMonthKey, _abbreviateMonth = !_abbreviateMonth);
  void toggleUiScale() {
    _uiScale = !_uiScale;
    _updatePreference(_uiScaleKey, _uiScale);

    // Smart Abbreviation: If UI Scale is ON, auto-enable abbreviations
    if (_uiScale) {
      if (!_abbreviateDayOfWeek) toggleAbbreviateDayOfWeek();
      if (!_abbreviateMonth) toggleAbbreviateMonth();
    }
  }

  void setGlowMode(int mode) {
    _updateIntPreference(_glowModeKey, _glowMode = mode);
  }

  void toggleHighlightPlayingWithRgb() => _updatePreference(
      _highlightPlayingWithRgbKey,
      _highlightPlayingWithRgb = !_highlightPlayingWithRgb);
  void toggleShowPlaybackMessages() => _updatePreference(
      _showPlaybackMessagesKey, _showPlaybackMessages = !_showPlaybackMessages);
  void toggleSortOldestFirst() => _updatePreference(
      _sortOldestFirstKey, _sortOldestFirst = !_sortOldestFirst);
  void toggleUseStrictSrcCategorization() => _updatePreference(
      _useStrictSrcCategorizationKey,
      _useStrictSrcCategorization = !_useStrictSrcCategorization);

  void toggleOfflineBuffering() => _updatePreference(
      _offlineBufferingKey, _offlineBuffering = !_offlineBuffering);

  static const String _rgbAnimationSpeedKey = 'rgb_animation_speed';
  double _rgbAnimationSpeed = 1.0;
  double get rgbAnimationSpeed => _rgbAnimationSpeed;
  void setRgbAnimationSpeed(double speed) => _updateDoublePreference(
      _rgbAnimationSpeedKey, _rgbAnimationSpeed = speed);

  Future<void> setSeedColor(Color? color) async {
    _seedColor = color;
    if (color == null) {
      await _prefs.remove(_seedColorKey);
    } else {
      // ignore: deprecated_member_use
      await _prefs.setInt(_seedColorKey, color.value);
    }
    notifyListeners();
  }

  void toggleRandomOnlyUnplayed() => _updatePreference(
      _randomOnlyUnplayedKey, _randomOnlyUnplayed = !_randomOnlyUnplayed);

  void toggleRandomOnlyHighRated() => _updatePreference(
      _randomOnlyHighRatedKey, _randomOnlyHighRated = !_randomOnlyHighRated);

  void toggleRandomExcludePlayed() => _updatePreference(
      _randomExcludePlayedKey, _randomExcludePlayed = !_randomExcludePlayed);

  // Source Filtering
  static const String _filterHighestShnidKey = 'filter_highest_shnid';
  static const String _sourceCategoryFiltersKey = 'source_category_filters';

  bool _filterHighestShnid = false;
  Map<String, bool> _sourceCategoryFilters = {
    'matrix': true,
    'ultra': true,
    'betty': true,
    'sbd': true,
    'fm': true,
    'dsbd': true,
    'unk': false, // Default to FALSE for Unknown
  };

  bool get filterHighestShnid => _filterHighestShnid;
  Map<String, bool> get sourceCategoryFilters => _sourceCategoryFilters;

  void toggleFilterHighestShnid() => _updatePreference(
      _filterHighestShnidKey, _filterHighestShnid = !_filterHighestShnid);

  Future<void> setSourceCategoryFilter(String category, bool isActive) async {
    _sourceCategoryFilters[category] = isActive;

    // Ensure at least one is active
    if (!_sourceCategoryFilters.containsValue(true)) {
      _sourceCategoryFilters[category] = true; // Revert
    }

    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  Future<void> setSoloSourceCategoryFilter(String category) async {
    _sourceCategoryFilters.forEach((key, value) {
      _sourceCategoryFilters[key] = (key == category);
    });

    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  Future<void> _saveSourceCategoryFilters() async {
    final String encoded = json.encode(_sourceCategoryFilters);
    await _prefs.setString(_sourceCategoryFiltersKey, encoded);
  }

  Future<void> enableAllSourceCategories() async {
    for (var key in _sourceCategoryFilters.keys) {
      _sourceCategoryFilters[key] = true;
    }
    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  // Persistence Helpers
  Future<void> _updatePreference(String key, bool value) async {
    await _prefs.setBool(key, value);
    notifyListeners();
  }

  Future<void> _updateStringPreference(String key, String value) async {
    await _prefs.setString(key, value);
    notifyListeners();
  }

  Future<void> _updateDoublePreference(String key, double value) async {
    await _prefs.setDouble(key, value);
    notifyListeners();
  }

  Future<void> _updateIntPreference(String key, int value) async {
    await _prefs.setInt(key, value);
    notifyListeners();
  }
}
