/// Centralized default settings for the application.
/// Edit these values to change the default behavior for new users
/// or when resetting preferences.
class DefaultSettings {
  // Appearance
  static const bool useDynamicColor = true;
  static const bool useTrueBlack = true;
  static const String appFont = 'rock_salt';
  static const bool uiScaleDesktopDefault = false;
  static const bool uiScaleMobileDefault = false;
  static const bool highlightPlayingWithRgb = true;
  static const int glowMode = 0;
  static const double rgbAnimationSpeed = 0.5;

  // Show Card & content
  static const bool showTrackNumbers = false;
  static const bool hideTrackDuration = true;
  static const bool dateFirstInShowCard = true;
  static const bool showDayOfWeek = true;
  static const bool abbreviateDayOfWeek = false;
  static const bool abbreviateMonth = false;

  // Playback Behavior
  static const bool playOnTap = false;
  static const bool playRandomOnStartup = false;
  static const bool playRandomOnCompletion = true;
  static const bool nonRandom = false;
  static const bool preventSleep = true;
  static const bool showPlaybackMessages = false;

  // Data & Filtering
  static const bool showSingleShnid = false;
  static const bool sortOldestFirst = true;
  static const bool useStrictSrcCategorization = true;
  static const bool offlineBuffering = false;
  static const bool enableBufferAgent = true;

  // Random Show Filters
  static const bool randomOnlyUnplayed = false;
  static const bool randomOnlyHighRated = false;
  static const bool randomExcludePlayed = false;

  // Source Categories (true = enabled by default)
  static const Map<String, bool> sourceCategoryFilters = {
    'matrix': true,
    'ultra': false,
    'betty': false,
    'sbd': false,
    'fm': false,
    'dsbd': false,
    'unk': false,
  };

  // Misc
  static const bool showSplashScreen = true;

  // Screensaver (steal)
  static const bool useOilScreensaver = true;
  static const String oilScreensaverMode = 'standard';
  static const int oilScreensaverInactivityMinutes = 5;

  // Steal Visualizer Parameters
  static const double oilFlowSpeed = 0.5;
  static const double oilPulseIntensity = 0.8;
  static const String oilPalette = 'acid_green';
  static const double oilFilmGrain = 0.15;
  static const double oilHeatDrift = 0.3;
  static const double oilLogoScale = 1.0;
  static const double oilBlurAmount = 0.0;
  static const bool oilFlatColor = false;
  static const bool oilBannerGlow = false;
  static const double oilBannerFlicker = 0.0;
  static const bool oilEnableAudioReactivity = true;
  static const bool oilPerformanceMode = false;
  static const bool oilPaletteCycle = false;
  static const double oilPaletteTransitionSpeed = 5.0;
  static const double oilAudioReactivityStrength = 1.0;
  static const double oilAudioBassBoost = 2.0;
  static const double oilAudioPeakDecay = 0.95;
  static const bool oilShowInfoBanner = true;

  // Ring controls (3-ring gap model)
  static const double oilInnerRingScale = 1.0; // base inner ring size
  static const double oilInnerToMiddleGap = 0.3; // gap inner→middle (0–1)
  static const double oilMiddleToOuterGap = 0.3; // gap middle→outer (0–1)
  static const double oilOrbitDrift = 1.0; // 0=centered, 1=default drift
}
