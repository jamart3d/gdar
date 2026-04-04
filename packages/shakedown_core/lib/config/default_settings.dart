import 'package:gdar_design/tokens/theme_tokens.dart';

/// Centralized default settings for the application.
/// Edit these values to change the default behavior for new users
/// or when resetting preferences.
class DefaultSettings {
  // Appearance
  static const bool useDynamicColor = true;
  static const bool useTrueBlack = false;
  static const String appFont = 'rock_salt';
  static const bool uiScaleDesktopDefault = false;
  static const bool uiScaleMobileDefault = false;
  static const bool carMode = false;
  static const bool fruitFloatingSpheres = false;
  static const bool highlightPlayingWithRgb = true;
  static const int glowMode = 0;
  static const double rgbAnimationSpeed = 0.5;
  static const bool useNeumorphism = false;
  static const NeumorphicStyle neumorphicStyle = NeumorphicStyle.convex;
  static const bool performanceMode = false;

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
  static const bool preventSleep = false;
  static const bool showPlaybackMessages = true;
  static const bool showDevAudioHud = true;
  static const String devHudMode = 'full';

  // Web Gapless Engine (web-only)
  static const String audioEngineMode =
      'auto'; // auto, webAudio, html5, standard, passive, hybrid
  static const int webPrefetchSeconds = 30;

  // Track Transitions (hybrid/standard engines)
  static const String trackTransitionMode = 'gapless'; // gap, gapless
  static const double crossfadeDurationSeconds = 3.0; // 1.0 - 12.0
  static const int handoffCrossfadeMs = 0; // 0 = off, 0-200 recommended

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
  static const bool markPlayedOnStart = true;

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
  static const bool enableSwipeToBlock = false;
  static const bool hideTabText = true;
  static const bool showDebugLayout = false;

  // TV Background Spheres
  static const bool enableTvBackgroundSpheres = false;
  static const String tvBackgroundSphereAmount = 'small';

  // Screensaver (steal)
  static const bool useOilScreensaver = true;
  static const String oilScreensaverMode = 'standard';
  static const int oilScreensaverInactivityMinutes = 1;

  // Steal Visualizer Parameters
  static const double oilFlowSpeed = 0.08;
  static const double oilPulseIntensity = 0.4;
  static const String oilPalette = 'acid_green';
  static const double oilFilmGrain = 0.15;
  static const double oilHeatDrift = 0.0;
  static const double oilLogoScale = .5;
  static const double oilBlurAmount = 0.0;
  static const bool oilFlatColor = true;
  static const bool oilBannerGlow = true;
  static const double oilBannerFlicker = 0.6;
  static const double oilBannerGlowBlur = 0.5;
  static const bool oilEnableAudioReactivity = true;
  static const int oilPerformanceLevel = 0;
  static const bool oilPaletteCycle = true;
  static const double oilPaletteTransitionSpeed = 5.0;
  static const double oilAudioReactivityStrength = 1.1;
  static const double oilAudioBassBoost = 1.6;
  static const double oilAudioPeakDecay = 0.992;
  static const bool oilShowInfoBanner = true;
  static const double oilTranslationSmoothing =
      0.85; // â”€â”€ Steal Screensaver Flat/Rings â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
  static const String oilBannerDisplayMode = 'flat'; // 'flat' or 'rings'
  static const String oilBannerFont = 'RockSalt'; // Primary font
  static const double oilFlatTextProximity = 0.65; // Middle proximity
  static const String oilFlatTextPlacement = 'above'; // below the logo
  static const double oilBannerResolution = 2.0;
  static const bool oilBannerPixelSnap = false;
  static const bool oilAutoTextSpacing = true;
  static const bool oilAutoRingSpacing = true;

  // Trail effect
  static const double oilLogoTrailIntensity = 1.0;
  static const int oilLogoTrailSlices = 16;
  static const double oilLogoTrailLength = 0.5;
  static const double oilLogoTrailInitialScale = 0.92;
  static const double oilLogoTrailScale = 0.5; // 10% reduction per slice
  static const bool oilLogoTrailDynamic = false;

  // Ring controls (3-ring gap model)
  static const double oilInnerRingScale = 0.5;
  static const double oilInnerToMiddleGap = 0.05;
  static const double oilMiddleToOuterGap = 0.05;
  static const double oilOrbitDrift = 1.0;
  static const double oilBannerLetterSpacing = 1.0;
  static const double oilBannerWordSpacing = 0.2;
  static const double oilTrackLetterSpacing = 1.0;
  static const double oilTrackWordSpacing = 0.2;
  static const double oilFlatLineSpacing = 1.0;
  static const double oilInnerRingFontScale = 0.75;
  static const double oilMiddleRingFontScale = 0.80;
  static const double oilOuterRingFontScale = 1.0;
  static const double oilInnerRingSpacingMultiplier = 1.5;
  static const double oilMiddleRingSpacingMultiplier = 1.15;
  static const double oilOuterRingSpacingMultiplier = 1.15;

  /// Logo anti-aliasing: fwidth smoothstep on alpha edge (TV-only setting).
  static const bool oilLogoAntiAlias = false;

  /// Audio graph display mode.
  /// Valid TV modes include: 'off', 'corner', 'corner_only', 'circular',
  /// 'ekg', 'circular_ekg', 'vu', 'scope', and 'beat_debug'.
  static const String oilAudioGraphMode = 'off';

  /// Preview panel focus mode: false = show logo, true = show audio graph.
  static const bool oilPreviewShowGraph = false;

  /// Radius multiplier for EKG (0.5x to 2.0x of base logo radius).
  static const double oilEkgRadius = 0.1;

  /// Number of parallel offset lines for EKG (1 to 10).
  static const int oilEkgReplication = 4;

  /// Vertical/Radial spread between replicated EKG lines.
  static const double oilEkgSpread = 16.0;

  /// Beat detection sensitivity for the TV visualizer (0.0 = gentler,
  /// 1.0 = more aggressive / easier to trigger).
  /// Detector mode: 'auto', 'hybrid', 'bass', 'mid', 'broad', or 'pcm'.
  static const String oilBeatDetectorMode = 'auto';
  static const double oilBeatSensitivity = 0.80;
  static const double oilBeatImpact = 0.25;

  /// Audio Reactivity Isolation
  /// -2 = None, -1 = Default, 0-7 = FFT Bands
  static const int oilScaleSource = -1;
  static const double oilScaleMultiplier = 1.0;
  static const bool oilScaleSineEnabled = false;
  static const double oilScaleSineFreq = 0.5;
  static const double oilScaleSineAmp = 0.2;
  static const int oilColorSource = -1; // Default treble/brilliance mapping
  static const double oilColorMultiplier = 1.0;
  static const bool oilWoodstockEveryHour = true;

  static const bool oilTvPremiumHighlight = false;
  static const bool omitHttpPathInCopy = true;
}

// -----------------------------------------------------------------------------
// Per-Platform Default Overrides
//
// Only list settings that DIFFER from the base DefaultSettings above.
// SettingsProvider picks the right class at init time via _d.
// -----------------------------------------------------------------------------

/// Defaults for the Web UI (browser tab, desktop).
class WebDefaults extends DefaultSettings {
  // Appearance
  static const bool useTrueBlack = false; // OLED burn-in not a concern on web
  static const bool useNeumorphism = true; // Fruit / Liquid Glass theme
  static const String appFont = 'rock_salt';
  static const bool performanceMode =
      false; // Fruit-first by default; low-power devices opt in via SettingsProvider detection

  // Screensaver: disabled by default on web (no idle-lock risk)
  static const bool useOilScreensaver = false;

  // Splash only shown on first run (handled dynamically in provider)
  static const bool showSplashScreen = false;

  // Audio: auto (hybrid-first) is the default on web
  static const String audioEngineMode = 'auto';
}

/// Defaults for the Google TV UI.
class TvDefaults extends DefaultSettings {
  // Appearance
  static const bool useTrueBlack = true;
  static const bool performanceMode = false;
  static const bool oilTvPremiumHighlight = false;
  static const bool hideTvScrollbars = true;

  // Screensaver: steal mode looks great on TV
  static const String oilScreensaverMode = 'steal';

  // Audio: TV is a native app - uses the same standard player as Phone

  // Screensaver performance mode ON by default (TV shader budget is limited)
  // User can toggle this off in TV Settings -> Screensaver -> Performance Mode
  static const int oilPerformanceLevel = 1;

  // Auto spacing helps Rock Salt avoid crowding on TV.
  static const bool oilAutoTextSpacing = true;
  static const bool oilAutoRingSpacing = true;

  // Prevent screen sleep by default â€” TV is a lean-back device
  static const bool preventSleep = true;

  // TV uses a clean UI; playback messages are off by default.
  static const bool showPlaybackMessages = false;

  // Airy spacing by default on TV
  static const double oilBannerLetterSpacing = 1.02;
  static const double oilTrackLetterSpacing = 1.02;
  static const double oilInnerRingSpacingMultiplier = 1.15;
  static const double oilMiddleRingSpacingMultiplier = 1.15;
  static const double oilOuterRingSpacingMultiplier = 1.15;
}

/// Defaults for the Phone / Android UI.
class PhoneDefaults extends DefaultSettings {
  // Appearance
  static const bool useNeumorphism = false;
  static const bool performanceMode = false;

  // Screen should turn off normally â€” music plays in background without keeping screen on
  static const bool preventSleep = false;

  // Audio: standard native player on Android
  static const String audioEngineMode = 'standard';
}
