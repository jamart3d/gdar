part of 'settings_provider.dart';

const String _useOilScreensaverKey = 'use_oil_screensaver';
const String _oilScreensaverModeKey = 'oil_screensaver_mode';
const String _oilScreensaverInactivityMinutesKey =
    'oil_screensaver_inactivity_minutes';
const String _oilFlowSpeedKey = 'oil_flow_speed';
const String _oilPulseIntensityKey = 'oil_pulse_intensity';
const String _oilPaletteKey = 'oil_palette';
const String _oilFilmGrainKey = 'oil_film_grain';
const String _oilHeatDriftKey = 'oil_heat_drift';
const String _oilTranslationSmoothingKey = 'oil_translation_smoothing';
const String _oilBlurAmountKey = 'oil_blur_amount';
const String _oilFlatColorKey = 'oil_flat_color';
const String _oilBannerGlowKey = 'oil_banner_glow';
const String _oilBannerFlickerKey = 'oil_banner_flicker';
const String _oilBannerGlowBlurKey = 'oil_banner_glow_blur';
const String _oilEnableAudioReactivityKey = 'oil_enable_audio_reactivity';
const String _oilPerformanceLevelKey = 'oil_performance_level';
const String _oilPaletteCycleKey = 'oil_palette_cycle';
const String _oilPaletteTransitionSpeedKey = 'oil_palette_transition_speed';
const String _oilBannerDisplayModeKey = 'oil_banner_display_mode';
const String _oilBannerFontKey = 'oil_banner_font';
const String _oilFlatTextProximityKey = 'oil_flat_text_proximity';
const String _oilFlatTextPlacementKey = 'oil_flat_text_placement';
const String _oilBannerResolutionKey = 'oil_banner_resolution';
const String _oilBannerPixelSnapKey = 'oil_banner_pixel_snap';
const String _oilAutoTextSpacingKey = 'oil_auto_text_spacing';
const String _oilAutoRingSpacingKey = 'oil_auto_ring_spacing';
const String _oilLogoTrailIntensityKey = 'oil_logo_trail_intensity';
const String _oilLogoTrailSlicesKey = 'oil_logo_trail_slices';
const String _oilLogoTrailLengthKey = 'oil_logo_trail_length';
const String _oilLogoTrailScaleKey = 'oil_logo_trail_scale';
const String _oilLogoTrailInitialScaleKey = 'oil_logo_trail_initial_scale';
const String _oilAudioPeakDecayKey = 'oil_audio_peak_decay';
const String _oilAudioBassBoostKey = 'oil_audio_bass_boost';
const String _oilLogoTrailDynamicKey = 'oil_logo_trail_dynamic';
const String _oilAudioReactivityStrengthKey = 'oil_audio_reactivity_strength';
const String _oilAudioGraphModeKey = 'oil_audio_graph_mode';
const String _oilEkgRadiusKey = 'oil_ekg_radius';
const String _oilEkgReplicationKey = 'oil_ekg_replication';
const String _oilEkgSpreadKey = 'oil_ekg_spread';
const String _oilBeatDetectorModeKey = 'oil_beat_detector_mode';
const String _oilAutocorrBeatVariantKey = 'oil_autocorr_beat_variant';
const String _oilAutocorrLogoVariantKey = 'oil_autocorr_logo_variant';
const String _oilBeatSensitivityKey = 'oil_beat_sensitivity';
const String _oilBeatImpactKey = 'oil_beat_impact';
const String _oilShowInfoBannerKey = 'oil_show_info_banner';
const String _oilLogoScaleKey = 'oil_logo_scale';
const String _oilBannerLetterSpacingKey = 'oil_banner_letter_spacing';
const String _oilBannerWordSpacingKey = 'oil_banner_word_spacing';
const String _oilTrackLetterSpacingKey = 'oil_track_letter_spacing';
const String _oilTrackWordSpacingKey = 'oil_track_word_spacing';
const String _oilFlatLineSpacingKey = 'oil_flat_line_spacing';
const String _oilLogoAntiAliasKey = 'oil_logo_anti_alias';
const String _oilInnerRingScaleKey = 'oil_inner_ring_scale';
const String _oilInnerToMiddleGapKey = 'oil_inner_to_middle_gap';
const String _oilMiddleToOuterGapKey = 'oil_middle_to_outer_gap';
const String _oilOrbitDriftKey = 'oil_orbit_drift';
const String _oilInnerRingFontScaleKey = 'oil_inner_ring_font_scale';
const String _oilInnerRingSpacingMultiplierKey =
    'oil_inner_ring_spacing_multiplier';
const String _oilMiddleRingSpacingMultiplierKey =
    'oil_middle_ring_spacing_multiplier';
const String _oilOuterRingSpacingMultiplierKey =
    'oil_outer_ring_spacing_multiplier';
const String _oilMiddleRingFontScaleKey = 'oil_middle_ring_font_scale';
const String _oilOuterRingFontScaleKey = 'oil_outer_ring_font_scale';
const String _oilScaleSourceKey = 'oil_scale_source';
const String _oilScaleMultiplierKey = 'oil_scale_multiplier';
const String _oilScaleSineEnabledKey = 'oil_scale_sine_enabled';
const String _oilScaleSineFreqKey = 'oil_scale_sine_freq';
const String _oilScaleSineAmpKey = 'oil_scale_sine_amp';
const String _oilColorSourceKey = 'oil_color_source';
const String _oilColorMultiplierKey = 'oil_color_multiplier';
const String _oilWoodstockEveryHourKey = 'oil_woodstock_every_hour';
const String _oilTvPremiumHighlightKey = 'oil_tv_premium_highlight';
const String _showScreensaverCountdownKey = 'show_screensaver_countdown';
const String _oilPreviewShowGraphKey = 'oil_preview_show_graph';
const String _beatAutocorrSecondPassKey = 'beat_autocorr_second_pass';
const String _beatAutocorrSecondPassHqKey = 'beat_autocorr_second_pass_hq';

mixin _SettingsProviderScreensaverFields {
  late bool _useOilScreensaver;
  late String _oilScreensaverMode;
  late int _oilScreensaverInactivityMinutes;
  late double _oilFlowSpeed;
  late double _oilPulseIntensity;
  late String _oilPalette;
  late double _oilFilmGrain;
  late double _oilHeatDrift;
  late bool _oilEnableAudioReactivity;
  late bool _preventSleep;
  late int _oilPerformanceLevel;
  late bool _oilPaletteCycle;
  late double _oilPaletteTransitionSpeed;
  late String _oilBannerDisplayMode;
  late String _oilBannerFont;
  late double _oilFlatTextProximity;
  late String _oilFlatTextPlacement;
  late double _oilBannerResolution;
  late bool _oilBannerPixelSnap;
  late bool _oilAutoTextSpacing;
  late bool _oilAutoRingSpacing;
  late double _oilBannerLetterSpacing;
  late double _oilBannerWordSpacing;
  late double _oilTrackLetterSpacing;
  late double _oilTrackWordSpacing;
  late double _oilFlatLineSpacing;
  late double _oilLogoTrailIntensity;
  late int _oilLogoTrailSlices;
  late bool _oilLogoTrailDynamic;
  late double _oilLogoTrailLength;
  late double _oilLogoTrailScale;
  late double _oilLogoTrailInitialScale;
  late double _oilAudioPeakDecay;
  late double _oilAudioBassBoost;
  late double _oilAudioReactivityStrength;
  late String _oilAudioGraphMode;
  late String _oilBeatDetectorMode;
  late String _oilAutocorrBeatVariant;
  late String _oilAutocorrLogoVariant;
  late double _oilBeatSensitivity;
  late double _oilBeatImpact;
  late bool _oilShowInfoBanner;
  late double _oilLogoScale;
  late double _oilTranslationSmoothing;
  late double _oilBlurAmount;
  late bool _oilFlatColor;
  late bool _oilBannerGlow;
  late double _oilBannerFlicker;
  late double _oilBannerGlowBlur;
  late bool _oilLogoAntiAlias;
  late bool _oilPreviewShowGraph;
  late double _oilInnerRingScale;
  late double _oilInnerToMiddleGap;
  late double _oilMiddleToOuterGap;
  late double _oilOrbitDrift;
  late double _oilInnerRingFontScale;
  late double _oilMiddleRingFontScale;
  late double _oilOuterRingFontScale;
  late double _oilInnerRingSpacingMultiplier;
  late double _oilMiddleRingSpacingMultiplier;
  late double _oilOuterRingSpacingMultiplier;
  late bool _oilTvPremiumHighlight;
  late int _oilScaleSource;
  late double _oilScaleMultiplier;
  late int _oilColorSource;
  late double _oilColorMultiplier;
  late bool _oilWoodstockEveryHour;
  late double _oilEkgRadius;
  late int _oilEkgReplication;
  late double _oilEkgSpread;
  late bool _oilScaleSineEnabled;
  late double _oilScaleSineFreq;
  late double _oilScaleSineAmp;
  late bool _showScreensaverCountdown;
  late bool _beatAutocorrSecondPass;
  late bool _beatAutocorrSecondPassHq;
}

mixin _SettingsProviderScreensaverExtension
    on ChangeNotifier, _SettingsProviderScreensaverFields {
  SharedPreferences get _prefs;
  Future<void> _updatePreference(String key, bool value);
  Future<void> _updateStringPreference(String key, String value);
  Future<void> _updateDoublePreference(String key, double value);
  Future<void> _updateIntPreference(String key, int value);

  bool get useOilScreensaver => _useOilScreensaver;
  String get oilScreensaverMode => _oilScreensaverMode;
  int get oilScreensaverInactivityMinutes => _oilScreensaverInactivityMinutes;
  double get oilFlowSpeed => _oilFlowSpeed;
  double get oilPulseIntensity => _oilPulseIntensity;
  String get oilPalette => _oilPalette;
  double get oilFilmGrain => _oilFilmGrain;
  double get oilHeatDrift => _oilHeatDrift;
  bool get oilEnableAudioReactivity => _oilEnableAudioReactivity;
  int get oilPerformanceLevel => _oilPerformanceLevel;
  bool get oilPaletteCycle => _oilPaletteCycle;
  double get oilPaletteTransitionSpeed => _oilPaletteTransitionSpeed;
  String get oilBannerDisplayMode => _oilBannerDisplayMode;
  String get oilBannerFont => _oilBannerFont;
  double get oilFlatTextProximity => _oilFlatTextProximity;
  String get oilFlatTextPlacement => _oilFlatTextPlacement;
  double get oilBannerResolution => _oilBannerResolution;
  bool get oilBannerPixelSnap => _oilBannerPixelSnap;
  bool get oilAutoTextSpacing => _oilAutoTextSpacing;
  bool get oilAutoRingSpacing => _oilAutoRingSpacing;
  double get oilBannerLetterSpacing => _oilBannerLetterSpacing;
  double get oilBannerWordSpacing => _oilBannerWordSpacing;
  double get oilTrackLetterSpacing => _oilTrackLetterSpacing;
  double get oilTrackWordSpacing => _oilTrackWordSpacing;
  double get oilFlatLineSpacing => _oilFlatLineSpacing;
  double get oilLogoTrailIntensity => _oilLogoTrailIntensity;
  int get oilLogoTrailSlices => _oilLogoTrailSlices;
  bool get oilLogoTrailDynamic => _oilLogoTrailDynamic;
  double get oilLogoTrailLength => _oilLogoTrailLength;
  double get oilLogoTrailScale => _oilLogoTrailScale;
  double get oilLogoTrailInitialScale => _oilLogoTrailInitialScale;
  double get oilAudioPeakDecay => _oilAudioPeakDecay;
  double get oilAudioBassBoost => _oilAudioBassBoost;
  double get oilAudioReactivityStrength => _oilAudioReactivityStrength;
  String get oilAudioGraphMode => _oilAudioGraphMode;
  double get oilEkgRadius => _oilEkgRadius;
  int get oilEkgReplication => _oilEkgReplication;
  double get oilEkgSpread => _oilEkgSpread;
  String get oilBeatDetectorMode => _oilBeatDetectorMode;
  String get oilAutocorrBeatVariant => _oilAutocorrBeatVariant;
  String get oilAutocorrLogoVariant => _oilAutocorrLogoVariant;
  double get oilBeatSensitivity => _oilBeatSensitivity;
  double get oilBeatImpact => _oilBeatImpact;
  bool get oilShowInfoBanner => _oilShowInfoBanner;
  double get oilLogoScale => _oilLogoScale;
  double get oilTranslationSmoothing => _oilTranslationSmoothing;
  double get oilBlurAmount => _oilBlurAmount;
  bool get oilFlatColor => _oilFlatColor;
  bool get oilBannerGlow => _oilBannerGlow;
  double get oilBannerFlicker => _oilBannerFlicker;
  double get oilBannerGlowBlur => _oilBannerGlowBlur;
  bool get oilLogoAntiAlias => _oilLogoAntiAlias;
  bool get oilPreviewShowGraph => _oilPreviewShowGraph;
  double get oilInnerRingScale => _oilInnerRingScale;
  double get oilInnerToMiddleGap => _oilInnerToMiddleGap;
  double get oilMiddleToOuterGap => _oilMiddleToOuterGap;
  double get oilOrbitDrift => _oilOrbitDrift;
  double get oilInnerRingFontScale => _oilInnerRingFontScale;
  double get oilMiddleRingFontScale => _oilMiddleRingFontScale;
  double get oilOuterRingFontScale => _oilOuterRingFontScale;
  double get oilInnerRingSpacingMultiplier => _oilInnerRingSpacingMultiplier;
  double get oilMiddleRingSpacingMultiplier => _oilMiddleRingSpacingMultiplier;
  double get oilOuterRingSpacingMultiplier => _oilOuterRingSpacingMultiplier;
  bool get oilTvPremiumHighlight => _oilTvPremiumHighlight;
  int get oilScaleSource => _oilScaleSource;
  double get oilScaleMultiplier => _oilScaleMultiplier;
  int get oilColorSource => _oilColorSource;
  double get oilColorMultiplier => _oilColorMultiplier;
  bool get oilWoodstockEveryHour => _oilWoodstockEveryHour;
  bool get oilScaleSineEnabled => _oilScaleSineEnabled;
  double get oilScaleSineFreq => _oilScaleSineFreq;
  double get oilScaleSineAmp => _oilScaleSineAmp;
  bool get showScreensaverCountdown => _showScreensaverCountdown;
  bool get beatAutocorrSecondPass => _beatAutocorrSecondPass;
  bool get beatAutocorrSecondPassHq => _beatAutocorrSecondPassHq;

  void toggleUseOilScreensaver() => _updatePreference(
    _useOilScreensaverKey,
    _useOilScreensaver = !_useOilScreensaver,
  );

  Future<void> setOilScreensaverMode(String mode) => _updateStringPreference(
    _oilScreensaverModeKey,
    _oilScreensaverMode = mode,
  );

  void setOilScreensaverInactivityMinutes(int minutes) {
    final enforced = [1, 5, 15].contains(minutes) ? minutes : 5;
    _updateIntPreference(
      _oilScreensaverInactivityMinutesKey,
      _oilScreensaverInactivityMinutes = enforced,
    );
  }

  Future<void> setOilFlowSpeed(double value) =>
      _updateDoublePreference(_oilFlowSpeedKey, _oilFlowSpeed = value);

  Future<void> setOilPulseIntensity(double value) => _updateDoublePreference(
    _oilPulseIntensityKey,
    _oilPulseIntensity = value,
  );

  Future<void> setOilPalette(String palette) =>
      _updateStringPreference(_oilPaletteKey, _oilPalette = palette);

  Future<void> setOilFilmGrain(double value) =>
      _updateDoublePreference(_oilFilmGrainKey, _oilFilmGrain = value);

  Future<void> setOilHeatDrift(double value) =>
      _updateDoublePreference(_oilHeatDriftKey, _oilHeatDrift = value);

  Future<void> toggleOilEnableAudioReactivity() async {
    _oilEnableAudioReactivity = !_oilEnableAudioReactivity;
    if (_oilEnableAudioReactivity && _oilPulseIntensity == 0.0) {
      await setOilPulseIntensity(1.0);
    }
    await _updatePreference(
      _oilEnableAudioReactivityKey,
      _oilEnableAudioReactivity,
    );
  }

  Future<void> setOilPerformanceLevel(int level) => _updateIntPreference(
    _oilPerformanceLevelKey,
    _oilPerformanceLevel = level,
  );

  Future<void> toggleOilLogoAntiAlias() => _updatePreference(
    _oilLogoAntiAliasKey,
    _oilLogoAntiAlias = !_oilLogoAntiAlias,
  );

  Future<void> toggleOilPreviewShowGraph() => _updatePreference(
    _oilPreviewShowGraphKey,
    _oilPreviewShowGraph = !_oilPreviewShowGraph,
  );

  Future<void> toggleOilPaletteCycle() => _updatePreference(
    _oilPaletteCycleKey,
    _oilPaletteCycle = !_oilPaletteCycle,
  );

  void setOilPaletteTransitionSpeed(double seconds) => _updateDoublePreference(
    _oilPaletteTransitionSpeedKey,
    _oilPaletteTransitionSpeed = seconds,
  );

  Future<void> setOilBannerDisplayMode(String mode) => _updateStringPreference(
    _oilBannerDisplayModeKey,
    _oilBannerDisplayMode = mode,
  );

  Future<void> setOilBannerFont(String font) =>
      _updateStringPreference(_oilBannerFontKey, _oilBannerFont = font);

  Future<void> setOilFlatTextProximity(double value) => _updateDoublePreference(
    _oilFlatTextProximityKey,
    _oilFlatTextProximity = value.clamp(0.0, 1.0),
  );

  Future<void> setOilFlatTextPlacement(String placement) =>
      _updateStringPreference(
        _oilFlatTextPlacementKey,
        _oilFlatTextPlacement = placement,
      );

  Future<void> setOilBannerLetterSpacing(double value) =>
      _updateDoublePreference(
        _oilBannerLetterSpacingKey,
        _oilBannerLetterSpacing = value.clamp(0.5, 2.0),
      );

  Future<void> setOilBannerWordSpacing(double value) => _updateDoublePreference(
    _oilBannerWordSpacingKey,
    _oilBannerWordSpacing = value.clamp(0.0, 5.0),
  );

  Future<void> setOilFlatLineSpacing(double value) => _updateDoublePreference(
    _oilFlatLineSpacingKey,
    _oilFlatLineSpacing = value.clamp(0.1, 5.0),
  );

  Future<void> setOilAutoTextSpacing(bool value) async {
    _oilAutoTextSpacing = value;
    await _prefs.setBool(_oilAutoTextSpacingKey, value);
    notifyListeners();
  }

  Future<void> setOilAutoRingSpacing(bool value) async {
    _oilAutoRingSpacing = value;
    await _prefs.setBool(_oilAutoRingSpacingKey, value);
    notifyListeners();
  }

  Future<void> setOilLogoTrailIntensity(double value) =>
      _updateDoublePreference(
        _oilLogoTrailIntensityKey,
        _oilLogoTrailIntensity = value.clamp(0.0, 1.0),
      );

  Future<void> setOilLogoTrailSlices(int value) => _updateIntPreference(
    _oilLogoTrailSlicesKey,
    _oilLogoTrailSlices = value.clamp(2, 16),
  );

  void toggleOilLogoTrailDynamic() => _updatePreference(
    _oilLogoTrailDynamicKey,
    _oilLogoTrailDynamic = !_oilLogoTrailDynamic,
  );

  Future<void> setOilLogoTrailLength(double value) => _updateDoublePreference(
    _oilLogoTrailLengthKey,
    _oilLogoTrailLength = value.clamp(0.0, 1.0),
  );

  Future<void> setOilLogoTrailScale(double value) => _updateDoublePreference(
    _oilLogoTrailScaleKey,
    _oilLogoTrailScale = value.clamp(0.0, 1.0),
  );

  Future<void> setOilLogoTrailInitialScale(double value) =>
      _updateDoublePreference(
        _oilLogoTrailInitialScaleKey,
        _oilLogoTrailInitialScale = value.clamp(0.5, 2.0),
      );

  Future<void> setOilAudioPeakDecay(double value) => _updateDoublePreference(
    _oilAudioPeakDecayKey,
    _oilAudioPeakDecay = value.clamp(0.990, 0.999),
  );

  Future<void> setOilAudioBassBoost(double value) => _updateDoublePreference(
    _oilAudioBassBoostKey,
    _oilAudioBassBoost = value.clamp(1.0, 3.0),
  );

  Future<void> setOilAudioReactivityStrength(double value) =>
      _updateDoublePreference(
        _oilAudioReactivityStrengthKey,
        _oilAudioReactivityStrength = value.clamp(0.5, 2.0),
      );

  Future<void> setOilAudioGraphMode(String mode) async {
    _oilAudioGraphMode = mode;
    await _updateStringPreference(_oilAudioGraphModeKey, mode);
    if (mode == 'off' && _oilPreviewShowGraph) {
      await _updatePreference(
        _oilPreviewShowGraphKey,
        _oilPreviewShowGraph = false,
      );
    }
  }

  Future<void> setOilBeatDetectorMode(String mode) => _updateStringPreference(
    _oilBeatDetectorModeKey,
    _oilBeatDetectorMode = mode,
  );

  Future<void> setOilAutocorrBeatVariant(String value) =>
      _updateStringPreference(
        _oilAutocorrBeatVariantKey,
        _oilAutocorrBeatVariant = value,
      );

  Future<void> setOilAutocorrLogoVariant(String value) =>
      _updateStringPreference(
        _oilAutocorrLogoVariantKey,
        _oilAutocorrLogoVariant = value,
      );

  Future<void> setOilBeatSensitivity(double value) => _updateDoublePreference(
    _oilBeatSensitivityKey,
    _oilBeatSensitivity = value.clamp(0.0, 1.0),
  );

  Future<void> setOilBeatImpact(double value) => _updateDoublePreference(
    _oilBeatImpactKey,
    _oilBeatImpact = value.clamp(0.0, 1.0),
  );

  Future<void> toggleBeatAutocorrSecondPass() => _updatePreference(
    _beatAutocorrSecondPassKey,
    _beatAutocorrSecondPass = !_beatAutocorrSecondPass,
  );

  Future<void> toggleBeatAutocorrSecondPassHq() => _updatePreference(
    _beatAutocorrSecondPassHqKey,
    _beatAutocorrSecondPassHq = !_beatAutocorrSecondPassHq,
  );

  void toggleOilShowInfoBanner() => _updatePreference(
    _oilShowInfoBannerKey,
    _oilShowInfoBanner = !_oilShowInfoBanner,
  );

  Future<void> setOilLogoScale(double value) =>
      _updateDoublePreference(_oilLogoScaleKey, _oilLogoScale = value);

  Future<void> setOilTranslationSmoothing(double value) =>
      _updateDoublePreference(
        _oilTranslationSmoothingKey,
        _oilTranslationSmoothing = value,
      );

  Future<void> setOilBlurAmount(double value) =>
      _updateDoublePreference(_oilBlurAmountKey, _oilBlurAmount = value);

  void toggleOilFlatColor() =>
      _updatePreference(_oilFlatColorKey, _oilFlatColor = !_oilFlatColor);

  void toggleOilBannerGlow() =>
      _updatePreference(_oilBannerGlowKey, _oilBannerGlow = !_oilBannerGlow);

  Future<void> setOilBannerFlicker(double value) =>
      _updateDoublePreference(_oilBannerFlickerKey, _oilBannerFlicker = value);

  Future<void> setOilBannerGlowBlur(double value) => _updateDoublePreference(
    _oilBannerGlowBlurKey,
    _oilBannerGlowBlur = value,
  );

  Future<void> setOilBannerResolution(double value) => _updateDoublePreference(
    _oilBannerResolutionKey,
    _oilBannerResolution = value.clamp(1.0, 4.0),
  );

  Future<void> toggleOilBannerPixelSnap() => _updatePreference(
    _oilBannerPixelSnapKey,
    _oilBannerPixelSnap = !_oilBannerPixelSnap,
  );

  Future<void> setOilInnerRingScale(double value) => _updateDoublePreference(
    _oilInnerRingScaleKey,
    _oilInnerRingScale = value.clamp(0.1, 1.0),
  );

  Future<void> setOilInnerRingSpacingMultiplier(double value) =>
      _updateDoublePreference(
        _oilInnerRingSpacingMultiplierKey,
        _oilInnerRingSpacingMultiplier = value.clamp(0.1, 5.0),
      );

  Future<void> setOilMiddleRingSpacingMultiplier(double value) =>
      _updateDoublePreference(
        _oilMiddleRingSpacingMultiplierKey,
        _oilMiddleRingSpacingMultiplier = value.clamp(0.1, 5.0),
      );

  Future<void> setOilOuterRingSpacingMultiplier(double value) =>
      _updateDoublePreference(
        _oilOuterRingSpacingMultiplierKey,
        _oilOuterRingSpacingMultiplier = value.clamp(0.1, 5.0),
      );

  Future<void> setOilInnerToMiddleGap(double value) => _updateDoublePreference(
    _oilInnerToMiddleGapKey,
    _oilInnerToMiddleGap = value.clamp(0.0, 1.0),
  );

  Future<void> setOilMiddleToOuterGap(double value) => _updateDoublePreference(
    _oilMiddleToOuterGapKey,
    _oilMiddleToOuterGap = value.clamp(0.0, 1.0),
  );

  Future<void> setOilOrbitDrift(double value) => _updateDoublePreference(
    _oilOrbitDriftKey,
    _oilOrbitDrift = value.clamp(0.0, 2.0),
  );

  Future<void> setOilInnerRingFontScale(double value) =>
      _updateDoublePreference(
        _oilInnerRingFontScaleKey,
        _oilInnerRingFontScale = value.clamp(0.3, 1.0),
      );

  Future<void> setOilMiddleRingFontScale(double value) =>
      _updateDoublePreference(
        _oilMiddleRingFontScaleKey,
        _oilMiddleRingFontScale = value.clamp(0.3, 1.0),
      );

  Future<void> setOilOuterRingFontScale(double value) =>
      _updateDoublePreference(
        _oilOuterRingFontScaleKey,
        _oilOuterRingFontScale = value.clamp(0.3, 1.0),
      );

  Future<void> setOilScaleSource(int value) async {
    _oilScaleSource = value;
    await _prefs.setInt(_oilScaleSourceKey, value);
    notifyListeners();
  }

  Future<void> setOilScaleMultiplier(double value) => _updateDoublePreference(
    _oilScaleMultiplierKey,
    _oilScaleMultiplier = value.clamp(0.1, 2.0),
  );

  Future<void> setOilColorSource(int value) async {
    _oilColorSource = value;
    await _prefs.setInt(_oilColorSourceKey, value);
    notifyListeners();
  }

  Future<void> setOilColorMultiplier(double value) => _updateDoublePreference(
    _oilColorMultiplierKey,
    _oilColorMultiplier = value.clamp(0.0, 2.0),
  );

  void toggleOilScaleSineEnabled() => _updatePreference(
    _oilScaleSineEnabledKey,
    _oilScaleSineEnabled = !_oilScaleSineEnabled,
  );

  Future<void> setOilScaleSineFreq(double value) => _updateDoublePreference(
    _oilScaleSineFreqKey,
    _oilScaleSineFreq = value.clamp(0.01, 10.0),
  );

  Future<void> setOilScaleSineAmp(double value) => _updateDoublePreference(
    _oilScaleSineAmpKey,
    _oilScaleSineAmp = value.clamp(0.0, 1.0),
  );

  void setOilWoodstockEveryHour(bool value) => _updatePreference(
    _oilWoodstockEveryHourKey,
    _oilWoodstockEveryHour = value,
  );

  Future<void> setOilEkgRadius(double value) => _updateDoublePreference(
    _oilEkgRadiusKey,
    _oilEkgRadius = value.clamp(0.1, 2.0),
  );

  Future<void> setOilEkgReplication(int value) => _updateIntPreference(
    _oilEkgReplicationKey,
    _oilEkgReplication = value.clamp(1, 10),
  );

  Future<void> setOilEkgSpread(double value) => _updateDoublePreference(
    _oilEkgSpreadKey,
    _oilEkgSpread = value.clamp(0.0, 20.0),
  );

  Future<void> setOilTrackLetterSpacing(double value) =>
      _updateDoublePreference(
        _oilTrackLetterSpacingKey,
        _oilTrackLetterSpacing = value,
      );

  Future<void> setOilTrackWordSpacing(double value) => _updateDoublePreference(
    _oilTrackWordSpacingKey,
    _oilTrackWordSpacing = value,
  );

  void toggleOilTvPremiumHighlight() => _updatePreference(
    _oilTvPremiumHighlightKey,
    _oilTvPremiumHighlight = !_oilTvPremiumHighlight,
  );

  void toggleShowScreensaverCountdown() => _updatePreference(
    _showScreensaverCountdownKey,
    _showScreensaverCountdown = !_showScreensaverCountdown,
  );
}
