import 'package:flutter/material.dart';

/// Configuration for the Steal Your Face screensaver.
class StealConfig {
  final double flowSpeed;
  final String palette;
  final double filmGrain;
  final double pulseIntensity;
  final double heatDrift;
  final double logoScale;
  final double blurAmount; // 0.0 = sharp, 1.0 = soft
  final bool flatColor; // true = static palette color, no animation
  final bool bannerGlow; // true = triple-layer neon glow on rings
  final double bannerFlicker; // 0.0 = steady, 1.0 = heavy neon buzz
  final bool enableAudioReactivity;
  final bool performanceMode;
  final bool showInfoBanner;
  final String bannerText; // inner ring: track title
  final String venue; // outer ring: venue
  final String date; // outer ring: date
  final bool paletteCycle;
  final double paletteTransitionSpeed;
  final double outerRingScale; // 1.0 = default outer radius
  final double innerRingScale; // 1.0 = default inner radius
  final double ringGap; // 0.0 = default separation, >0 pushes rings apart
  final double orbitDrift; // 1.0 = default drift amplitude

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
    this.flowSpeed = 0.4,
    this.palette = 'psychedelic',
    this.filmGrain = 0.1,
    this.pulseIntensity = 0.5,
    this.heatDrift = 0.2,
    this.logoScale = 1.0,
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
    this.paletteCycle = false,
    this.paletteTransitionSpeed = 5.0,
    this.outerRingScale = 1.0,
    this.innerRingScale = 1.0,
    this.ringGap = 0.0,
    this.orbitDrift = 1.0,
  });

  factory StealConfig.fromMap(Map<String, dynamic> map) {
    return StealConfig(
      flowSpeed: (map['flowSpeed'] as num?)?.toDouble() ?? 0.4,
      palette: map['palette'] as String? ?? 'psychedelic',
      filmGrain: (map['filmGrain'] as num?)?.toDouble() ?? 0.1,
      pulseIntensity: (map['pulseIntensity'] as num?)?.toDouble() ?? 0.5,
      heatDrift: (map['heatDrift'] as num?)?.toDouble() ?? 0.2,
      logoScale: (map['logoScale'] as num?)?.toDouble() ?? 1.0,
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
      paletteCycle: map['paletteCycle'] as bool? ?? false,
      paletteTransitionSpeed:
          (map['paletteTransitionSpeed'] as num?)?.toDouble() ?? 5.0,
      outerRingScale: (map['outerRingScale'] as num?)?.toDouble() ?? 1.0,
      innerRingScale: (map['innerRingScale'] as num?)?.toDouble() ?? 1.0,
      ringGap: (map['ringGap'] as num?)?.toDouble() ?? 0.0,
      orbitDrift: (map['orbitDrift'] as num?)?.toDouble() ?? 1.0,
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
      'outerRingScale': outerRingScale,
      'innerRingScale': innerRingScale,
      'ringGap': ringGap,
      'orbitDrift': orbitDrift,
    };
  }

  StealConfig copyWith({
    double? flowSpeed,
    String? palette,
    double? filmGrain,
    double? pulseIntensity,
    double? heatDrift,
    double? logoScale,
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
    double? outerRingScale,
    double? innerRingScale,
    double? ringGap,
    double? orbitDrift,
  }) {
    return StealConfig(
      flowSpeed: flowSpeed ?? this.flowSpeed,
      palette: palette ?? this.palette,
      filmGrain: filmGrain ?? this.filmGrain,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      heatDrift: heatDrift ?? this.heatDrift,
      logoScale: logoScale ?? this.logoScale,
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
      outerRingScale: outerRingScale ?? this.outerRingScale,
      innerRingScale: innerRingScale ?? this.innerRingScale,
      ringGap: ringGap ?? this.ringGap,
      orbitDrift: orbitDrift ?? this.orbitDrift,
    );
  }
}
