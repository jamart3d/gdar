import 'package:flutter/material.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

/// A robust FakeSettingsProvider that can be shared across tests.
/// Mirrors the SettingsProvider API and provides default values.
class FakeSettingsProvider extends ChangeNotifier implements SettingsProvider {
  bool _isTv = false;
  @override
  bool get isTv => _isTv;
  set isTv(bool value) {
    _isTv = value;
    notifyListeners();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  AudioEngineMode get audioEngineMode => AudioEngineMode.auto;
  @override
  void setAudioEngineMode(AudioEngineMode mode) {}
  @override
  bool get useOilScreensaver => true;
  @override
  int get oilScaleSource => 1;
  @override
  double get oilScaleMultiplier => 1.0;
  @override
  int get oilColorSource => 0;
  @override
  double get oilColorMultiplier => 1.0;
  @override
  bool get oilWoodstockEveryHour => false;
  @override
  bool get preventSleep => false;
  @override
  int get oilScreensaverInactivityMinutes => 5;
  @override
  bool get showOnboarding => false;
  @override
  bool get useMaterial3 => true;
  @override
  bool get uiScale => false;
  @override
  double get oilBeatImpact => 1.0;
  @override
  Future<void> setOilBeatImpact(double value) async {}
  @override
  double get oilLogoScale => 1.0;
  @override
  Future<void> setOilLogoScale(double value) async {}
  @override
  String get appFont => 'default';
  @override
  String get activeAppFont => _isTv ? 'RockSalt' : 'default';
  @override
  void resetFruitFirstTimeSettings() {}

  @override
  bool get hideTabText => false;

  @override
  bool get highlightCurrentShowCard => false;
  @override
  bool get showDayOfWeek => true;
  @override
  bool get abbreviateDayOfWeek => true;
  @override
  bool get abbreviateMonth => true;
  @override
  bool get dateFirstInShowCard => true;
  @override
  bool get showSingleShnid => false;
  @override
  bool get showTrackNumbers => false;
  @override
  bool get sortOldestFirst => true;
  @override
  void toggleSortOldestFirst() {}

  @override
  bool get fruitStickyNowPlaying => false;
  @override
  void toggleFruitStickyNowPlaying() {}
  @override
  bool get playOnTap => false;
  @override
  bool get playRandomOnCompletion => false;

  @override
  bool get fruitEnableLiquidGlass => false;
  @override
  void toggleFruitEnableLiquidGlass() {}
  @override
  bool get playRandomOnStartup => false;
  @override
  bool get nonRandom => false;
  @override
  bool get randomOnlyUnplayed => false;
  @override
  bool get randomOnlyHighRated => false;
  @override
  bool get randomExcludePlayed => false;
  @override
  bool get filterHighestShnid => false;
  bool _useTrueBlack = true;
  @override
  bool get useTrueBlack => _useTrueBlack;
  void setTrueBlack(bool value) {
    _useTrueBlack = value;
    notifyListeners();
  }

  @override
  NeumorphicStyle get neumorphicStyle => NeumorphicStyle.convex;
  @override
  void setNeumorphicStyle(NeumorphicStyle value, {bool? notify}) {}
  @override
  bool get useDynamicColor => false;
  @override
  bool showPlaybackMessages = false;
  @override
  bool showDevAudioHud = false;
  @override
  bool highlightPlayingWithRgb = true;
  @override
  bool get offlineBuffering => false;
  @override
  bool get enableBufferAgent => false;
  @override
  bool get markPlayedOnStart => false;
  @override
  bool get showSplashScreen => false;
  @override
  bool get useSliverAppBar => false;
  @override
  bool get useSharedAxisTransition => false;
  @override
  bool get hideTrackCountInSourceList => false;
  @override
  bool get showExpandIcon => false;
  @override
  set showExpandIcon(bool value) {}
  int _glowMode = 0;
  @override
  int get glowMode => _glowMode;
  @override
  void setGlowMode(int mode) {
    _glowMode = mode;
    notifyListeners();
  }

  @override
  double get rgbAnimationSpeed => 1.0;
  @override
  Color? get seedColor => null;
  @override
  bool get hideTrackDuration => false;
  @override
  bool get showGlobalAlbumArt => true;
  @override
  bool get isFirstRun => false;
  @override
  bool get hasShownAdvancedCacheSuggestion => true;
  @override
  bool get showDebugLayout => false;
  @override
  bool get enableShakedownTween => false;
  @override
  bool get simpleRandomIcon => false;
  @override
  bool get useStrictSrcCategorization => false;
  @override
  bool get marqueeEnabled => true;
  @override
  bool get omitHttpPathInCopy => true;
  @override
  void toggleOmitHttpPathInCopy() {}
  @override
  String get oilScreensaverMode => 'visualizer';
  @override
  double get oilFlowSpeed => 1.0;
  @override
  double get oilPulseIntensity => 1.0;
  @override
  String get oilPalette => 'psychedelic';
  @override
  double get oilHeatDrift => 0.5;
  @override
  bool get oilEnableAudioReactivity => true;
  @override
  int get oilPerformanceLevel => 0;
  @override
  bool get oilPaletteCycle => false;
  @override
  double get oilPaletteTransitionSpeed => 5.0;
  @override
  double get oilAudioPeakDecay => 0.998;
  @override
  double get oilAudioBassBoost => 1.0;
  @override
  double get oilAudioReactivityStrength => 1.0;
  @override
  double get oilFilmGrain => 0.15;
  @override
  double get oilBlurAmount => 0.0;
  @override
  bool get oilFlatColor => false;
  @override
  bool get oilBannerGlow => false;
  @override
  double get oilBannerFlicker => 0.0;
  @override
  double get oilBannerGlowBlur => 0.5;
  @override
  double get oilInnerRingScale => 1.0;
  @override
  double get oilInnerToMiddleGap => 0.3;
  @override
  double get oilMiddleToOuterGap => 0.3;
  @override
  double get oilOrbitDrift => 1.0;
  @override
  String get oilBannerDisplayMode => 'ring';
  @override
  Future<void> setOilBannerDisplayMode(String mode) async {}
  @override
  double get oilFlatTextProximity => 0.0;
  @override
  Future<void> setOilFlatTextProximity(double value) async {}
  @override
  String get oilFlatTextPlacement => 'below';
  @override
  Future<void> setOilFlatTextPlacement(String placement) async {}

  @override
  bool get showScreensaverCountdown => false;
  @override
  void toggleShowScreensaverCountdown() {}

  @override
  double get oilBannerResolution => 2.0;
  @override
  Future<void> setOilBannerResolution(double value) async {}
  @override
  bool get oilBannerPixelSnap => true;
  @override
  Future<void> toggleOilBannerPixelSnap() async {}
  @override
  double get oilBannerLetterSpacing => 1.02;
  @override
  Future<void> setOilBannerLetterSpacing(double value) async {}
  @override
  double get oilBannerWordSpacing => 0.4;
  @override
  Future<void> setOilBannerWordSpacing(double value) async {}
  @override
  double get oilTrackLetterSpacing => 1.02;
  @override
  Future<void> setOilTrackLetterSpacing(double value) async {}
  @override
  double get oilTrackWordSpacing => 0.4;
  @override
  Future<void> setOilTrackWordSpacing(double value) async {}
  @override
  double get oilFlatLineSpacing => 1.0;
  @override
  Future<void> setOilFlatLineSpacing(double value) async {}
  @override
  bool get oilAutoTextSpacing => false;
  @override
  Future<void> setOilAutoTextSpacing(bool value) async {}
  @override
  bool get oilAutoRingSpacing => false;
  @override
  Future<void> setOilAutoRingSpacing(bool value) async {}
  @override
  String get oilAudioGraphMode => 'off';
  @override
  Future<void> setOilAudioGraphMode(String mode) async {}
  @override
  String get oilBeatDetectorMode => 'auto';
  @override
  Future<void> setOilBeatDetectorMode(String mode) async {}
  @override
  Future<void> setOilColorSource(int value) async {}
  @override
  Future<void> setOilScaleSource(int value) async {}
  @override
  Future<void> setOilColorMultiplier(double value) async {}
  @override
  Future<void> setOilScaleMultiplier(double value) async {}
  @override
  double get oilBeatSensitivity => 0.5;
  @override
  Future<void> setOilBeatSensitivity(double value) async {}

  @override
  double get oilLogoTrailIntensity => 0.0;
  @override
  int get oilLogoTrailSlices => 6;
  @override
  double get oilLogoTrailLength => 0.5;
  @override
  double get oilLogoTrailScale => 1.0;
  @override
  double get oilLogoTrailInitialScale => 0.92;
  @override
  bool get oilTvPremiumHighlight => false;
  @override
  void toggleOilTvPremiumHighlight() {}
  @override
  bool get oilLogoTrailDynamic => true;
  @override
  void toggleOilLogoTrailDynamic() {}
  @override
  Map<String, bool> get sourceCategoryFilters => {};

  @override
  void toggleShowSplashScreen() {}
  @override
  void toggleShowTrackNumbers() {}
  @override
  void togglePlayOnTap() {}
  @override
  void toggleShowSingleShnid() {}
  @override
  void togglePlayRandomOnCompletion() {}
  @override
  void togglePlayRandomOnStartup() {}
  @override
  void toggleDateFirstInShowCard() {}
  @override
  void toggleUseDynamicColor() {}
  @override
  void setAppFont(String font) {}
  @override
  void toggleUiScale() {}
  @override
  void toggleUseTrueBlack() {
    _useTrueBlack = !_useTrueBlack;
    notifyListeners();
  }

  @override
  void toggleHighlightPlayingWithRgb() {}
  @override
  void toggleShowPlaybackMessages() {}
  @override
  void setRgbAnimationSpeed(double speed) {}
  @override
  void toggleShowDevAudioHud() {}
  @override
  void toggleMarkPlayedOnStart() {}
  @override
  void setFruitEnableLiquidGlass(bool value) {}
  @override
  void setHighlightPlayingWithRgb(bool value) {}

  @override
  bool get enableHaptics => true;
  @override
  void toggleEnableHaptics() {}

  @override
  Future<void> setSeedColor(Color? color) async {}
  @override
  void toggleHideTrackDuration() {}
  @override
  Future<void> completeOnboarding() async {}
  @override
  void toggleNonRandom() {}
  @override
  void toggleRandomOnlyUnplayed() {}
  @override
  void toggleRandomOnlyHighRated() {}
  @override
  void toggleRandomExcludePlayed() {}
  @override
  void toggleFilterHighestShnid() {}
  @override
  Future<void> setSourceCategoryFilter(String category, bool isActive) async {}
  @override
  Future<void> setSoloSourceCategoryFilter(String category) async {}
  @override
  Future<void> enableAllSourceCategories() async {}
  @override
  void markAdvancedCacheSuggestionShown() {}
  @override
  void toggleShowDebugLayout() {}
  @override
  void toggleEnableShakedownTween() {}

  @override
  bool get enableSwipeToBlock => false;
  @override
  void toggleEnableSwipeToBlock() {}
  @override
  bool get useNeumorphism => false;

  @override
  void toggleUseNeumorphism() {}
  @override
  void setUseNeumorphism(bool value) {}

  @override
  bool get performanceMode => false;
  @override
  void togglePerformanceMode() {}

  @override
  bool get webGaplessEngine => true;
  @override
  void toggleWebGaplessEngine() {}
  @override
  int get webPrefetchSeconds => 30;
  @override
  Future<void> setWebPrefetchSeconds(int seconds) async {}

  @override
  String get trackTransitionMode => 'gapless';
  @override
  void setTrackTransitionMode(String value) {}

  @override
  HybridHandoffMode get hybridHandoffMode => HybridHandoffMode.buffered;
  @override
  void setHybridHandoffMode(HybridHandoffMode value) {}

  @override
  HybridBackgroundMode get hybridBackgroundMode =>
      HybridBackgroundMode.heartbeat;
  @override
  void setHybridBackgroundMode(HybridBackgroundMode value) {}

  @override
  double get crossfadeDurationSeconds => 3.0;
  @override
  void setCrossfadeDurationSeconds(double seconds) {}

  @override
  HiddenSessionPreset get hiddenSessionPreset => HiddenSessionPreset.balanced;
  @override
  void setHiddenSessionPreset(HiddenSessionPreset value) {}

  @override
  Future<void> resetToDefaults() async {}
  @override
  void toggleAbbreviateMonth() {}
  @override
  void toggleSimpleRandomIcon() {}
  @override
  void toggleUseStrictSrcCategorization() {}
  @override
  void toggleOfflineBuffering() {}
  @override
  void toggleEnableBufferAgent() {}
  @override
  void togglePreventSleep() {}
  @override
  void toggleUseOilScreensaver() {}
  @override
  @override
  Future<void> setOilScreensaverMode(String mode) async {}
  @override
  void setOilScreensaverInactivityMinutes(int minutes) {}
  @override
  Future<void> setOilFlowSpeed(double value) async {}
  @override
  Future<void> setOilPulseIntensity(double value) async {}
  @override
  Future<void> setOilPalette(String palette) async {}
  @override
  Future<void> setOilHeatDrift(double value) async {}
  @override
  Future<void> toggleOilEnableAudioReactivity() async {}
  @override
  Future<void> setOilPerformanceLevel(int level) async {}
  @override
  bool get oilLogoAntiAlias => false;
  @override
  Future<void> toggleOilLogoAntiAlias() async {}
  @override
  Future<void> toggleOilPaletteCycle() async {}
  @override
  bool get oilScaleSineEnabled => false;
  @override
  double get oilScaleSineFreq => 1.0;
  @override
  double get oilScaleSineAmp => 0.0;
  @override
  void toggleOilScaleSineEnabled() {}
  @override
  Future<void> setOilScaleSineFreq(double value) async {}
  @override
  Future<void> setOilScaleSineAmp(double value) async {}
  @override
  double get oilEkgRadius => 1.0;
  @override
  Future<void> setOilEkgRadius(double value) async {}
  @override
  int get oilEkgReplication => 1;
  @override
  Future<void> setOilEkgReplication(int value) async {}
  @override
  double get oilEkgSpread => 1.0;
  @override
  Future<void> setOilEkgSpread(double value) async {}

  @override
  bool get oilShowInfoBanner => true;
  @override
  void toggleOilShowInfoBanner() {}

  @override
  void setOilPaletteTransitionSpeed(double seconds) {}
  @override
  Future<void> setOilAudioPeakDecay(double value) async {}
  @override
  Future<void> setOilAudioBassBoost(double value) async {}
  @override
  Future<void> setOilAudioReactivityStrength(double value) async {}
  @override
  Future<void> setOilFilmGrain(double value) async {}
  @override
  Future<void> setOilBlurAmount(double value) async {}
  @override
  void toggleOilFlatColor() {}
  @override
  void toggleOilBannerGlow() {}
  @override
  Future<void> setOilBannerFlicker(double value) async {}
  @override
  Future<void> setOilBannerGlowBlur(double value) async {}
  @override
  Future<void> setOilInnerRingScale(double value) async {}
  @override
  Future<void> setOilInnerToMiddleGap(double value) async {}
  @override
  Future<void> setOilMiddleToOuterGap(double value) async {}
  @override
  Future<void> setOilOrbitDrift(double value) async {}
  @override
  double get oilInnerRingFontScale => 0.75;
  @override
  Future<void> setOilInnerRingFontScale(double value) async {}
  @override
  double get oilMiddleRingFontScale => 0.75;
  @override
  Future<void> setOilMiddleRingFontScale(double value) async {}
  @override
  double get oilOuterRingFontScale => 0.75;
  @override
  Future<void> setOilOuterRingFontScale(double value) async {}
  @override
  double get oilInnerRingSpacingMultiplier => 0.7;
  @override
  Future<void> setOilInnerRingSpacingMultiplier(double value) async {}
  @override
  double get oilMiddleRingSpacingMultiplier => 0.7;
  @override
  Future<void> setOilMiddleRingSpacingMultiplier(double value) async {}
  @override
  double get oilOuterRingSpacingMultiplier => 0.7;
  @override
  Future<void> setOilOuterRingSpacingMultiplier(double value) async {}

  @override
  double get oilTranslationSmoothing => 1.0;
  @override
  Future<void> setOilTranslationSmoothing(double value) async {}

  @override
  Future<void> setOilLogoTrailIntensity(double value) async {}
  @override
  Future<void> setOilLogoTrailSlices(int value) async {}
  @override
  Future<void> setOilLogoTrailLength(double value) async {}
  @override
  Future<void> setOilLogoTrailScale(double value) async {}
  @override
  Future<void> setOilLogoTrailInitialScale(double value) async {}

  @override
  String get oilBannerFont => 'Roboto';
  @override
  Future<void> setOilBannerFont(String font) async {}

  @override
  bool get hideTvScrollbars => false;
  @override
  bool get forceTv => false;
  @override
  void toggleForceTv() {}
  @override
  @override
  Future<void> setForceTv(bool value) async {}

  @override
  bool get fruitDenseList => false;
  @override
  void toggleFruitDenseList() {}

  @override
  void saveResumeSession(String sourceId, int trackIndex, int positionMs) {}

  @override
  bool hasResumeSession() => false;

  @override
  ({String sourceId, int trackIndex, int positionMs})? consumeResumeSession() =>
      null;

  @override
  bool get usePlayPauseFade => true;
  @override
  void togglePlayPauseFade() {}

  @override
  bool get hasListeners => super.hasListeners;
}
