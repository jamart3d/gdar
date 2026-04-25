part of 'settings_provider.dart';

mixin _SettingsProviderScreensaverLoaderExtension
    on
        ChangeNotifier,
        _SettingsProviderWebFields,
        _SettingsProviderScreensaverFields,
        _SettingsProviderPlatformDefaultsExtension {
  SharedPreferences get _prefs;
  @override
  bool get isTv;

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
    return loadOilPerformanceLevelPreference(
      _prefs,
      oilPerformanceLevelKey: _oilPerformanceLevelKey,
      isTv: isTv,
      isWeb: kIsWeb,
    );
  }

  String _loadOilBannerFont() {
    return loadOilBannerFontPreference(
      _prefs,
      oilBannerFontKey: _oilBannerFontKey,
    );
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
    _oilAutocorrBeatVariant =
        _prefs.getString(_oilAutocorrBeatVariantKey) ??
        DefaultSettings.oilAutocorrBeatVariant;
    _oilAutocorrLogoVariant =
        _prefs.getString(_oilAutocorrLogoVariantKey) ??
        DefaultSettings.oilAutocorrLogoVariant;
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
