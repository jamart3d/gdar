import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  static const String _appFontKey = 'app_font';
  String _appFont = 'default';
  String get appFont => _appFont;
  void setAppFont(String font) =>
      _updateStringPreference(_appFontKey, _appFont = font);

  // Deprecated key for migration
  // static const String _useHandwritingFontKey = 'use_handwriting_font';
  static const String _uiScaleKey = 'ui_scale';
  static const String _seedColorKey = 'seed_color';
  static const String _showGlowBorderKey = 'show_glow_border';
  static const String _highlightPlayingWithRgbKey =
      'highlight_playing_with_rgb';
  static const String _showPlaybackMessagesKey = 'show_playback_messages';
  static const String _sortOldestFirstKey = 'sort_oldest_first';
  static const String _useStrictSrcCategorizationKey =
      'use_strict_src_categorization';

  static const String _showSplashScreenKey = 'show_splash_screen';
  late bool _showSplashScreen;
  bool get showSplashScreen => _showSplashScreen;
  bool get isFirstRun => _isFirstRun;

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
  // late bool _useHandwritingFont; // Removed
  late bool _uiScale;
  late bool _showGlowBorder;
  late bool _highlightPlayingWithRgb;
  late bool _showPlaybackMessages;
  late bool _sortOldestFirst;
  late bool _useStrictSrcCategorization;

  Color? _seedColor;

  // Ratings & Played Status
  static const String _showRatingsKey = 'show_ratings';
  static const String _playedShowsKey = 'played_shows';
  static const String _randomOnlyUnplayedKey = 'random_only_unplayed';
  static const String _randomOnlyHighRatedKey = 'random_only_high_rated';

  Map<String, int> _showRatings = {};
  Set<String> _playedShows = {};
  bool _randomOnlyUnplayed = false;
  bool _randomOnlyHighRated = false;

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
  bool get useSliverAppBar => true;
  bool get useSharedAxisTransition => true;
  // bool get useHandwritingFont => _useHandwritingFont; // Removed
  bool get uiScale => _uiScale;
  bool get showGlowBorder => _showGlowBorder;
  bool get highlightPlayingWithRgb => _highlightPlayingWithRgb;
  bool get showPlaybackMessages => _showPlaybackMessages;
  bool get sortOldestFirst => _sortOldestFirst;
  bool get useStrictSrcCategorization => _useStrictSrcCategorization;
  bool get highlightCurrentShowCard => true;
  bool get useMaterial3 => true;

  Color? get seedColor => _seedColor;

  Map<String, int> get showRatings => _showRatings;
  Set<String> get playedShows => _playedShows;
  bool get randomOnlyUnplayed => _randomOnlyUnplayed;
  bool get randomOnlyHighRated => _randomOnlyHighRated;

  // Internal setting: Global Album Art
  bool get showGlobalAlbumArt => true;

  SettingsProvider(this._prefs) {
    _init();
  }

  void _init() {
    // Check if this is the first run (or if we haven't checked screen size yet)
    bool firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;

    // Default values
    _uiScale = _prefs.getBool(_uiScaleKey) ?? false;

    if (!firstRunCheckDone) {
      // Get physical screen size
      // We use the first view, which is standard for mobile apps
      final view = WidgetsBinding.instance.platformDispatcher.views.first;
      final physicalWidth = view.physicalSize.width;

      if (physicalWidth <= 720) {
        // Small screen: Default scale settings to false
        _uiScale = false;
        // Save these defaults immediately so they persist
        _prefs.setBool(_uiScaleKey, false);
      }

      _isFirstRun = true; // Mark as first run for Splash Screen

      // Mark check as done
      _prefs.setBool('first_run_check_done', true);
    }

    _showTrackNumbers = _prefs.getBool(_trackNumberKey) ?? false;
    _hideTrackDuration = _prefs.getBool(_hideTrackDurationKey) ?? true;
    _playOnTap = _prefs.getBool(_playOnTapKey) ?? false;
    _showSingleShnid = _prefs.getBool(_showSingleShnidKey) ?? false;
    _playRandomOnCompletion =
        _prefs.getBool(_playRandomOnCompletionKey) ?? false;
    _playRandomOnStartup = _prefs.getBool(_playRandomOnStartupKey) ?? false;
    _dateFirstInShowCard = _prefs.getBool(_dateFirstInShowCardKey) ?? true;
    _useDynamicColor = _prefs.getBool(_useDynamicColorKey) ?? true;
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
      _appFont = _prefs.getString(_appFontKey) ?? 'default';
    }

    _showGlowBorder = _prefs.getBool(_showGlowBorderKey) ?? false;
    _highlightPlayingWithRgb =
        _prefs.getBool(_highlightPlayingWithRgbKey) ?? false;
    _halfGlowDynamic = _prefs.getBool(_halfGlowDynamicKey) ?? false;
    _rgbAnimationSpeed = _prefs.getDouble(_rgbAnimationSpeedKey) ?? 1.0;

    _showSplashScreen = _prefs.getBool(_showSplashScreenKey) ?? true;
    _showPlaybackMessages = _prefs.getBool(_showPlaybackMessagesKey) ?? false;
    _sortOldestFirst = _prefs.getBool(_sortOldestFirstKey) ?? true;
    _useStrictSrcCategorization =
        _prefs.getBool(_useStrictSrcCategorizationKey) ?? true;

    final seedColorValue = _prefs.getInt(_seedColorKey);
    if (seedColorValue != null) {
      _seedColor = Color(seedColorValue);
    } else {
      _seedColor = null;
    }

    _initRatings();
  }

  void _initRatings() {
    final String? ratingsJson = _prefs.getString(_showRatingsKey);
    if (ratingsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(ratingsJson);
        _showRatings = decoded.map((key, value) => MapEntry(key, value as int));
      } catch (e) {
        // Handle error or ignore
        _showRatings = {};
      }
    }

    final List<String>? playedList = _prefs.getStringList(_playedShowsKey);
    if (playedList != null) {
      _playedShows = playedList.toSet();
    }

    _randomOnlyUnplayed = _prefs.getBool(_randomOnlyUnplayedKey) ?? false;
    _randomOnlyHighRated = _prefs.getBool(_randomOnlyHighRatedKey) ?? false;

    _initSourceFilters();
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
  // void toggleUseHandwritingFont() => ... // Removed
  void toggleUiScale() => _updatePreference(_uiScaleKey, _uiScale = !_uiScale);
  void toggleShowGlowBorder() =>
      _updatePreference(_showGlowBorderKey, _showGlowBorder = !_showGlowBorder);
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
    if (color == null) {
      await _prefs.remove(_seedColorKey);
    } else {
      await _prefs.setInt(_seedColorKey, color.value);
    }
    notifyListeners();
  }

  // Ratings & Played Methods
  int getRating(String showName) {
    return _showRatings[showName] ?? 0;
  }

  bool isPlayed(String showName) {
    return _playedShows.contains(showName);
  }

  Future<void> setRating(String showName, int rating) async {
    _showRatings[showName] = rating;
    notifyListeners();
    await _saveRatings();
  }

  Future<void> togglePlayed(String showName) async {
    if (_playedShows.contains(showName)) {
      _playedShows.remove(showName);
    } else {
      _playedShows.add(showName);
    }
    notifyListeners();
    await _savePlayedShows();
  }

  Future<void> markAsPlayed(String showName) async {
    if (!_playedShows.contains(showName)) {
      _playedShows.add(showName);
      notifyListeners();
      await _savePlayedShows();
    }
  }

  void toggleRandomOnlyUnplayed() => _updatePreference(
      _randomOnlyUnplayedKey, _randomOnlyUnplayed = !_randomOnlyUnplayed);

  void toggleRandomOnlyHighRated() => _updatePreference(
      _randomOnlyHighRatedKey, _randomOnlyHighRated = !_randomOnlyHighRated);

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

  // ... existing methods ...

  // Update _init or create _initSourceFilters called by it.
  // Since I can't easily inject into _init with replace_file_content without context,
  // I will append these helper methods and manually update _init in a separate call
  // or try to fit it all here if I can match the end of the class.

  // Actually, I should update _init in a separate chunk to avoid overwriting too much.
  // This chunk will be for adding the fields and methods.
  // I will place them before "Persistence Helpers".

  Future<void> _initSourceFilters() async {
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
      _sourceCategoryFilters = {
        'matrix': true,
        'ultra': false,
        'betty': false,
        'sbd': false,
        'fm': false,
        'dsbd': false,
        'unk': false,
      };
    }
  }

  // Toggles

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

  Future<void> _saveRatings() async {
    final String encoded = json.encode(_showRatings);
    await _prefs.setString(_showRatingsKey, encoded);
  }

  Future<void> _savePlayedShows() async {
    await _prefs.setStringList(_playedShowsKey, _playedShows.toList());
  }
}
