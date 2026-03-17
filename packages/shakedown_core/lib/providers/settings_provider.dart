import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown_core/config/default_settings.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/web_perf_hint.dart';

import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

enum DevHudMode {
  full,
  mini,
  micro;

  static DevHudMode fromString(String? value) {
    return DevHudMode.values.firstWhere(
      (e) => e.name == value,
      orElse: () => DevHudMode.full,
    );
  }
}

enum WebEngineProfile {
  modern,
  legacy;

  static WebEngineProfile fromString(String? value) {
    return WebEngineProfile.values.firstWhere(
      (e) => e.name == value,
      orElse: () => WebEngineProfile.modern,
    );
  }
}

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final bool isTv;

  // Preference Keys
  static const String _trackNumberKey = 'show_track_numbers';
  static const String _playOnTapKey = 'play_on_tap';
  static const String _showSingleShnidKey = 'show_single_shnid';
  static const String _hideTrackDurationKey = 'hide_track_duration';
  static const String _playRandomOnCompletionKey = 'play_random_on_completion';
  static const String _nonRandomKey = 'non_random';
  static const String _playRandomOnStartupKey = 'play_random_on_startup';
  static const String _dateFirstInShowCardKey = 'date_first_in_show_card';
  static const String _useDynamicColorKey = 'use_dynamic_color';
  static const String _useTrueBlackKey = 'use_true_black';
  static const String _appFontKey = 'app_font';
  static const String _showDayOfWeekKey = 'show_day_of_week';
  static const String _abbreviateDayOfWeekKey = 'abbreviate_day_of_week';
  static const String _abbreviateMonthKey = 'abbreviate_month';
  static const String _useNeumorphismKey = 'use_neumorphism';
  static const String _fruitEnableLiquidGlassKey = 'fruit_enable_liquid_glass';
  static const String _neumorphicStyleKey = 'neumorphic_style';
  static const String _performanceModeKey = 'performance_mode';
  String _appFont = 'default';
  String get appFont => _appFont;

  /// Returns the actual font being used, respecting TV-specific overrides.
  /// On TV, we force 'rock_salt' for the "10-foot" look (v1.1.70 parity).
  String get activeAppFont => isTv ? 'rock_salt' : _appFont;

  void setAppFont(String font) =>
      _updateStringPreference(_appFontKey, _appFont = font);

  static const String _uiScaleKey = 'ui_scale';
  static const String _seedColorKey = 'seed_color';
  static const String _glowModeKey = 'glow_mode';
  static const String _showGlowBorderKey = 'show_glow_border'; // Deprecated
  static const String _halfGlowDynamicKey = 'half_glow_dynamic'; // Deprecated
  static const String _highlightPlayingWithRgbKey =
      'highlight_playing_with_rgb';
  static const String _showPlaybackMessagesKey = 'show_playback_messages';
  static const String _showDevAudioHudKey = 'show_dev_audio_hud';
  static const String _devHudModeKey = 'dev_hud_mode';
  static const String _devAudioHudSnapshotKey = 'dev_audio_hud_snapshot';
  static const String _sortOldestFirstKey = 'sort_oldest_first';
  static const String _useStrictSrcCategorizationKey =
      'use_strict_src_categorization';
  static const String _offlineBufferingKey = 'offline_buffering';
  static const String _enableBufferAgentKey = 'enable_buffer_agent';
  static const String _preventSleepKey = 'prevent_sleep';

  // Web Gapless Engine (web-only)
  static const String _audioEngineModeKey = 'audio_engine_mode';
  static const String _webPrefetchSecondsKey = 'web_prefetch_seconds';
  static const String _trackTransitionModeKey = 'track_transition_mode';
  static const String _crossfadeDurationSecondsKey =
      'crossfade_duration_seconds';
  static const String _hybridHandoffModeKey = 'hybrid_handoff_mode';
  static const String _hybridBackgroundModeKey = 'hybrid_background_mode';
  static const String _allowHiddenWebAudioKey = 'allow_hidden_web_audio';
  static const String _handoffCrossfadeMsKey = 'handoff_crossfade_ms';
  static const String _hybridForceHtml5StartKey = 'hybrid_force_html5_start';
  static const String _hiddenSessionPresetKey = 'hidden_session_preset';
  static const String _webEngineProfileInitKey = 'web_engine_profile_init_v1';
  static const String _webEngineProfileChoiceKey = 'web_engine_profile_choice';
  static const String _webSourceFiltersInitKey = 'web_source_filters_init_v1';
  static const String _simpleRandomIconKey = 'simple_random_icon';
  static const String _fruitDenseListKey = 'fruit_dense_list';
  static const String _fruitStickyNowPlayingKey = 'fruit_sticky_now_playing';
  static const String _enableRunDetectionKey = 'enable_run_detection';

  // Screensaver (steal)
  static const String _useOilScreensaverKey = 'use_oil_screensaver';
  static const String _oilScreensaverModeKey = 'oil_screensaver_mode';
  static const String _oilScreensaverInactivityMinutesKey =
      'oil_screensaver_inactivity_minutes';
  static const String _oilFlowSpeedKey = 'oil_flow_speed';
  static const String _oilPulseIntensityKey = 'oil_pulse_intensity';
  static const String _oilPaletteKey = 'oil_palette';
  static const String _oilFilmGrainKey = 'oil_film_grain';
  static const String _oilHeatDriftKey = 'oil_heat_drift';
  static const String _oilTranslationSmoothingKey = 'oil_translation_smoothing';
  static const String _oilBlurAmountKey = 'oil_blur_amount';
  static const String _oilFlatColorKey = 'oil_flat_color';
  static const String _oilBannerGlowKey = 'oil_banner_glow';
  static const String _oilBannerFlickerKey = 'oil_banner_flicker';
  static const String _oilBannerGlowBlurKey = 'oil_banner_glow_blur';
  static const String _oilEnableAudioReactivityKey =
      'oil_enable_audio_reactivity';
  static const String _oilPerformanceLevelKey = 'oil_performance_level';
  static const String _oilPaletteCycleKey = 'oil_palette_cycle';
  static const String _oilPaletteTransitionSpeedKey =
      'oil_palette_transition_speed';
  static const String _oilBannerDisplayModeKey = 'oil_banner_display_mode';
  static const String _oilBannerFontKey = 'oil_banner_font';
  static const String _oilFlatTextProximityKey = 'oil_flat_text_proximity';
  static const String _oilFlatTextPlacementKey = 'oil_flat_text_placement';
  static const String _oilBannerResolutionKey = 'oil_banner_resolution';
  static const String _oilBannerPixelSnapKey = 'oil_banner_pixel_snap';
  static const String _oilAutoTextSpacingKey = 'oil_auto_text_spacing';
  static const String _oilAutoRingSpacingKey = 'oil_auto_ring_spacing';

  // Trail effect
  static const String _oilLogoTrailIntensityKey = 'oil_logo_trail_intensity';
  static const String _oilLogoTrailSlicesKey = 'oil_logo_trail_slices';
  static const String _oilLogoTrailLengthKey = 'oil_logo_trail_length';
  static const String _oilLogoTrailScaleKey = 'oil_logo_trail_scale';
  static const String _oilLogoTrailInitialScaleKey =
      'oil_logo_trail_initial_scale';

  // Audio Reactivity Tuning
  static const String _oilAudioPeakDecayKey = 'oil_audio_peak_decay';
  static const String _oilAudioBassBoostKey = 'oil_audio_bass_boost';
  static const String _oilLogoTrailDynamicKey = 'oil_logo_trail_dynamic';
  static const String _oilAudioReactivityStrengthKey =
      'oil_audio_reactivity_strength';
  static const String _oilAudioGraphModeKey = 'oil_audio_graph_mode';
  static const String _oilEkgRadiusKey = 'oil_ekg_radius';
  static const String _oilEkgReplicationKey = 'oil_ekg_replication';
  static const String _oilEkgSpreadKey = 'oil_ekg_spread';
  static const String _oilBeatSensitivityKey = 'oil_beat_sensitivity';
  static const String _oilBeatImpactKey = 'oil_beat_impact';
  static const String _oilShowInfoBannerKey = 'oil_show_info_banner';
  static const String _oilLogoScaleKey = 'oil_logo_scale';
  static const String _oilBannerLetterSpacingKey = 'oil_banner_letter_spacing';
  static const String _oilBannerWordSpacingKey = 'oil_banner_word_spacing';
  static const String _oilTrackLetterSpacingKey = 'oil_track_letter_spacing';
  static const String _oilTrackWordSpacingKey = 'oil_track_word_spacing';
  static const String _oilFlatLineSpacingKey = 'oil_flat_line_spacing';
  static const String _oilLogoAntiAliasKey = 'oil_logo_anti_alias';

  // Ring controls (3-ring gap model)
  static const String _oilInnerRingScaleKey = 'oil_inner_ring_scale';
  static const String _oilInnerToMiddleGapKey = 'oil_inner_to_middle_gap';
  static const String _oilMiddleToOuterGapKey = 'oil_middle_to_outer_gap';
  static const String _oilOrbitDriftKey = 'oil_orbit_drift';
  static const String _oilInnerRingFontScaleKey = 'oil_inner_ring_font_scale';
  static const String _oilInnerRingSpacingMultiplierKey =
      'oil_inner_ring_spacing_multiplier';
  static const String _oilMiddleRingSpacingMultiplierKey =
      'oil_middle_ring_spacing_multiplier';
  static const String _oilOuterRingSpacingMultiplierKey =
      'oil_outer_ring_spacing_multiplier';
  static const String _oilMiddleRingFontScaleKey = 'oil_middle_ring_font_scale';
  static const String _oilOuterRingFontScaleKey = 'oil_outer_ring_font_scale';
  static const String _oilScreensaver4kSupportKey =
      'oil_screensaver_4k_support';
  static const String _oilScaleSourceKey = 'oil_scale_source';
  static const String _oilScaleMultiplierKey = 'oil_scale_multiplier';
  static const String _oilScaleSineEnabledKey = 'oil_scale_sine_enabled';
  static const String _oilScaleSineFreqKey = 'oil_scale_sine_freq';
  static const String _oilScaleSineAmpKey = 'oil_scale_sine_amp';
  static const String _oilColorSourceKey = 'oil_color_source';
  static const String _oilColorMultiplierKey = 'oil_color_multiplier';
  static const String _oilWoodstockEveryHourKey = 'oil_woodstock_every_hour';
  static const String _oilTvPremiumHighlightKey = 'oil_tv_premium_highlight';
  static const String _hideTvScrollbarsKey = 'hide_tv_scrollbars';

  static const String _marqueeEnabledKey = 'marquee_enabled';
  static const String _enableSwipeToBlockKey = 'enable_swipe_to_block';
  static const String _omitHttpPathInCopyKey = 'omit_http_path_in_copy';
  static const String _showSplashScreenKey = 'show_splash_screen';
  static const String _forceTvKey = 'force_tv';
  static const String _enableHapticsKey = 'enable_haptics';
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
      _onboardingCompletedVersionKey,
      _onboardingCompletedVersion,
    );
    notifyListeners();
  }

  void toggleShowSplashScreen() => _updatePreference(
    _showSplashScreenKey,
    _showSplashScreen = !_showSplashScreen,
  );

  bool showExpandIcon = false;

  // Private state
  late bool _showTrackNumbers;
  late bool _hideTrackDuration;
  bool _isFirstRun = false;
  late bool _playOnTap;
  late bool _showSingleShnid;
  late bool _playRandomOnCompletion;
  late bool _nonRandom;
  late bool _playRandomOnStartup;
  late bool _dateFirstInShowCard;
  late bool _useDynamicColor;
  late bool _useTrueBlack;
  late bool _uiScale;
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
  late bool _omitHttpPathInCopy;
  late bool _useNeumorphism;
  late bool _fruitEnableLiquidGlass;
  late NeumorphicStyle _neumorphicStyle;
  late bool _performanceMode;
  late bool _forceTv;
  late bool _enableHaptics;
  late bool _fruitStickyNowPlaying;
  late bool _enableRunDetection;
  late bool _hideTvScrollbars;

  // Web Gapless Engine
  late AudioEngineMode _audioEngineMode;
  late int _webPrefetchSeconds;
  late String _trackTransitionMode;
  late double _crossfadeDurationSeconds;
  late HybridHandoffMode _hybridHandoffMode;
  late HybridBackgroundMode _hybridBackgroundMode;
  late bool _allowHiddenWebAudio;
  late int _handoffCrossfadeMs;
  late bool _hybridForceHtml5Start;
  late HiddenSessionPreset _hiddenSessionPreset;
  late WebEngineProfile _webEngineProfile;

  // Screensaver (steal)
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

  // Trail effect
  late double _oilLogoTrailIntensity;
  late int _oilLogoTrailSlices;
  late bool _oilLogoTrailDynamic;
  late double _oilLogoTrailLength;
  late double _oilLogoTrailScale;
  late double _oilLogoTrailInitialScale;

  // Audio Reactivity Tuning
  late double _oilAudioPeakDecay;
  late double _oilAudioBassBoost;
  late double _oilAudioReactivityStrength;
  late String _oilAudioGraphMode;
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

  // Ring controls
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
  late bool _oilScreensaver4kSupport;
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

  // Track Layout State
  Color? _seedColor;

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
  bool get nonRandom => _nonRandom;
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
  bool get omitHttpPathInCopy => _omitHttpPathInCopy;
  bool get useNeumorphism => _useNeumorphism;
  bool get fruitEnableLiquidGlass =>
      isWasmSafeMode() ? false : _fruitEnableLiquidGlass;
  bool get fruitStickyNowPlaying => _fruitStickyNowPlaying;
  bool get enableHaptics => _enableHaptics;
  bool get enableRunDetection => _enableRunDetection;

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

  void toggleEnableRunDetection() {
    _enableRunDetection = !_enableRunDetection;
    _updatePreference(_enableRunDetectionKey, _enableRunDetection);
  }

  NeumorphicStyle get neumorphicStyle => _neumorphicStyle;
  bool get performanceMode => isWasmSafeMode() ? true : _performanceMode;
  bool get forceTv => _forceTv;
  bool get hideTvScrollbars => _hideTvScrollbars;

  /// Whether the custom gapless Web Audio engine is enabled (web-only).
  AudioEngineMode get audioEngineMode => _audioEngineMode;

  /// Sets the explicit audio engine mode.
  void setAudioEngineMode(AudioEngineMode mode) {
    _audioEngineMode = mode;
    _prefs.setString(_audioEngineModeKey, mode.name);
    notifyListeners();
  }

  /// Compatibility getter for legacy callers.
  bool get webGaplessEngine => _audioEngineMode != AudioEngineMode.standard;

  /// Seconds ahead of a track end to prefetch the next buffer (web-only).
  int get webPrefetchSeconds => _webPrefetchSeconds;

  String get trackTransitionMode => _trackTransitionMode;
  void setTrackTransitionMode(String mode) {
    final normalized = mode == 'gap' ? 'gap' : 'gapless';
    _trackTransitionMode = normalized;
    _prefs.setString(_trackTransitionModeKey, normalized);
    notifyListeners();
  }

  double get crossfadeDurationSeconds => _crossfadeDurationSeconds;
  void setCrossfadeDurationSeconds(double seconds) {
    _crossfadeDurationSeconds = seconds;
    _prefs.setDouble(_crossfadeDurationSecondsKey, seconds);
    notifyListeners();
  }

  HybridHandoffMode get hybridHandoffMode => _hybridHandoffMode;
  void setHybridHandoffMode(HybridHandoffMode mode) {
    _hybridHandoffMode = mode;
    _prefs.setString(_hybridHandoffModeKey, mode.name);
    notifyListeners();
  }

  HybridBackgroundMode get hybridBackgroundMode => _hybridBackgroundMode;

  bool get allowHiddenWebAudio => _allowHiddenWebAudio;
  void setAllowHiddenWebAudio(bool value) {
    _allowHiddenWebAudio = value;
    _prefs.setBool(_allowHiddenWebAudioKey, value);
    notifyListeners();
  }

  int get handoffCrossfadeMs => _handoffCrossfadeMs;
  void setHandoffCrossfadeMs(int ms) {
    _handoffCrossfadeMs = ms.clamp(0, 200);
    _prefs.setInt(_handoffCrossfadeMsKey, _handoffCrossfadeMs);
    notifyListeners();
  }

  bool get hybridForceHtml5Start => _hybridForceHtml5Start;
  void setHybridForceHtml5Start(bool value) {
    _hybridForceHtml5Start = value;
    _prefs.setBool(_hybridForceHtml5StartKey, value);
    notifyListeners();
  }

  HiddenSessionPreset get hiddenSessionPreset => _hiddenSessionPreset;
  WebEngineProfile get webEngineProfile => _webEngineProfile;
  void setHybridBackgroundMode(HybridBackgroundMode mode) {
    _hybridBackgroundMode = mode;
    _prefs.setString(_hybridBackgroundModeKey, mode.name);
    notifyListeners();
  }

  void setHiddenSessionPreset(HiddenSessionPreset preset) {
    _hiddenSessionPreset = preset;

    switch (preset) {
      case HiddenSessionPreset.stability:
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.video;
        _allowHiddenWebAudio = false;
        _hybridForceHtml5Start = true;
        break;
      case HiddenSessionPreset.balanced:
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.heartbeat;
        _allowHiddenWebAudio = false;
        _hybridForceHtml5Start = true;
        break;
      case HiddenSessionPreset.maxGapless:
        _audioEngineMode = AudioEngineMode.webAudio;
        _hybridHandoffMode = HybridHandoffMode.immediate;
        _hybridBackgroundMode = HybridBackgroundMode.heartbeat;
        _allowHiddenWebAudio = true;
        _hybridForceHtml5Start = false;
        break;
    }

    _prefs.setString(_hiddenSessionPresetKey, _hiddenSessionPreset.name);
    _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
    _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
    _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
    _prefs.setBool(_hybridForceHtml5StartKey, _hybridForceHtml5Start);

    notifyListeners();
  }

  void setWebEngineProfile(WebEngineProfile profile) {
    if (!kIsWeb) return;
    _webEngineProfile = profile;
    _applyWebEngineProfile(profile, persistPrefs: true);
    _prefs.setBool(_webEngineProfileInitKey, true);
    _prefs.setString(_webEngineProfileChoiceKey, profile.name);
    notifyListeners();
  }

  void _applyWebEngineProfile(
    WebEngineProfile profile, {
    required bool persistPrefs,
  }) {
    switch (profile) {
      case WebEngineProfile.modern:
        _hiddenSessionPreset = HiddenSessionPreset.balanced;
        _audioEngineMode = AudioEngineMode.hybrid;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.heartbeat;
        _allowHiddenWebAudio = false;
        _hybridForceHtml5Start = true;
        break;
      case WebEngineProfile.legacy:
        _hiddenSessionPreset = HiddenSessionPreset.stability;
        _audioEngineMode = AudioEngineMode.html5;
        _hybridHandoffMode = HybridHandoffMode.buffered;
        _hybridBackgroundMode = HybridBackgroundMode.video;
        _allowHiddenWebAudio = false;
        _hybridForceHtml5Start = true;
        break;
    }

    if (!persistPrefs) return;
    _prefs.setString(_hiddenSessionPresetKey, _hiddenSessionPreset.name);
    _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    _prefs.setString(_hybridHandoffModeKey, _hybridHandoffMode.name);
    _prefs.setString(_hybridBackgroundModeKey, _hybridBackgroundMode.name);
    _prefs.setBool(_allowHiddenWebAudioKey, _allowHiddenWebAudio);
    _prefs.setBool(_hybridForceHtml5StartKey, _hybridForceHtml5Start);
  }

  // Screensaver getters
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

  // Trail effect getters
  double get oilLogoTrailIntensity => _oilLogoTrailIntensity;
  int get oilLogoTrailSlices => _oilLogoTrailSlices;
  bool get oilLogoTrailDynamic => _oilLogoTrailDynamic;
  double get oilLogoTrailLength => _oilLogoTrailLength;
  double get oilLogoTrailScale => _oilLogoTrailScale;
  double get oilLogoTrailInitialScale => _oilLogoTrailInitialScale;

  // Audio Reactivity getters
  double get oilAudioPeakDecay => _oilAudioPeakDecay;
  double get oilAudioBassBoost => _oilAudioBassBoost;
  double get oilAudioReactivityStrength => _oilAudioReactivityStrength;
  String get oilAudioGraphMode => _oilAudioGraphMode;
  double get oilEkgRadius => _oilEkgRadius;
  int get oilEkgReplication => _oilEkgReplication;
  double get oilEkgSpread => _oilEkgSpread;
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

  // Ring control getters
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
  bool get oilScreensaver4kSupport => _oilScreensaver4kSupport;
  bool get oilTvPremiumHighlight => _oilTvPremiumHighlight;
  int get oilScaleSource => _oilScaleSource;
  double get oilScaleMultiplier => _oilScaleMultiplier;
  int get oilColorSource => _oilColorSource;
  double get oilColorMultiplier => _oilColorMultiplier;
  bool get oilWoodstockEveryHour => _oilWoodstockEveryHour;
  bool get oilScaleSineEnabled => _oilScaleSineEnabled;
  double get oilScaleSineFreq => _oilScaleSineFreq;
  double get oilScaleSineAmp => _oilScaleSineAmp;

  // Track Layout State

  Color? get seedColor => _seedColor;
  bool get randomOnlyUnplayed => _randomOnlyUnplayed;
  bool get randomOnlyHighRated => _randomOnlyHighRated;
  bool get randomExcludePlayed => _randomExcludePlayed;
  bool get showGlobalAlbumArt => true;

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
    _showDebugLayoutKey,
    _showDebugLayout = !_showDebugLayout,
  );

  static const String _enableShakedownTweenKey = 'enable_shakedown_tween';
  late bool _enableShakedownTween;
  bool get enableShakedownTween => _enableShakedownTween;
  void toggleEnableShakedownTween() => _updatePreference(
    _enableShakedownTweenKey,
    _enableShakedownTween = !_enableShakedownTween,
  );

  static const MethodChannel _uiScaleChannel = MethodChannel(
    'com.jamart3d.shakedown/ui_scale',
  );

  void resetFruitFirstTimeSettings() {
    // Disable dense list for Fruit
    _fruitDenseList = false;
    _prefs.setBool(_fruitDenseListKey, false);

    // Disable Simple Icon and Simple Theme
    _simpleRandomIcon = false;
    _prefs.setBool(_simpleRandomIconKey, false);
    _performanceMode = true;
    _prefs.setBool(_performanceModeKey, true);

    // Turn off Glow and RGB
    _oilBannerGlow = false;
    _prefs.setBool(_oilBannerGlowKey, false);
    setGlowMode(0);
    setHighlightPlayingWithRgb(false);

    notifyListeners();
  }

  SettingsProvider(this._prefs, {this.isTv = false}) {
    _init();
    _setupUiScaleChannel();
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
      if (call.method == 'setUiScale') {
        final bool enabled = call.arguments as bool;
        if (enabled != _uiScale) {
          _uiScale = enabled;
          await _prefs.setBool(_uiScaleKey, enabled);
          if (_uiScale) {
            _abbreviateDayOfWeek = true;
            _abbreviateMonth = true;
          } else {
            _abbreviateDayOfWeek = false;
            _abbreviateMonth = false;
          }
          await _prefs.setBool(_abbreviateDayOfWeekKey, _abbreviateDayOfWeek);
          await _prefs.setBool(_abbreviateMonthKey, _abbreviateMonth);
          notifyListeners();
          logger.i('SettingsProvider: UI Scale set to $enabled via ADB');
        }
      }
    });
  }

  void _init() {
    bool firstRunCheckDone = _prefs.getBool('first_run_check_done') ?? false;
    _uiScale =
        _prefs.getBool(_uiScaleKey) ?? DefaultSettings.uiScaleDesktopDefault;

    if (!firstRunCheckDone) {
      final views = WidgetsBinding.instance.platformDispatcher.views;
      if (views.isNotEmpty) {
        final view = views.first;
        final physicalWidth = view.physicalSize.width;
        if (isTv) {
          _uiScale = true;
          _prefs.setBool(_uiScaleKey, true);
        } else if (physicalWidth <= 720) {
          _uiScale = DefaultSettings.uiScaleMobileDefault;
          _prefs.setBool(_uiScaleKey, DefaultSettings.uiScaleMobileDefault);
        }
      }
      _isFirstRun = true;
      _prefs.setBool('first_run_check_done', true);
    }

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
    _enableHaptics = _prefs.getBool(_enableHapticsKey) ?? true;
    _fruitDenseList = _prefs.getBool(_fruitDenseListKey) ?? false;
    _fruitStickyNowPlaying = _prefs.getBool(_fruitStickyNowPlayingKey) ?? false;
    _enableRunDetection =
        _prefs.getBool(_enableRunDetectionKey) ??
        DefaultSettings.enableRunDetection;

    // Screensaver Migration
    final defaultScreensaver = _dBool(
      WebDefaults.useOilScreensaver,
      DefaultSettings.useOilScreensaver,
      DefaultSettings.useOilScreensaver,
    );
    if (_prefs.containsKey('use_screensaver')) {
      bool oldEnabled = _prefs.getBool('use_screensaver') ?? true;
      _useOilScreensaver = defaultScreensaver ? oldEnabled : false;
      if (oldEnabled) _prefs.setBool(_useOilScreensaverKey, _useOilScreensaver);
      _prefs.remove('use_screensaver');
    } else {
      _useOilScreensaver =
          _prefs.getBool(_useOilScreensaverKey) ?? defaultScreensaver;
    }

    // Font Migration
    if (_prefs.containsKey('use_handwriting_font')) {
      bool oldHandwriting = _prefs.getBool('use_handwriting_font') ?? false;
      _appFont = oldHandwriting ? 'caveat' : 'default';
      if (oldHandwriting) _prefs.setString(_appFontKey, 'caveat');
      _prefs.remove('use_handwriting_font');
      _appFont =
          _prefs.getString(_appFontKey) ??
          _dStr(
            WebDefaults.appFont,
            DefaultSettings.appFont,
            DefaultSettings.appFont,
          );
    }
    logger.i('SettingsProvider: Active App Font = $_appFont');

    // Glow Border Migration
    if (_prefs.containsKey(_glowModeKey)) {
      _glowMode = _prefs.getInt(_glowModeKey) ?? DefaultSettings.glowMode;
      if (_glowMode == 1) {
        _glowMode = 25;
        _prefs.setInt(_glowModeKey, _glowMode);
      } else if (_glowMode == 2) {
        _glowMode = 50;
        _prefs.setInt(_glowModeKey, _glowMode);
      } else if (_glowMode == 3) {
        _glowMode = 100;
        _prefs.setInt(_glowModeKey, _glowMode);
      }
    } else {
      bool oldShow = _prefs.getBool(_showGlowBorderKey) ?? false;
      bool oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
      _glowMode = oldHalf
          ? 50
          : oldShow
          ? 100
          : DefaultSettings.glowMode;
      _prefs.setInt(_glowModeKey, _glowMode);
    }

    bool oldHalf = _prefs.getBool(_halfGlowDynamicKey) ?? false;
    if (oldHalf && !_prefs.containsKey(_useTrueBlackKey)) {
      _useTrueBlack = true;
      _prefs.setBool(_useTrueBlackKey, true);
    } else {
      _useTrueBlack =
          _prefs.getBool(_useTrueBlackKey) ??
          _dBool(
            WebDefaults.useTrueBlack,
            DefaultSettings.useTrueBlack,
            DefaultSettings.useTrueBlack,
          );
    }

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

    // Prevent Sleep Migration
    if (_prefs.containsKey('prevent_screensaver') &&
        !_prefs.containsKey(_preventSleepKey)) {
      _preventSleep =
          _prefs.getBool('prevent_screensaver') ?? DefaultSettings.preventSleep;
      _prefs.setBool(_preventSleepKey, _preventSleep);
      _prefs.remove('prevent_screensaver');
    } else {
      _preventSleep =
          _prefs.getBool(_preventSleepKey) ??
          _dBool(
            DefaultSettings.preventSleep,
            TvDefaults.preventSleep,
            PhoneDefaults.preventSleep,
          );
    }

    _marqueeEnabled = _prefs.getBool(_marqueeEnabledKey) ?? true;
    _enableSwipeToBlock =
        _prefs.getBool(_enableSwipeToBlockKey) ??
        DefaultSettings.enableSwipeToBlock;
    _omitHttpPathInCopy =
        _prefs.getBool(_omitHttpPathInCopyKey) ??
        DefaultSettings.omitHttpPathInCopy;
    _showDebugLayout =
        _prefs.getBool(_showDebugLayoutKey) ?? DefaultSettings.showDebugLayout;
    _enableShakedownTween = _prefs.getBool(_enableShakedownTweenKey) ?? true;
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
    final hasPerformancePreference = _prefs.containsKey(_performanceModeKey);
    _performanceMode =
        _prefs.getBool(_performanceModeKey) ??
        _dBool(
          WebDefaults.performanceMode,
          TvDefaults.performanceMode,
          PhoneDefaults.performanceMode,
        );

    if (!hasPerformancePreference &&
        kIsWeb &&
        isLikelyLowPowerWebDevice() &&
        !_performanceMode) {
      _performanceMode = true;
      _prefs.setBool(_performanceModeKey, true);
      logger.i(
        'SettingsProvider: Auto-enabled performance mode for low-power web mobile device.',
      );
    }

    if (_performanceMode) {
      _glowMode = 0;
      _highlightPlayingWithRgb = false;
      _fruitEnableLiquidGlass = false;
    }
    _enableHaptics = _prefs.getBool(_enableHapticsKey) ?? true;

    // Web Gapless Engine Migration
    if (_prefs.containsKey('web_gapless_engine')) {
      bool oldEnabled = _prefs.getBool('web_gapless_engine') ?? true;
      _audioEngineMode = oldEnabled
          ? AudioEngineMode.auto
          : AudioEngineMode.standard;
      _prefs.remove('web_gapless_engine');
      _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    } else {
      _audioEngineMode = AudioEngineMode.fromString(
        _prefs.getString(_audioEngineModeKey) ??
            _dStr(
              WebDefaults.audioEngineMode,
              PhoneDefaults.audioEngineMode,
              PhoneDefaults.audioEngineMode,
            ),
      );
    }
    _webEngineProfile = WebEngineProfile.fromString(
      _prefs.getString(_webEngineProfileChoiceKey),
    );

    final hasAdaptiveProfileInit =
        _prefs.getBool(_webEngineProfileInitKey) ?? false;
    final bool hasExplicitEngineOverride =
        _prefs.containsKey(_audioEngineModeKey) &&
        _audioEngineMode != AudioEngineMode.auto;
    if (kIsWeb && !hasAdaptiveProfileInit && !hasExplicitEngineOverride) {
      _webEngineProfile = isLikelyLowPowerWebDevice()
          ? WebEngineProfile.legacy
          : WebEngineProfile.modern;
      _applyWebEngineProfile(_webEngineProfile, persistPrefs: true);
      _prefs.setBool(_webEngineProfileInitKey, true);
      _prefs.setString(_webEngineProfileChoiceKey, _webEngineProfile.name);
      logger.i(
        'SettingsProvider: Adaptive web engine profile applied: ${_webEngineProfile.name}',
      );
    }
    // Greedy prefetch (-1) if in Web Audio mode, otherwise use fixed 30s
    _webPrefetchSeconds = (_audioEngineMode == AudioEngineMode.webAudio)
        ? -1
        : DefaultSettings.webPrefetchSeconds;

    // Still ensure the preference is stored correctly if it wasn't
    if (_prefs.getInt(_webPrefetchSecondsKey) != _webPrefetchSeconds) {
      _prefs.setInt(_webPrefetchSecondsKey, _webPrefetchSeconds);
    }

    _forceTv = _prefs.getBool(_forceTvKey) ?? false;

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
      _prefs.getString(_hybridBackgroundModeKey) ?? 'html5',
    );
    _hiddenSessionPreset = HiddenSessionPreset.fromString(
      _prefs.getString(_hiddenSessionPresetKey) ?? 'balanced',
    );
    _allowHiddenWebAudio = _prefs.getBool(_allowHiddenWebAudioKey) ?? false;
    _handoffCrossfadeMs =
        _prefs.getInt(_handoffCrossfadeMsKey) ??
        DefaultSettings.handoffCrossfadeMs;
    _hybridForceHtml5Start =
        _prefs.getBool(_hybridForceHtml5StartKey) ??
        DefaultSettings.hybridForceHtml5Start;

    // Screensaver
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
    _oilPerformanceLevel =
        _prefs.getInt(_oilPerformanceLevelKey) ??
        (_prefs.getBool('oil_performance_mode') == true ? 2 : 0);
    // Ensure accurate platform defaults if no preference exists
    if (!_prefs.containsKey(_oilPerformanceLevelKey) &&
        !_prefs.containsKey('oil_performance_mode')) {
      _oilPerformanceLevel = _dInt(
        DefaultSettings.oilPerformanceLevel,
        TvDefaults.oilPerformanceLevel,
        DefaultSettings.oilPerformanceLevel,
      );
    }
    _oilPaletteCycle =
        _prefs.getBool(_oilPaletteCycleKey) ?? DefaultSettings.oilPaletteCycle;
    _oilPaletteTransitionSpeed =
        _prefs.getDouble(_oilPaletteTransitionSpeedKey) ??
        DefaultSettings.oilPaletteTransitionSpeed;
    _oilBannerDisplayMode =
        _prefs.getString(_oilBannerDisplayModeKey) ??
        DefaultSettings.oilBannerDisplayMode;
    _oilBannerFont =
        _prefs.getString(_oilBannerFontKey) ?? DefaultSettings.oilBannerFont;
    if (_oilBannerFont == 'rock_salt') {
      _oilBannerFont = 'RockSalt';
      _prefs.setString(_oilBannerFontKey, _oilBannerFont);
    }
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

    // Audio Reactivity
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
    _oilBeatSensitivity =
        _prefs.getDouble(_oilBeatSensitivityKey) ??
        DefaultSettings.oilBeatSensitivity;
    _oilBeatImpact =
        _prefs.getDouble(_oilBeatImpactKey) ?? DefaultSettings.oilBeatImpact;

    // Banner & visual
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

    // Ring controls
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
    _oilScreensaver4kSupport =
        _prefs.getBool(_oilScreensaver4kSupportKey) ?? false;
    _oilTvPremiumHighlight =
        _prefs.getBool(_oilTvPremiumHighlightKey) ??
        DefaultSettings.oilTvPremiumHighlight;
    _hideTvScrollbars = _prefs.getBool(_hideTvScrollbarsKey) ?? false;

    // Reactivity isolation
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
    _oilEkgRadius =
        _prefs.getDouble(_oilEkgRadiusKey) ?? DefaultSettings.oilEkgRadius;
    _oilEkgReplication =
        _prefs.getInt(_oilEkgReplicationKey) ??
        DefaultSettings.oilEkgReplication;
    _oilEkgSpread =
        _prefs.getDouble(_oilEkgSpreadKey) ?? DefaultSettings.oilEkgSpread;
    _oilScaleSineEnabled =
        _prefs.getBool(_oilScaleSineEnabledKey) ??
        DefaultSettings.oilScaleSineEnabled;
    _oilScaleSineFreq =
        _prefs.getDouble(_oilScaleSineFreqKey) ??
        DefaultSettings.oilScaleSineFreq;
    _oilScaleSineAmp =
        _prefs.getDouble(_oilScaleSineAmpKey) ??
        DefaultSettings.oilScaleSineAmp;

    // TV screensaver mode override â€” use TvDefaults as the canonical source.
    if (isTv) _oilScreensaverMode = TvDefaults.oilScreensaverMode;

    final seedColorValue = _prefs.getInt(_seedColorKey);
    _seedColor = seedColorValue != null ? Color(seedColorValue) : null;

    _initSourceFilters();
  }

  void _initSourceFilters() {
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

    final String? catsJson = _prefs.getString(_sourceCategoryFiltersKey);
    if (catsJson != null) {
      try {
        final Map<String, dynamic> decoded = json.decode(catsJson);
        decoded.forEach((key, value) {
          if (_sourceCategoryFilters.containsKey(key) && value is bool) {
            _sourceCategoryFilters[key] = value;
          }
        });
      } catch (e) {
        // use defaults
      }
    } else {
      _sourceCategoryFilters = Map.from(DefaultSettings.sourceCategoryFilters);
    }

    // Web-only override: all categories ON by default.
    // We use a one-time migration check to ensure existing web users also get
    // all categories enabled, while preserving their future custom choices.
    // Web-only override: Only 'matrix' ON by default for a curated first experience.
    // We use a one-time migration check to ensure new web users start with matrix,
    // while preserving their future custom choices.
    if (kIsWeb && !(_prefs.getBool(_webSourceFiltersInitKey) ?? false)) {
      _sourceCategoryFilters.forEach((key, _) {
        _sourceCategoryFilters[key] = (key == 'matrix');
      });
      _prefs.setBool(_webSourceFiltersInitKey, true);
      _saveSourceCategoryFilters();
    }
  }

  // Toggle methods
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

  void toggleHideTvScrollbars() => _updatePreference(
    _hideTvScrollbarsKey,
    _hideTvScrollbars = !_hideTvScrollbars,
  );

  void setGlowMode(int mode) {
    if (_performanceMode && mode > 0) return;
    _updateIntPreference(_glowModeKey, _glowMode = mode);
  }

  void toggleHighlightPlayingWithRgb() {
    if (_performanceMode) return;
    _updatePreference(
      _highlightPlayingWithRgbKey,
      _highlightPlayingWithRgb = !_highlightPlayingWithRgb,
    );
  }

  void setHighlightPlayingWithRgb(bool value) {
    if (_performanceMode && value) return;
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
  void toggleOmitHttpPathInCopy() => _updatePreference(
    _omitHttpPathInCopyKey,
    _omitHttpPathInCopy = !_omitHttpPathInCopy,
  );
  //
  void setUseNeumorphism(bool value) =>
      _updatePreference(_useNeumorphismKey, _useNeumorphism = value);
  void togglePerformanceMode() {
    _performanceMode = !_performanceMode;
    _updatePreference(_performanceModeKey, _performanceMode);

    if (_performanceMode) {
      // Disable expensive visuals when Performance Mode is ON
      setFruitEnableLiquidGlass(false);
      setGlowMode(0);
      setHighlightPlayingWithRgb(false);
    }
  }

  void toggleForceTv() => _updatePreference(_forceTvKey, _forceTv = !_forceTv);

  void setForceTv(bool value) =>
      _updatePreference(_forceTvKey, _forceTv = value);

  void toggleEnableHaptics() =>
      _updatePreference(_enableHapticsKey, _enableHaptics = !_enableHaptics);

  void toggleFruitDenseList() =>
      _updatePreference(_fruitDenseListKey, _fruitDenseList = !_fruitDenseList);

  void toggleOilTvPremiumHighlight() => _updatePreference(
    _oilTvPremiumHighlightKey,
    _oilTvPremiumHighlight = !_oilTvPremiumHighlight,
  );

  void setNeumorphicStyle(NeumorphicStyle value, {bool? notify}) {
    if (_neumorphicStyle != value) {
      _neumorphicStyle = value;
      _updateIntPreference(_neumorphicStyleKey, value.index);
      if (notify ?? true) notifyListeners();
    }
  }

  /// Toggles the custom gapless Web Audio engine on or off (web-only).
  void toggleWebGaplessEngine() {
    setAudioEngineMode(
      webGaplessEngine ? AudioEngineMode.standard : AudioEngineMode.auto,
    );
  }

  /// Prefetch-ahead duration is now fixed at 30s (hidden from UI).
  Future<void> setWebPrefetchSeconds(int seconds) async {
    // This method is now a no-op as we use a fixed value.
  }

  static const String _rgbAnimationSpeedKey = 'rgb_animation_speed';
  double _rgbAnimationSpeed = 1.0;
  double get rgbAnimationSpeed => _rgbAnimationSpeed;
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

  void toggleRandomOnlyUnplayed() => _updatePreference(
    _randomOnlyUnplayedKey,
    _randomOnlyUnplayed = !_randomOnlyUnplayed,
  );
  void toggleRandomOnlyHighRated() => _updatePreference(
    _randomOnlyHighRatedKey,
    _randomOnlyHighRated = !_randomOnlyHighRated,
  );
  void toggleRandomExcludePlayed() => _updatePreference(
    _randomExcludePlayedKey,
    _randomExcludePlayed = !_randomExcludePlayed,
  );

  // Screensaver setters
  void toggleUseOilScreensaver() => _updatePreference(
    _useOilScreensaverKey,
    _useOilScreensaver = !_useOilScreensaver,
  );
  void setOilScreensaverMode(String mode) => _updateStringPreference(
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

    // Explicitly nudge pulse intensity to 1.0 if it's currently 0.0,
    // otherwise enabling reactivity does nothing visually in the shader.
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

  // Audio Reactivity setters
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
  void setOilAudioGraphMode(String mode) =>
      _updateStringPreference(_oilAudioGraphModeKey, _oilAudioGraphMode = mode);
  Future<void> setOilBeatSensitivity(double value) => _updateDoublePreference(
    _oilBeatSensitivityKey,
    _oilBeatSensitivity = value.clamp(0.0, 1.0),
  );
  Future<void> setOilBeatImpact(double value) => _updateDoublePreference(
    _oilBeatImpactKey,
    _oilBeatImpact = value.clamp(0.0, 1.0),
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



  // Ring control setters
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

  // Source Filtering
  static const String _filterHighestShnidKey = 'filter_highest_shnid';
  static const String _sourceCategoryFiltersKey = 'source_category_filters';
  bool _filterHighestShnid = false;
  Map<String, bool> _sourceCategoryFilters = {
    'matrix': true,
    'ultra': false,
    'betty': false,
    'sbd': false,
    'fm': false,
    'dsbd': false,
    'unk': false,
  };
  bool get filterHighestShnid => _filterHighestShnid;
  Map<String, bool> get sourceCategoryFilters => _sourceCategoryFilters;
  void toggleFilterHighestShnid() => _updatePreference(
    _filterHighestShnidKey,
    _filterHighestShnid = !_filterHighestShnid,
  );

  Future<void> setSourceCategoryFilter(String category, bool isActive) async {
    _sourceCategoryFilters[category] = isActive;
    if (!_sourceCategoryFilters.containsValue(true)) {
      _sourceCategoryFilters[category] = true;
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
    await _prefs.setString(
      _sourceCategoryFiltersKey,
      json.encode(_sourceCategoryFilters),
    );
  }

  Future<void> enableAllSourceCategories() async {
    for (var key in _sourceCategoryFilters.keys) {
      _sourceCategoryFilters[key] = true;
    }
    notifyListeners();
    await _saveSourceCategoryFilters();
  }

  // Persistence helpers
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

  Future<void> setOilTrackLetterSpacing(double val) => _updateDoublePreference(
    _oilTrackLetterSpacingKey,
    _oilTrackLetterSpacing = val,
  );
  Future<void> setOilTrackWordSpacing(double val) => _updateDoublePreference(
    _oilTrackWordSpacingKey,
    _oilTrackWordSpacing = val,
  );

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _init();
    notifyListeners();
  }
}

