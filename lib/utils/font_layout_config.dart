import 'package:flutter/material.dart';
import 'package:shakedown/providers/settings_provider.dart';

class FontLayoutConfig {
  final double baseControlZoneWidth;
  final double textScaleBoost;
  final double textScaleClampMin;
  final double textScaleClampMax;
  final double verticalPaddingMultiplier;
  final double headerHeightMultiplier;

  const FontLayoutConfig({
    required this.baseControlZoneWidth,
    this.textScaleBoost = 1.0,
    this.textScaleClampMin = 1.0,
    this.textScaleClampMax = 2.0,
    this.verticalPaddingMultiplier = 1.2, // Standardized to Rock Salt
    this.headerHeightMultiplier = 1.8, // Standardized to Rock Salt
  });

  // Centralized Font Configuration
  static const Map<String, FontLayoutConfig> _fontConfigs = {
    'rock_salt': FontLayoutConfig(
      baseControlZoneWidth: 68.0,
      textScaleClampMax: 1.35,
      textScaleBoost: 0.83,
    ),
    'caveat': FontLayoutConfig(
      baseControlZoneWidth: 68.0, // Standardized
      textScaleClampMax: 1.5,
      verticalPaddingMultiplier:
          1.0, // Caveat handles vertical space better, keeping 1.0? No, user said "same size".
    ),
    'permanent_marker': FontLayoutConfig(
      baseControlZoneWidth: 68.0, // Standardized
      textScaleClampMax: 1.4,
      verticalPaddingMultiplier: 1.1, // Slight adjustment kept
    ),
    'default': FontLayoutConfig(
      baseControlZoneWidth: 68.0, // Standardized
    ),
  };

  static FontLayoutConfig getConfig(String fontKey) {
    return _fontConfigs[fontKey] ?? _fontConfigs['default']!;
  }

  /// Calculates the effective scale factor based on:
  /// 1. System text scale (MediaQuery)
  /// 2. User preference (UI Scale toggle)
  /// 3. Font-specific intrinsic scaling (textScaleBoost)
  static double getEffectiveScale(
      BuildContext context, SettingsProvider settingsProvider) {
    final config = getConfig(settingsProvider.appFont);

    // System text scale
    final double textScale = MediaQuery.textScalerOf(context).scale(1.0);

    // Scaling Logic:
    // - If UI Scale is OFF: Use system scale (clamped). No extra boosts.
    // - If UI Scale is ON: Apply 1.2x boost AND intrinsic font boost (clamped).
    // This ensures "Base" state is clean (scale 1), while "Large" state gets all enhancements.
    final double effectiveScale = settingsProvider.uiScale
        ? (textScale * 1.2 * config.textScaleBoost)
            .clamp(config.textScaleClampMin, config.textScaleClampMax)
        : textScale.clamp(config.textScaleClampMin, config.textScaleClampMax);

    return effectiveScale;
  }
}
