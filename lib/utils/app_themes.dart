// lib/utils/app_themes.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Bundled locally

class AppThemes {
  static TextTheme? getTextTheme(String appFont, TextTheme baseTextTheme) {
    debugPrint('AppThemes: Getting theme for font: $appFont');
    switch (appFont) {
      case 'caveat':
        return baseTextTheme.apply(fontFamily: 'Caveat');
      case 'permanent_marker':
        return baseTextTheme.apply(fontFamily: 'Permanent Marker');

      case 'rock_salt':
        // Rock Salt has wide character spacing and tall ascenders/descenders.
        // Apply minimal downscaling (0.85x) to compensate for width, and
        // increased line height (1.4) to prevent clipping.
        // Helper function handles null fontSize gracefully
        TextStyle? scaleStyle(TextStyle? style) {
          if (style == null) return null;
          return style.copyWith(
            fontFamily: 'RockSalt',
            fontSize: style.fontSize != null ? style.fontSize! * 0.85 : null,
            height: 1.4,
          );
        }

        return TextTheme(
          displayLarge: scaleStyle(baseTextTheme.displayLarge),
          displayMedium: scaleStyle(baseTextTheme.displayMedium),
          displaySmall: scaleStyle(baseTextTheme.displaySmall),
          headlineLarge: scaleStyle(baseTextTheme.headlineLarge),
          headlineMedium: scaleStyle(baseTextTheme.headlineMedium),
          headlineSmall: scaleStyle(baseTextTheme.headlineSmall),
          titleLarge: scaleStyle(baseTextTheme.titleLarge),
          titleMedium: scaleStyle(baseTextTheme.titleMedium),
          titleSmall: scaleStyle(baseTextTheme.titleSmall),
          bodyLarge: scaleStyle(baseTextTheme.bodyLarge),
          bodyMedium: scaleStyle(baseTextTheme.bodyMedium),
          bodySmall: scaleStyle(baseTextTheme.bodySmall),
          labelLarge: scaleStyle(baseTextTheme.labelLarge),
          labelMedium: scaleStyle(baseTextTheme.labelMedium),
          labelSmall: scaleStyle(baseTextTheme.labelSmall),
        );
      default:
        return null; // Use default M3 typography
    }
  }

  static ThemeData lightTheme(String appFont, {bool useMaterial3 = true}) {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = getTextTheme(appFont, baseTextTheme);

    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.light,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: const Color(0xFFF5F5F5), // A cool white
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      cardColor: Colors.white,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.blue,
        selectionColor: Colors.blue.withValues(alpha: 0.3),
        selectionHandleColor: Colors.blue,
      ),
    );
  }

  static ThemeData darkTheme(String appFont, {bool useMaterial3 = true}) {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = getTextTheme(appFont, baseTextTheme);

    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.dark,
      primarySwatch: Colors.blue,
      scaffoldBackgroundColor: Colors.black, // True black for OLED
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
      ),
      cardColor: Colors.black,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: Colors.blue,
        selectionColor: Colors.blue.withValues(alpha: 0.3),
        selectionHandleColor: Colors.blue,
      ),
    );
  }
}
