import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/config/default_settings.dart';
import 'package:shakedown/utils/logger.dart';

import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';

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
  static const String _webSourceFiltersInitKey = 'web_source_filters_init_v1';
  static const String _simpleRandomIconKey = 'simple_random_icon';
  static const String _fruitDenseListKey = 'fruit_dense_list';

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
  static const String _oilAudioReactivityStrengthKey =
      'oil_audio_reactivity_strength';
  static const String _oilAudioGraphModeKey = 'oil_audio_graph_mode';
  static const String _oilBeatSensitivityKey = 'oil_beat_sensitivity';
  static const String _oilShowInfoBannerKey = 'oil_show_info_banner';
  static const String _oilLogoScaleKey = 'oil_logo_scale';
  static const String _oilTranslationSmoothingKey = 'oil_translation_smoothing';
  static const String _oilBlurAmountKey = 'oil_blur_amount';
  static const String _oilFlatColorKey = 'oil_flat_color';
  static const String _oilBannerGlowKey = 'oil_banner_glow';
  static const String _oilBannerFlickerKey = 'oil_banner_flicker';
  static const String _oilBannerGlowBlurKey = 'oil_banner_glow_blur';
  static const String _oilBannerResolutionKey = 'oil_banner_resolution';
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
  static const String _oilScreensaver4kSupportKey =
      'oil_screensaver_4k_support';
  static const String _oilTvPremiumHighlightKey = 'oil_tv_premium_highlight';

  static const String _marqueeEnabledKey = 'marquee_enabled';
  static const String _enableSwipeToBlockKey = 'enable_swipe_to_block';
  static const String _omitHttpPathInCopyKey = 'omit_http_path_in_copy';
  static const String _showSplashScreenKey = 'show_splash_screen';
  static const String _forceTvKey = 'force_tv';
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

  // Web Gapless Engine
  late AudioEngineMode _audioEngineMode;
  late int _webPrefetchSeconds;
  late String _trackTransitionMode;
  late double _crossfadeDurationSeconds;
  late HybridHandoffMode _hybridHandoffMode;
  late HybridBackgroundMode _hybridBackgroundMode;

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
  late double _oilBannerLetterSpacing;
  late double _oilBannerWordSpacing;
  late double _oilTrackLetterSpacing;
  late double _oilTrackWordSpacing;
  late double _oilFlatLineSpacing;

  // Trail effect
  late double _oilLogoTrailIntensity;
  late int _oilLogoTrailSlices;
  late double _oilLogoTrailLength;
  late double _oilLogoTrailScale;
  late double _oilLogoTrailInitialScale;

  // Audio Reactivity Tuning
  late double _oilAudioPeakDecay;
  late double _oilAudioBassBoost;
  late double _oilAudioReactivityStrength;
  late String _oilAudioGraphMode;
  late double _oilBeatSensitivity;
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
  late double _oilInnerRingSpacingMultiplier;
  late bool _oilScreensaver4kSupport;
  late bool _oilTvPremiumHighlight;

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
  bool get fruitEnableLiquidGlass => _fruitEnableLiquidGlass;

  void toggleUseNeumorphism() {
    _useNeumorphism = !_useNeumorphism;
    _updatePreference(_useNeumorphismKey, _useNeumorphism);
  }

  void toggleFruitEnableLiquidGlass() {
    _fruitEnableLiquidGlass = !_fruitEnableLiquidGlass;
    _updatePreference(_fruitEnableLiquidGlassKey, _fruitEnableLiquidGlass);
  }

  NeumorphicStyle get neumorphicStyle => _neumorphicStyle;
  bool get performanceMode => _performanceMode;
  bool get forceTv => _forceTv;

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
    _trackTransitionMode = mode;
    _prefs.setString(_trackTransitionModeKey, mode);
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
    // Notify player if on web
    if (kIsWeb) {
      GaplessPlayer().setHybridHandoffMode(mode.name);
    }
    notifyListeners();
  }

  HybridBackgroundMode get hybridBackgroundMode => _hybridBackgroundMode;
  void setHybridBackgroundMode(HybridBackgroundMode mode) {
    _hybridBackgroundMode = mode;
    _prefs.setString(_hybridBackgroundModeKey, mode.name);
    // Notify player if on web
    if (kIsWeb) {
      GaplessPlayer().setHybridBackgroundMode(mode.name);
    }
    notifyListeners();
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
  double get oilBannerLetterSpacing => _oilBannerLetterSpacing;
  double get oilBannerWordSpacing => _oilBannerWordSpacing;
  double get oilTrackLetterSpacing => _oilTrackLetterSpacing;
  double get oilTrackWordSpacing => _oilTrackWordSpacing;
  double get oilFlatLineSpacing => _oilFlatLineSpacing;

  // Trail effect getters
  double get oilLogoTrailIntensity => _oilLogoTrailIntensity;
  int get oilLogoTrailSlices => _oilLogoTrailSlices;
  double get oilLogoTrailLength => _oilLogoTrailLength;
  double get oilLogoTrailScale => _oilLogoTrailScale;
  double get oilLogoTrailInitialScale => _oilLogoTrailInitialScale;

  // Audio Reactivity getters
  double get oilAudioPeakDecay => _oilAudioPeakDecay;
  double get oilAudioBassBoost => _oilAudioBassBoost;
  double get oilAudioReactivityStrength => _oilAudioReactivityStrength;
  String get oilAudioGraphMode => _oilAudioGraphMode;
  double get oilBeatSensitivity => _oilBeatSensitivity;
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
  double get oilInnerRingSpacingMultiplier => _oilInnerRingSpacingMultiplier;
  bool get oilScreensaver4kSupport => _oilScreensaver4kSupport;
  bool get oilTvPremiumHighlight => _oilTvPremiumHighlight;

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
      _showDebugLayoutKey, _showDebugLayout = !_showDebugLayout);

  static const String _enableShakedownTweenKey = 'enable_shakedown_tween';
  late bool _enableShakedownTween;
  bool get enableShakedownTween => _enableShakedownTween;
  void toggleEnableShakedownTween() => _updatePreference(
      _enableShakedownTweenKey, _enableShakedownTween = !_enableShakedownTween);

  static const MethodChannel _uiScaleChannel =
      MethodChannel('com.jamart3d.shakedown/ui_scale');

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
    _nonRandom = _prefs.getBool(_nonRandomKey) ?? DefaultSettings.nonRandom;
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
    _simpleRandomIcon = _prefs.getBool(_simpleRandomIconKey) ?? false;
    _fruitDenseList = _prefs.getBool(_fruitDenseListKey) ?? false;

    // Screensaver Migration
    final defaultScreensaver = _dBool(WebDefaults.useOilScreensaver,
        DefaultSettings.useOilScreensaver, DefaultSettings.useOilScreensaver);
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
    } else {
      _appFont = _prefs.getString(_appFontKey) ?? DefaultSettings.appFont;
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
      _useTrueBlack = _prefs.getBool(_useTrueBlackKey) ??
          _dBool(WebDefaults.useTrueBlack, DefaultSettings.useTrueBlack,
              DefaultSettings.useTrueBlack);
    }

    _highlightPlayingWithRgb = _prefs.getBool(_highlightPlayingWithRgbKey) ??
        DefaultSettings.highlightPlayingWithRgb;
    _rgbAnimationSpeed = _prefs.getDouble(_rgbAnimationSpeedKey) ??
        DefaultSettings.rgbAnimationSpeed;
    _showSplashScreen = _prefs.getBool(_showSplashScreenKey) ??
        _dBool(kIsWeb ? _isFirstRun : WebDefaults.showSplashScreen,
            DefaultSettings.showSplashScreen, DefaultSettings.showSplashScreen);
    _showPlaybackMessages = _prefs.getBool(_showPlaybackMessagesKey) ??
        DefaultSettings.showPlaybackMessages;
    _sortOldestFirst =
        _prefs.getBool(_sortOldestFirstKey) ?? DefaultSettings.sortOldestFirst;
    _useStrictSrcCategorization =
        _prefs.getBool(_useStrictSrcCategorizationKey) ??
            DefaultSettings.useStrictSrcCategorization;
    _offlineBuffering = _prefs.getBool(_offlineBufferingKey) ??
        DefaultSettings.offlineBuffering;
    _enableBufferAgent = _prefs.getBool(_enableBufferAgentKey) ??
        DefaultSettings.enableBufferAgent;

    // Prevent Sleep Migration
    if (_prefs.containsKey('prevent_screensaver') &&
        !_prefs.containsKey(_preventSleepKey)) {
      _preventSleep =
          _prefs.getBool('prevent_screensaver') ?? DefaultSettings.preventSleep;
      _prefs.setBool(_preventSleepKey, _preventSleep);
      _prefs.remove('prevent_screensaver');
    } else {
      _preventSleep = _prefs.getBool(_preventSleepKey) ??
          _dBool(DefaultSettings.preventSleep, TvDefaults.preventSleep,
              PhoneDefaults.preventSleep);
    }

    _marqueeEnabled = _prefs.getBool(_marqueeEnabledKey) ?? true;
    _enableSwipeToBlock = _prefs.getBool(_enableSwipeToBlockKey) ??
        DefaultSettings.enableSwipeToBlock;
    _omitHttpPathInCopy = _prefs.getBool(_omitHttpPathInCopyKey) ??
        DefaultSettings.omitHttpPathInCopy;
    _showDebugLayout = _prefs.getBool(_showDebugLayoutKey) ?? false;
    _enableShakedownTween = _prefs.getBool(_enableShakedownTweenKey) ?? true;
    _useNeumorphism = _prefs.getBool(_useNeumorphismKey) ??
        _dBool(WebDefaults.useNeumorphism, DefaultSettings.useNeumorphism,
            PhoneDefaults.useNeumorphism);
    _fruitEnableLiquidGlass =
        _prefs.getBool(_fruitEnableLiquidGlassKey) ?? false;
    _neumorphicStyle = NeumorphicStyle.values[
        _prefs.getInt(_neumorphicStyleKey) ??
            DefaultSettings.neumorphicStyle.index];
    _performanceMode =
        _prefs.getBool(_performanceModeKey) ?? DefaultSettings.performanceMode;

    // Web Gapless Engine Migration
    if (_prefs.containsKey('web_gapless_engine')) {
      bool oldEnabled = _prefs.getBool('web_gapless_engine') ?? true;
      _audioEngineMode =
          oldEnabled ? AudioEngineMode.auto : AudioEngineMode.standard;
      _prefs.remove('web_gapless_engine');
      _prefs.setString(_audioEngineModeKey, _audioEngineMode.name);
    } else {
      _audioEngineMode = AudioEngineMode.fromString(
          _prefs.getString(_audioEngineModeKey) ??
              _dStr(WebDefaults.audioEngineMode, PhoneDefaults.audioEngineMode,
                  PhoneDefaults.audioEngineMode));
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

    _trackTransitionMode = _prefs.getString(_trackTransitionModeKey) ??
        DefaultSettings.trackTransitionMode;
    _crossfadeDurationSeconds =
        _prefs.getDouble(_crossfadeDurationSecondsKey) ??
            DefaultSettings.crossfadeDurationSeconds;
    _hybridHandoffMode = HybridHandoffMode.fromString(
        _prefs.getString(_hybridHandoffModeKey) ?? 'buffered');
    _hybridBackgroundMode = HybridBackgroundMode.fromString(
        _prefs.getString(_hybridBackgroundModeKey) ?? 'relisten');

    // Screensaver
    _useOilScreensaver = _prefs.getBool(_useOilScreensaverKey) ??
        DefaultSettings.useOilScreensaver;
    _oilScreensaverMode = _prefs.getString(_oilScreensaverModeKey) ??
        DefaultSettings.oilScreensaverMode;
    _oilScreensaverInactivityMinutes =
        _prefs.getInt(_oilScreensaverInactivityMinutesKey) ??
            DefaultSettings.oilScreensaverInactivityMinutes;
    _oilFlowSpeed =
        _prefs.getDouble(_oilFlowSpeedKey) ?? DefaultSettings.oilFlowSpeed;
    _oilPulseIntensity = _prefs.getDouble(_oilPulseIntensityKey) ??
        DefaultSettings.oilPulseIntensity;
    _oilPalette =
        _prefs.getString(_oilPaletteKey) ?? DefaultSettings.oilPalette;
    _oilFilmGrain =
        _prefs.getDouble(_oilFilmGrainKey) ?? DefaultSettings.oilFilmGrain;
    _oilHeatDrift =
        _prefs.getDouble(_oilHeatDriftKey) ?? DefaultSettings.oilHeatDrift;
    _oilEnableAudioReactivity = _prefs.getBool(_oilEnableAudioReactivityKey) ??
        DefaultSettings.oilEnableAudioReactivity;
    _oilPerformanceLevel = _prefs.getInt(_oilPerformanceLevelKey) ??
        (_prefs.getBool('oil_performance_mode') == true ? 2 : 0);
    // Ensure accurate platform defaults if no preference exists
    if (!_prefs.containsKey(_oilPerformanceLevelKey) &&
        !_prefs.containsKey('oil_performance_mode')) {
      _oilPerformanceLevel = _dInt(DefaultSettings.oilPerformanceLevel,
          TvDefaults.oilPerformanceLevel, DefaultSettings.oilPerformanceLevel);
    }
    _oilPaletteCycle =
        _prefs.getBool(_oilPaletteCycleKey) ?? DefaultSettings.oilPaletteCycle;
    _oilPaletteTransitionSpeed =
        _prefs.getDouble(_oilPaletteTransitionSpeedKey) ??
            DefaultSettings.oilPaletteTransitionSpeed;
    _oilBannerDisplayMode = _prefs.getString(_oilBannerDisplayModeKey) ??
        DefaultSettings.oilBannerDisplayMode;
    _oilBannerFont =
        _prefs.getString(_oilBannerFontKey) ?? DefaultSettings.oilBannerFont;
    _oilFlatTextProximity = _prefs.getDouble(_oilFlatTextProximityKey) ??
        DefaultSettings.oilFlatTextProximity;
    _oilFlatTextPlacement = _prefs.getString(_oilFlatTextPlacementKey) ??
        DefaultSettings.oilFlatTextPlacement;
    _oilBannerResolution = _prefs.getDouble(_oilBannerResolutionKey) ??
        DefaultSettings.oilBannerResolution;
    _oilBannerLetterSpacing = _prefs.getDouble(_oilBannerLetterSpacingKey) ??
        DefaultSettings.oilBannerLetterSpacing;
    _oilBannerWordSpacing = _prefs.getDouble(_oilBannerWordSpacingKey) ??
        DefaultSettings.oilBannerWordSpacing;
    _oilTrackLetterSpacing = _prefs.getDouble(_oilTrackLetterSpacingKey) ??
        DefaultSettings.oilTrackLetterSpacing;
    _oilTrackWordSpacing = _prefs.getDouble(_oilTrackWordSpacingKey) ??
        DefaultSettings.oilTrackWordSpacing;
    _oilFlatLineSpacing = _prefs.getDouble(_oilFlatLineSpacingKey) ??
        DefaultSettings.oilFlatLineSpacing;

    _oilLogoTrailIntensity = _prefs.getDouble(_oilLogoTrailIntensityKey) ??
        DefaultSettings.oilLogoTrailIntensity;
    _oilLogoTrailSlices = _prefs.getInt(_oilLogoTrailSlicesKey) ??
        DefaultSettings.oilLogoTrailSlices;
    _oilLogoTrailLength = _prefs.getDouble(_oilLogoTrailLengthKey) ??
        DefaultSettings.oilLogoTrailLength;
    _oilLogoTrailScale = _prefs.getDouble(_oilLogoTrailScaleKey) ??
        DefaultSettings.oilLogoTrailScale;
    _oilLogoTrailInitialScale =
        _prefs.getDouble(_oilLogoTrailInitialScaleKey) ??
            DefaultSettings.oilLogoTrailInitialScale;

    // Audio Reactivity
    _oilAudioPeakDecay = _prefs.getDouble(_oilAudioPeakDecayKey) ??
        DefaultSettings.oilAudioPeakDecay;
    _oilAudioBassBoost = _prefs.getDouble(_oilAudioBassBoostKey) ??
        DefaultSettings.oilAudioBassBoost;
    _oilAudioReactivityStrength =
        _prefs.getDouble(_oilAudioReactivityStrengthKey) ??
            DefaultSettings.oilAudioReactivityStrength;
    _oilAudioGraphMode = _prefs.getString(_oilAudioGraphModeKey) ??
        DefaultSettings.oilAudioGraphMode;
    _oilBeatSensitivity = _prefs.getDouble(_oilBeatSensitivityKey) ??
        DefaultSettings.oilBeatSensitivity;

    // Banner & visual
    _oilShowInfoBanner = _prefs.getBool(_oilShowInfoBannerKey) ??
        DefaultSettings.oilShowInfoBanner;
    _oilLogoScale =
        _prefs.getDouble(_oilLogoScaleKey) ?? DefaultSettings.oilLogoScale;
    _oilTranslationSmoothing = _prefs.getDouble(_oilTranslationSmoothingKey) ??
        DefaultSettings.oilTranslationSmoothing;
    _oilBlurAmount =
        _prefs.getDouble(_oilBlurAmountKey) ?? DefaultSettings.oilBlurAmount;
    _oilFlatColor =
        _prefs.getBool(_oilFlatColorKey) ?? DefaultSettings.oilFlatColor;
    _oilBannerGlow =
        _prefs.getBool(_oilBannerGlowKey) ?? DefaultSettings.oilBannerGlow;
    _oilBannerFlicker = _prefs.getDouble(_oilBannerFlickerKey) ??
        DefaultSettings.oilBannerFlicker;
    _oilBannerGlowBlur = _prefs.getDouble(_oilBannerGlowBlurKey) ??
        DefaultSettings.oilBannerGlowBlur;
    _oilLogoAntiAlias = _prefs.getBool(_oilLogoAntiAliasKey) ??
        DefaultSettings.oilLogoAntiAlias;

    // Ring controls
    _oilInnerRingScale = _prefs.getDouble(_oilInnerRingScaleKey) ??
        DefaultSettings.oilInnerRingScale;
    _oilInnerToMiddleGap = _prefs.getDouble(_oilInnerToMiddleGapKey) ??
        DefaultSettings.oilInnerToMiddleGap;
    _oilMiddleToOuterGap = _prefs.getDouble(_oilMiddleToOuterGapKey) ??
        DefaultSettings.oilMiddleToOuterGap;
    _oilOrbitDrift =
        _prefs.getDouble(_oilOrbitDriftKey) ?? DefaultSettings.oilOrbitDrift;
    _oilInnerRingFontScale = _prefs.getDouble(_oilInnerRingFontScaleKey) ??
        DefaultSettings.oilInnerRingFontScale;
    _oilInnerRingSpacingMultiplier =
        _prefs.getDouble(_oilInnerRingSpacingMultiplierKey) ??
            DefaultSettings.oilInnerRingSpacingMultiplier;

    _oilScreensaver4kSupport =
        _prefs.getBool(_oilScreensaver4kSupportKey) ?? false;
    _oilTvPremiumHighlight = _prefs.getBool(_oilTvPremiumHighlightKey) ??
        DefaultSettings.oilTvPremiumHighlight;

    // TV screensaver mode override — use TvDefaults as the canonical source.
    if (isTv) _oilScreensaverMode = TvDefaults.oilScreensaverMode;

    final seedColorValue = _prefs.getInt(_seedColorKey);
    _seedColor = seedColorValue != null ? Color(seedColorValue) : null;

    _initSourceFilters();
  }

  void _initSourceFilters() {
    _randomOnlyUnplayed = _prefs.getBool(_randomOnlyUnplayedKey) ??
        DefaultSettings.randomOnlyUnplayed;
    _randomOnlyHighRated = _prefs.getBool(_randomOnlyHighRatedKey) ??
        DefaultSettings.randomOnlyHighRated;
    _randomExcludePlayed = _prefs.getBool(_randomExcludePlayedKey) ??
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
  void toggleNonRandom() =>
      _updatePreference(_nonRandomKey, _nonRandom = !_nonRandom);
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
  void toggleSimpleRandomIcon() => _updatePreference(
      _simpleRandomIconKey, _simpleRandomIcon = !_simpleRandomIcon);
  void toggleUiScale() {
    _uiScale = !_uiScale;
    _prefs.setBool(_uiScaleKey, _uiScale);
    _abbreviateDayOfWeek = _uiScale;
    _abbreviateMonth = _uiScale;
    _prefs.setBool(_abbreviateDayOfWeekKey, _abbreviateDayOfWeek);
    _prefs.setBool(_abbreviateMonthKey, _abbreviateMonth);
    notifyListeners();
  }

  void setGlowMode(int mode) =>
      _updateIntPreference(_glowModeKey, _glowMode = mode);
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
  void toggleEnableBufferAgent() => _updatePreference(
      _enableBufferAgentKey, _enableBufferAgent = !_enableBufferAgent);
  void togglePreventSleep() =>
      _updatePreference(_preventSleepKey, _preventSleep = !_preventSleep);
  void toggleEnableSwipeToBlock() => _updatePreference(
      _enableSwipeToBlockKey, _enableSwipeToBlock = !_enableSwipeToBlock);
  void toggleOmitHttpPathInCopy() => _updatePreference(
      _omitHttpPathInCopyKey, _omitHttpPathInCopy = !_omitHttpPathInCopy);
//
  void setUseNeumorphism(bool value) =>
      _updatePreference(_useNeumorphismKey, _useNeumorphism = value);
  void togglePerformanceMode() => _updatePreference(
      _performanceModeKey, _performanceMode = !_performanceMode);

  void toggleForceTv() => _updatePreference(_forceTvKey, _forceTv = !_forceTv);

  void setForceTv(bool value) =>
      _updatePreference(_forceTvKey, _forceTv = value);

  void toggleFruitDenseList() =>
      _updatePreference(_fruitDenseListKey, _fruitDenseList = !_fruitDenseList);

  void toggleOilTvPremiumHighlight() => _updatePreference(
      _oilTvPremiumHighlightKey,
      _oilTvPremiumHighlight = !_oilTvPremiumHighlight);

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
        webGaplessEngine ? AudioEngineMode.standard : AudioEngineMode.auto);
  }

  /// Prefetch-ahead duration is now fixed at 30s (hidden from UI).
  Future<void> setWebPrefetchSeconds(int seconds) async {
    // This method is now a no-op as we use a fixed value.
  }

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
      await _prefs.setInt(_seedColorKey, color.toARGB32());
    }
    notifyListeners();
  }

  void toggleRandomOnlyUnplayed() => _updatePreference(
      _randomOnlyUnplayedKey, _randomOnlyUnplayed = !_randomOnlyUnplayed);
  void toggleRandomOnlyHighRated() => _updatePreference(
      _randomOnlyHighRatedKey, _randomOnlyHighRated = !_randomOnlyHighRated);
  void toggleRandomExcludePlayed() => _updatePreference(
      _randomExcludePlayedKey, _randomExcludePlayed = !_randomExcludePlayed);

  // Screensaver setters
  void toggleUseOilScreensaver() => _updatePreference(
      _useOilScreensaverKey, _useOilScreensaver = !_useOilScreensaver);
  void setOilScreensaverMode(String mode) => _updateStringPreference(
      _oilScreensaverModeKey, _oilScreensaverMode = mode);
  void setOilScreensaverInactivityMinutes(int minutes) {
    final enforced = [1, 5, 15].contains(minutes) ? minutes : 5;
    _updateIntPreference(_oilScreensaverInactivityMinutesKey,
        _oilScreensaverInactivityMinutes = enforced);
  }

  Future<void> setOilFlowSpeed(double value) =>
      _updateDoublePreference(_oilFlowSpeedKey, _oilFlowSpeed = value);
  Future<void> setOilPulseIntensity(double value) => _updateDoublePreference(
      _oilPulseIntensityKey, _oilPulseIntensity = value);
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
        _oilEnableAudioReactivityKey, _oilEnableAudioReactivity);
  }

  Future<void> setOilPerformanceLevel(int level) => _updateIntPreference(
      _oilPerformanceLevelKey, _oilPerformanceLevel = level);
  Future<void> toggleOilLogoAntiAlias() => _updatePreference(
      _oilLogoAntiAliasKey, _oilLogoAntiAlias = !_oilLogoAntiAlias);
  Future<void> toggleOilPaletteCycle() => _updatePreference(
      _oilPaletteCycleKey, _oilPaletteCycle = !_oilPaletteCycle);
  void setOilPaletteTransitionSpeed(double seconds) => _updateDoublePreference(
      _oilPaletteTransitionSpeedKey, _oilPaletteTransitionSpeed = seconds);
  Future<void> setOilBannerDisplayMode(String mode) => _updateStringPreference(
      _oilBannerDisplayModeKey, _oilBannerDisplayMode = mode);
  Future<void> setOilBannerFont(String font) =>
      _updateStringPreference(_oilBannerFontKey, _oilBannerFont = font);
  Future<void> setOilFlatTextProximity(double value) => _updateDoublePreference(
      _oilFlatTextProximityKey, _oilFlatTextProximity = value.clamp(0.0, 1.0));
  Future<void> setOilFlatTextPlacement(String placement) =>
      _updateStringPreference(
          _oilFlatTextPlacementKey, _oilFlatTextPlacement = placement);

  Future<void> setOilBannerLetterSpacing(double value) =>
      _updateDoublePreference(_oilBannerLetterSpacingKey,
          _oilBannerLetterSpacing = value.clamp(0.5, 2.0));

  Future<void> setOilBannerWordSpacing(double value) => _updateDoublePreference(
      _oilBannerWordSpacingKey, _oilBannerWordSpacing = value.clamp(0.0, 5.0));

  Future<void> setOilFlatLineSpacing(double value) => _updateDoublePreference(
      _oilFlatLineSpacingKey, _oilFlatLineSpacing = value.clamp(0.1, 5.0));

  Future<void> setOilLogoTrailIntensity(double value) =>
      _updateDoublePreference(_oilLogoTrailIntensityKey,
          _oilLogoTrailIntensity = value.clamp(0.0, 1.0));
  Future<void> setOilLogoTrailSlices(int value) => _updateIntPreference(
      _oilLogoTrailSlicesKey, _oilLogoTrailSlices = value.clamp(2, 16));
  Future<void> setOilLogoTrailLength(double value) => _updateDoublePreference(
      _oilLogoTrailLengthKey, _oilLogoTrailLength = value.clamp(0.0, 1.0));
  Future<void> setOilLogoTrailScale(double value) => _updateDoublePreference(
      _oilLogoTrailScaleKey, _oilLogoTrailScale = value.clamp(0.0, 1.0));
  Future<void> setOilLogoTrailInitialScale(double value) =>
      _updateDoublePreference(_oilLogoTrailInitialScaleKey,
          _oilLogoTrailInitialScale = value.clamp(0.5, 2.0));

  // Audio Reactivity setters
  Future<void> setOilAudioPeakDecay(double value) => _updateDoublePreference(
      _oilAudioPeakDecayKey, _oilAudioPeakDecay = value.clamp(0.990, 0.999));
  Future<void> setOilAudioBassBoost(double value) => _updateDoublePreference(
      _oilAudioBassBoostKey, _oilAudioBassBoost = value.clamp(1.0, 3.0));
  Future<void> setOilAudioReactivityStrength(double value) =>
      _updateDoublePreference(_oilAudioReactivityStrengthKey,
          _oilAudioReactivityStrength = value.clamp(0.5, 2.0));
  void setOilAudioGraphMode(String mode) =>
      _updateStringPreference(_oilAudioGraphModeKey, _oilAudioGraphMode = mode);
  Future<void> setOilBeatSensitivity(double value) => _updateDoublePreference(
      _oilBeatSensitivityKey, _oilBeatSensitivity = value.clamp(0.0, 1.0));
  void toggleOilShowInfoBanner() => _updatePreference(
      _oilShowInfoBannerKey, _oilShowInfoBanner = !_oilShowInfoBanner);
  Future<void> setOilLogoScale(double value) =>
      _updateDoublePreference(_oilLogoScaleKey, _oilLogoScale = value);
  Future<void> setOilTranslationSmoothing(double value) =>
      _updateDoublePreference(
          _oilTranslationSmoothingKey, _oilTranslationSmoothing = value);
  Future<void> setOilBlurAmount(double value) =>
      _updateDoublePreference(_oilBlurAmountKey, _oilBlurAmount = value);
  void toggleOilFlatColor() =>
      _updatePreference(_oilFlatColorKey, _oilFlatColor = !_oilFlatColor);
  void toggleOilBannerGlow() =>
      _updatePreference(_oilBannerGlowKey, _oilBannerGlow = !_oilBannerGlow);
  Future<void> setOilBannerFlicker(double value) =>
      _updateDoublePreference(_oilBannerFlickerKey, _oilBannerFlicker = value);
  Future<void> setOilBannerGlowBlur(double value) => _updateDoublePreference(
      _oilBannerGlowBlurKey, _oilBannerGlowBlur = value);

  Future<void> setOilBannerResolution(double value) => _updateDoublePreference(
      _oilBannerResolutionKey, _oilBannerResolution = value.clamp(1.0, 4.0));

  // Ring control setters
  Future<void> setOilInnerRingScale(double value) => _updateDoublePreference(
      _oilInnerRingScaleKey, _oilInnerRingScale = value.clamp(0.1, 1.0));
  Future<void> setOilInnerToMiddleGap(double value) => _updateDoublePreference(
      _oilInnerToMiddleGapKey, _oilInnerToMiddleGap = value.clamp(0.0, 1.0));
  Future<void> setOilMiddleToOuterGap(double value) => _updateDoublePreference(
      _oilMiddleToOuterGapKey, _oilMiddleToOuterGap = value.clamp(0.0, 1.0));
  Future<void> setOilOrbitDrift(double value) => _updateDoublePreference(
      _oilOrbitDriftKey, _oilOrbitDrift = value.clamp(0.0, 2.0));
  Future<void> setOilInnerRingFontScale(double value) =>
      _updateDoublePreference(_oilInnerRingFontScaleKey,
          _oilInnerRingFontScale = value.clamp(0.3, 1.0));
  Future<void> setOilInnerRingSpacingMultiplier(double value) =>
      _updateDoublePreference(_oilInnerRingSpacingMultiplierKey,
          _oilInnerRingSpacingMultiplier = value.clamp(0.3, 1.0));

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
      _filterHighestShnidKey, _filterHighestShnid = !_filterHighestShnid);

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
        _sourceCategoryFiltersKey, json.encode(_sourceCategoryFilters));
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
      _oilTrackLetterSpacingKey, _oilTrackLetterSpacing = val);
  Future<void> setOilTrackWordSpacing(double val) => _updateDoublePreference(
      _oilTrackWordSpacingKey, _oilTrackWordSpacing = val);

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _init();
    notifyListeners();
  }
}
