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
      fontFamily: 'Caveat',
      scaleFactor: 1.2, // Reduced from 1.23 for smaller scaled appearance
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Caveat',
    ),
    'rock_salt': FontConfig(
      fontFamily: 'RockSalt',
      scaleFactor: 1.3, // Increased from 1.25
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Rock Salt',
    ),
    'permanent_marker': FontConfig(
      fontFamily: 'Permanent Marker',
      scaleFactor: 1.3, // Increased from 1.25
      lineHeight: 1.3,
      weightAdjustment: 0,
      letterSpacing: 0.0,
      displayName: 'Permanent Marker',
    ),
  };

  /// Retrieves configuration for a given font key.
  static FontConfig get(String fontKey) {
    return _registry[fontKey] ?? _registry['default']!;
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
