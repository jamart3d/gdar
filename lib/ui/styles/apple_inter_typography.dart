import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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

  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.2,
      color: primaryColor,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45 * scaleFactor,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: primaryColor,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: primaryColor,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: primaryColor,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: primaryColor,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: primaryColor,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22 * scaleFactor,
      fontWeight: FontWeight.w700,
      letterSpacing: -0.2,
      color: primaryColor,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: secondaryColor,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.2,
      color: primaryColor,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: -0.1,
      color: secondaryColor,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w400,
      letterSpacing: 0.0,
      color: secondaryColor,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: secondaryColor,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.2,
      color: tertiaryColor,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11 * scaleFactor,
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: tertiaryColor,
    ),
  );
}
