/// Configuration for the oil_slide visualizer.
///
/// This class encapsulates all visual and behavioral parameters for the
/// oil_slide effect, making it easy to serialize/deserialize from settings
/// and potentially extract into a standalone package.
class OilSlideConfig {
  final double viscosity;
  final double flowSpeed;
  final String palette;
  final double filmGrain;
  final double pulseIntensity;
  final double heatDrift;
  final int metaballCount;
  final bool enableAudioReactivity;
  final String visualMode;

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
        other.visualMode == visualMode;
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
    );
  }

  @override
  String toString() {
    return 'OilSlideConfig(viscosity: $viscosity, flowSpeed: $flowSpeed, '
        'palette: $palette, filmGrain: $filmGrain, pulseIntensity: $pulseIntensity, '
        'heatDrift: $heatDrift, metaballCount: $metaballCount, '
        'enableAudioReactivity: $enableAudioReactivity, visualMode: $visualMode)';
  }
}
