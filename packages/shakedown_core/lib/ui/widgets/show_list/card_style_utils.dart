import 'package:flutter/material.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/utils/color_generator.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

/// Holds computed style values for [ShowListCard].
class CardStyle {
  final Color cardBorderColor;
  final bool shouldShowBadge;
  final double effectiveScale;
  final TextStyle topStyle;
  final TextStyle bottomStyle;
  final Color backgroundColor;
  final bool showGlow;
  final bool useRgb;
  final bool showShadow;
  final double glowOpacity;
  final String formattedDate;
  final FontLayoutConfig config;
  final bool suppressOuterGlow;
  final double cardBorderWidth;
  final bool isHovered;

  const CardStyle({
    required this.cardBorderColor,
    required this.shouldShowBadge,
    required this.effectiveScale,
    required this.topStyle,
    required this.bottomStyle,
    required this.backgroundColor,
    required this.showGlow,
    required this.useRgb,
    required this.showShadow,
    required this.glowOpacity,
    required this.formattedDate,
    required this.config,
    required this.suppressOuterGlow,
    required this.cardBorderWidth,
    this.isHovered = false,
  });

  /// Computes the card style based on current state and settings.
  static CardStyle compute({
    required BuildContext context,
    required Show show,
    required bool isExpanded,
    required bool isPlaying,
    required Source? playingSource,
    required SettingsProvider settings,
    bool isHovered = false,
  }) {
    final textTheme = Theme.of(context).textTheme;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

    final colorScheme = Theme.of(
      context,
    ).colorScheme; // Define colorScheme here

    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;

    final bool shouldShowBadge =
        !isExpanded &&
        (show.sources.length > 1 ||
            (show.sources.length == 1 && settings.showSingleShnid));

    final config = FontLayoutConfig.getConfig(settings.appFont);
    double effectiveScale = FontLayoutConfig.getEffectiveScale(
      context,
      settings,
    );

    // Apply the same TV multiplier used in AppTypography (1.2x)
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    if (deviceService.isTv) {
      effectiveScale *= 1.2;
    }

    // Venue Style
    final baseVenueStyle =
        textTheme.bodyLarge?.copyWith(fontSize: 15.0) ??
        const TextStyle(fontSize: 15.0);
    final bool isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final venueStyle = baseVenueStyle
        .apply(fontSizeFactor: effectiveScale)
        .copyWith(
          color: isFruit
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.9)
                    : Colors.black.withValues(alpha: 0.9))
              : colorScheme.onSurface,
        );

    final String formattedDate = AppDateUtils.formatDate(
      show.date,
      settings: settings,
    );

    // Date Style
    final baseDateStyle =
        textTheme.bodySmall?.copyWith(fontSize: 9.5) ??
        const TextStyle(fontSize: 9.5);
    final dateStyle = baseDateStyle
        .apply(fontSizeFactor: effectiveScale)
        .copyWith(
          color: isFruit
              ? (isDark
                    ? Colors.white.withValues(alpha: 0.6)
                    : Colors.black.withValues(alpha: 0.6))
              : colorScheme.onSurfaceVariant,
          letterSpacing: 0.15,
        );

    // Font Sizing Logic
    final bool isRockSalt = settings.activeAppFont == 'rock_salt';
    final bool isCaveat = settings.activeAppFont == 'caveat';
    final bool dateFirst = settings.dateFirstInShowCard;

    double topSize = (themeProvider.themeStyle == ThemeStyle.fruit)
        ? 28.0
        : 15.0; // v134 standard Venue size
    double bottomSize = (themeProvider.themeStyle == ThemeStyle.fruit)
        ? 11.0
        : 9.5; // v134 standard Date size

    if (isRockSalt) {
      if (dateFirst) {
        topSize = 12.0;
      } else {
        bottomSize = 7.0;
      }
    } else if (isCaveat) {
      if (settings.uiScale) {
        topSize = 16.5;
        bottomSize = 10.0;
      } else {
        topSize = 22.0;
        bottomSize = 14.0;
      }
    }

    if (deviceService.isTv) {
      // On TV, we give the Venue and Date more balanced authority in the Row
      topSize = 20.0;
      bottomSize = 16.0;

      if (isRockSalt) {
        topSize = 14.0;
        bottomSize = 12.0;
      } else if (isCaveat) {
        topSize = 24.0;
        bottomSize = 20.0;
      }
    }

    final sp = Provider.of<SettingsProvider>(context, listen: false);
    final bool isLiquidGlassOff = isFruit && !sp.fruitEnableLiquidGlass;
    final bool useLetterpress = isFruit && !isLiquidGlassOff;

    final finalTopStyle = venueStyle.copyWith(
      fontSize: topSize * effectiveScale,
      fontFeatures: useLetterpress ? [const FontFeature('opsz', 1)] : null,
      shadows: useLetterpress
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.15),
                offset: const Offset(0.5, 0.5),
                blurRadius: 0.5,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.5),
                offset: const Offset(-0.5, -0.5),
                blurRadius: 0.5,
              ),
            ]
          : null,
    );

    final finalBottomStyle = dateStyle.copyWith(
      fontSize: bottomSize * effectiveScale,
      fontFeatures: useLetterpress ? [const FontFeature('opsz', 1)] : null,
      shadows: useLetterpress
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.12),
                offset: const Offset(0.4, 0.4),
                blurRadius: 0.4,
              ),
              Shadow(
                color: Colors.white.withValues(alpha: 0.4),
                offset: const Offset(-0.4, -0.4),
                blurRadius: 0.4,
              ),
            ]
          : null,
    );

    // Background Color
    Color backgroundColor = deviceService.isTv
        ? Colors.black
        : colorScheme.surface;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settings.useTrueBlack;

    if (!deviceService.isTv &&
        themeProvider.themeStyle != ThemeStyle.fruit &&
        (!isTrueBlackMode || settings.glowMode >= 25) &&
        isPlaying &&
        settings.highlightCurrentShowCard) {
      String seed = show.name;
      if (playingSource != null) {
        seed = playingSource.id;
      }
      backgroundColor = ColorGenerator.getColor(
        seed,
        brightness: isDarkMode ? Brightness.dark : Brightness.light,
      );
    }

    // Glow and Shadow Logic
    bool suppressOuterGlow = isExpanded && show.sources.length > 1;
    bool showGlow = settings.glowMode > 0;

    final isFruitHighlight =
        themeProvider.themeStyle == ThemeStyle.fruit &&
        isPlaying &&
        settings.highlightCurrentShowCard;

    bool useRgb =
        !settings.performanceMode &&
        settings.highlightPlayingWithRgb &&
        isPlaying;
    if (isFruitHighlight) {
      showGlow =
          true; // Force border for Fruit highlight, but use theme colors unless RGB is enabled
    }

    bool showShadow =
        settings.glowMode > 0 && (!isTrueBlackMode || settings.glowMode >= 2);

    double baseOpacity = settings.glowMode / 100.0;
    double glowOpacity = isPlaying ? baseOpacity : baseOpacity * 0.25;

    // Border Width: Increase for TV visibility (baseline fix)
    double cardBorderWidth = deviceService.isTv ? 4.0 : 3.0;
    if (themeProvider.themeStyle == ThemeStyle.fruit) {
      if (!isExpanded && !isPlaying) {
        cardBorderWidth = deviceService.isTv
            ? 1.0
            : 0.5; // Hairline is thicker on TV
      }
    }

    return CardStyle(
      cardBorderColor: cardBorderColor,
      shouldShowBadge: shouldShowBadge,
      effectiveScale: effectiveScale,
      topStyle: finalTopStyle,
      bottomStyle: finalBottomStyle,
      backgroundColor: backgroundColor,
      showGlow: showGlow,
      useRgb: useRgb,
      showShadow: showShadow,
      glowOpacity: glowOpacity,
      formattedDate: formattedDate,
      config: config,
      suppressOuterGlow: suppressOuterGlow,
      cardBorderWidth: cardBorderWidth,
      isHovered: isHovered,
    );
  }
}
