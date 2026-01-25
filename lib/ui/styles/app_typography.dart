import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';

class AppTypography {
  /// Base size constants to enforce consistency
  static const double baseBodySize = 16.0;
  static const double baseTitleSize = 18.0;
  static const double baseHeaderSize = 22.0; // Venue name in panel
  static const double baseSmallSize = 14.0;
  static const double baseTinySize = 12.0;

  /// Returns the effective font size calculated from:
  /// 1. [baseSize]: The standard Material Design font size (e.g. 16.0)
  /// 2. [SettingsProvider.uiScale]: User's preference
  /// 3. [SettingsProvider.appFont]: Adjustments for specific fonts (Caveat needs to be bigger)
  static double responsiveFontSize(BuildContext context, double baseSize) {
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // Font-specific size corrections relative to Roboto
    // Caveat is naturally small/thin, so we boost it relative to the base design size
    // Rock Salt is wide, so we slightly tame it or keep it standard.
    double fontMultiplier = 1.0;
    switch (settingsProvider.appFont) {
      case 'caveat':
        fontMultiplier = 1.4; // +40% for readability
        break;
      case 'rock_salt':
        fontMultiplier = 0.9; // -10% to prevent overflow
        break;
      case 'permanent_marker':
        fontMultiplier = 0.95;
        break;
      default:
        fontMultiplier = 1.0;
    }

    return baseSize * fontMultiplier * scaleFactor;
  }

  /// Helper for commonly used text styles
  static TextStyle body(BuildContext context) {
    return TextStyle(fontSize: responsiveFontSize(context, baseBodySize));
  }

  static TextStyle title(BuildContext context) {
    return TextStyle(fontSize: responsiveFontSize(context, baseTitleSize));
  }

  static TextStyle header(BuildContext context) {
    return TextStyle(fontSize: responsiveFontSize(context, baseHeaderSize));
  }

  static TextStyle small(BuildContext context) {
    return TextStyle(fontSize: responsiveFontSize(context, baseSmallSize));
  }

  static TextStyle tiny(BuildContext context) {
    return TextStyle(fontSize: responsiveFontSize(context, baseTinySize));
  }

  /// Returns (height, letterSpacing) for header text based on the active font.
  static ({double height, double letterSpacing}) getHeaderMetrics(
      String fontName) {
    switch (fontName) {
      case 'rock_salt':
        return (height: 1.4, letterSpacing: 1.5);
      case 'permanent_marker':
        return (height: 1.2, letterSpacing: 0.8);
      case 'caveat':
        return (height: 1.2, letterSpacing: 0.0);
      default:
        return (height: 1.1, letterSpacing: -0.5);
    }
  }
}
