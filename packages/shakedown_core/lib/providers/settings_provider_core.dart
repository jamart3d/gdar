part of 'settings_provider.dart';

const String _trackNumberKey = 'show_track_numbers';
const String _playOnTapKey = 'play_on_tap';
const String _showSingleShnidKey = 'show_single_shnid';
const String _hideTrackDurationKey = 'hide_track_duration';
const String _playRandomOnCompletionKey = 'play_random_on_completion';
const String _nonRandomKey = 'non_random';
const String _playRandomOnStartupKey = 'play_random_on_startup';
const String _dateFirstInShowCardKey = 'date_first_in_show_card';
const String _useDynamicColorKey = 'use_dynamic_color';
const String _useTrueBlackKey = 'use_true_black';
const String _appFontKey = 'app_font';
const String _showDayOfWeekKey = 'show_day_of_week';
const String _abbreviateDayOfWeekKey = 'abbreviate_day_of_week';
const String _abbreviateMonthKey = 'abbreviate_month';
const String _useNeumorphismKey = 'use_neumorphism';
const String _fruitEnableLiquidGlassKey = 'fruit_enable_liquid_glass';
const String _neumorphicStyleKey = 'neumorphic_style';
const String _performanceModeKey = 'performance_mode';
const String _uiScaleKey = 'ui_scale';
const String _carModeKey = 'car_mode';
const String _fruitFloatingSpheresKey = 'fruit_floating_spheres';
const String _seedColorKey = 'seed_color';
const String _glowModeKey = 'glow_mode';
const String _showGlowBorderKey = 'show_glow_border';
const String _halfGlowDynamicKey = 'half_glow_dynamic';
const String _highlightPlayingWithRgbKey = 'highlight_playing_with_rgb';
const String _showPlaybackMessagesKey = 'show_playback_messages';
const String _showDevAudioHudKey = 'show_dev_audio_hud';
const String _devHudModeKey = 'dev_hud_mode';
const String _devAudioHudSnapshotKey = 'dev_audio_hud_snapshot';
const String _sortOldestFirstKey = 'sort_oldest_first';
const String _useStrictSrcCategorizationKey = 'use_strict_src_categorization';
const String _offlineBufferingKey = 'offline_buffering';
const String _enableBufferAgentKey = 'enable_buffer_agent';
const String _preventSleepKey = 'prevent_sleep';
const String _simpleRandomIconKey = 'simple_random_icon';
const String _fruitDenseListKey = 'fruit_dense_list';
const String _fruitStickyNowPlayingKey = 'fruit_sticky_now_playing';
const String _markPlayedOnStartKey = 'mark_played_on_start';
const String _hideTvScrollbarsKey = 'hide_tv_scrollbars';
const String _marqueeEnabledKey = 'marquee_enabled';
const String _enableSwipeToBlockKey = 'enable_swipe_to_block';
const String _hideTabTextKey = 'hide_tab_text';
const String _omitHttpPathInCopyKey = 'omit_http_path_in_copy';
const String _showSplashScreenKey = 'show_splash_screen';
const String _forceTvKey = 'force_tv';
const String _enableHapticsKey = 'enable_haptics';
const String _resumeSourceIdKey = 'resume_source_id';
const String _resumeTrackIndexKey = 'resume_track_index';
const String _resumePositionMsKey = 'resume_position_ms';
const String _onboardingCompletedVersionKey = 'onboarding_completed_version';
const int kCurrentOnboardingVersion = 1;
const String _showDebugLayoutKey = 'show_debug_layout';
const String _enableShakedownTweenKey = 'enable_shakedown_tween';
const String _rgbAnimationSpeedKey = 'rgb_animation_speed';
const String _enableTvBackgroundSpheresKey = 'enable_tv_background_spheres';
const String _tvBackgroundSphereAmountKey = 'tv_background_sphere_amount';
const MethodChannel _uiScaleChannel = MethodChannel(
  'com.jamart3d.shakedown/ui_scale',
);

mixin _SettingsProviderCoreFields {
  String _appFont = 'default';
  late bool _showSplashScreen;
  bool _isFirstRun = false;
  int _onboardingCompletedVersion = 0;

  late bool _showTrackNumbers;
  late bool _hideTrackDuration;
  late bool _playOnTap;
  late bool _showSingleShnid;
  late bool _playRandomOnCompletion;
  late bool _nonRandom;
  late bool _playRandomOnStartup;
  late bool _dateFirstInShowCard;
  late bool _useDynamicColor;
  late bool _useTrueBlack;
  late bool _uiScale;
  late bool _carMode;
  late bool _fruitFloatingSpheres;
  late int _glowMode;
  late bool _highlightPlayingWithRgb;
  late bool _showPlaybackMessages;
  late bool _showDevAudioHud;
  late DevHudMode _devHudMode;
  String _devAudioHudSnapshot = '';
  late bool _sortOldestFirst;
  late bool _useStrictSrcCategorization;
  late bool _offlineBuffering;
  late bool _enableBufferAgent;
  late bool _showDayOfWeek;
  late bool _abbreviateDayOfWeek;
  late bool _abbreviateMonth;
  late bool _simpleRandomIcon;
  late bool _fruitDenseList;
  late bool _marqueeEnabled;
  late bool _enableSwipeToBlock;
  late bool _hideTabText;
  late bool _omitHttpPathInCopy;
  late bool _useNeumorphism;
  late bool _fruitEnableLiquidGlass;
  late NeumorphicStyle _neumorphicStyle;
  late bool _performanceMode;
  late bool _forceTv;
  late bool _enableHaptics;
  late bool _fruitStickyNowPlaying;
  late bool _markPlayedOnStart;
  late bool _hideTvScrollbars;
  late bool _enableTvBackgroundSpheres;
  late String _tvBackgroundSphereAmount;

  Color? _seedColor;
  bool _hasShownAdvancedCacheSuggestion = false;
  late bool _showDebugLayout;
  late bool _enableShakedownTween;
  bool _debugPaintSizeEnabled = true;
  double _rgbAnimationSpeed = 1.0;
}

mixin _SettingsProviderCoreExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderScreensaverFields {
  SharedPreferences get _prefs;
  bool get isTv;
  void _init();

  String get appFont => _appFont;
  String get activeAppFont => isTv ? 'rock_salt' : _appFont;
  bool get showSplashScreen => _showSplashScreen;
  bool get isFirstRun => _isFirstRun;
  bool get showOnboarding =>
      _onboardingCompletedVersion < kCurrentOnboardingVersion;
  bool get showTrackNumbers => _showTrackNumbers;
  bool get hideTrackDuration => _hideTrackDuration;
  bool get playOnTap => _playOnTap;
  bool get showSingleShnid => _showSingleShnid;
  bool get hideTrackCountInSourceList => true;
  bool get playRandomOnCompletion => _playRandomOnCompletion;
  bool get nonRandom => _nonRandom;
  bool get playRandomOnStartup => _playRandomOnStartup;
  bool get dateFirstInShowCard => _dateFirstInShowCard;
  bool get useDynamicColor => _useDynamicColor;
  bool get useTrueBlack => _useTrueBlack;
  bool get useSliverAppBar => true;
  bool get useSharedAxisTransition => true;
  bool get uiScale => _uiScale;
  bool get carMode => _carMode;
  bool get fruitFloatingSpheres => _fruitFloatingSpheres;
  int get glowMode => _glowMode;
  bool get highlightPlayingWithRgb => _highlightPlayingWithRgb;
  bool get showPlaybackMessages => _showPlaybackMessages;
  bool get showDevAudioHud => _showDevAudioHud;
  String get devAudioHudSnapshot => _devAudioHudSnapshot;
  bool get sortOldestFirst => _sortOldestFirst;
  bool get useStrictSrcCategorization => _useStrictSrcCategorization;
  bool get offlineBuffering => _offlineBuffering;
  bool get enableBufferAgent => _enableBufferAgent;
  bool get preventSleep => _preventSleep;
  bool get highlightCurrentShowCard => true;
  bool get useMaterial3 => true;
  bool get showDayOfWeek => _showDayOfWeek;
  bool get abbreviateDayOfWeek => _abbreviateDayOfWeek;
  bool get abbreviateMonth => _abbreviateMonth;
  bool get simpleRandomIcon => _simpleRandomIcon;
  bool get fruitDenseList => _fruitDenseList;
  bool get marqueeEnabled => _marqueeEnabled;
  bool get enableSwipeToBlock => _enableSwipeToBlock;
  bool get hideTabText => _hideTabText;
  bool get omitHttpPathInCopy => _omitHttpPathInCopy;
  bool get useNeumorphism => _useNeumorphism;
  bool get fruitEnableLiquidGlass =>
      isWasmSafeMode() ? false : _fruitEnableLiquidGlass;
  bool get fruitStickyNowPlaying => _fruitStickyNowPlaying;
  bool get enableHaptics => _enableHaptics;
  bool get markPlayedOnStart => _markPlayedOnStart;
  NeumorphicStyle get neumorphicStyle => _neumorphicStyle;
  bool get performanceMode => isWasmSafeMode() ? true : _performanceMode;
  bool get forceTv => _forceTv;
  bool get hideTvScrollbars => _hideTvScrollbars;
  bool get enableTvBackgroundSpheres => _enableTvBackgroundSpheres;
  SphereAmount get tvBackgroundSphereAmount => SphereAmount.values.firstWhere(
    (e) => e.name == _tvBackgroundSphereAmount,
    orElse: () => SphereAmount.small,
  );
  Color? get seedColor => _seedColor;
  bool get showGlobalAlbumArt => true;
  bool get hasShownAdvancedCacheSuggestion => _hasShownAdvancedCacheSuggestion;
  bool get showDebugLayout => _showDebugLayout;
  bool get enableShakedownTween => _enableShakedownTween;
  bool get debugPaintSizeEnabled => _debugPaintSizeEnabled;
  double get rgbAnimationSpeed => _rgbAnimationSpeed;

  void setAppFont(String font) =>
      _updateStringPreference(_appFontKey, _appFont = font);

  Future<void> completeOnboarding() async {
    _onboardingCompletedVersion = kCurrentOnboardingVersion;
    await _prefs.setInt(
      _onboardingCompletedVersionKey,
      _onboardingCompletedVersion,
    );
    notifyListeners();
  }

  void toggleShowSplashScreen() => _updatePreference(
    _showSplashScreenKey,
    _showSplashScreen = !_showSplashScreen,
  );

  void markAdvancedCacheSuggestionShown() {
    _hasShownAdvancedCacheSuggestion = true;
    notifyListeners();
  }

  void saveResumeSession(String sourceId, int trackIndex, int positionMs) {
    _prefs.setString(_resumeSourceIdKey, sourceId);
    _prefs.setInt(_resumeTrackIndexKey, trackIndex);
    _prefs.setInt(_resumePositionMsKey, positionMs);
  }

  bool hasResumeSession() => _prefs.getString(_resumeSourceIdKey) != null;

  ({String sourceId, int trackIndex, int positionMs})? consumeResumeSession() {
    final sourceId = _prefs.getString(_resumeSourceIdKey);
    final trackIndex = _prefs.getInt(_resumeTrackIndexKey);
    final positionMs = _prefs.getInt(_resumePositionMsKey);
    _prefs.remove(_resumeSourceIdKey);
    _prefs.remove(_resumeTrackIndexKey);
    _prefs.remove(_resumePositionMsKey);
    if (sourceId == null || trackIndex == null || positionMs == null) {
      return null;
    }
    return (sourceId: sourceId, trackIndex: trackIndex, positionMs: positionMs);
  }

  void toggleShowDebugLayout() => _updatePreference(
    _showDebugLayoutKey,
    _showDebugLayout = !_showDebugLayout,
  );

  void setShowDebugLayout(bool value) =>
      _updatePreference(_showDebugLayoutKey, _showDebugLayout = value);

  void toggleEnableShakedownTween() => _updatePreference(
    _enableShakedownTweenKey,
    _enableShakedownTween = !_enableShakedownTween,
  );

  void setDebugPaintSizeEnabled(bool value) {
    if (_debugPaintSizeEnabled != value) {
      _debugPaintSizeEnabled = value;
      notifyListeners();
    }
  }

  void toggleUseNeumorphism() {
    _useNeumorphism = !_useNeumorphism;
    _updatePreference(_useNeumorphismKey, _useNeumorphism);
  }

  void toggleFruitEnableLiquidGlass() {
    _fruitEnableLiquidGlass = !_fruitEnableLiquidGlass;
    _updatePreference(_fruitEnableLiquidGlassKey, _fruitEnableLiquidGlass);
  }

  void setFruitEnableLiquidGlass(bool value) {
    if (_fruitEnableLiquidGlass != value) {
      _fruitEnableLiquidGlass = value;
      _updatePreference(_fruitEnableLiquidGlassKey, _fruitEnableLiquidGlass);
    }
  }

  void toggleFruitStickyNowPlaying() {
    _fruitStickyNowPlaying = !_fruitStickyNowPlaying;
    _updatePreference(_fruitStickyNowPlayingKey, _fruitStickyNowPlaying);
  }

  void toggleMarkPlayedOnStart() {
    _markPlayedOnStart = !_markPlayedOnStart;
    _updatePreference(_markPlayedOnStartKey, _markPlayedOnStart);
  }

  void toggleShowTrackNumbers() => _updatePreference(
    _trackNumberKey,
    _showTrackNumbers = !_showTrackNumbers,
  );

  void toggleHideTrackDuration() => _updatePreference(
    _hideTrackDurationKey,
    _hideTrackDuration = !_hideTrackDuration,
  );

  void togglePlayOnTap() =>
      _updatePreference(_playOnTapKey, _playOnTap = !_playOnTap);

  void toggleShowSingleShnid() => _updatePreference(
    _showSingleShnidKey,
    _showSingleShnid = !_showSingleShnid,
  );

  void togglePlayRandomOnCompletion() => _updatePreference(
    _playRandomOnCompletionKey,
    _playRandomOnCompletion = !_playRandomOnCompletion,
  );

  void toggleNonRandom() =>
      _updatePreference(_nonRandomKey, _nonRandom = !_nonRandom);

  void togglePlayRandomOnStartup() => _updatePreference(
    _playRandomOnStartupKey,
    _playRandomOnStartup = !_playRandomOnStartup,
  );

  void toggleDateFirstInShowCard() => _updatePreference(
    _dateFirstInShowCardKey,
    _dateFirstInShowCard = !_dateFirstInShowCard,
  );

  void toggleUseDynamicColor() => _updatePreference(
    _useDynamicColorKey,
    _useDynamicColor = !_useDynamicColor,
  );

  void toggleUseTrueBlack() =>
      _updatePreference(_useTrueBlackKey, _useTrueBlack = !_useTrueBlack);

  void toggleShowDayOfWeek() =>
      _updatePreference(_showDayOfWeekKey, _showDayOfWeek = !_showDayOfWeek);

  void toggleAbbreviateDayOfWeek() => _updatePreference(
    _abbreviateDayOfWeekKey,
    _abbreviateDayOfWeek = !_abbreviateDayOfWeek,
  );

  void toggleAbbreviateMonth() => _updatePreference(
    _abbreviateMonthKey,
    _abbreviateMonth = !_abbreviateMonth,
  );

  void toggleSimpleRandomIcon() => _updatePreference(
    _simpleRandomIconKey,
    _simpleRandomIcon = !_simpleRandomIcon,
  );

  void toggleUiScale() {
    _uiScale = !_uiScale;
    _prefs.setBool(_uiScaleKey, _uiScale);
    _abbreviateDayOfWeek = _uiScale;
    _abbreviateMonth = _uiScale;
    _prefs.setBool(_abbreviateDayOfWeekKey, _abbreviateDayOfWeek);
    _prefs.setBool(_abbreviateMonthKey, _abbreviateMonth);
    notifyListeners();
  }

  void toggleCarMode() {
    _carMode = !_carMode;
    _prefs.setBool(_carModeKey, _carMode);

    if (_carMode && _uiScale) {
      _uiScale = false;
      _abbreviateDayOfWeek = false;
      _abbreviateMonth = false;
      _prefs.setBool(_uiScaleKey, false);
      _prefs.setBool(_abbreviateDayOfWeekKey, false);
      _prefs.setBool(_abbreviateMonthKey, false);
    }

    notifyListeners();
  }

  void toggleFruitFloatingSpheres() => _updatePreference(
    _fruitFloatingSpheresKey,
    _fruitFloatingSpheres = !_fruitFloatingSpheres,
  );

  void toggleHideTvScrollbars() => _updatePreference(
    _hideTvScrollbarsKey,
    _hideTvScrollbars = !_hideTvScrollbars,
  );

  void toggleEnableTvBackgroundSpheres() => _updatePreference(
    _enableTvBackgroundSpheresKey,
    _enableTvBackgroundSpheres = !_enableTvBackgroundSpheres,
  );

  void setTvBackgroundSphereAmount(SphereAmount amount) =>
      _updateStringPreference(
        _tvBackgroundSphereAmountKey,
        _tvBackgroundSphereAmount = amount.name,
      );

  void setGlowMode(int mode) {
    if (_performanceMode && mode > 0) return;
    _updateIntPreference(_glowModeKey, _glowMode = mode);
  }

  void toggleHighlightPlayingWithRgb() => _updatePreference(
    _highlightPlayingWithRgbKey,
    _highlightPlayingWithRgb = !_highlightPlayingWithRgb,
  );

  void setHighlightPlayingWithRgb(bool value) {
    if (_highlightPlayingWithRgb != value) {
      _highlightPlayingWithRgb = value;
      _updatePreference(_highlightPlayingWithRgbKey, _highlightPlayingWithRgb);
    }
  }

  void toggleShowPlaybackMessages() => _updatePreference(
    _showPlaybackMessagesKey,
    _showPlaybackMessages = !_showPlaybackMessages,
  );

  void toggleShowDevAudioHud() => _updatePreference(
    _showDevAudioHudKey,
    _showDevAudioHud = !_showDevAudioHud,
  );

  DevHudMode get devHudMode => _devHudMode;

  void setDevHudMode(DevHudMode mode) =>
      _updateStringPreference(_devHudModeKey, (_devHudMode = mode).name);

  void cycleDevHudMode() {
    final next =
        DevHudMode.values[(_devHudMode.index + 1) % DevHudMode.values.length];
    setDevHudMode(next);
  }

  Future<void> saveDevAudioHudSnapshot(String snapshot) async {
    if (_devAudioHudSnapshot == snapshot) return;
    _devAudioHudSnapshot = snapshot;
    await _prefs.setString(_devAudioHudSnapshotKey, snapshot);
  }

  void toggleSortOldestFirst() => _updatePreference(
    _sortOldestFirstKey,
    _sortOldestFirst = !_sortOldestFirst,
  );

  void toggleUseStrictSrcCategorization() => _updatePreference(
    _useStrictSrcCategorizationKey,
    _useStrictSrcCategorization = !_useStrictSrcCategorization,
  );

  void toggleOfflineBuffering() => _updatePreference(
    _offlineBufferingKey,
    _offlineBuffering = !_offlineBuffering,
  );

  void toggleEnableBufferAgent() => _updatePreference(
    _enableBufferAgentKey,
    _enableBufferAgent = !_enableBufferAgent,
  );

  void togglePreventSleep() =>
      _updatePreference(_preventSleepKey, _preventSleep = !_preventSleep);

  void toggleEnableSwipeToBlock() => _updatePreference(
    _enableSwipeToBlockKey,
    _enableSwipeToBlock = !_enableSwipeToBlock,
  );

  void toggleHideTabText() =>
      _updatePreference(_hideTabTextKey, _hideTabText = !_hideTabText);

  void toggleOmitHttpPathInCopy() => _updatePreference(
    _omitHttpPathInCopyKey,
    _omitHttpPathInCopy = !_omitHttpPathInCopy,
  );

  void setUseNeumorphism(bool value) =>
      _updatePreference(_useNeumorphismKey, _useNeumorphism = value);

  void setPerformanceMode(bool value) {
    if (_performanceMode == value) return;
    _performanceMode = value;
    _updatePreference(_performanceModeKey, _performanceMode);
    if (_performanceMode) {
      setFruitEnableLiquidGlass(false);
      setGlowMode(0);
    }
  }

  void togglePerformanceMode() {
    setPerformanceMode(!_performanceMode);
  }

  void toggleForceTv() => _updatePreference(_forceTvKey, _forceTv = !_forceTv);

  Future<void> setForceTv(bool value) =>
      _updatePreference(_forceTvKey, _forceTv = value);

  void toggleEnableHaptics() =>
      _updatePreference(_enableHapticsKey, _enableHaptics = !_enableHaptics);

  void toggleFruitDenseList() =>
      _updatePreference(_fruitDenseListKey, _fruitDenseList = !_fruitDenseList);

  void setNeumorphicStyle(NeumorphicStyle value, {bool? notify}) {
    if (_neumorphicStyle != value) {
      _neumorphicStyle = value;
      _updateIntPreference(_neumorphicStyleKey, value.index);
      if (notify ?? true) notifyListeners();
    }
  }

  void setRgbAnimationSpeed(double speed) => _updateDoublePreference(
    _rgbAnimationSpeedKey,
    _rgbAnimationSpeed = speed,
  );

  Future<void> setSeedColor(Color? color) async {
    _seedColor = color;
    if (color == null) {
      await _prefs.remove(_seedColorKey);
    } else {
      await _prefs.setInt(_seedColorKey, color.toARGB32());
    }
    notifyListeners();
  }

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

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _init();
    notifyListeners();
  }
}
