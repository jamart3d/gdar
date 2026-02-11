import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/services/device_service.dart';

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
  });

  /// Computes the card style based on current state and settings.
  static CardStyle compute({
    required BuildContext context,
    required Show show,
    required bool isExpanded,
    required bool isPlaying,
    required Source? playingSource,
    required SettingsProvider settings,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
            ? colorScheme.tertiary
            : colorScheme.outlineVariant;

    final bool shouldShowBadge = !isExpanded &&
        (show.sources.length > 1 ||
            (show.sources.length == 1 && settings.showSingleShnid));

    final config = FontLayoutConfig.getConfig(settings.appFont);
    double effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settings);

    // Apply the same TV multiplier used in AppTypography (1.2x)
    final deviceService = Provider.of<DeviceService>(context, listen: false);
    if (deviceService.isTv) {
      effectiveScale *= 1.2;
    }

    // Venue Style
    final baseVenueStyle = textTheme.bodyLarge?.copyWith(fontSize: 15.0) ??
        const TextStyle(fontSize: 15.0);
    final venueStyle =
        baseVenueStyle.apply(fontSizeFactor: effectiveScale).copyWith(
              color: colorScheme.onSurface,
            );

    // Date Formatting
    String dateFormatPattern = '';
    if (settings.showDayOfWeek) {
      dateFormatPattern += settings.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
    }
    dateFormatPattern += settings.abbreviateMonth ? 'MMM' : 'MMMM';
    dateFormatPattern += ' d, y';

    final String formattedDate = () {
      try {
        final date = DateTime.parse(show.date);
        return DateFormat(dateFormatPattern).format(date);
      } catch (e) {
        return show.date;
      }
    }();

    // Date Style
    final baseDateStyle = textTheme.bodySmall?.copyWith(fontSize: 9.5) ??
        const TextStyle(fontSize: 9.5);
    final dateStyle =
        baseDateStyle.apply(fontSizeFactor: effectiveScale).copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.15,
            );

    // Font Sizing Logic
    final bool isRockSalt = settings.appFont == 'rock_salt';
    final bool isCaveat = settings.appFont == 'caveat';
    final bool dateFirst = settings.dateFirstInShowCard;

    double topSize = 15.0;
    double bottomSize = 9.5;

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
      topSize = 18.0;
      bottomSize = 15.0;

      if (isRockSalt) {
        topSize = 14.0;
        bottomSize = 12.0;
      } else if (isCaveat) {
        topSize = 24.0;
        bottomSize = 20.0;
      }
    }

    final finalTopStyle =
        venueStyle.copyWith(fontSize: topSize * effectiveScale);
    final finalBottomStyle =
        dateStyle.copyWith(fontSize: bottomSize * effectiveScale);

    // Background Color
    Color backgroundColor = colorScheme.surface;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settings.useTrueBlack;

    if ((!isTrueBlackMode || settings.glowMode == 50) &&
        isPlaying &&
        settings.highlightCurrentShowCard) {
      String seed = show.name;
      if (playingSource != null) {
        seed = playingSource.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: isDarkMode ? Brightness.dark : Brightness.light);
    }

    // Glow and Shadow Logic
    bool suppressOuterGlow = isExpanded && show.sources.length > 1;
    bool showGlow = settings.glowMode > 0;
    bool useRgb = settings.highlightPlayingWithRgb && isPlaying;
    bool showShadow =
        settings.glowMode > 0 && (!isTrueBlackMode || settings.glowMode == 2);

    double baseOpacity = settings.glowMode / 100.0;
    double glowOpacity = isPlaying ? baseOpacity : baseOpacity * 0.25;

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
    );
  }
}
