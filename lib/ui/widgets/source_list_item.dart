import 'package:flutter/material.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/rating_control.dart';

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
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

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

    return Material(
      color: itemBackgroundColor,
      borderRadius: BorderRadius.circular(borderRadius),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: (showBorder && (isSourcePlaying || isTrueBlackMode))
              ? Border.all(
                  color: isSourcePlaying
                      ? colorScheme.tertiary
                      : colorScheme.outlineVariant,
                  width: isSourcePlaying ? 2 : 1)
              : null,
          boxShadow: (isTrueBlackMode && !isSourcePlaying)
              ? []
              : [
                  BoxShadow(
                    color: colorScheme.shadow.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  )
                ],
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
                      child: RatingControl(
                        rating: settingsProvider.getRating(source.id),
                        size: 18 * scaleFactor,
                        onTap: (isSourcePlaying || alwaysShowRatingInteraction)
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
                                    isPlayed:
                                        settingsProvider.isPlayed(source.id),
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
                    ),
                  ),
                  if (!settingsProvider.hideTrackCountInSourceList)
                    IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSourcePlaying
                              ? colorScheme.tertiary.withOpacity(0.1)
                              : colorScheme.secondary.withOpacity(0.1),
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
      ),
    );
  }
}
