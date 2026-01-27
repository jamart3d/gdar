// lib/utils/app_themes.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Bundled locally
import 'package:shakedown/ui/styles/font_config.dart';

class AppThemes {
  static TextTheme buildTextTheme(
    String fontKey,
    TextTheme baseTextTheme, {
    bool uiScale = false,
  }) {
    final config = FontConfig.get(fontKey);
    final double scaleMultiplier = uiScale ? 1.35 : 1.0; // Reduced from 1.4
    final double totalScale = config.scaleFactor * scaleMultiplier;

    // Only apply font family - DO NOT use fontSizeFactor here as it fails with null fontSize
    final appliedTheme = baseTextTheme.apply(
      fontFamily: config.fontFamily,
    );

    // Helper to normalize AND scale specific styles
    TextStyle? normalize(TextStyle? style) {
      if (style == null) return null;

      // Apply scaling to fontSize (handle null case)
      final baseFontSize = style.fontSize;
      final scaledFontSize =
          baseFontSize != null ? baseFontSize * totalScale : null;

      return style.copyWith(
        fontSize: scaledFontSize, // Apply our custom scaling here
        height: config.lineHeight,
        letterSpacing: (style.letterSpacing ?? 0.0) + config.letterSpacing,
        fontWeight: config.adjustWeight(style.fontWeight ?? FontWeight.normal),
      );
    }

    return appliedTheme.copyWith(
      displayLarge: normalize(appliedTheme.displayLarge),
      displayMedium: normalize(appliedTheme.displayMedium),
      displaySmall: normalize(appliedTheme.displaySmall),
      headlineLarge: normalize(appliedTheme.headlineLarge),
      headlineMedium: normalize(appliedTheme.headlineMedium),
      headlineSmall: normalize(appliedTheme.headlineSmall),
      titleLarge: normalize(appliedTheme.titleLarge),
      titleMedium: normalize(appliedTheme.titleMedium),
      titleSmall: normalize(appliedTheme.titleSmall),
      bodyLarge: normalize(appliedTheme.bodyLarge),
      bodyMedium: normalize(appliedTheme.bodyMedium),
      bodySmall: normalize(appliedTheme.bodySmall),
      labelLarge: normalize(appliedTheme.labelLarge),
      labelMedium: normalize(appliedTheme.labelMedium),
      labelSmall: normalize(appliedTheme.labelSmall),
    );
  }

  static ThemeData lightTheme(
    String appFont, {
    bool useMaterial3 = true,
    bool uiScale = false,
  }) {
    final baseTextTheme = ThemeData.light().textTheme;
    final textTheme = buildTextTheme(appFont, baseTextTheme, uiScale: uiScale);

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

  static ThemeData darkTheme(
    String appFont, {
    bool useMaterial3 = true,
    bool uiScale = false,
  }) {
    final baseTextTheme = ThemeData.dark().textTheme;
    final textTheme = buildTextTheme(appFont, baseTextTheme, uiScale: uiScale);

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
