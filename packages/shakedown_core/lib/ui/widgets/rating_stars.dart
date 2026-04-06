import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';

const Color _fruitRatingStarYellow = Color(0xFFFFC107);

class RatingStars extends StatelessWidget {
  final int rating;
  final bool isPlayed;
  final bool compact;
  final double size;
  final bool ignoreGestures;
  final ValueChanged<double>? onRatingUpdate;
  final double? horizontalPadding;

  const RatingStars({
    super.key,
    required this.rating,
    this.isPlayed = false,
    this.compact = false,
    this.size = 24.0,
    this.ignoreGestures = true,
    this.onRatingUpdate,
    this.horizontalPadding,
  });

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scaledSize = AppTypography.responsiveFontSize(context, size);

    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.watch<DeviceService>().isTv;
    final isFruitNeumorphic =
        isFruit &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack &&
        !isTv;
    final Color filledStarColor = isFruit
        ? _fruitRatingStarYellow
        : Colors.orangeAccent;

    if (isFruitNeumorphic) {
      final Brightness brightness = Theme.of(context).brightness;
      // In light mode, the alpha needs to be slightly higher to be visible against frosted glass
      final Color emptyColor = brightness == Brightness.light
          ? colorScheme.outline.withValues(alpha: 0.35)
          : colorScheme.onSurfaceVariant.withValues(alpha: 0.2);

      Widget innerStars = rating == -1
          ? Semantics(
              label: 'Blocked show',
              child: Icon(
                isFruit ? Icons.star : LucideIcons.star,
                size: scaledSize * 1.0, // Increased size
                color: Colors.redAccent.withValues(alpha: 0.9),
              ),
            )
          : RatingBar(
              initialRating: (rating == 0 && isPlayed)
                  ? 3.0
                  : rating.toDouble(),
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 3,
              itemPadding: EdgeInsets.symmetric(
                horizontal: horizontalPadding ?? (isFruit ? 1.0 : 0.0),
              ), // 2px gap to match HTML space-x-0.5
              itemSize: scaledSize * 1.0, // Increased size from 0.9 to 1.0
              ignoreGestures: ignoreGestures,
              ratingWidget: RatingWidget(
                full: Icon(
                  isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                  color: (rating == 0 && isPlayed)
                      ? colorScheme.outline.withValues(alpha: 0.5)
                      : filledStarColor,
                ),
                half: Icon(
                  isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                  color: filledStarColor,
                ),
                empty: Icon(
                  isFruit ? Icons.star_rate_rounded : LucideIcons.star,
                  color: emptyColor,
                ),
              ),
              onRatingUpdate: onRatingUpdate ?? (_) {},
            );

      if (compact) {
        return innerStars;
      }

      return NeumorphicWrapper(
        enabled: !isTv && !settingsProvider.performanceMode,
        isCircle: false,
        borderRadius: 12,
        intensity: 0.8,
        color: settingsProvider.performanceMode
            ? colorScheme.surfaceContainerHighest
            : Colors.transparent,
        child: LiquidGlassWrapper(
          enabled: !isTv && !settingsProvider.performanceMode,
          showBorder: false, // Maintain no-sharp-edge rule
          borderRadius: BorderRadius.circular(12),
          opacity: brightness == Brightness.light ? 0.15 : 0.08,
          blur: 6,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: innerStars,
          ),
        ),
      );
    } else {
      // Android / Expressive Style (RADICALLY DIFFERENT from Fruit)
      if (rating == -1) {
        return Semantics(
          label: 'Blocked show',
          child: Icon(
            Icons.star_rounded,
            size: scaledSize,
            color: Colors.redAccent,
          ),
        );
      }

      return Semantics(
        label: rating == 0 && isPlayed
            ? 'Played, unrated'
            : 'Rated $rating stars',
        child: RatingBar(
          initialRating: (rating == 0 && isPlayed) ? 3.0 : rating.toDouble(),
          minRating: 1,
          direction: Axis.horizontal,
          allowHalfRating: false,
          itemCount: 3,
          itemSize: scaledSize,
          itemPadding: EdgeInsets.symmetric(
            horizontal: horizontalPadding ?? 1.0,
          ),
          ignoreGestures: ignoreGestures,
          ratingWidget: RatingWidget(
            full: Icon(
              Icons.star_rounded,
              color: (rating == 0 && isPlayed)
                  ? colorScheme.outline.withValues(alpha: 0.5)
                  : Colors.amber,
            ),
            half: const Icon(Icons.star_half_rounded, color: Colors.amber),
            empty: Icon(
              Icons.star_rounded,
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          onRatingUpdate: onRatingUpdate ?? (_) {},
        ),
      );
    }
  }
}
