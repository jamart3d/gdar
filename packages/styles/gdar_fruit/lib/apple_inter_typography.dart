import 'package:flutter/material.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'package:gdar_fruit/src/web_runtime.dart';

/// Builds a custom Flutter TextTheme using GoogleFonts.inter()
/// specifically tailored for a "Liquid Glass" UI following Apple's aesthetics.
TextTheme buildAppleInterTextTheme(bool isDark, {double scaleFactor = 1.0}) {
  final String? interFont = FontConfig.resolve('Inter');

  final Color primaryColor = isDark
      ? Colors.white.withValues(alpha: 0.9)
      : Colors.black.withValues(alpha: 0.9);

  final Color secondaryColor = isDark
      ? Colors.white.withValues(alpha: 0.6)
      : Colors.black.withValues(alpha: 0.6);

  final Color tertiaryColor = isDark
      ? Colors.white.withValues(alpha: 0.4)
      : Colors.black.withValues(alpha: 0.4);

  // Skwasm is prone to "Memory Out Bounds" errors in TextPainter.layout
  // when using heavily negative letter spacing on short strings.
  // We clamp these to 0.0 in Wasm Safe Mode.
  double safeLs(double val) => isWasmSafeMode() ? 0.0 : val;

  return TextTheme(
    displayLarge: TextStyle(
      fontFamily: interFont,
      fontSize: 57 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: safeLs(-1.2),
      color: primaryColor,
    ),
    displayMedium: TextStyle(
      fontFamily: interFont,
      fontSize: 45 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: safeLs(-1.0),
      color: primaryColor,
    ),
    displaySmall: TextStyle(
      fontFamily: interFont,
      fontSize: 36 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.5),
      color: primaryColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: interFont,
      fontSize: 32 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: interFont,
      fontSize: 28 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: interFont,
      fontSize: 24 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: safeLs(-0.1),
      color: primaryColor,
    ),
    titleLarge: TextStyle(
      fontFamily: interFont,
      fontSize: 22 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    titleMedium: TextStyle(
      fontFamily: interFont,
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: safeLs(-0.1),
      color: secondaryColor,
    ),
    titleSmall: TextStyle(
      fontFamily: interFont,
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: interFont,
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: interFont,
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: safeLs(-0.1),
      color: secondaryColor,
    ),
    bodySmall: TextStyle(
      fontFamily: interFont,
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    labelLarge: TextStyle(
      fontFamily: interFont,
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: secondaryColor,
    ),
    labelMedium: TextStyle(
      fontFamily: interFont,
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: tertiaryColor,
    ),
    labelSmall: TextStyle(
      fontFamily: interFont,
      fontSize: 11 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: tertiaryColor,
    ),
  );
}
