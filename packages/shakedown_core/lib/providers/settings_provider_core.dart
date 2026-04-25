part of 'settings_provider.dart';

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
  bool get settingsScreenUiScale => _settingsScreenUiScale;
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

    if (_carMode) {
      _showDayOfWeek = false;
      _abbreviateMonth = true;
      _abbreviateDayOfWeek = true; // Match UI Scale behavior
      _settingsScreenUiScale = true;
      _prefs.setBool(_showDayOfWeekKey, false);
      _prefs.setBool(_abbreviateMonthKey, true);
      _prefs.setBool(_abbreviateDayOfWeekKey, true);
      _prefs.setBool(_settingsScreenUiScaleKey, true);

      if (_uiScale) {
        _uiScale = false;
        _prefs.setBool(_uiScaleKey, false);
      }
    } else {
      _settingsScreenUiScale = false;
      _abbreviateMonth = false;
      _abbreviateDayOfWeek = false;
      _prefs.setBool(_settingsScreenUiScaleKey, false);
      _prefs.setBool(_abbreviateMonthKey, false);
      _prefs.setBool(_abbreviateDayOfWeekKey, false);
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
