// lib/utils/app_themes.dart

import 'package:flutter/material.dart';
// import 'package:google_fonts/google_fonts.dart'; // Bundled locally
import 'package:shakedown/ui/styles/font_config.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/styles/apple_inter_typography.dart';

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
    ThemeStyle style = ThemeStyle.android,
    FruitColorOption fruitColorOption = FruitColorOption.sophisticate,
  }) {
    final effectiveFont = style == ThemeStyle.fruit ? 'inter' : appFont;
    final baseTextTheme = ThemeData.light().textTheme;

    final TextTheme textTheme;
    if (style == ThemeStyle.fruit) {
      final config = FontConfig.get('inter');
      final double scaleMultiplier = uiScale ? 1.35 : 1.0;
      final double totalScale = config.scaleFactor * scaleMultiplier;
      textTheme = buildAppleInterTextTheme(false, scaleFactor: totalScale);
    } else {
      textTheme =
          buildTextTheme(effectiveFont, baseTextTheme, uiScale: uiScale);
    }

    Color scaffoldBg = const Color(0xFFF2F2F7); // Apple System Gray 6 (Light)
    Color primaryColor = Colors.blue;
    Color cardColor = Colors.white;

    if (style == ThemeStyle.fruit) {
      switch (fruitColorOption) {
        case FruitColorOption.sophisticate:
          primaryColor = const Color(0xFF5856D6); // Apple Indigo
          scaffoldBg = const Color(0xFFF2F2F7);
          break;
        case FruitColorOption.minimalist:
          primaryColor = const Color(0xFF34C759); // Apple Green
          scaffoldBg = Colors.white;
          break;
        case FruitColorOption.creative:
          primaryColor = const Color(0xFFFF2D55); // Apple Pink
          scaffoldBg = const Color(0xFFFFF9F9); // Very light warm tint
          break;
      }
    } else {
      scaffoldBg = const Color(0xFFF5F5F5);
    }

    final baseTheme = ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor:
            style == ThemeStyle.fruit ? Colors.transparent : Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: style == ThemeStyle.fruit
            ? const IconThemeData(color: Colors.black87)
            : null,
      ),
      cardColor: cardColor,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
    );

    if (style == ThemeStyle.fruit) {
      return baseTheme.copyWith(
        cardTheme: CardThemeData(
          color: Colors.white.withValues(alpha: 0.65),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.white.withValues(alpha: 0.8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    return baseTheme;
  }

  static ThemeData darkTheme(
    String appFont, {
    bool useMaterial3 = true,
    bool uiScale = false,
    ThemeStyle style = ThemeStyle.android,
    FruitColorOption fruitColorOption = FruitColorOption.sophisticate,
  }) {
    final effectiveFont = style == ThemeStyle.fruit ? 'inter' : appFont;
    final baseTextTheme = ThemeData.dark().textTheme;

    final TextTheme textTheme;
    if (style == ThemeStyle.fruit) {
      final config = FontConfig.get('inter');
      final double scaleMultiplier = uiScale ? 1.35 : 1.0;
      final double totalScale = config.scaleFactor * scaleMultiplier;
      textTheme = buildAppleInterTextTheme(true, scaleFactor: totalScale);
    } else {
      textTheme =
          buildTextTheme(effectiveFont, baseTextTheme, uiScale: uiScale);
    }

    Color scaffoldBg = const Color(0xFF1C1C1E); // Apple System Gray 6 (Dark)
    Color primaryColor = Colors.blue;
    Color cardColor = Colors.black;

    if (style == ThemeStyle.fruit) {
      switch (fruitColorOption) {
        case FruitColorOption.sophisticate:
          primaryColor = const Color(0xFF5E5CE6); // Apple Indigo (Dark)
          scaffoldBg = const Color(0xFF121212); // Slate Charcoal
          break;
        case FruitColorOption.minimalist:
          primaryColor = const Color(0xFF30D158); // Apple Green (Dark)
          scaffoldBg = const Color(0xFF1C1C1E); // Keep standard dark
          break;
        case FruitColorOption.creative:
          primaryColor = const Color(0xFFFF375F); // Apple Pink (Dark)
          scaffoldBg = const Color(0xFF1A1A1A); // Warm Charcoal
          break;
      }
    } else {
      scaffoldBg = Colors.black;
    }

    final baseTheme = ThemeData(
      useMaterial3: useMaterial3,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: scaffoldBg,
      ),
      scaffoldBackgroundColor: scaffoldBg,
      appBarTheme: AppBarTheme(
        backgroundColor:
            style == ThemeStyle.fruit ? Colors.transparent : Colors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: style == ThemeStyle.fruit
            ? const IconThemeData(color: Colors.white70)
            : null,
      ),
      cardColor: cardColor,
      textTheme: textTheme,
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: primaryColor,
        selectionColor: primaryColor.withValues(alpha: 0.3),
        selectionHandleColor: primaryColor,
      ),
    );

    if (style == ThemeStyle.fruit) {
      return baseTheme.copyWith(
        cardTheme: CardThemeData(
          color: Colors.black.withValues(alpha: 0.65),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: Colors.black.withValues(alpha: 0.8),
          elevation: 0,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      );
    }
    return baseTheme;
  }
}
