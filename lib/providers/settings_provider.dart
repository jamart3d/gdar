import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shakedown/config/default_settings.dart';
import 'package:shakedown/utils/logger.dart';

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
  static const String _simpleRandomIconKey = 'simple_random_icon';

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
  static const String _oilPerformanceModeKey = 'oil_performance_mode';
  static const String _oilPaletteCycleKey = 'oil_palette_cycle';
  static const String _oilPaletteTransitionSpeedKey =
      'oil_palette_transition_speed';
  static const String _oilBannerDisplayModeKey = 'oil_banner_display_mode';

  // Audio Reactivity Tuning
  static const String _oilAudioPeakDecayKey = 'oil_audio_peak_decay';
  static const String _oilAudioBassBoostKey = 'oil_audio_bass_boost';
  static const String _oilAudioReactivityStrengthKey =
      'oil_audio_reactivity_strength';
  static const String _oilShowInfoBannerKey = 'oil_show_info_banner';
  static const String _oilLogoScaleKey = 'oil_logo_scale';
  static const String _oilTranslationSmoothingKey = 'oil_translation_smoothing';
  static const String _oilBlurAmountKey = 'oil_blur_amount';
  static const String _oilFlatColorKey = 'oil_flat_color';
  static const String _oilBannerGlowKey = 'oil_banner_glow';
  static const String _oilBannerFlickerKey = 'oil_banner_flicker';

  // Ring controls (3-ring gap model)
  static const String _oilInnerRingScaleKey = 'oil_inner_ring_scale';
  static const String _oilInnerToMiddleGapKey = 'oil_inner_to_middle_gap';
  static const String _oilMiddleToOuterGapKey = 'oil_middle_to_outer_gap';
  static const String _oilOrbitDriftKey = 'oil_orbit_drift';

  static const String _marqueeEnabledKey = 'marquee_enabled';
  static const String _enableSwipeToBlockKey = 'enable_swipe_to_block';
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
  late bool _marqueeEnabled;
  late bool _enableSwipeToBlock;

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
  late bool _oilPerformanceMode;
  late bool _oilPaletteCycle;
  late double _oilPaletteTransitionSpeed;
  late String _oilBannerDisplayMode;

  // Audio Reactivity Tuning
  late double _oilAudioPeakDecay;
  late double _oilAudioBassBoost;
  late double _oilAudioReactivityStrength;
  late bool _oilShowInfoBanner;
  late double _oilLogoScale;
  late double _oilTranslationSmoothing;
  late double _oilBlurAmount;
  late bool _oilFlatColor;
  late bool _oilBannerGlow;
  late double _oilBannerFlicker;

  // Ring controls
  late double _oilInnerRingScale;
  late double _oilInnerToMiddleGap;
  late double _oilMiddleToOuterGap;
  late double _oilOrbitDrift;

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
  bool get marqueeEnabled => _marqueeEnabled;
  bool get enableSwipeToBlock => _enableSwipeToBlock;

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
  bool get oilPerformanceMode => _oilPerformanceMode;
  bool get oilPaletteCycle => _oilPaletteCycle;
  double get oilPaletteTransitionSpeed => _oilPaletteTransitionSpeed;
  String get oilBannerDisplayMode => _oilBannerDisplayMode;

  // Audio Reactivity getters
  double get oilAudioPeakDecay => _oilAudioPeakDecay;
  double get oilAudioBassBoost => _oilAudioBassBoost;
  double get oilAudioReactivityStrength => _oilAudioReactivityStrength;
  bool get oilShowInfoBanner => _oilShowInfoBanner;
  double get oilLogoScale => _oilLogoScale;
  double get oilTranslationSmoothing => _oilTranslationSmoothing;
  double get oilBlurAmount => _oilBlurAmount;
  bool get oilFlatColor => _oilFlatColor;
  bool get oilBannerGlow => _oilBannerGlow;
  double get oilBannerFlicker => _oilBannerFlicker;

  // Ring control getters
  double get oilInnerRingScale => _oilInnerRingScale;
  double get oilInnerToMiddleGap => _oilInnerToMiddleGap;
  double get oilMiddleToOuterGap => _oilMiddleToOuterGap;
  double get oilOrbitDrift => _oilOrbitDrift;

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
        if (physicalWidth <= 720) {
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
      _preventSleep =
          _prefs.getBool(_preventSleepKey) ?? DefaultSettings.preventSleep;
    }

    _marqueeEnabled = _prefs.getBool(_marqueeEnabledKey) ?? true;
    _enableSwipeToBlock = _prefs.getBool(_enableSwipeToBlockKey) ??
        DefaultSettings.enableSwipeToBlock;
    _showDebugLayout = _prefs.getBool(_showDebugLayoutKey) ?? false;
    _enableShakedownTween = _prefs.getBool(_enableShakedownTweenKey) ?? true;

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
    _oilPerformanceMode = _prefs.getBool(_oilPerformanceModeKey) ??
        DefaultSettings.oilPerformanceMode;
    _oilPaletteCycle =
        _prefs.getBool(_oilPaletteCycleKey) ?? DefaultSettings.oilPaletteCycle;
    _oilPaletteTransitionSpeed =
        _prefs.getDouble(_oilPaletteTransitionSpeedKey) ??
            DefaultSettings.oilPaletteTransitionSpeed;
    _oilBannerDisplayMode = _prefs.getString(_oilBannerDisplayModeKey) ??
        DefaultSettings.oilBannerDisplayMode;

    // Audio Reactivity
    _oilAudioPeakDecay = _prefs.getDouble(_oilAudioPeakDecayKey) ??
        DefaultSettings.oilAudioPeakDecay;
    _oilAudioBassBoost = _prefs.getDouble(_oilAudioBassBoostKey) ??
        DefaultSettings.oilAudioBassBoost;
    _oilAudioReactivityStrength =
        _prefs.getDouble(_oilAudioReactivityStrengthKey) ??
            DefaultSettings.oilAudioReactivityStrength;

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

    // Ring controls
    _oilInnerRingScale = _prefs.getDouble(_oilInnerRingScaleKey) ??
        DefaultSettings.oilInnerRingScale;
    _oilInnerToMiddleGap = _prefs.getDouble(_oilInnerToMiddleGapKey) ??
        DefaultSettings.oilInnerToMiddleGap;
    _oilMiddleToOuterGap = _prefs.getDouble(_oilMiddleToOuterGapKey) ??
        DefaultSettings.oilMiddleToOuterGap;
    _oilOrbitDrift =
        _prefs.getDouble(_oilOrbitDriftKey) ?? DefaultSettings.oilOrbitDrift;

    if (isTv) _oilScreensaverMode = 'steal';

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
  void toggleOilEnableAudioReactivity() => _updatePreference(
      _oilEnableAudioReactivityKey,
      _oilEnableAudioReactivity = !_oilEnableAudioReactivity);
  void toggleOilPerformanceMode() => _updatePreference(
      _oilPerformanceModeKey, _oilPerformanceMode = !_oilPerformanceMode);
  void toggleOilPaletteCycle() => _updatePreference(
      _oilPaletteCycleKey, _oilPaletteCycle = !_oilPaletteCycle);
  void setOilPaletteTransitionSpeed(double seconds) => _updateDoublePreference(
      _oilPaletteTransitionSpeedKey, _oilPaletteTransitionSpeed = seconds);
  Future<void> setOilBannerDisplayMode(String mode) => _updateStringPreference(
      _oilBannerDisplayModeKey, _oilBannerDisplayMode = mode);

  // Audio Reactivity setters
  Future<void> setOilAudioPeakDecay(double value) => _updateDoublePreference(
      _oilAudioPeakDecayKey, _oilAudioPeakDecay = value.clamp(0.990, 0.999));
  Future<void> setOilAudioBassBoost(double value) => _updateDoublePreference(
      _oilAudioBassBoostKey, _oilAudioBassBoost = value.clamp(1.0, 3.0));
  Future<void> setOilAudioReactivityStrength(double value) =>
      _updateDoublePreference(_oilAudioReactivityStrengthKey,
          _oilAudioReactivityStrength = value.clamp(0.5, 2.0));
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

  // Ring control setters
  Future<void> setOilInnerRingScale(double value) => _updateDoublePreference(
      _oilInnerRingScaleKey, _oilInnerRingScale = value.clamp(0.5, 2.0));
  Future<void> setOilInnerToMiddleGap(double value) => _updateDoublePreference(
      _oilInnerToMiddleGapKey, _oilInnerToMiddleGap = value.clamp(0.0, 1.0));
  Future<void> setOilMiddleToOuterGap(double value) => _updateDoublePreference(
      _oilMiddleToOuterGapKey, _oilMiddleToOuterGap = value.clamp(0.0, 1.0));
  Future<void> setOilOrbitDrift(double value) => _updateDoublePreference(
      _oilOrbitDriftKey, _oilOrbitDrift = value.clamp(0.0, 2.0));

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

  Future<void> resetToDefaults() async {
    await _prefs.clear();
    _init();
    notifyListeners();
  }
}
