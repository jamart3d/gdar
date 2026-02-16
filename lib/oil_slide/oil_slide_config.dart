/// Configuration for the oil_slide visualizer.
///
/// This class encapsulates all visual and behavioral parameters for the
/// oil_slide effect, making it easy to serialize/deserialize from settings
/// and potentially extract into a standalone package.
library;

import 'package:flutter/material.dart';

class OilSlideConfig {
  final double viscosity;
  final double flowSpeed;
  final String palette;
  final double filmGrain;
  final double pulseIntensity;
  final double heatDrift;
  final int metaballCount;
  final bool enableAudioReactivity;
  final String
      visualMode; // 'lava_lamp', 'silk', 'psychedelic', 'steal', 'custom'
  final bool oilPerformanceMode;

  /// Centralized palette definitions for all visual modes.
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
    'lava_gold': [
      Color(0xFFFF4500),
      Color(0xFFFFD700),
      Color(0xFFFF8C00),
      Color(0xFFFF6347),
    ],
    'lava_classic': [
      Color(0xFF1a0505), // Very Dark Red (Background)
      Color(0xFFd40000), // Vibrant Red
      Color(0xFFFF5500), // Bright Orange
      Color(0xFFFFcc00), // Yellow (Highlights)
    ],
    'purple_haze': [
      Color(0xFF4B0082), // Indigo
      Color(0xFF8B008B), // Dark magenta
      Color(0xFFBA55D3), // Medium orchid
      Color(0xFFDA70D6), // Orchid
    ],
    'ocean': [
      Color(0xFF000080), // Navy
      Color(0xFF0000CD), // Medium blue
      Color(0xFF00CED1), // Dark turquoise
      Color(0xFF40E0D0), // Turquoise
    ],
    'pearl': [
      Color(0xFFe6e2d8), // Champagne / Off-white
      Color(0xFFc7c2b8), // Silver / Grey
      Color(0xFFa69f91), // Darker Champagne shadow
      Color(0xFF8c8577), // Deep shadow
    ],
    'aurora': [
      Color(0xFF00008B), // Dark Blue
      Color(0xFF00FF7F), // Spring Green
      Color(0xFF9400D3), // Dark Violet
      Color(0xFF1E90FF), // Dodger Blue
    ],
    'deep_blue': [
      Color(0xFF0000FF),
      Color(0xFF0080FF),
      Color(0xFF00FFFF),
      Color(0xFF4B0082),
    ],
    'sunset': [
      Color(0xFFFF7E5F),
      Color(0xFFFEB47B),
      Color(0xFFFFC371),
      Color(0xFFFF5F6D),
    ],
    'cosmic': [
      Color(0xFF0000FF), // Deep Blue
      Color(0xFFFF00FF), // Magenta
      Color(0xFFFF4500), // Orange Red
      Color(0xFF00FFFF), // Cyan
    ],
  };

  const OilSlideConfig({
    this.viscosity = 0.7,
    this.flowSpeed = 0.5,
    this.palette = 'psychedelic',
    this.filmGrain = 0.15,
    this.pulseIntensity = 0.6,
    this.heatDrift = 0.3,
    this.metaballCount = 6,
    this.enableAudioReactivity = true,
    this.visualMode = 'custom', // 'lava_lamp', 'silk', 'psychedelic', 'custom'
    this.oilPerformanceMode = false,
  });

  /// Create config from a preset mode
  factory OilSlideConfig.fromMode(String mode) {
    switch (mode) {
      case 'lava_lamp':
        return const OilSlideConfig(
          visualMode: 'lava_lamp',
          viscosity: 0.9,
          flowSpeed: 0.3,
          metaballCount: 5,
          pulseIntensity: 0.2,
          filmGrain: 0.05,
          heatDrift: 0.5,
          palette: 'lava_classic',
        );
      case 'silk':
        return const OilSlideConfig(
          visualMode: 'silk',
          viscosity: 0.5,
          flowSpeed: 0.6,
          metaballCount: 9,
          pulseIntensity: 0.4,
          filmGrain: 0.0,
          heatDrift: 0.2,
          palette: 'ocean',
        );
      case 'psychedelic':
        return const OilSlideConfig(
          visualMode: 'psychedelic',
          viscosity: 0.7,
          flowSpeed: 0.5,
          metaballCount: 6,
          pulseIntensity: 0.6,
          filmGrain: 0.15,
          heatDrift: 0.3,
          palette: 'psychedelic',
        );
      case 'steal':
        return const OilSlideConfig(
          visualMode: 'steal',
          viscosity: 0.6,
          flowSpeed: 0.4,
          metaballCount: 1, // Only one image
          pulseIntensity: 0.5,
          filmGrain: 0.1,
          heatDrift: 0.2,
          palette: 'psychedelic', // Not used but good to have a default
        );
      default: // custom
        return const OilSlideConfig(
          visualMode: 'custom',
        );
    }
  }

  /// Create config from a map (e.g., from SharedPreferences)
  factory OilSlideConfig.fromMap(Map<String, dynamic> map) {
    return OilSlideConfig(
      viscosity: (map['viscosity'] as num?)?.toDouble() ?? 0.7,
      flowSpeed: (map['flowSpeed'] as num?)?.toDouble() ?? 0.5,
      palette: map['palette'] as String? ?? 'psychedelic',
      filmGrain: (map['filmGrain'] as num?)?.toDouble() ?? 0.15,
      pulseIntensity: (map['pulseIntensity'] as num?)?.toDouble() ?? 0.6,
      heatDrift: (map['heatDrift'] as num?)?.toDouble() ?? 0.3,
      metaballCount: (map['metaballCount'] as int?) ?? 6,
      enableAudioReactivity: map['enableAudioReactivity'] as bool? ?? true,
      visualMode: map['visualMode'] as String? ?? 'custom',
      oilPerformanceMode: map['oilPerformanceMode'] as bool? ?? false,
    );
  }

  /// Convert config to a map (e.g., for SharedPreferences)
  Map<String, dynamic> toMap() {
    return {
      'viscosity': viscosity,
      'flowSpeed': flowSpeed,
      'palette': palette,
      'filmGrain': filmGrain,
      'pulseIntensity': pulseIntensity,
      'heatDrift': heatDrift,
      'metaballCount': metaballCount,
      'enableAudioReactivity': enableAudioReactivity,
      'visualMode': visualMode,
      'oilPerformanceMode': oilPerformanceMode,
    };
  }

  /// Create a copy with modified parameters
  OilSlideConfig copyWith({
    double? viscosity,
    double? flowSpeed,
    String? palette,
    double? filmGrain,
    double? pulseIntensity,
    double? heatDrift,
    int? metaballCount,
    bool? enableAudioReactivity,
    String? visualMode,
    bool? oilPerformanceMode,
  }) {
    return OilSlideConfig(
      viscosity: viscosity ?? this.viscosity,
      flowSpeed: flowSpeed ?? this.flowSpeed,
      palette: palette ?? this.palette,
      filmGrain: filmGrain ?? this.filmGrain,
      pulseIntensity: pulseIntensity ?? this.pulseIntensity,
      heatDrift: heatDrift ?? this.heatDrift,
      metaballCount: metaballCount ?? this.metaballCount,
      enableAudioReactivity:
          enableAudioReactivity ?? this.enableAudioReactivity,
      visualMode: visualMode ?? this.visualMode,
      oilPerformanceMode: oilPerformanceMode ?? this.oilPerformanceMode,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OilSlideConfig &&
        other.viscosity == viscosity &&
        other.flowSpeed == flowSpeed &&
        other.palette == palette &&
        other.filmGrain == filmGrain &&
        other.pulseIntensity == pulseIntensity &&
        other.heatDrift == heatDrift &&
        other.metaballCount == metaballCount &&
        other.enableAudioReactivity == enableAudioReactivity &&
        other.visualMode == visualMode &&
        other.oilPerformanceMode == oilPerformanceMode;
  }

  @override
  int get hashCode {
    return Object.hash(
      viscosity,
      flowSpeed,
      palette,
      filmGrain,
      pulseIntensity,
      heatDrift,
      metaballCount,
      enableAudioReactivity,
      visualMode,
      oilPerformanceMode,
    );
  }

  @override
  String toString() {
    return 'OilSlideConfig(viscosity: $viscosity, flowSpeed: $flowSpeed, '
        'palette: $palette, filmGrain: $filmGrain, pulseIntensity: $pulseIntensity, '
        'heatDrift: $heatDrift, metaballCount: $metaballCount, '
        'enableAudioReactivity: $enableAudioReactivity, visualMode: $visualMode, '
        'oilPerformanceMode: $oilPerformanceMode)';
  }
}
