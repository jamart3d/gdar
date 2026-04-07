part of 'settings_provider.dart';

mixin _SettingsProviderInitializationExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields {
  SharedPreferences get _prefs;
  bool get isTv;
  void setHiddenSessionPreset(HiddenSessionPreset preset);
  void setGlowMode(int mode);
  void setHighlightPlayingWithRgb(bool value);

  void resetAndroidFirstTimeSettings() {
    _appFont = 'rock_salt';
    _prefs.setString(_appFontKey, 'rock_salt');

    final lowPower = kIsWeb && isLikelyLowPowerWebDevice();
    if (lowPower) {
      _performanceMode = true;
      _prefs.setBool(_performanceModeKey, true);
    } else {
      _performanceMode = false;
      _prefs.setBool(_performanceModeKey, false);
      setGlowMode(25);
      setHighlightPlayingWithRgb(true);
    }

    _resetWebPlaybackSettings();
    notifyListeners();
  }

  void resetFruitFirstTimeSettings() {
    _fruitDenseList = false;
    _prefs.setBool(_fruitDenseListKey, false);
    _fruitFloatingSpheres = false;
    _prefs.setBool(_fruitFloatingSpheresKey, false);
    _simpleRandomIcon = false;
    _prefs.setBool(_simpleRandomIconKey, false);
    _performanceMode = true;
    _prefs.setBool(_performanceModeKey, true);
    _oilBannerGlow = false;
    _prefs.setBool(_oilBannerGlowKey, false);
    setGlowMode(0);
    setHighlightPlayingWithRgb(false);

    if (kIsWeb && isLikelyLowPowerWebDevice()) {
      _fruitEnableLiquidGlass = false;
      _prefs.setBool(_fruitEnableLiquidGlassKey, false);
    }

    _resetWebPlaybackSettings();
    notifyListeners();
  }

  void _resetWebPlaybackSettings() {
    if (!kIsWeb) return;

    final profile = detectWebRuntimeProfile();
    final isSafari = isSafariWeb();

    switch (profile) {
      case WebRuntimeProfile.low:
        setHiddenSessionPreset(HiddenSessionPreset.stability);
        break;
      case WebRuntimeProfile.pwa:
        setHiddenSessionPreset(HiddenSessionPreset.balanced);
        break;
      case WebRuntimeProfile.web:
        setHiddenSessionPreset(
          isSafari
              ? HiddenSessionPreset.stability
              : HiddenSessionPreset.balanced,
        );
        break;
      case WebRuntimeProfile.desk:
        setHiddenSessionPreset(
          isSafari
              ? HiddenSessionPreset.balanced
              : HiddenSessionPreset.maxGapless,
        );
        break;
    }
  }

  bool _dBool(bool webVal, bool tvVal, bool phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }

  String _dStr(String webVal, String tvVal, String phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }

  int _dInt(int webVal, int tvVal, int phoneVal) {
    if (isTv) return tvVal;
    if (kIsWeb) return webVal;
    return phoneVal;
  }

  void _setupUiScaleChannel() {
    _uiScaleChannel.setMethodCallHandler((call) async {
      if (call.method != 'setUiScale') return;

      final enabled = call.arguments as bool;
      if (enabled == _uiScale) return;

      await _setUiScale(enabled);
      logger.i('SettingsProvider: UI Scale set to $enabled via ADB');
    });
  }

  Future<void> _setUiScale(bool enabled) async {
    _uiScale = enabled;
    _abbreviateDayOfWeek = enabled;
    _abbreviateMonth = enabled;

    await _prefs.setBool(_uiScaleKey, enabled);
    await _prefs.setBool(_abbreviateDayOfWeekKey, _abbreviateDayOfWeek);
    await _prefs.setBool(_abbreviateMonthKey, _abbreviateMonth);
    notifyListeners();
  }

  void _init() {
    _initializeFirstRunState();
    _loadCorePreferences();
    _loadWebPlaybackPreferences();
    _loadScreensaverPreferences();
    _loadSourceFilterPreferences();
  }

  void _initializeFirstRunState() {
    final firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;
    _uiScale =
        _prefs.getBool(_uiScaleKey) ?? DefaultSettings.uiScaleDesktopDefault;

    if (firstRunCheckDone) return;

    final views = WidgetsBinding.instance.platformDispatcher.views;
    if (views.isNotEmpty) {
      final view = views.first;
      final physicalWidth = view.physicalSize.width;
      if (isTv) {
        _uiScale = false;
        _prefs.setBool(_uiScaleKey, false);
      } else if (physicalWidth <= 720) {
        _uiScale = DefaultSettings.uiScaleMobileDefault;
        _prefs.setBool(_uiScaleKey, DefaultSettings.uiScaleMobileDefault);
      }
    }

    _isFirstRun = true;
    _prefs.setBool('first_run_check_done', true);
  }

  void _loadCorePreferences() {
    _onboardingCompletedVersion =
        _prefs.getInt(_onboardingCompletedVersionKey) ??
        (kIsWeb ? kCurrentOnboardingVersion : 0);
    _showTrackNumbers =
        _prefs.getBool(_trackNumberKey) ?? DefaultSettings.showTrackNumbers;
    _hideTrackDuration =
        _prefs.getBool(_hideTrackDurationKey) ??
        DefaultSettings.hideTrackDuration;
    _playOnTap = _prefs.getBool(_playOnTapKey) ?? DefaultSettings.playOnTap;
    _showSingleShnid =
        _prefs.getBool(_showSingleShnidKey) ?? DefaultSettings.showSingleShnid;
    _playRandomOnCompletion =
        _prefs.getBool(_playRandomOnCompletionKey) ??
        DefaultSettings.playRandomOnCompletion;
    _nonRandom = _prefs.getBool(_nonRandomKey) ?? DefaultSettings.nonRandom;
    _playRandomOnStartup =
        _prefs.getBool(_playRandomOnStartupKey) ??
        DefaultSettings.playRandomOnStartup;
    _dateFirstInShowCard =
        _prefs.getBool(_dateFirstInShowCardKey) ??
        DefaultSettings.dateFirstInShowCard;
    _useDynamicColor =
        _prefs.getBool(_useDynamicColorKey) ?? DefaultSettings.useDynamicColor;
    _showDayOfWeek =
        _prefs.getBool(_showDayOfWeekKey) ?? DefaultSettings.showDayOfWeek;
    _abbreviateDayOfWeek =
        _prefs.getBool(_abbreviateDayOfWeekKey) ??
        DefaultSettings.abbreviateDayOfWeek;
    _abbreviateMonth =
        _prefs.getBool(_abbreviateMonthKey) ?? DefaultSettings.abbreviateMonth;
    _simpleRandomIcon = _prefs.getBool(_simpleRandomIconKey) ?? false;
    _fruitDenseList = _prefs.getBool(_fruitDenseListKey) ?? false;
    _fruitStickyNowPlaying = _prefs.getBool(_fruitStickyNowPlayingKey) ?? false;
    _markPlayedOnStart =
        _prefs.getBool(_markPlayedOnStartKey) ??
        DefaultSettings.markPlayedOnStart;
    _enableHaptics = _prefs.getBool(_enableHapticsKey) ?? true;
    _carMode = _prefs.getBool(_carModeKey) ?? DefaultSettings.carMode;
    _fruitFloatingSpheres =
        _prefs.getBool(_fruitFloatingSpheresKey) ??
        DefaultSettings.fruitFloatingSpheres;
    if (_carMode) {
      _showDayOfWeek = false;
      _abbreviateMonth = true;
      _prefs.setBool(_showDayOfWeekKey, false);
      _prefs.setBool(_abbreviateMonthKey, true);

      if (_uiScale) {
        _uiScale = false;
        _abbreviateDayOfWeek = false;
        _prefs.setBool(_uiScaleKey, false);
        _prefs.setBool(_abbreviateDayOfWeekKey, false);
      }
    }

    _loadLegacyCoreMigrations();
    _loadAppearancePreferences();
    _loadBehaviorPreferences();
    _loadDebugPreferences();
  }

  void _loadSourceFilterPreferences() {
    _randomOnlyUnplayed =
        _prefs.getBool(_randomOnlyUnplayedKey) ??
        DefaultSettings.randomOnlyUnplayed;
    _randomOnlyHighRated =
        _prefs.getBool(_randomOnlyHighRatedKey) ??
        DefaultSettings.randomOnlyHighRated;
    _randomExcludePlayed =
        _prefs.getBool(_randomExcludePlayedKey) ??
        DefaultSettings.randomExcludePlayed;
    _filterHighestShnid = _prefs.getBool(_filterHighestShnidKey) ?? true;

    final categoriesJson = _prefs.getString(_sourceCategoryFiltersKey);
    if (categoriesJson != null) {
      try {
        final decoded = json.decode(categoriesJson) as Map<String, dynamic>;
        decoded.forEach((key, value) {
          if (_sourceCategoryFilters.containsKey(key) && value is bool) {
            _sourceCategoryFilters[key] = value;
          }
        });
      } catch (_) {
        // Keep defaults when persisted data is malformed.
      }
    } else {
      _sourceCategoryFilters = Map.from(DefaultSettings.sourceCategoryFilters);
    }

    if (kIsWeb && !(_prefs.getBool(_webSourceFiltersInitKey) ?? false)) {
      _sourceCategoryFilters.updateAll((key, _) => key == 'matrix');
      _prefs.setBool(_webSourceFiltersInitKey, true);
      _prefs.setString(
        _sourceCategoryFiltersKey,
        json.encode(_sourceCategoryFilters),
      );
    }
  }

  void _loadLegacyCoreMigrations() {
    final defaultScreensaver = _dBool(
      WebDefaults.useOilScreensaver,
      DefaultSettings.useOilScreensaver,
      DefaultSettings.useOilScreensaver,
    );

    if (_prefs.containsKey('use_screensaver')) {
      final oldEnabled = _prefs.getBool('use_screensaver') ?? true;
      _useOilScreensaver = defaultScreensaver ? oldEnabled : false;
      if (oldEnabled) {
        _prefs.setBool(_useOilScreensaverKey, _useOilScreensaver);
      }
      _prefs.remove('use_screensaver');
    } else {
      _useOilScreensaver =
          _prefs.getBool(_useOilScreensaverKey) ?? defaultScreensaver;
    }

    if (_prefs.containsKey('use_handwriting_font')) {
      final oldHandwriting = _prefs.getBool('use_handwriting_font') ?? false;
      _appFont = oldHandwriting ? 'caveat' : 'default';
      if (oldHandwriting) {
        _prefs.setString(_appFontKey, 'caveat');
      }
      _prefs.remove('use_handwriting_font');
    }
  }

  void _loadAppearancePreferences() {
    _appFont =
        _prefs.getString(_appFontKey) ??
        _dStr(
          WebDefaults.appFont,
          DefaultSettings.appFont,
          DefaultSettings.appFont,
        );
    logger.i('SettingsProvider: Active App Font = $_appFont');

    _glowMode = _loadGlowModePreference();
    _useTrueBlack = _loadUseTrueBlackPreference();
    _highlightPlayingWithRgb =
        _prefs.getBool(_highlightPlayingWithRgbKey) ??
        DefaultSettings.highlightPlayingWithRgb;
    _rgbAnimationSpeed =
        _prefs.getDouble(_rgbAnimationSpeedKey) ??
        DefaultSettings.rgbAnimationSpeed;
    _showSplashScreen =
        _prefs.getBool(_showSplashScreenKey) ??
        _dBool(
          kIsWeb ? _isFirstRun : WebDefaults.showSplashScreen,
          DefaultSettings.showSplashScreen,
          DefaultSettings.showSplashScreen,
        );
    _useNeumorphism =
        _prefs.getBool(_useNeumorphismKey) ??
        _dBool(
          WebDefaults.useNeumorphism,
          DefaultSettings.useNeumorphism,
          PhoneDefaults.useNeumorphism,
        );
    _fruitEnableLiquidGlass =
        _prefs.getBool(_fruitEnableLiquidGlassKey) ?? false;
    _neumorphicStyle =
        NeumorphicStyle.values[_prefs.getInt(_neumorphicStyleKey) ??
            DefaultSettings.neumorphicStyle.index];
    _seedColor = _readSeedColor();
  }

  int _loadGlowModePreference() {
    if (_prefs.containsKey(_glowModeKey)) {
      final glowMode = _prefs.getInt(_glowModeKey) ?? DefaultSettings.glowMode;
      final migrated = switch (glowMode) {
        1 => 25,
        2 => 50,
        3 => 100,
        _ => glowMode,
      };
      if (migrated != glowMode) {
        _prefs.setInt(_glowModeKey, migrated);
      }
      return migrated;
    }

    final oldShow = _prefs.getBool(_showGlowBorderKey) ?? false;
    final oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
    final migrated = oldHalf
        ? 50
        : oldShow
        ? 100
        : DefaultSettings.glowMode;
    _prefs.setInt(_glowModeKey, migrated);
    return migrated;
  }

  bool _loadUseTrueBlackPreference() {
    final oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
    if (oldHalf && !_prefs.containsKey(_useTrueBlackKey)) {
      _prefs.setBool(_useTrueBlackKey, true);
      return true;
    }

    return _prefs.getBool(_useTrueBlackKey) ??
        _dBool(
          WebDefaults.useTrueBlack,
          TvDefaults.useTrueBlack,
          DefaultSettings.useTrueBlack,
        );
  }

  Color? _readSeedColor() {
    final seedColorValue = _prefs.getInt(_seedColorKey);
    return seedColorValue != null ? Color(seedColorValue) : null;
  }

  void _loadBehaviorPreferences() {
    _showPlaybackMessages =
        _prefs.getBool(_showPlaybackMessagesKey) ??
        _dBool(
          DefaultSettings.showPlaybackMessages,
          TvDefaults.showPlaybackMessages,
          DefaultSettings.showPlaybackMessages,
        );
    _showDevAudioHud =
        _prefs.getBool(_showDevAudioHudKey) ?? DefaultSettings.showDevAudioHud;
    _devHudMode = DevHudMode.fromString(
      _prefs.getString(_devHudModeKey) ?? DefaultSettings.devHudMode,
    );
    _devAudioHudSnapshot = _prefs.getString(_devAudioHudSnapshotKey) ?? '';
    _sortOldestFirst =
        _prefs.getBool(_sortOldestFirstKey) ?? DefaultSettings.sortOldestFirst;
    _useStrictSrcCategorization =
        _prefs.getBool(_useStrictSrcCategorizationKey) ??
        DefaultSettings.useStrictSrcCategorization;
    _offlineBuffering =
        _prefs.getBool(_offlineBufferingKey) ??
        DefaultSettings.offlineBuffering;
    _enableBufferAgent =
        _prefs.getBool(_enableBufferAgentKey) ??
        DefaultSettings.enableBufferAgent;
    _preventSleep = _loadPreventSleepPreference();
    _marqueeEnabled = _prefs.getBool(_marqueeEnabledKey) ?? true;
    _enableSwipeToBlock =
        _prefs.getBool(_enableSwipeToBlockKey) ??
        DefaultSettings.enableSwipeToBlock;
    _hideTabText =
        _prefs.getBool(_hideTabTextKey) ?? DefaultSettings.hideTabText;
    _omitHttpPathInCopy =
        _prefs.getBool(_omitHttpPathInCopyKey) ??
        DefaultSettings.omitHttpPathInCopy;
    _performanceMode = _loadPerformanceModePreference();
    _forceTv = _prefs.getBool(_forceTvKey) ?? false;
  }

  bool _loadPreventSleepPreference() {
    if (_prefs.containsKey('prevent_screensaver') &&
        !_prefs.containsKey(_preventSleepKey)) {
      final migrated =
          _prefs.getBool('prevent_screensaver') ?? DefaultSettings.preventSleep;
      _prefs.setBool(_preventSleepKey, migrated);
      _prefs.remove('prevent_screensaver');
      return migrated;
    }

    return _prefs.getBool(_preventSleepKey) ??
        _dBool(
          DefaultSettings.preventSleep,
          TvDefaults.preventSleep,
          PhoneDefaults.preventSleep,
        );
  }

  bool _loadPerformanceModePreference() {
    final hasPreference = _prefs.containsKey(_performanceModeKey);
    var performanceMode =
        _prefs.getBool(_performanceModeKey) ??
        _dBool(
          WebDefaults.performanceMode,
          TvDefaults.performanceMode,
          PhoneDefaults.performanceMode,
        );

    if (!hasPreference &&
        kIsWeb &&
        isLikelyLowPowerWebDevice() &&
        !performanceMode) {
      performanceMode = true;
      _prefs.setBool(_performanceModeKey, true);
      logger.i(
        'SettingsProvider: Auto-enabled performance mode for low-power web mobile device.',
      );
    }

    return performanceMode;
  }

  void _loadDebugPreferences() {
    _showDebugLayout =
        _prefs.getBool(_showDebugLayoutKey) ?? DefaultSettings.showDebugLayout;
    if (_showDebugLayout) {
      _showDebugLayout = false;
      _prefs.setBool(_showDebugLayoutKey, false);
    }
    _enableShakedownTween = _prefs.getBool(_enableShakedownTweenKey) ?? true;
  }

  void _loadWebPlaybackPreferences() {
    _audioEngineMode = _loadAudioEngineModePreference();
    _webEngineProfile = WebEngineProfile.fromString(
      _prefs.getString(_webEngineProfileChoiceKey),
    );
    _applyAdaptiveWebEngineProfileIfNeeded();

    _webPrefetchSeconds = _audioEngineMode == AudioEngineMode.webAudio
        ? -1
        : DefaultSettings.webPrefetchSeconds;
    if (_prefs.getInt(_webPrefetchSecondsKey) != _webPrefetchSeconds) {
      _prefs.setInt(_webPrefetchSecondsKey, _webPrefetchSeconds);
    }

    _trackTransitionMode =
        _prefs.getString(_trackTransitionModeKey) ??
        DefaultSettings.trackTransitionMode;
    if (_trackTransitionMode == 'crossfade') {
      _trackTransitionMode = 'gapless';
      _prefs.setString(_trackTransitionModeKey, _trackTransitionMode);
    }

    _crossfadeDurationSeconds =
        _prefs.getDouble(_crossfadeDurationSecondsKey) ??
        DefaultSettings.crossfadeDurationSeconds;
    _hybridHandoffMode = HybridHandoffMode.fromString(
      _prefs.getString(_hybridHandoffModeKey) ?? 'buffered',
    );
    _hybridBackgroundMode = HybridBackgroundMode.fromString(
      _prefs.getString(_hybridBackgroundModeKey) ?? 'heartbeat',
    );
    _hiddenSessionPreset = HiddenSessionPreset.fromString(
      _prefs.getString(_hiddenSessionPresetKey) ?? 'balanced',
    );
    _allowHiddenWebAudio = _prefs.getBool(_allowHiddenWebAudioKey) ?? false;
    _usePlayPauseFade = _prefs.getBool(_usePlayPauseFadeKey) ?? true;
    _handoffCrossfadeMs =
        _prefs.getInt(_handoffCrossfadeMsKey) ??
        DefaultSettings.handoffCrossfadeMs;
  }

  AudioEngineMode _loadAudioEngineModePreference() {
    if (_prefs.containsKey('web_gapless_engine')) {
      final oldEnabled = _prefs.getBool('web_gapless_engine') ?? true;
      final migrated = oldEnabled
          ? AudioEngineMode.auto
          : AudioEngineMode.standard;
      _prefs.remove('web_gapless_engine');
      _prefs.setString(_audioEngineModeKey, migrated.name);
      return migrated;
    }

    return AudioEngineMode.fromString(
      _prefs.getString(_audioEngineModeKey) ??
          _dStr(
            WebDefaults.audioEngineMode,
            PhoneDefaults.audioEngineMode,
            PhoneDefaults.audioEngineMode,
          ),
    );
  }

  void _applyAdaptiveWebEngineProfileIfNeeded() {
    final hasAdaptiveProfileInit =
        _prefs.getBool(_webEngineProfileInitKey) ?? false;
    final hasExplicitEngineOverride =
        _prefs.containsKey(_audioEngineModeKey) &&
        _audioEngineMode != AudioEngineMode.auto;

    if (!kIsWeb || hasAdaptiveProfileInit || hasExplicitEngineOverride) {
      return;
    }

    // Delegate to the hardware-aware decision tree for first-run defaults
    _resetWebPlaybackSettings();
    _webEngineProfile = isLikelyLowPowerWebDevice()
        ? WebEngineProfile.legacy
        : WebEngineProfile.modern;

    _prefs.setBool(_webEngineProfileInitKey, true);
    _prefs.setString(_webEngineProfileChoiceKey, _webEngineProfile.name);
    logger.i(
      'SettingsProvider: Adaptive web engine profile applied (Decision Tree Logic).',
    );
  }

  void _loadScreensaverPreferences() {
    _useOilScreensaver =
        _prefs.getBool(_useOilScreensaverKey) ??
        _dBool(
          WebDefaults.useOilScreensaver,
          DefaultSettings.useOilScreensaver,
          DefaultSettings.useOilScreensaver,
        );
    _oilScreensaverMode =
        _prefs.getString(_oilScreensaverModeKey) ??
        _dStr(
          DefaultSettings.oilScreensaverMode,
          TvDefaults.oilScreensaverMode,
          DefaultSettings.oilScreensaverMode,
        );
    _oilScreensaverInactivityMinutes =
        _prefs.getInt(_oilScreensaverInactivityMinutesKey) ??
        DefaultSettings.oilScreensaverInactivityMinutes;
    _oilFlowSpeed =
        _prefs.getDouble(_oilFlowSpeedKey) ?? DefaultSettings.oilFlowSpeed;
    _oilPulseIntensity =
        _prefs.getDouble(_oilPulseIntensityKey) ??
        DefaultSettings.oilPulseIntensity;
    _oilPalette =
        _prefs.getString(_oilPaletteKey) ?? DefaultSettings.oilPalette;
    _oilFilmGrain =
        _prefs.getDouble(_oilFilmGrainKey) ?? DefaultSettings.oilFilmGrain;
    _oilHeatDrift =
        _prefs.getDouble(_oilHeatDriftKey) ?? DefaultSettings.oilHeatDrift;
    _oilEnableAudioReactivity =
        _prefs.getBool(_oilEnableAudioReactivityKey) ??
        DefaultSettings.oilEnableAudioReactivity;
    _oilPerformanceLevel = _loadOilPerformanceLevel();
    _oilPaletteCycle =
        _prefs.getBool(_oilPaletteCycleKey) ?? DefaultSettings.oilPaletteCycle;
    _oilPaletteTransitionSpeed =
        _prefs.getDouble(_oilPaletteTransitionSpeedKey) ??
        DefaultSettings.oilPaletteTransitionSpeed;
    _oilBannerDisplayMode =
        _prefs.getString(_oilBannerDisplayModeKey) ??
        DefaultSettings.oilBannerDisplayMode;
    _oilBannerFont = _loadOilBannerFont();
    _oilFlatTextProximity =
        _prefs.getDouble(_oilFlatTextProximityKey) ??
        DefaultSettings.oilFlatTextProximity;
    _oilFlatTextPlacement =
        _prefs.getString(_oilFlatTextPlacementKey) ??
        DefaultSettings.oilFlatTextPlacement;
    _oilBannerResolution =
        _prefs.getDouble(_oilBannerResolutionKey) ??
        DefaultSettings.oilBannerResolution;
    _oilBannerPixelSnap =
        _prefs.getBool(_oilBannerPixelSnapKey) ??
        DefaultSettings.oilBannerPixelSnap;
    _oilAutoTextSpacing =
        _prefs.getBool(_oilAutoTextSpacingKey) ??
        _dBool(
          DefaultSettings.oilAutoTextSpacing,
          TvDefaults.oilAutoTextSpacing,
          DefaultSettings.oilAutoTextSpacing,
        );
    _oilAutoRingSpacing =
        _prefs.getBool(_oilAutoRingSpacingKey) ??
        _dBool(
          DefaultSettings.oilAutoRingSpacing,
          TvDefaults.oilAutoRingSpacing,
          DefaultSettings.oilAutoRingSpacing,
        );
    _oilBannerLetterSpacing =
        _prefs.getDouble(_oilBannerLetterSpacingKey) ??
        DefaultSettings.oilBannerLetterSpacing;
    _oilBannerWordSpacing =
        _prefs.getDouble(_oilBannerWordSpacingKey) ??
        DefaultSettings.oilBannerWordSpacing;
    _oilTrackLetterSpacing =
        _prefs.getDouble(_oilTrackLetterSpacingKey) ??
        DefaultSettings.oilTrackLetterSpacing;
    _oilTrackWordSpacing =
        _prefs.getDouble(_oilTrackWordSpacingKey) ??
        DefaultSettings.oilTrackWordSpacing;
    _oilInnerRingSpacingMultiplier =
        _prefs.getDouble(_oilInnerRingSpacingMultiplierKey) ?? 1.0;
    _oilMiddleRingSpacingMultiplier =
        _prefs.getDouble(_oilMiddleRingSpacingMultiplierKey) ?? 1.0;
    _oilOuterRingSpacingMultiplier =
        _prefs.getDouble(_oilOuterRingSpacingMultiplierKey) ?? 1.0;
    _oilFlatLineSpacing =
        _prefs.getDouble(_oilFlatLineSpacingKey) ??
        DefaultSettings.oilFlatLineSpacing;

    _loadScreensaverTrailPreferences();
    _loadScreensaverAudioPreferences();
    _loadScreensaverVisualPreferences();
    _loadScreensaverRingPreferences();
  }

  int _loadOilPerformanceLevel() {
    if (!_prefs.containsKey(_oilPerformanceLevelKey) &&
        !_prefs.containsKey('oil_performance_mode')) {
      return _dInt(
        DefaultSettings.oilPerformanceLevel,
        TvDefaults.oilPerformanceLevel,
        DefaultSettings.oilPerformanceLevel,
      );
    }

    return _prefs.getInt(_oilPerformanceLevelKey) ??
        (_prefs.getBool('oil_performance_mode') == true ? 2 : 0);
  }

  String _loadOilBannerFont() {
    final storedFont =
        _prefs.getString(_oilBannerFontKey) ?? DefaultSettings.oilBannerFont;
    if (storedFont != 'rock_salt') {
      return storedFont;
    }

    _prefs.setString(_oilBannerFontKey, 'RockSalt');
    return 'RockSalt';
  }

  void _loadScreensaverTrailPreferences() {
    _oilLogoTrailIntensity =
        _prefs.getDouble(_oilLogoTrailIntensityKey) ??
        DefaultSettings.oilLogoTrailIntensity;
    _oilLogoTrailSlices =
        _prefs.getInt(_oilLogoTrailSlicesKey) ??
        DefaultSettings.oilLogoTrailSlices;
    _oilLogoTrailDynamic =
        _prefs.getBool(_oilLogoTrailDynamicKey) ??
        DefaultSettings.oilLogoTrailDynamic;
    _oilLogoTrailLength =
        _prefs.getDouble(_oilLogoTrailLengthKey) ??
        DefaultSettings.oilLogoTrailLength;
    _oilLogoTrailScale =
        _prefs.getDouble(_oilLogoTrailScaleKey) ??
        DefaultSettings.oilLogoTrailScale;
    _oilLogoTrailInitialScale =
        _prefs.getDouble(_oilLogoTrailInitialScaleKey) ??
        DefaultSettings.oilLogoTrailInitialScale;
  }

  void _loadScreensaverAudioPreferences() {
    _oilAudioPeakDecay =
        _prefs.getDouble(_oilAudioPeakDecayKey) ??
        DefaultSettings.oilAudioPeakDecay;
    _oilAudioBassBoost =
        _prefs.getDouble(_oilAudioBassBoostKey) ??
        DefaultSettings.oilAudioBassBoost;
    _oilAudioReactivityStrength =
        _prefs.getDouble(_oilAudioReactivityStrengthKey) ??
        DefaultSettings.oilAudioReactivityStrength;
    _oilAudioGraphMode =
        _prefs.getString(_oilAudioGraphModeKey) ??
        DefaultSettings.oilAudioGraphMode;
    _oilBeatDetectorMode =
        _prefs.getString(_oilBeatDetectorModeKey) ??
        DefaultSettings.oilBeatDetectorMode;
    _oilBeatSensitivity =
        _prefs.getDouble(_oilBeatSensitivityKey) ??
        DefaultSettings.oilBeatSensitivity;
    _oilBeatImpact =
        _prefs.getDouble(_oilBeatImpactKey) ?? DefaultSettings.oilBeatImpact;
    _beatAutocorrSecondPass =
        _prefs.getBool(_beatAutocorrSecondPassKey) ??
        _dBool(
          DefaultSettings.beatAutocorrSecondPass,
          TvDefaults.beatAutocorrSecondPass,
          DefaultSettings.beatAutocorrSecondPass,
        );
    _beatAutocorrSecondPassHq =
        _prefs.getBool(_beatAutocorrSecondPassHqKey) ??
        _dBool(
          DefaultSettings.beatAutocorrSecondPassHq,
          TvDefaults.beatAutocorrSecondPassHq,
          DefaultSettings.beatAutocorrSecondPassHq,
        );
    _oilEkgRadius =
        _prefs.getDouble(_oilEkgRadiusKey) ?? DefaultSettings.oilEkgRadius;
    _oilEkgReplication =
        _prefs.getInt(_oilEkgReplicationKey) ??
        DefaultSettings.oilEkgReplication;
    _oilEkgSpread =
        _prefs.getDouble(_oilEkgSpreadKey) ?? DefaultSettings.oilEkgSpread;
  }

  void _loadScreensaverVisualPreferences() {
    _oilShowInfoBanner =
        _prefs.getBool(_oilShowInfoBannerKey) ??
        DefaultSettings.oilShowInfoBanner;
    _oilLogoScale =
        _prefs.getDouble(_oilLogoScaleKey) ?? DefaultSettings.oilLogoScale;
    _oilTranslationSmoothing =
        _prefs.getDouble(_oilTranslationSmoothingKey) ??
        DefaultSettings.oilTranslationSmoothing;
    _oilBlurAmount =
        _prefs.getDouble(_oilBlurAmountKey) ?? DefaultSettings.oilBlurAmount;
    _oilFlatColor =
        _prefs.getBool(_oilFlatColorKey) ?? DefaultSettings.oilFlatColor;
    _oilBannerGlow =
        _prefs.getBool(_oilBannerGlowKey) ?? DefaultSettings.oilBannerGlow;
    _oilBannerFlicker =
        _prefs.getDouble(_oilBannerFlickerKey) ??
        DefaultSettings.oilBannerFlicker;
    _oilBannerGlowBlur =
        _prefs.getDouble(_oilBannerGlowBlurKey) ??
        DefaultSettings.oilBannerGlowBlur;
    _oilLogoAntiAlias =
        _prefs.getBool(_oilLogoAntiAliasKey) ??
        DefaultSettings.oilLogoAntiAlias;
    _oilPreviewShowGraph =
        _prefs.getBool(_oilPreviewShowGraphKey) ??
        DefaultSettings.oilPreviewShowGraph;
  }

  void _loadScreensaverRingPreferences() {
    _oilInnerRingScale =
        _prefs.getDouble(_oilInnerRingScaleKey) ??
        DefaultSettings.oilInnerRingScale;
    _oilInnerToMiddleGap =
        _prefs.getDouble(_oilInnerToMiddleGapKey) ??
        DefaultSettings.oilInnerToMiddleGap;
    _oilMiddleToOuterGap =
        _prefs.getDouble(_oilMiddleToOuterGapKey) ??
        DefaultSettings.oilMiddleToOuterGap;
    _oilOrbitDrift =
        _prefs.getDouble(_oilOrbitDriftKey) ?? DefaultSettings.oilOrbitDrift;
    _oilInnerRingFontScale =
        _prefs.getDouble(_oilInnerRingFontScaleKey) ??
        DefaultSettings.oilInnerRingFontScale;
    _oilMiddleRingFontScale =
        _prefs.getDouble(_oilMiddleRingFontScaleKey) ??
        DefaultSettings.oilMiddleRingFontScale;
    _oilOuterRingFontScale =
        _prefs.getDouble(_oilOuterRingFontScaleKey) ??
        DefaultSettings.oilOuterRingFontScale;
    _oilInnerRingSpacingMultiplier =
        _prefs.getDouble(_oilInnerRingSpacingMultiplierKey) ??
        DefaultSettings.oilInnerRingSpacingMultiplier;
    _oilTvPremiumHighlight =
        _prefs.getBool(_oilTvPremiumHighlightKey) ??
        (isTv
            ? TvDefaults.oilTvPremiumHighlight
            : DefaultSettings.oilTvPremiumHighlight);
    _hideTvScrollbars =
        _prefs.getBool(_hideTvScrollbarsKey) ??
        (isTv ? TvDefaults.hideTvScrollbars : false);
    _oilScaleSource =
        _prefs.getInt(_oilScaleSourceKey) ?? DefaultSettings.oilScaleSource;
    _oilScaleMultiplier =
        _prefs.getDouble(_oilScaleMultiplierKey) ??
        DefaultSettings.oilScaleMultiplier;
    _oilColorSource =
        _prefs.getInt(_oilColorSourceKey) ?? DefaultSettings.oilColorSource;
    _oilColorMultiplier =
        _prefs.getDouble(_oilColorMultiplierKey) ??
        DefaultSettings.oilColorMultiplier;
    _oilWoodstockEveryHour =
        _prefs.getBool(_oilWoodstockEveryHourKey) ??
        DefaultSettings.oilWoodstockEveryHour;
    _oilScaleSineEnabled =
        _prefs.getBool(_oilScaleSineEnabledKey) ??
        DefaultSettings.oilScaleSineEnabled;
    _oilScaleSineFreq =
        _prefs.getDouble(_oilScaleSineFreqKey) ??
        DefaultSettings.oilScaleSineFreq;
    _oilScaleSineAmp =
        _prefs.getDouble(_oilScaleSineAmpKey) ??
        DefaultSettings.oilScaleSineAmp;
    _showScreensaverCountdown =
        _prefs.getBool(_showScreensaverCountdownKey) ?? false;
    _enableTvBackgroundSpheres =
        _prefs.getBool(_enableTvBackgroundSpheresKey) ??
        DefaultSettings.enableTvBackgroundSpheres;
    _tvBackgroundSphereAmount =
        _prefs.getString(_tvBackgroundSphereAmountKey) ??
        DefaultSettings.tvBackgroundSphereAmount;

    if (isTv) {
      _oilScreensaverMode = TvDefaults.oilScreensaverMode;
    }
  }
}
