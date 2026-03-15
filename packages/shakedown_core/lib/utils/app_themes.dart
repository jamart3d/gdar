import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/styles/font_config.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

class AppThemes {
  static TextTheme buildTextTheme(
    String fontKey,
    TextTheme baseTextTheme, {
    bool uiScale = false,
  }) {
    final config = FontConfig.get(fontKey);
    final double scaleMultiplier = uiScale ? 1.35 : 1.0;
    final double totalScale = config.scaleFactor * scaleMultiplier;

    final appliedTheme = baseTextTheme.apply(
      fontFamily: config.fontFamily,
    );

    TextStyle? normalize(TextStyle? style) {
      if (style == null) return null;

      final baseFontSize = style.fontSize;
      final scaledFontSize =
          baseFontSize != null ? baseFontSize * totalScale : null;

      return style.copyWith(
        fontSize: scaledFontSize,
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
    ThemeStyle style = ThemeStyle.android,
  }) {
    // Note: ThemeStyle.fruit logic has been migrated to package:gdar_fruit
    final baseTextTheme = ThemeData.light().textTheme;
    final TextTheme textTheme =
        buildTextTheme(appFont, baseTextTheme, uiScale: uiScale);

    const Color scaffoldBg = Color(0xFFF5F5F5);
    const Color primaryColor = Colors.blue;

    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
    );
  }

  static ThemeData darkTheme(
    String appFont, {
    bool useMaterial3 = true,
    bool uiScale = false,
    ThemeStyle style = ThemeStyle.android,
  }) {
    // Note: ThemeStyle.fruit logic has been migrated to package:gdar_fruit
    final baseTextTheme = ThemeData.dark().textTheme;
    final TextTheme textTheme =
        buildTextTheme(appFont, baseTextTheme, uiScale: uiScale);

    const Color scaffoldBg = Colors.black;
    const Color primaryColor = Colors.blue;

    return ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
    );
  }
}

