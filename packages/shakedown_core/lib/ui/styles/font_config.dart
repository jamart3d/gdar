import 'package:flutter/material.dart';

/// Configuration for normalized font metrics.
/// Maps "Personality" factors to standardize visual appearance.
class FontConfig {
  final String fontFamily;
  final double scaleFactor;
  final double lineHeight; // Normalized height for line containers
  final int weightAdjustment; // Adjusts FontWeight (e.g., +100 or -100)
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

  /// The Matrix: Defined values for each supported font.
  /// All fonts scaled larger for better visibility
  static const Map<String, FontConfig> _registry = {
    'default': FontConfig(
      fontFamily: 'Roboto',
      scaleFactor: 1.0, // Reduced from 1.05
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Default (Roboto)',
    ),
    'caveat': FontConfig(
      fontFamily: 'packages/shakedown_core/Caveat',
      scaleFactor: 1.2, // Reduced from 1.23 for smaller scaled appearance
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Caveat',
    ),
    'rock_salt': FontConfig(
      fontFamily: 'packages/shakedown_core/RockSalt',
      scaleFactor: 1.3, // Increased from 1.25
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Rock Salt',
    ),
    'permanent_marker': FontConfig(
      fontFamily: 'packages/shakedown_core/Permanent Marker',
      scaleFactor: 1.3, // Increased from 1.25
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Permanent Marker',
    ),
    'inter': FontConfig(
      fontFamily: 'packages/shakedown_core/Inter',
      scaleFactor: 1.0,
      lineHeight: 1.2,
      weightAdjustment: 0,
      letterSpacing: -0.02,
      displayName: 'Inter',
    ),
  };

  /// Retrieves configuration for a given font key.
  static FontConfig get(String fontKey) {
    return _registry[fontKey] ?? _registry['default']!;
  }

  /// Ensures a font family name correctly includes the package prefix
  /// if it's one of the known bundled fonts.
  static String? resolve(String? fontFamily) {
    if (fontFamily == null) return null;

    // If it already has the prefix, it's fine.
    if (fontFamily.startsWith('packages/shakedown_core/')) {
      return fontFamily;
    }

    // Attempt to match raw name to a known font configuration.
    // 'rock_salt', 'RockSalt', 'Rock Salt' -> all should resolve to the correct path if possible.
    final normalized = fontFamily
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

    return fontFamily; // Fallback to whatever was provided
  }

  /// Calculates the adjusted font weight based on configuration.
  FontWeight adjustWeight(FontWeight original) {
    if (weightAdjustment == 0) return original;

    // Convert enum to index values (w100=0 ... w900=8) to do math?
    // Enum indices are linear: w100, w200, ...

    // Easier mapping:
    // FontWeight.index is deprecated, so we use value (100-900) to calculate index (0-8)
    final int currentIndex = (original.value ~/ 100) - 1;
    final int targetIndex = currentIndex + (weightAdjustment ~/ 100);
    final clampedIndex = targetIndex.clamp(0, FontWeight.values.length - 1);

    return FontWeight.values[clampedIndex];
  }
}
