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
  final bool enableAudioReactivity;
  final bool performanceMode;
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
  };

  const StealConfig({
    this.flowSpeed = 0.1,
    this.palette = 'psychedelic',
    this.filmGrain = 0.1,
    this.pulseIntensity = 0.5,
    this.heatDrift = 0.2,
    this.logoScale = 0.5,
    this.translationSmoothing = 0.3,
    this.blurAmount = 0.0,
    this.flatColor = false,
    this.bannerGlow = false,
    this.bannerFlicker = 0.0,
    this.enableAudioReactivity = true,
    this.performanceMode = false,
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
          (map['translationSmoothing'] as num?)?.toDouble() ?? 0.3,
      blurAmount: (map['blurAmount'] as num?)?.toDouble() ?? 0.0,
      flatColor: map['flatColor'] as bool? ?? false,
      bannerGlow: map['bannerGlow'] as bool? ?? false,
      bannerFlicker: (map['bannerFlicker'] as num?)?.toDouble() ?? 0.0,
      enableAudioReactivity: map['enableAudioReactivity'] as bool? ?? true,
      performanceMode: map['performanceMode'] as bool? ?? false,
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
      'enableAudioReactivity': enableAudioReactivity,
      'performanceMode': performanceMode,
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
    bool? enableAudioReactivity,
    bool? performanceMode,
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
      enableAudioReactivity:
          enableAudioReactivity ?? this.enableAudioReactivity,
      performanceMode: performanceMode ?? this.performanceMode,
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
        enableAudioReactivity == other.enableAudioReactivity &&
        performanceMode == other.performanceMode &&
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
        bannerDisplayMode == other.bannerDisplayMode;
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
        enableAudioReactivity,
        performanceMode,
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
      ]);
}
