import 'package:flutter/material.dart';

/// Configuration for the Steal Your Face screensaver.
class StealConfig {
  final double flowSpeed;
  final String palette;
  final double filmGrain;
  final double pulseIntensity;
  final double heatDrift;
  final bool enableAudioReactivity;
  final bool performanceMode;

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
    this.enableAudioReactivity = true,
    this.performanceMode = false,
  });

  factory StealConfig.fromMap(Map<String, dynamic> map) {
    return StealConfig(
      flowSpeed: (map['flowSpeed'] as num?)?.toDouble() ?? 0.4,
      palette: map['palette'] as String? ?? 'psychedelic',
      filmGrain: (map['filmGrain'] as num?)?.toDouble() ?? 0.1,
      pulseIntensity: (map['pulseIntensity'] as num?)?.toDouble() ?? 0.5,
      heatDrift: (map['heatDrift'] as num?)?.toDouble() ?? 0.2,
      enableAudioReactivity: map['enableAudioReactivity'] as bool? ?? true,
      performanceMode: map['performanceMode'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'flowSpeed': flowSpeed,
      'palette': palette,
      'filmGrain': filmGrain,
      'pulseIntensity': pulseIntensity,
      'heatDrift': heatDrift,
      'enableAudioReactivity': enableAudioReactivity,
      'performanceMode': performanceMode,
    };
  }

  StealConfig copyWith({
    double? flowSpeed,
    String? palette,
    double? filmGrain,
    double? pulseIntensity,
    double? heatDrift,
    bool? enableAudioReactivity,
    bool? performanceMode,
  }) {
    return StealConfig(
      flowSpeed: flowSpeed ?? this.flowSpeed,
      palette: palette ?? this.palette,
      filmGrain: filmGrain ?? this.filmGrain,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      heatDrift: heatDrift ?? this.heatDrift,
      enableAudioReactivity:
          enableAudioReactivity ?? this.enableAudioReactivity,
      performanceMode: performanceMode ?? this.performanceMode,
    );
  }
}
