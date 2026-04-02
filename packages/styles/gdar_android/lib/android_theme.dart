import 'package:flutter/material.dart';
import 'package:gdar_design/typography/font_config.dart';

/// Android Material 3 Expressive theme for GDAR.
class GDARAndroidTheme {
  static ThemeData light({required String appFont, bool uiScale = false}) {
    final themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );

    return themeData.copyWith(
      textTheme: _buildTextTheme(
        themeData.textTheme,
        appFont: appFont,
        uiScale: uiScale,
      ),
    );
  }

  static ThemeData dark({
    required String appFont,
    bool uiScale = false,
    bool useTrueBlack = false,
  }) {
    final Color? blackColor = useTrueBlack ? Colors.black : null;
    final themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
        surface: blackColor,
        surfaceContainer: blackColor,
        surfaceContainerHigh: blackColor,
        surfaceContainerHighest: blackColor,
        surfaceContainerLow: blackColor,
        surfaceContainerLowest: blackColor,
        surfaceTint: useTrueBlack ? Colors.transparent : null,
      ),
      scaffoldBackgroundColor: blackColor,
      appBarTheme: AppBarTheme(
        backgroundColor: blackColor,
        surfaceTintColor: useTrueBlack ? Colors.transparent : null,
      ),
      cardTheme: CardThemeData(
        color: blackColor,
        surfaceTintColor: useTrueBlack ? Colors.transparent : null,
      ),
    );

    return themeData.copyWith(
      textTheme: _buildTextTheme(
        themeData.textTheme,
        appFont: appFont,
        uiScale: uiScale,
      ),
    );
  }

  static TextTheme _buildTextTheme(
    TextTheme base, {
    required String appFont,
    required bool uiScale,
  }) {
    final config = FontConfig.get(appFont);
    final double scale = uiScale ? 1.35 : 1.0;
    final double totalScale = config.scaleFactor * scale;

    TextStyle? normalize(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: config.fontFamily,
        fontSize: style.fontSize != null ? style.fontSize! * totalScale : null,
        height: config.lineHeight,
        letterSpacing: (style.letterSpacing ?? 0.0) + config.letterSpacing,
        fontWeight: config.adjustWeight(style.fontWeight ?? FontWeight.normal),
      );
    }

    return base.copyWith(
      displayLarge: normalize(base.displayLarge),
      displayMedium: normalize(base.displayMedium),
      displaySmall: normalize(base.displaySmall),
      headlineLarge: normalize(base.headlineLarge),
      headlineMedium: normalize(base.headlineMedium),
      headlineSmall: normalize(base.headlineSmall),
      titleLarge: normalize(base.titleLarge),
      titleMedium: normalize(base.titleMedium),
      titleSmall: normalize(base.titleSmall),
      bodyLarge: normalize(base.bodyLarge),
      bodyMedium: normalize(base.bodyMedium),
      bodySmall: normalize(base.bodySmall),
      labelLarge: normalize(base.labelLarge),
      labelMedium: normalize(base.labelMedium),
      labelSmall: normalize(base.labelSmall),
    );
  }
}
