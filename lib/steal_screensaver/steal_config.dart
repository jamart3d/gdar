import 'package:flutter/material.dart';

/// Configuration for the Steal Your Face screensaver.
class StealConfig {
  final double flowSpeed;
  final String palette;
  final double pulseIntensity;
  final double heatDrift;
  final double logoScale;
  final bool enableAudioReactivity;
  final bool performanceMode;
  final bool showInfoBanner;
  final String bannerText;
  final String venue;
  final String date;
  final bool paletteCycle;
  final double paletteTransitionSpeed;

  static const Map<String, List<Color>> palettes = {
    'white': [Color(0xFFFFFFFF)],
    'red': [Color(0xFFFF0000)],
    'green': [Color(0xFF00FF00)],
    'blue': [Color(0xFF0000FF)],
    'cmyk': [
      Color(0xFF00FFFF),
      Color(0xFFFF00FF),
      Color(0xFFFFFF00),
      Color(0xFF111111),
    ],
    'rgb': [
      Color(0xFFFF0000),
      Color(0xFF00FF00),
      Color(0xFF0000FF),
    ],
  };

  const StealConfig({
    this.flowSpeed = 0.4,
    this.palette = 'white',
    this.pulseIntensity = 0.5,
    this.heatDrift = 0.2,
    this.logoScale = 1.0,
    this.enableAudioReactivity = true,
    this.performanceMode = false,
    this.showInfoBanner = true,
    this.bannerText = '',
    this.venue = '',
    this.date = '',
    this.paletteCycle = false,
    this.paletteTransitionSpeed = 5.0,
  });

  factory StealConfig.fromMap(Map<String, dynamic> map) {
    return StealConfig(
      flowSpeed: (map['flowSpeed'] as num?)?.toDouble() ?? 0.4,
      palette: map['palette'] as String? ?? 'white',
      pulseIntensity: (map['pulseIntensity'] as num?)?.toDouble() ?? 0.5,
      heatDrift: (map['heatDrift'] as num?)?.toDouble() ?? 0.2,
      logoScale: (map['logoScale'] as num?)?.toDouble() ?? 1.0,
      enableAudioReactivity: map['enableAudioReactivity'] as bool? ?? true,
      performanceMode: map['performanceMode'] as bool? ?? false,
      showInfoBanner: map['showInfoBanner'] as bool? ?? true,
      bannerText: map['bannerText'] as String? ?? '',
      venue: map['venue'] as String? ?? '',
      date: map['date'] as String? ?? '',
      paletteCycle: map['paletteCycle'] as bool? ?? false,
      paletteTransitionSpeed:
          (map['paletteTransitionSpeed'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flowSpeed': flowSpeed,
      'palette': palette,
      'pulseIntensity': pulseIntensity,
      'heatDrift': heatDrift,
      'logoScale': logoScale,
      'enableAudioReactivity': enableAudioReactivity,
      'performanceMode': performanceMode,
      'showInfoBanner': showInfoBanner,
      'bannerText': bannerText,
      'venue': venue,
      'date': date,
      'paletteCycle': paletteCycle,
      'paletteTransitionSpeed': paletteTransitionSpeed,
    };
  }

  StealConfig copyWith({
    double? flowSpeed,
    String? palette,
    double? pulseIntensity,
    double? heatDrift,
    double? logoScale,
    bool? enableAudioReactivity,
    bool? performanceMode,
    bool? showInfoBanner,
    String? bannerText,
    String? venue,
    String? date,
    bool? paletteCycle,
    double? paletteTransitionSpeed,
  }) {
    return StealConfig(
      flowSpeed: flowSpeed ?? this.flowSpeed,
      palette: palette ?? this.palette,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      heatDrift: heatDrift ?? this.heatDrift,
      logoScale: logoScale ?? this.logoScale,
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
    );
  }
}
