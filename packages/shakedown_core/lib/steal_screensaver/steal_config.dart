import 'package:flutter/material.dart';

double _readDouble(Map<String, dynamic> map, String key, double fallback) {
  return (map[key] as num?)?.toDouble() ?? fallback;
}

int _readInt(Map<String, dynamic> map, String key, int fallback) {
  return (map[key] as int?) ?? fallback;
}

bool _readBool(Map<String, dynamic> map, String key, bool fallback) {
  return map[key] as bool? ?? fallback;
}

String _readString(Map<String, dynamic> map, String key, String fallback) {
  return map[key] as String? ?? fallback;
}

int _performanceLevelFromMap(Map<String, dynamic> map) {
  return _readInt(
    map,
    'performanceLevel',
    (_readBool(map, 'performanceMode', false) ? 2 : 0),
  );
}

/// Configuration for the Steal Your Face screensaver.
class StealConfig {
  final double flowSpeed;
  final String palette;
  final double filmGrain;
  final double pulseIntensity;
  final double heatDrift;
  final double logoScale;
  final double translationSmoothing; // 0.0 = instant, 1.0 = very smooth
  final double blurAmount;
  final bool flatColor;
  final bool bannerGlow;
  final double bannerFlicker;
  final double bannerGlowBlur;
  final bool enableAudioReactivity;
  final bool logoTrailDynamic;

  /// Overall quality/performance level: 0=High, 1=Balanced, 2=Fast.
  final int performanceLevel;
  final bool showInfoBanner;
  final String bannerText;
  final String venue;
  final String date;
  final String trackHintId;
  final String trackHintTitle;
  final String trackHintVariant;
  final String trackHintSeedSource;
  final bool paletteCycle;
  final double paletteTransitionSpeed;
  final double innerRingScale;
  final double innerToMiddleGap;
  final double middleToOuterGap;
  final double orbitDrift;
  final String bannerDisplayMode; // 'ring' or 'flat'
  final String bannerFont; // e.g. 'Rock Salt' or 'Roboto'
  final double logoTrailIntensity; // 0.0 = off, 1.0 = full
  final int logoTrailSlices; // 2-16 ghost copies
  final double logoTrailLength; // 0.0-1.0 spacing between snapshots
  final double logoTrailScale; // 0.0-1.0 shrinkage per snapshot
  final double logoTrailInitialScale; // 0.5-2.0 base scaling from logo
  /// Flat mode: 0.0 = default gap (text just below visual edge),
  /// 1.0 = text at logo center (fully overlapping).
  final double flatTextProximity;

  /// Multiplier for text rasterization resolution (supersampling).
  /// 1.0 = native, 2.0 = double resolution (sharper), etc.
  final double bannerResolution;
  final bool bannerPixelSnap;
  final bool autoTextSpacing;
  final bool autoRingSpacing;

  /// Spacing between letters in the banner.
  final double bannerLetterSpacing;

  /// Extra spacing between words in the banner.
  final double bannerWordSpacing;

  /// Spacing between letters in the track title ring.
  final double trackLetterSpacing;

  /// Extra spacing between words in the track title ring.
  final double trackWordSpacing;

  /// Flat mode: where the text block is positioned relative to the logo.
  /// 'below' = stacked below logo, 'above' = stacked above logo.
  final String flatTextPlacement;

  /// Flat mode: multiplier for the vertical distance between lines.
  /// 1.0 = standard, 0.5 = tight, 2.0 = double spaced.
  final double flatLineSpacing;

  /// Audio graph display mode: 'off', 'corner', 'corner_only', 'circular', 'ekg', or 'circular_ekg'.
  final String audioGraphMode;
  final String beatDetectorMode;
  final String autocorrBeatVariant;
  final String autocorrLogoVariant;

  /// Radius multiplier for EKG (0.5x to 2.0x of base logo radius).
  final double ekgRadius;

  /// Number of parallel offset lines for EKG (1 to 10).
  final int ekgReplication;

  /// Vertical/Radial spread between replicated EKG lines.
  final double ekgSpread;

  /// Beat detection sensitivity (0.0 = gentle, 1.0 = aggressive).
  final double beatSensitivity;

  /// Visual beat scale impact (0.0 = off, 1.0 = full).
  final double beatImpact;

  final double innerRingFontScale;

  /// Font size multiplier for the middle (track) ring.
  final double middleRingFontScale;

  /// Font size multiplier for the outer (venue) ring.
  final double outerRingFontScale;

  final double innerRingSpacingMultiplier;

  /// Spacing multiplier for the middle (track) ring.
  final double middleRingSpacingMultiplier;

  /// Spacing multiplier for the outer (venue) ring.
  final double outerRingSpacingMultiplier;

  /// Whether to apply fwidth-based anti-aliasing on the logo alpha edge.
  final bool logoAntiAlias;

  /// Source for logo scale reactivity (-2 = none, -1 = default, 0-7 = bands).
  final int scaleSource;
  final double scaleMultiplier;

  /// Whether to add a sine wave drive to the logo scale.
  final bool scaleSineEnabled;

  /// Frequency of the logo scale sine wave in Hz.
  final double scaleSineFreq;

  /// Amplitude of the logo scale sine wave (0.0 to 1.0).
  final double scaleSineAmp;

  /// Source for logo color reactivity (-2 = none, -1 = default, 0-7 = bands).
  final int colorSource;
  final double colorMultiplier;

  final bool woodstockEveryHour;

  static const Map<String, List<Color>> palettes = {
    'psychedelic': [
      Color(0xFFFF00FF),
      Color(0xFF00FFFF),
      Color(0xFFFFFF00),
      Color(0xFFFF0000),
    ],
    'acid_green': [
      Color(0xFF00FF00),
      Color(0xFF00FFFF),
      Color(0xFF00FF7F),
      Color(0xFF7FFF00),
    ],
    'purple_haze': [
      Color(0xFF4B0082),
      Color(0xFF8B008B),
      Color(0xFFBA55D3),
      Color(0xFFDA70D6),
    ],
    'ocean': [
      Color(0xFF000080),
      Color(0xFF0000CD),
      Color(0xFF00CED1),
      Color(0xFF40E0D0),
    ],
    'aurora': [
      Color(0xFF00008B),
      Color(0xFF00FF7F),
      Color(0xFF9400D3),
      Color(0xFF1E90FF),
    ],
    'cosmic': [
      Color(0xFF0000FF),
      Color(0xFFFF00FF),
      Color(0xFFFF4500),
      Color(0xFF00FFFF),
    ],
    'classic': [
      Color(0xFF34E7FF),
      Color(0xFF4AF3C6),
      Color(0xFF8BFF91),
      Color(0xFFFFE66D),
    ],
  };

  static List<Color> paletteColorsForName(String name) {
    return palettes[name] ?? palettes.values.first;
  }

  const StealConfig({
    this.flowSpeed = 0.1,
    this.palette = 'psychedelic',
    this.filmGrain = 0.1,
    this.pulseIntensity = 0.5,
    this.heatDrift = 0.2,
    this.logoScale = 0.5,
    this.translationSmoothing = 0.7,
    this.blurAmount = 0.0,
    this.flatColor = false,
    this.bannerGlow = false,
    this.bannerFlicker = 0.0,
    this.bannerGlowBlur = 0.5,
    this.enableAudioReactivity = true,
    this.logoTrailDynamic = true,
    this.performanceLevel = 0,
    this.showInfoBanner = true,
    this.bannerText = '',
    this.venue = '',
    this.date = '',
    this.trackHintId = '',
    this.trackHintTitle = '',
    this.trackHintVariant = '',
    this.trackHintSeedSource = 'audio',
    this.paletteCycle = true,
    this.paletteTransitionSpeed = 5.0,
    this.innerRingScale = 1.0,
    this.innerToMiddleGap = 0.3,
    this.middleToOuterGap = 0.3,
    this.orbitDrift = 1.0,
    this.bannerDisplayMode = 'ring',
    this.bannerFont = 'RockSalt',
    this.logoTrailIntensity = 0.0,
    this.logoTrailSlices = 6,
    this.logoTrailLength = 0.5,
    this.logoTrailScale = 0.1,
    this.logoTrailInitialScale = 0.92,
    this.flatTextProximity = 0.0,
    this.flatTextPlacement = 'below',
    this.bannerResolution = 2.0,
    this.bannerPixelSnap = true,
    this.autoTextSpacing = false,
    this.autoRingSpacing = true,
    this.bannerLetterSpacing = 1.02,
    this.bannerWordSpacing = 0.4,
    this.trackLetterSpacing = 1.02,
    this.trackWordSpacing = 0.4,
    this.flatLineSpacing = 1.0,
    this.audioGraphMode = 'off',
    this.beatDetectorMode = 'auto',
    this.autocorrBeatVariant = 'bpm',
    this.autocorrLogoVariant = 'pulse',
    this.ekgRadius = 1.0,
    this.ekgReplication = 1,
    this.ekgSpread = 4.0,
    this.beatSensitivity = 0.5,
    this.beatImpact = 0.4,
    this.innerRingFontScale = 1.0,
    this.middleRingFontScale = 1.0,
    this.outerRingFontScale = 1.0,
    this.innerRingSpacingMultiplier = 1.0,
    this.middleRingSpacingMultiplier = 1.0,
    this.outerRingSpacingMultiplier = 1.0,
    this.logoAntiAlias = false,
    this.scaleSource = -1,
    this.scaleMultiplier = 1.0,
    this.scaleSineEnabled = false,
    this.scaleSineFreq = 0.5,
    this.scaleSineAmp = 0.2,
    this.colorSource = -1,
    this.colorMultiplier = 1.0,
    this.woodstockEveryHour = true,
  });

  factory StealConfig.fromMap(Map<String, dynamic> map) {
    return StealConfig(
      flowSpeed: _readDouble(map, 'flowSpeed', 0.1),
      palette: _readString(map, 'palette', 'psychedelic'),
      filmGrain: _readDouble(map, 'filmGrain', 0.1),
      pulseIntensity: _readDouble(map, 'pulseIntensity', 0.5),
      heatDrift: _readDouble(map, 'heatDrift', 0.2),
      logoScale: _readDouble(map, 'logoScale', 0.5),
      translationSmoothing: _readDouble(map, 'translationSmoothing', 0.7),
      blurAmount: _readDouble(map, 'blurAmount', 0.0),
      flatColor: _readBool(map, 'flatColor', false),
      bannerGlow: _readBool(map, 'bannerGlow', false),
      bannerFlicker: _readDouble(map, 'bannerFlicker', 0.0),
      bannerGlowBlur: _readDouble(map, 'bannerGlowBlur', 0.5),
      enableAudioReactivity: _readBool(map, 'enableAudioReactivity', true),
      logoTrailDynamic: _readBool(map, 'logoTrailDynamic', true),
      performanceLevel: _performanceLevelFromMap(map),
      showInfoBanner: _readBool(map, 'showInfoBanner', true),
      bannerText: _readString(map, 'bannerText', ''),
      venue: _readString(map, 'venue', ''),
      date: _readString(map, 'date', ''),
      trackHintId: _readString(map, 'trackHintId', ''),
      trackHintTitle: _readString(map, 'trackHintTitle', ''),
      trackHintVariant: _readString(map, 'trackHintVariant', ''),
      trackHintSeedSource: _readString(map, 'trackHintSeedSource', 'audio'),
      paletteCycle: _readBool(map, 'paletteCycle', true),
      paletteTransitionSpeed: _readDouble(map, 'paletteTransitionSpeed', 5.0),
      innerRingScale: _readDouble(map, 'innerRingScale', 1.0),
      innerToMiddleGap: _readDouble(map, 'innerToMiddleGap', 0.3),
      middleToOuterGap: _readDouble(map, 'middleToOuterGap', 0.3),
      orbitDrift: _readDouble(map, 'orbitDrift', 1.0),
      bannerDisplayMode: _readString(map, 'bannerDisplayMode', 'ring'),
      bannerFont: _readString(map, 'bannerFont', 'Rock Salt'),
      logoTrailIntensity: _readDouble(map, 'logoTrailIntensity', 0.0),
      logoTrailSlices: _readInt(map, 'logoTrailSlices', 6),
      logoTrailLength: _readDouble(map, 'logoTrailLength', 0.5),
      logoTrailScale: _readDouble(map, 'logoTrailScale', 0.1),
      logoTrailInitialScale: _readDouble(map, 'logoTrailInitialScale', 0.92),
      flatTextProximity: _readDouble(map, 'flatTextProximity', 0.0),
      flatTextPlacement: _readString(map, 'flatTextPlacement', 'below'),
      bannerResolution: _readDouble(map, 'bannerResolution', 2.0),
      bannerPixelSnap: _readBool(map, 'bannerPixelSnap', true),
      autoTextSpacing: _readBool(map, 'autoTextSpacing', false),
      autoRingSpacing: _readBool(map, 'autoRingSpacing', true),
      bannerLetterSpacing: _readDouble(map, 'bannerLetterSpacing', 1.02),
      bannerWordSpacing: _readDouble(map, 'bannerWordSpacing', 0.4),
      trackLetterSpacing: _readDouble(map, 'trackLetterSpacing', 1.02),
      trackWordSpacing: _readDouble(map, 'trackWordSpacing', 0.4),
      flatLineSpacing: _readDouble(map, 'flatLineSpacing', 1.0),
      audioGraphMode: _readString(map, 'audioGraphMode', 'off'),
      beatDetectorMode: _readString(map, 'beatDetectorMode', 'auto'),
      autocorrBeatVariant: _readString(map, 'autocorrBeatVariant', 'bpm'),
      autocorrLogoVariant: _readString(map, 'autocorrLogoVariant', 'pulse'),
      ekgRadius: _readDouble(map, 'ekgRadius', 1.0),
      ekgReplication: _readInt(map, 'ekgReplication', 1),
      ekgSpread: _readDouble(map, 'ekgSpread', 4.0),
      beatSensitivity: _readDouble(map, 'beatSensitivity', 0.5),
      beatImpact: _readDouble(map, 'beatImpact', 0.4),
      innerRingFontScale: _readDouble(map, 'innerRingFontScale', 1.0),
      middleRingFontScale: _readDouble(map, 'middleRingFontScale', 1.0),
      outerRingFontScale: _readDouble(map, 'outerRingFontScale', 1.0),
      innerRingSpacingMultiplier: _readDouble(
        map,
        'innerRingSpacingMultiplier',
        1.0,
      ),
      middleRingSpacingMultiplier: _readDouble(
        map,
        'middleRingSpacingMultiplier',
        1.0,
      ),
      outerRingSpacingMultiplier: _readDouble(
        map,
        'outerRingSpacingMultiplier',
        1.0,
      ),
      logoAntiAlias: _readBool(map, 'logoAntiAlias', false),
      scaleSource: _readInt(map, 'scaleSource', -1),
      scaleMultiplier: _readDouble(map, 'scaleMultiplier', 1.0),
      scaleSineEnabled: _readBool(map, 'scaleSineEnabled', false),
      scaleSineFreq: _readDouble(map, 'scaleSineFreq', 0.5),
      scaleSineAmp: _readDouble(map, 'scaleSineAmp', 0.2),
      colorSource: _readInt(map, 'colorSource', -1),
      colorMultiplier: _readDouble(map, 'colorMultiplier', 1.0),
      woodstockEveryHour: _readBool(map, 'woodstockEveryHour', true),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flowSpeed': flowSpeed,
      'palette': palette,
      'filmGrain': filmGrain,
      'pulseIntensity': pulseIntensity,
      'heatDrift': heatDrift,
      'logoScale': logoScale,
      'translationSmoothing': translationSmoothing,
      'blurAmount': blurAmount,
      'flatColor': flatColor,
      'bannerGlow': bannerGlow,
      'bannerFlicker': bannerFlicker,
      'bannerGlowBlur': bannerGlowBlur,
      'enableAudioReactivity': enableAudioReactivity,
      'logoTrailDynamic': logoTrailDynamic,
      'performanceLevel': performanceLevel,
      'showInfoBanner': showInfoBanner,
      'bannerText': bannerText,
      'venue': venue,
      'date': date,
      'trackHintId': trackHintId,
      'trackHintTitle': trackHintTitle,
      'trackHintVariant': trackHintVariant,
      'trackHintSeedSource': trackHintSeedSource,
      'paletteCycle': paletteCycle,
      'paletteTransitionSpeed': paletteTransitionSpeed,
      'innerRingScale': innerRingScale,
      'innerToMiddleGap': innerToMiddleGap,
      'middleToOuterGap': middleToOuterGap,
      'orbitDrift': orbitDrift,
      'bannerDisplayMode': bannerDisplayMode,
      'bannerFont': bannerFont,
      'logoTrailIntensity': logoTrailIntensity,
      'logoTrailSlices': logoTrailSlices,
      'logoTrailLength': logoTrailLength,
      'logoTrailScale': logoTrailScale,
      'logoTrailInitialScale': logoTrailInitialScale,
      'flatTextProximity': flatTextProximity,
      'flatTextPlacement': flatTextPlacement,
      'bannerResolution': bannerResolution,
      'bannerPixelSnap': bannerPixelSnap,
      'autoTextSpacing': autoTextSpacing,
      'autoRingSpacing': autoRingSpacing,
      'bannerLetterSpacing': bannerLetterSpacing,
      'bannerWordSpacing': bannerWordSpacing,
      'trackLetterSpacing': trackLetterSpacing,
      'trackWordSpacing': trackWordSpacing,
      'flatLineSpacing': flatLineSpacing,
      'audioGraphMode': audioGraphMode,
      'beatDetectorMode': beatDetectorMode,
      'autocorrBeatVariant': autocorrBeatVariant,
      'autocorrLogoVariant': autocorrLogoVariant,
      'ekgRadius': ekgRadius,
      'ekgReplication': ekgReplication,
      'beatSensitivity': beatSensitivity,
      'beatImpact': beatImpact,
      'innerRingFontScale': innerRingFontScale,
      'middleRingFontScale': middleRingFontScale,
      'outerRingFontScale': outerRingFontScale,
      'innerRingSpacingMultiplier': innerRingSpacingMultiplier,
      'middleRingSpacingMultiplier': middleRingSpacingMultiplier,
      'outerRingSpacingMultiplier': outerRingSpacingMultiplier,
      'logoAntiAlias': logoAntiAlias,
      'scaleSource': scaleSource,
      'scaleMultiplier': scaleMultiplier,
      'scaleSineEnabled': scaleSineEnabled,
      'scaleSineFreq': scaleSineFreq,
      'scaleSineAmp': scaleSineAmp,
      'colorSource': colorSource,
      'colorMultiplier': colorMultiplier,
      'woodstockEveryHour': woodstockEveryHour,
    };
  }

  StealConfig copyWith({
    double? flowSpeed,
    String? palette,
    double? filmGrain,
    double? pulseIntensity,
    double? heatDrift,
    double? logoScale,
    double? translationSmoothing,
    double? blurAmount,
    bool? flatColor,
    bool? bannerGlow,
    double? bannerFlicker,
    double? bannerGlowBlur,
    bool? enableAudioReactivity,
    bool? logoTrailDynamic,
    int? performanceLevel,
    bool? showInfoBanner,
    String? bannerText,
    String? venue,
    String? date,
    String? trackHintId,
    String? trackHintTitle,
    String? trackHintVariant,
    String? trackHintSeedSource,
    bool? paletteCycle,
    double? paletteTransitionSpeed,
    double? innerRingScale,
    double? innerToMiddleGap,
    double? middleToOuterGap,
    double? orbitDrift,
    String? bannerDisplayMode,
    String? bannerFont,
    double? logoTrailIntensity,
    int? logoTrailSlices,
    double? logoTrailLength,
    double? logoTrailScale,
    double? logoTrailInitialScale,
    double? flatTextProximity,
    String? flatTextPlacement,
    double? bannerResolution,
    bool? bannerPixelSnap,
    bool? autoTextSpacing,
    bool? autoRingSpacing,
    double? bannerLetterSpacing,
    double? bannerWordSpacing,
    double? trackLetterSpacing,
    double? trackWordSpacing,
    double? flatLineSpacing,
    String? audioGraphMode,
    String? beatDetectorMode,
    String? autocorrBeatVariant,
    String? autocorrLogoVariant,
    double? ekgRadius,
    int? ekgReplication,
    double? ekgSpread,
    double? beatSensitivity,
    double? beatImpact,
    double? innerRingFontScale,
    double? middleRingFontScale,
    double? outerRingFontScale,
    double? innerRingSpacingMultiplier,
    double? middleRingSpacingMultiplier,
    double? outerRingSpacingMultiplier,
    bool? logoAntiAlias,
    int? scaleSource,
    double? scaleMultiplier,
    bool? scaleSineEnabled,
    double? scaleSineFreq,
    double? scaleSineAmp,
    int? colorSource,
    double? colorMultiplier,
    bool? woodstockEveryHour,
  }) {
    return StealConfig(
      flowSpeed: flowSpeed ?? this.flowSpeed,
      palette: palette ?? this.palette,
      filmGrain: filmGrain ?? this.filmGrain,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      heatDrift: heatDrift ?? this.heatDrift,
      logoScale: logoScale ?? this.logoScale,
      translationSmoothing: translationSmoothing ?? this.translationSmoothing,
      blurAmount: blurAmount ?? this.blurAmount,
      flatColor: flatColor ?? this.flatColor,
      bannerGlow: bannerGlow ?? this.bannerGlow,
      bannerFlicker: bannerFlicker ?? this.bannerFlicker,
      bannerGlowBlur: bannerGlowBlur ?? this.bannerGlowBlur,
      enableAudioReactivity:
          enableAudioReactivity ?? this.enableAudioReactivity,
      logoTrailDynamic: logoTrailDynamic ?? this.logoTrailDynamic,
      performanceLevel: performanceLevel ?? this.performanceLevel,
      showInfoBanner: showInfoBanner ?? this.showInfoBanner,
      bannerText: bannerText ?? this.bannerText,
      venue: venue ?? this.venue,
      date: date ?? this.date,
      trackHintId: trackHintId ?? this.trackHintId,
      trackHintTitle: trackHintTitle ?? this.trackHintTitle,
      trackHintVariant: trackHintVariant ?? this.trackHintVariant,
      trackHintSeedSource: trackHintSeedSource ?? this.trackHintSeedSource,
      paletteCycle: paletteCycle ?? this.paletteCycle,
      paletteTransitionSpeed:
          paletteTransitionSpeed ?? this.paletteTransitionSpeed,
      innerRingScale: innerRingScale ?? this.innerRingScale,
      innerToMiddleGap: innerToMiddleGap ?? this.innerToMiddleGap,
      middleToOuterGap: middleToOuterGap ?? this.middleToOuterGap,
      orbitDrift: orbitDrift ?? this.orbitDrift,
      bannerDisplayMode: bannerDisplayMode ?? this.bannerDisplayMode,
      bannerFont: bannerFont ?? this.bannerFont,
      logoTrailIntensity: logoTrailIntensity ?? this.logoTrailIntensity,
      logoTrailSlices: logoTrailSlices ?? this.logoTrailSlices,
      logoTrailLength: logoTrailLength ?? this.logoTrailLength,
      logoTrailScale: logoTrailScale ?? this.logoTrailScale,
      logoTrailInitialScale:
          logoTrailInitialScale ?? this.logoTrailInitialScale,
      flatTextProximity: flatTextProximity ?? this.flatTextProximity,
      flatTextPlacement: flatTextPlacement ?? this.flatTextPlacement,
      bannerResolution: bannerResolution ?? this.bannerResolution,
      bannerPixelSnap: bannerPixelSnap ?? this.bannerPixelSnap,
      autoTextSpacing: autoTextSpacing ?? this.autoTextSpacing,
      autoRingSpacing: autoRingSpacing ?? this.autoRingSpacing,
      bannerLetterSpacing: bannerLetterSpacing ?? this.bannerLetterSpacing,
      bannerWordSpacing: bannerWordSpacing ?? this.bannerWordSpacing,
      trackLetterSpacing: trackLetterSpacing ?? this.trackLetterSpacing,
      trackWordSpacing: trackWordSpacing ?? this.trackWordSpacing,
      flatLineSpacing: flatLineSpacing ?? this.flatLineSpacing,
      audioGraphMode: audioGraphMode ?? this.audioGraphMode,
      beatDetectorMode: beatDetectorMode ?? this.beatDetectorMode,
      autocorrBeatVariant: autocorrBeatVariant ?? this.autocorrBeatVariant,
      autocorrLogoVariant: autocorrLogoVariant ?? this.autocorrLogoVariant,
      ekgRadius: ekgRadius ?? this.ekgRadius,
      ekgReplication: ekgReplication ?? this.ekgReplication,
      ekgSpread: ekgSpread ?? this.ekgSpread,
      beatSensitivity: beatSensitivity ?? this.beatSensitivity,
      beatImpact: beatImpact ?? this.beatImpact,
      innerRingFontScale: innerRingFontScale ?? this.innerRingFontScale,
      middleRingFontScale: middleRingFontScale ?? this.middleRingFontScale,
      outerRingFontScale: outerRingFontScale ?? this.outerRingFontScale,
      innerRingSpacingMultiplier:
          innerRingSpacingMultiplier ?? this.innerRingSpacingMultiplier,
      middleRingSpacingMultiplier:
          middleRingSpacingMultiplier ?? this.middleRingSpacingMultiplier,
      outerRingSpacingMultiplier:
          outerRingSpacingMultiplier ?? this.outerRingSpacingMultiplier,
      logoAntiAlias: logoAntiAlias ?? this.logoAntiAlias,
      scaleSource: scaleSource ?? this.scaleSource,
      scaleMultiplier: scaleMultiplier ?? this.scaleMultiplier,
      scaleSineEnabled: scaleSineEnabled ?? this.scaleSineEnabled,
      scaleSineFreq: scaleSineFreq ?? this.scaleSineFreq,
      scaleSineAmp: scaleSineAmp ?? this.scaleSineAmp,
      colorSource: colorSource ?? this.colorSource,
      colorMultiplier: colorMultiplier ?? this.colorMultiplier,
      woodstockEveryHour: woodstockEveryHour ?? this.woodstockEveryHour,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! StealConfig) return false;
    return flowSpeed == other.flowSpeed &&
        palette == other.palette &&
        filmGrain == other.filmGrain &&
        pulseIntensity == other.pulseIntensity &&
        heatDrift == other.heatDrift &&
        logoScale == other.logoScale &&
        translationSmoothing == other.translationSmoothing &&
        blurAmount == other.blurAmount &&
        flatColor == other.flatColor &&
        bannerGlow == other.bannerGlow &&
        bannerFlicker == other.bannerFlicker &&
        bannerGlowBlur == other.bannerGlowBlur &&
        enableAudioReactivity == other.enableAudioReactivity &&
        logoTrailDynamic == other.logoTrailDynamic &&
        performanceLevel == other.performanceLevel &&
        showInfoBanner == other.showInfoBanner &&
        bannerText == other.bannerText &&
        venue == other.venue &&
        date == other.date &&
        trackHintId == other.trackHintId &&
        trackHintTitle == other.trackHintTitle &&
        trackHintVariant == other.trackHintVariant &&
        trackHintSeedSource == other.trackHintSeedSource &&
        paletteCycle == other.paletteCycle &&
        paletteTransitionSpeed == other.paletteTransitionSpeed &&
        innerRingScale == other.innerRingScale &&
        innerToMiddleGap == other.innerToMiddleGap &&
        middleToOuterGap == other.middleToOuterGap &&
        orbitDrift == other.orbitDrift &&
        bannerDisplayMode == other.bannerDisplayMode &&
        bannerFont == other.bannerFont &&
        logoTrailIntensity == other.logoTrailIntensity &&
        logoTrailSlices == other.logoTrailSlices &&
        logoTrailLength == other.logoTrailLength &&
        logoTrailScale == other.logoTrailScale &&
        logoTrailInitialScale == other.logoTrailInitialScale &&
        flatTextProximity == other.flatTextProximity &&
        flatTextPlacement == other.flatTextPlacement &&
        bannerResolution == other.bannerResolution &&
        bannerPixelSnap == other.bannerPixelSnap &&
        autoTextSpacing == other.autoTextSpacing &&
        autoRingSpacing == other.autoRingSpacing &&
        bannerLetterSpacing == other.bannerLetterSpacing &&
        bannerWordSpacing == other.bannerWordSpacing &&
        trackLetterSpacing == other.trackLetterSpacing &&
        trackWordSpacing == other.trackWordSpacing &&
        flatLineSpacing == other.flatLineSpacing &&
        audioGraphMode == other.audioGraphMode &&
        beatDetectorMode == other.beatDetectorMode &&
        autocorrBeatVariant == other.autocorrBeatVariant &&
        autocorrLogoVariant == other.autocorrLogoVariant &&
        ekgRadius == other.ekgRadius &&
        ekgReplication == other.ekgReplication &&
        ekgSpread == other.ekgSpread &&
        beatSensitivity == other.beatSensitivity &&
        beatImpact == other.beatImpact &&
        innerRingFontScale == other.innerRingFontScale &&
        middleRingFontScale == other.middleRingFontScale &&
        outerRingFontScale == other.outerRingFontScale &&
        innerRingSpacingMultiplier == other.innerRingSpacingMultiplier &&
        middleRingSpacingMultiplier == other.middleRingSpacingMultiplier &&
        outerRingSpacingMultiplier == other.outerRingSpacingMultiplier &&
        logoAntiAlias == other.logoAntiAlias &&
        scaleSource == other.scaleSource &&
        scaleMultiplier == other.scaleMultiplier &&
        scaleSineEnabled == other.scaleSineEnabled &&
        scaleSineFreq == other.scaleSineFreq &&
        scaleSineAmp == other.scaleSineAmp &&
        colorSource == other.colorSource &&
        colorMultiplier == other.colorMultiplier &&
        woodstockEveryHour == other.woodstockEveryHour;
  }

  @override
  int get hashCode => Object.hashAll([
    flowSpeed,
    palette,
    filmGrain,
    pulseIntensity,
    heatDrift,
    logoScale,
    translationSmoothing,
    blurAmount,
    flatColor,
    bannerGlow,
    bannerFlicker,
    bannerGlowBlur,
    enableAudioReactivity,
    logoTrailDynamic,
    performanceLevel,
    showInfoBanner,
    bannerText,
    venue,
    date,
    trackHintId,
    trackHintTitle,
    trackHintVariant,
    trackHintSeedSource,
    paletteCycle,
    paletteTransitionSpeed,
    innerRingScale,
    innerToMiddleGap,
    middleToOuterGap,
    orbitDrift,
    bannerDisplayMode,
    bannerFont,
    logoTrailIntensity,
    logoTrailSlices,
    logoTrailLength,
    logoTrailScale,
    logoTrailInitialScale,
    flatTextProximity,
    flatTextPlacement,
    bannerResolution,
    bannerPixelSnap,
    autoTextSpacing,
    autoRingSpacing,
    bannerLetterSpacing,
    bannerWordSpacing,
    trackLetterSpacing,
    trackWordSpacing,
    flatLineSpacing,
    audioGraphMode,
    beatDetectorMode,
    autocorrBeatVariant,
    autocorrLogoVariant,
    ekgRadius,
    ekgReplication,
    ekgSpread,
    beatSensitivity,
    beatImpact,
    innerRingFontScale,
    middleRingFontScale,
    outerRingFontScale,
    innerRingSpacingMultiplier,
    middleRingSpacingMultiplier,
    outerRingSpacingMultiplier,
    logoAntiAlias,
    scaleSource,
    scaleMultiplier,
    scaleSineEnabled,
    scaleSineFreq,
    scaleSineAmp,
    colorSource,
    colorMultiplier,
    woodstockEveryHour,
  ]);
}
