import 'package:flutter/material.dart';

/// Configuration for normalized font metrics.
/// Maps "Personality" factors to standardize visual appearance.
class FontConfig {
  final String fontFamily;
  final double scaleFactor;
  final double lineHeight;
  final int weightAdjustment;
  final double letterSpacing;
  final String displayName;

  const FontConfig({
    required this.fontFamily,
    required this.scaleFactor,
    required this.lineHeight,
    required this.weightAdjustment,
    required this.letterSpacing,
    required this.displayName,
  });

  static const String _packagePrefix = 'packages/gdar_design/';
  static const String _legacyPackagePrefix = 'packages/shakedown_core/';

  static const Map<String, FontConfig> _registry = {
    'default': FontConfig(
      fontFamily: '${_packagePrefix}Inter',
      scaleFactor: 1.0,
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Inter',
    ),
    'caveat': FontConfig(
      fontFamily: '${_packagePrefix}Caveat',
      scaleFactor: 1.2,
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Caveat',
    ),
    'rock_salt': FontConfig(
      fontFamily: '${_packagePrefix}RockSalt',
      scaleFactor: 1.3,
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Rock Salt',
    ),
    'permanent_marker': FontConfig(
      fontFamily: '${_packagePrefix}Permanent Marker',
      scaleFactor: 1.3,
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Permanent Marker',
    ),
    'inter': FontConfig(
      fontFamily: '${_packagePrefix}Inter',
      scaleFactor: 1.0,
      lineHeight: 1.2,
      weightAdjustment: 0,
      letterSpacing: -0.02,
      displayName: 'Inter',
    ),
  };

  static FontConfig get(String fontKey) {
    return _registry[fontKey] ?? _registry['default']!;
  }

  /// Ensures a font family name correctly includes the package prefix
  /// if it's one of the known bundled fonts.
  static String? resolve(String? fontFamily) {
    if (fontFamily == null) return null;

    if (fontFamily.startsWith(_packagePrefix)) {
      return fontFamily;
    }

    final normalized = fontFamily
        .replaceFirst(_legacyPackagePrefix, '')
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll('_', '');

    for (final entry in _registry.values) {
      final configNormalized = entry.fontFamily
          .split('/')
          .last
          .toLowerCase()
          .replaceAll(' ', '');
      final keyNormalized = entry.displayName.toLowerCase().replaceAll(' ', '');

      if (normalized == configNormalized || normalized == keyNormalized) {
        return entry.fontFamily;
      }
    }

    return fontFamily;
  }

  /// Calculates the adjusted font weight based on configuration.
  FontWeight adjustWeight(FontWeight original) {
    if (weightAdjustment == 0) return original;

    final int currentIndex = (original.value ~/ 100) - 1;
    final int targetIndex = currentIndex + (weightAdjustment ~/ 100);
    final clampedIndex = targetIndex.clamp(0, FontWeight.values.length - 1);

    return FontWeight.values[clampedIndex];
  }
}
