part of 'settings_provider.dart';

mixin _SettingsProviderCoreLoaderExtension
    on
        ChangeNotifier,
        _SettingsProviderCoreFields,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderSourceFiltersFields,
        _SettingsProviderPlatformDefaultsExtension {
  SharedPreferences get _prefs;
  bool get isTv;

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
    _settingsScreenUiScale = _prefs.getBool(_settingsScreenUiScaleKey) ?? false;
    _carMode = _prefs.getBool(_carModeKey) ?? DefaultSettings.carMode;
    _fruitFloatingSpheres =
        _prefs.getBool(_fruitFloatingSpheresKey) ??
        DefaultSettings.fruitFloatingSpheres;
    if (_carMode) {
      _showDayOfWeek = false;
      _abbreviateMonth = true;
      _settingsScreenUiScale = true;
      _prefs.setBool(_showDayOfWeekKey, false);
      _prefs.setBool(_abbreviateMonthKey, true);
      _prefs.setBool(_settingsScreenUiScaleKey, true);

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

  void _loadLegacyCoreMigrations() {
    final migration = migrateLegacyCorePreferences(
      _prefs,
      isTv: isTv,
      isWeb: kIsWeb,
      useOilScreensaverKey: _useOilScreensaverKey,
      appFontKey: _appFontKey,
    );
    _useOilScreensaver = migration.useOilScreensaver;
    _appFont = migration.appFont;
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
    _highlightPlayingWithRgbKey; // Ensure access
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
          WebDefaults.showPlaybackMessages,
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
    return loadPreventSleepPreference(
      _prefs,
      preventSleepKey: _preventSleepKey,
      isTv: isTv,
      isWeb: kIsWeb,
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
}
