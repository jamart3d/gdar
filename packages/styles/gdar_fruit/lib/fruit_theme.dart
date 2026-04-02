import 'package:flutter/material.dart';
import 'package:gdar_design/tokens/theme_tokens.dart';
import 'package:gdar_design/typography/font_config.dart';
import 'apple_inter_typography.dart';

/// Apple Liquid Glass "Fruit" style for GDAR Web.
class GDARFruitTheme {
  static ThemeData light({
    bool uiScale = false,
    FruitColorOption colorOption = FruitColorOption.sophisticate,
  }) {
    final config = FontConfig.get('inter');
    final double scale = uiScale ? 1.35 : 1.0;
    final double totalScale = config.scaleFactor * scale;

    final textTheme = buildAppleInterTextTheme(false, scaleFactor: totalScale);

    Color scaffoldBg;
    Color primaryColor;

    switch (colorOption) {
      case FruitColorOption.sophisticate:
        primaryColor = const Color(0xFF5C6BC0);
        scaffoldBg = const Color(0xFFE0E5EC);
        break;
      case FruitColorOption.minimalist:
        primaryColor = const Color(0xFF34C759);
        scaffoldBg = Colors.white;
        break;
      case FruitColorOption.creative:
        primaryColor = const Color(0xFFFF2D55);
        scaffoldBg = const Color(0xFFFFF9F9);
        break;
    }

    final themeData = ThemeData(
      useMaterial3:
          false, // Fruit style strictly avoids M3 ripples/interactions
      brightness: Brightness.light,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        surface: scaffoldBg,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.black87),
      ),
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.65),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white.withValues(alpha: 0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: textTheme,
    );

    return themeData.copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.white.withValues(alpha: 0.05),
    );
  }

  static ThemeData dark({
    bool uiScale = false,
    FruitColorOption colorOption = FruitColorOption.sophisticate,
  }) {
    final config = FontConfig.get('inter');
    final double scale = uiScale ? 1.35 : 1.0;
    final double totalScale = config.scaleFactor * scale;

    final textTheme = buildAppleInterTextTheme(true, scaleFactor: totalScale);

    Color scaffoldBg;
    Color primaryColor;
    Color surfaceColor;

    switch (colorOption) {
      case FruitColorOption.sophisticate:
        primaryColor = const Color(0xFF00E676);
        scaffoldBg = const Color(0xFF0F172A);
        surfaceColor = const Color(0xFF1E293B);
        break;
      case FruitColorOption.minimalist:
        primaryColor = const Color(0xFF30D158);
        scaffoldBg = const Color(0xFF1C1C1E);
        surfaceColor = scaffoldBg;
        break;
      case FruitColorOption.creative:
        primaryColor = const Color(0xFFFF375F);
        scaffoldBg = const Color(0xFF1A1A1A);
        surfaceColor = scaffoldBg;
        break;
    }

    final themeData = ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: scaffoldBg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: surfaceColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: Colors.white70),
      ),
      cardTheme: CardThemeData(
        color: Colors.black.withValues(alpha: 0.65),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.black.withValues(alpha: 0.8),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      textTheme: textTheme,
    );

    return themeData.copyWith(
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      splashColor: Colors.transparent,
      hoverColor: Colors.white.withValues(alpha: 0.05),
    );
  }
}
