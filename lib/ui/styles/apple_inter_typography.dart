import 'package:flutter/material.dart';
import 'package:shakedown/utils/web_runtime.dart';

/// Builds a custom Flutter TextTheme using GoogleFonts.inter()
/// specifically tailored for a "Liquid Glass" UI following Apple's aesthetics.
TextTheme buildAppleInterTextTheme(bool isDark, {double scaleFactor = 1.0}) {
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
      fontFamily: 'Inter',
      fontSize: 57 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: safeLs(-1.2),
      color: primaryColor,
    ),
    displayMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 45 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: safeLs(-1.0),
      color: primaryColor,
    ),
    displaySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 36 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.5),
      color: primaryColor,
    ),
    headlineLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 32 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    headlineMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 28 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    headlineSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 24 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: safeLs(-0.1),
      color: primaryColor,
    ),
    titleLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 22 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    titleMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: safeLs(-0.1),
      color: secondaryColor,
    ),
    titleSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    bodyLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: safeLs(-0.2),
      color: primaryColor,
    ),
    bodyMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: safeLs(-0.1),
      color: secondaryColor,
    ),
    bodySmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    labelLarge: TextStyle(
      fontFamily: 'Inter',
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: secondaryColor,
    ),
    labelMedium: TextStyle(
      fontFamily: 'Inter',
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: tertiaryColor,
    ),
    labelSmall: TextStyle(
      fontFamily: 'Inter',
      fontSize: 11 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: tertiaryColor,
    ),
  );
}
