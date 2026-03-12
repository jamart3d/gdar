import 'package:flutter/material.dart';

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
  final bool paletteCycle;
  final double paletteTransitionSpeed;
  final double innerRingScale;
  final double innerToMiddleGap;
  final double middleToOuterGap;
  final double orbitDrift;
  final String bannerDisplayMode; // 'ring' or 'flat'
  final String bannerFont; // e.g. 'Rock Salt' or 'Roboto'
  final double logoTrailIntensity; // 0.0 = off, 1.0 = full
  final int logoTrailSlices; // 2–16 ghost copies
  final double logoTrailLength; // 0.0–1.0 spacing between snapshots
  final double logoTrailScale; // 0.0–1.0 shrinkage per snapshot
  final double logoTrailInitialScale; // 0.5–2.0 base scaling from logo
  /// Flat mode: 0.0 = default gap (text just below visual edge),
  /// 1.0 = text at logo center (fully overlapping).
  final double flatTextProximity;

  /// Multiplier for text rasterization resolution (supersampling).
  /// 1.0 = native, 2.0 = double resolution (sharper), etc.
  final double bannerResolution;
  final bool bannerPixelSnap;

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

  /// Font size multiplier for the inner (date) ring.
  /// 1.0 = same as other rings, <1.0 = smaller text to fit tighter arcs.
  final double innerRingFontScale;

  /// Spacing multiplier for the inner (date) ring.
  /// Applied on top of bannerLetterSpacing/bannerWordSpacing.
  /// 1.0 = same as other rings, <1.0 = tighter spacing.
  final double innerRingSpacingMultiplier;

  /// Whether to apply fwidth-based anti-aliasing on the logo alpha edge.
  final bool logoAntiAlias;

  /// Source for logo scale reactivity (-1 = overall, 0-7 = bands).
  final int scaleSource;
  final double scaleMultiplier;

  /// Whether to add a sine wave drive to the logo scale.
  final bool scaleSineEnabled;

  /// Frequency of the logo scale sine wave in Hz.
  final double scaleSineFreq;

  /// Amplitude of the logo scale sine wave (0.0 to 1.0).
  final double scaleSineAmp;

  /// Source for logo color reactivity (-1 = overall, 0-7 = bands).
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
    this.paletteCycle = true,
    this.paletteTransitionSpeed = 5.0,
    this.innerRingScale = 1.0,
    this.innerToMiddleGap = 0.3,
    this.middleToOuterGap = 0.3,
    this.orbitDrift = 1.0,
    this.bannerDisplayMode = 'ring',
    this.bannerFont = 'Rock Salt',
    this.logoTrailIntensity = 0.0,
    this.logoTrailSlices = 6,
    this.logoTrailLength = 0.5,
    this.logoTrailScale = 0.1,
    this.logoTrailInitialScale = 0.92,
    this.flatTextProximity = 0.0,
    this.flatTextPlacement = 'below',
    this.bannerResolution = 2.0,
    this.bannerPixelSnap = true,
    this.bannerLetterSpacing = 1.02,
    this.bannerWordSpacing = 0.4,
    this.trackLetterSpacing = 1.02,
    this.trackWordSpacing = 0.4,
    this.flatLineSpacing = 1.0,
    this.audioGraphMode = 'off',
    this.ekgRadius = 1.0,
    this.ekgReplication = 1,
    this.ekgSpread = 4.0,
    this.beatSensitivity = 0.5,
    this.beatImpact = 0.4,
    this.innerRingFontScale = 1.0,
    this.innerRingSpacingMultiplier = 1.0,
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
      flowSpeed: (map['flowSpeed'] as num?)?.toDouble() ?? 0.1,
      palette: map['palette'] as String? ?? 'psychedelic',
      filmGrain: (map['filmGrain'] as num?)?.toDouble() ?? 0.1,
      pulseIntensity: (map['pulseIntensity'] as num?)?.toDouble() ?? 0.5,
      heatDrift: (map['heatDrift'] as num?)?.toDouble() ?? 0.2,
      logoScale: (map['logoScale'] as num?)?.toDouble() ?? 0.5,
      translationSmoothing:
          (map['translationSmoothing'] as num?)?.toDouble() ?? 0.7,
      blurAmount: (map['blurAmount'] as num?)?.toDouble() ?? 0.0,
      flatColor: map['flatColor'] as bool? ?? false,
      bannerGlow: map['bannerGlow'] as bool? ?? false,
      bannerFlicker: (map['bannerFlicker'] as num?)?.toDouble() ?? 0.0,
      bannerGlowBlur: (map['bannerGlowBlur'] as num?)?.toDouble() ?? 0.5,
      enableAudioReactivity: map['enableAudioReactivity'] as bool? ?? true,
      logoTrailDynamic: map['logoTrailDynamic'] as bool? ?? true,
      performanceLevel: (map['performanceLevel'] as int?) ??
          ((map['performanceMode'] as bool? ?? false) ? 2 : 0),
      showInfoBanner: map['showInfoBanner'] as bool? ?? true,
      bannerText: map['bannerText'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      date: map['date'] as String? ?? '',
      paletteCycle: map['paletteCycle'] as bool? ?? true,
      paletteTransitionSpeed:
          (map['paletteTransitionSpeed'] as num?)?.toDouble() ?? 5.0,
      innerRingScale: (map['innerRingScale'] as num?)?.toDouble() ?? 1.0,
      innerToMiddleGap: (map['innerToMiddleGap'] as num?)?.toDouble() ?? 0.3,
      middleToOuterGap: (map['middleToOuterGap'] as num?)?.toDouble() ?? 0.3,
      orbitDrift: (map['orbitDrift'] as num?)?.toDouble() ?? 1.0,
      bannerDisplayMode: map['bannerDisplayMode'] as String? ?? 'ring',
      bannerFont: map['bannerFont'] as String? ?? 'Rock Salt',
      logoTrailIntensity:
          (map['logoTrailIntensity'] as num?)?.toDouble() ?? 0.0,
      logoTrailSlices: (map['logoTrailSlices'] as int?) ?? 6,
      logoTrailLength: (map['logoTrailLength'] as num?)?.toDouble() ?? 0.5,
      logoTrailScale: (map['logoTrailScale'] as num?)?.toDouble() ?? 0.1,
      logoTrailInitialScale:
          (map['logoTrailInitialScale'] as num?)?.toDouble() ?? 0.92,
      flatTextProximity: (map['flatTextProximity'] as num?)?.toDouble() ?? 0.0,
      flatTextPlacement: map['flatTextPlacement'] as String? ?? 'below',
      bannerResolution: (map['bannerResolution'] as num?)?.toDouble() ?? 2.0,
      bannerPixelSnap: map['bannerPixelSnap'] as bool? ?? true,
      bannerLetterSpacing:
          (map['bannerLetterSpacing'] as num?)?.toDouble() ?? 1.02,
      bannerWordSpacing: (map['bannerWordSpacing'] as num?)?.toDouble() ?? 0.4,
      trackLetterSpacing:
          (map['trackLetterSpacing'] as num?)?.toDouble() ?? 1.02,
      trackWordSpacing: (map['trackWordSpacing'] as num?)?.toDouble() ?? 0.4,
      flatLineSpacing: (map['flatLineSpacing'] as num?)?.toDouble() ?? 1.0,
      audioGraphMode: map['audioGraphMode'] as String? ?? 'off',
      ekgRadius: (map['ekgRadius'] as num?)?.toDouble() ?? 1.0,
      ekgReplication: (map['ekgReplication'] as int?) ?? 1,
      ekgSpread: (map['ekgSpread'] as num?)?.toDouble() ?? 4.0,
      beatSensitivity: (map['beatSensitivity'] as num?)?.toDouble() ?? 0.5,
      beatImpact: (map['beatImpact'] as num?)?.toDouble() ?? 0.4,
      innerRingFontScale:
          (map['innerRingFontScale'] as num?)?.toDouble() ?? 1.0,
      innerRingSpacingMultiplier:
          (map['innerRingSpacingMultiplier'] as num?)?.toDouble() ?? 1.0,
      logoAntiAlias: map['logoAntiAlias'] as bool? ?? false,
      scaleSource: map['scaleSource'] as int? ?? -1,
      scaleMultiplier: (map['scaleMultiplier'] as num?)?.toDouble() ?? 1.0,
      scaleSineEnabled: map['scaleSineEnabled'] as bool? ?? false,
      scaleSineFreq: (map['scaleSineFreq'] as num?)?.toDouble() ?? 0.5,
      scaleSineAmp: (map['scaleSineAmp'] as num?)?.toDouble() ?? 0.2,
      colorSource: map['colorSource'] as int? ?? -1,
      colorMultiplier: (map['colorMultiplier'] as num?)?.toDouble() ?? 1.0,
      woodstockEveryHour: map['woodstockEveryHour'] as bool? ?? true,
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
      'bannerLetterSpacing': bannerLetterSpacing,
      'bannerWordSpacing': bannerWordSpacing,
      'trackLetterSpacing': trackLetterSpacing,
      'trackWordSpacing': trackWordSpacing,
      'flatLineSpacing': flatLineSpacing,
      'audioGraphMode': audioGraphMode,
      'ekgRadius': ekgRadius,
      'ekgReplication': ekgReplication,
      'beatSensitivity': beatSensitivity,
      'beatImpact': beatImpact,
      'innerRingFontScale': innerRingFontScale,
      'innerRingSpacingMultiplier': innerRingSpacingMultiplier,
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
    double? bannerLetterSpacing,
    double? bannerWordSpacing,
    double? trackLetterSpacing,
    double? trackWordSpacing,
    double? flatLineSpacing,
    String? audioGraphMode,
    double? ekgRadius,
    int? ekgReplication,
    double? ekgSpread,
    double? beatSensitivity,
    double? beatImpact,
    double? innerRingFontScale,
    double? innerRingSpacingMultiplier,
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
      bannerLetterSpacing: bannerLetterSpacing ?? this.bannerLetterSpacing,
      bannerWordSpacing: bannerWordSpacing ?? this.bannerWordSpacing,
      trackLetterSpacing: trackLetterSpacing ?? this.trackLetterSpacing,
      trackWordSpacing: trackWordSpacing ?? this.trackWordSpacing,
      flatLineSpacing: flatLineSpacing ?? this.flatLineSpacing,
      audioGraphMode: audioGraphMode ?? this.audioGraphMode,
      ekgRadius: ekgRadius ?? this.ekgRadius,
      ekgReplication: ekgReplication ?? this.ekgReplication,
      ekgSpread: ekgSpread ?? this.ekgSpread,
      beatSensitivity: beatSensitivity ?? this.beatSensitivity,
      beatImpact: beatImpact ?? this.beatImpact,
      innerRingFontScale: innerRingFontScale ?? this.innerRingFontScale,
      innerRingSpacingMultiplier:
          innerRingSpacingMultiplier ?? this.innerRingSpacingMultiplier,
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
        bannerLetterSpacing == other.bannerLetterSpacing &&
        bannerWordSpacing == other.bannerWordSpacing &&
        trackLetterSpacing == other.trackLetterSpacing &&
        trackWordSpacing == other.trackWordSpacing &&
        flatLineSpacing == other.flatLineSpacing &&
        audioGraphMode == other.audioGraphMode &&
        ekgRadius == other.ekgRadius &&
        ekgReplication == other.ekgReplication &&
        ekgSpread == other.ekgSpread &&
        beatSensitivity == other.beatSensitivity &&
        beatImpact == other.beatImpact &&
        innerRingFontScale == other.innerRingFontScale &&
        innerRingSpacingMultiplier == other.innerRingSpacingMultiplier &&
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
        bannerLetterSpacing,
        bannerWordSpacing,
        trackLetterSpacing,
        trackWordSpacing,
        flatLineSpacing,
        audioGraphMode,
        ekgRadius,
        ekgReplication,
        ekgSpread,
        beatSensitivity,
        beatImpact,
        innerRingFontScale,
        innerRingSpacingMultiplier,
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
