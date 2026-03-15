import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/styles/font_config.dart';

/// Android Material 3 Expressive theme for GDAR.
class GDARAndroidTheme {
  static ThemeData light({bool uiScale = false}) {
    final themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
    );

    return themeData.copyWith(
      textTheme: _buildTextTheme(themeData.textTheme, uiScale: uiScale),
    );
  }

  static ThemeData dark({bool uiScale = false}) {
    final themeData = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
    );

    return themeData.copyWith(
      textTheme: _buildTextTheme(themeData.textTheme, uiScale: uiScale),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, {required bool uiScale}) {
    // Roboto is the required font for Android style per specs.
    final config = FontConfig.get('roboto');
    final double scale = uiScale ? 1.35 : 1.0;
    final double totalScale = config.scaleFactor * scale;

    TextStyle? normalize(TextStyle? style) {
      if (style == null) return null;
      return style.copyWith(
        fontFamily: 'Roboto',
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
