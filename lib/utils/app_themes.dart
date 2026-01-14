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
        final theme = baseTextTheme.apply(fontFamily: 'RockSalt');
        // Rock Salt is huge/wide and has tall ascenders/descenders.
        // We scale it down AND increase line height to prevent clipping.
        return theme.copyWith(
          displayLarge: theme.displayLarge?.copyWith(
              fontSize: (theme.displayLarge?.fontSize ?? 57) * 0.75,
              height: 1.5),
          displayMedium: theme.displayMedium?.copyWith(
              fontSize: (theme.displayMedium?.fontSize ?? 45) * 0.75,
              height: 1.5),
          displaySmall: theme.displaySmall?.copyWith(
              fontSize: (theme.displaySmall?.fontSize ?? 36) * 0.75,
              height: 1.5),
          headlineLarge: theme.headlineLarge?.copyWith(
              fontSize: (theme.headlineLarge?.fontSize ?? 32) * 0.6,
              height: 1.6),
          headlineMedium: theme.headlineMedium?.copyWith(
              fontSize: (theme.headlineMedium?.fontSize ?? 28) * 0.6,
              height: 1.6),
          headlineSmall: theme.headlineSmall?.copyWith(
              fontSize: (theme.headlineSmall?.fontSize ?? 24) * 0.6,
              height: 1.6),
          titleLarge: theme.titleLarge?.copyWith(
              fontSize: (theme.titleLarge?.fontSize ?? 22) * 0.6, height: 1.6),
          titleMedium: theme.titleMedium?.copyWith(
              fontSize: (theme.titleMedium?.fontSize ?? 16) * 0.6, height: 1.6),
          titleSmall: theme.titleSmall?.copyWith(
              fontSize: (theme.titleSmall?.fontSize ?? 14) * 0.6, height: 1.6),
          bodyLarge: theme.bodyLarge?.copyWith(
              fontSize: (theme.bodyLarge?.fontSize ?? 16) * 0.7, height: 1.6),
          bodyMedium: theme.bodyMedium?.copyWith(
              fontSize: (theme.bodyMedium?.fontSize ?? 14) * 0.7, height: 1.6),
          bodySmall: theme.bodySmall?.copyWith(
              fontSize: (theme.bodySmall?.fontSize ?? 12) * 0.7, height: 1.6),
          labelLarge: theme.labelLarge?.copyWith(
              fontSize: (theme.labelLarge?.fontSize ?? 14) * 0.7, height: 1.6),
          labelMedium: theme.labelMedium?.copyWith(
              fontSize: (theme.labelMedium?.fontSize ?? 12) * 0.7, height: 1.6),
          labelSmall: theme.labelSmall?.copyWith(
              fontSize: (theme.labelSmall?.fontSize ?? 11) * 0.7, height: 1.6),
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
