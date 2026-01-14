import 'package:flutter/material.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';

import 'package:provider/provider.dart';

class SourceListItem extends StatelessWidget {
  final Source source;
  final bool isSourcePlaying;
  final double scaleFactor;
  final double borderRadius;
  final bool showBorder;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool alwaysShowRatingInteraction;

  const SourceListItem({
    super.key,
    required this.source,
    required this.isSourcePlaying,
    this.scaleFactor = 1.0,
    this.borderRadius = 16.0,
    this.showBorder = true,
    required this.onTap,
    required this.onLongPress,
    this.alwaysShowRatingInteraction = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    Color itemBackgroundColor;
    if (isTrueBlackMode) {
      // In True Black mode, background is always black
      itemBackgroundColor = Colors.black;
    } else {
      // Standard behavior
      itemBackgroundColor = isSourcePlaying
          ? colorScheme.tertiaryContainer
          : colorScheme.secondaryContainer;
    }

    // Glow Logic
    bool showGlow = settingsProvider.glowMode > 0;
    bool useRgb = false;

    if (settingsProvider.highlightPlayingWithRgb && isSourcePlaying) {
      useRgb = true;
    }

    // Strict Black Mode Check
    if (isDarkMode && !settingsProvider.useDynamicColor && !isSourcePlaying) {
      showGlow = false;
    }

    // Shadow Visibility
    bool showShadow = !(isTrueBlackMode && !isSourcePlaying);

    double glowOpacity = (isSourcePlaying ? 1.0 : 0.25) *
        (settingsProvider.glowMode / 100.0);

    Widget buildContent() {
      return Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: itemBackgroundColor,
          border: (!showGlow &&
                  !useRgb &&
                  showBorder &&
                  (isSourcePlaying || isTrueBlackMode))
              ? Border.all(
                  color: isSourcePlaying
                      ? colorScheme.tertiary
                      : colorScheme.outlineVariant,
                  width: isSourcePlaying ? 2 : 1)
              : null,
          boxShadow: (!showGlow && !useRgb && showShadow)
              ? [
                  BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: onTap,
                  onLongPress: onLongPress,
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12 * scaleFactor),
              child: Row(
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Text(
                        source.id,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.apply(fontSizeFactor: scaleFactor)
                            .copyWith(
                              color: isSourcePlaying
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSecondaryContainer,
                              fontWeight: isSourcePlaying
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                              letterSpacing: 0.1,
                            ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Container(
                      color: Colors.transparent,
                      child: Row(
                        children: [
                          if (source.src != null) ...[
                            SrcBadge(
                                src: source.src!, isPlaying: isSourcePlaying),
                            const SizedBox(width: 8),
                          ],
                          RatingControl(
                            rating: settingsProvider.getRating(source.id),
                            size: 18 * scaleFactor,
                            isPlayed: settingsProvider.isPlayed(source.id),
                            onTap: (isSourcePlaying ||
                                    alwaysShowRatingInteraction)
                                ? () async {
                                    final currentRating =
                                        settingsProvider.getRating(source.id);
                                    await showDialog(
                                      context: context,
                                      builder: (context) => RatingDialog(
                                        initialRating: currentRating,
                                        sourceId: source.id,
                                        sourceUrl: source.tracks.isNotEmpty
                                            ? source.tracks.first.url
                                            : null,
                                        isPlayed: settingsProvider
                                            .isPlayed(source.id),
                                        onRatingChanged: (newRating) {
                                          settingsProvider.setRating(
                                              source.id, newRating);
                                        },
                                        onPlayedChanged: (bool isPlayed) {
                                          if (isPlayed !=
                                              settingsProvider
                                                  .isPlayed(source.id)) {
                                            settingsProvider
                                                .togglePlayed(source.id);
                                          }
                                        },
                                      ),
                                    );
                                  }
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!settingsProvider.hideTrackCountInSourceList)
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSourcePlaying
                              ? colorScheme.tertiary.withValues(alpha: 0.1)
                              : colorScheme.secondary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '${source.tracks.length}',
                          style:
                              Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: isSourcePlaying
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (showGlow || useRgb) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: (useRgb ? Colors.red : colorScheme.primary)
                          .withValues(
                              alpha: (useRgb ? 0.4 : 0.2) * glowOpacity),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: AnimatedGradientBorder(
            borderRadius: borderRadius,
            borderWidth: useRgb ? 3 : 2,
            colors: useRgb
                ? const [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ]
                : [
                    colorScheme.primary,
                    colorScheme.tertiary,
                    colorScheme.secondary,
                    colorScheme.primary,
                  ],
            showGlow: true,
            showShadow: false, // Handled by outer container
            glowOpacity: 0.5 * glowOpacity,
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: buildContent(),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: buildContent(),
      ),
    );
  }
}
