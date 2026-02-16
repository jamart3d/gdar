/// Centralized default settings for the application.
/// Edit these values to change the default behavior for new users
/// or when resetting preferences.
class DefaultSettings {
  // Appearance
  static const bool useDynamicColor = true;
  static const bool useTrueBlack = true;
  static const String appFont = 'rock_salt';
  // Options:
  // 'default' - Standard system font (clean, legible)
  // 'caveat' - Handwriting style
  // 'permanent_marker' - Bold marker style
  // 'rock_salt' - Rough, hand-lettered style (Note: scaled down due to size)
  static const bool uiScaleDesktopDefault = false; // Default for large screens
  static const bool uiScaleMobileDefault =
      false; // Default for small screens (<720)
  static const bool highlightPlayingWithRgb = true;
  static const int glowMode =
      0; // 0=Off, 1-100=Intensity Percentage (e.g. 50=Half)
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

  // Screensaver (oil_slide)
  static const bool useOilScreensaver = false;
  static const String oilScreensaverMode = 'standard'; // 'standard' or 'kiosk'
  static const int oilScreensaverInactivityMinutes = 5;

  // oil_slide Visual Parameters
  static const double oilViscosity = 0.7;
  static const double oilFlowSpeed = 0.5;
  static const double oilPulseIntensity = 0.8;
  static const String oilPalette =
      'acid_green'; // 'acid_green', 'lava_gold', etc.
  static const double oilFilmGrain = 0.15; // Film grain intensity (0.0-1.0)
  static const double oilHeatDrift =
      0.3; // Heat drift for OLED safety (0.0-1.0)
  static const int oilMetaballCount = 6;
  static const bool oilEnableAudioReactivity = true;
  static const bool oilPerformanceMode = false; // Auto-detected for TV
  static const bool oilEasterEggsEnabled = true;
  static const String oilVisualMode =
      'psychedelic'; // 'lava_lamp', 'silk', 'psychedelic', 'custom'
}
