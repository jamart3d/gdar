import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:provider/provider.dart';

import 'package:gdar/utils/color_generator.dart';

class ShowListCard extends StatelessWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final String? playingSourceId; // New field
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const ShowListCard({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    this.playingSourceId, // New parameter
    required this.isLoading,
    required this.onTap,
    required this.onLongPress,
  });

  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
            ? colorScheme.tertiary
            : colorScheme.outlineVariant;
    final bool shouldShowBadge = show.sources.length > 1 ||
        (show.sources.length == 1 && settingsProvider.showSingleShnid);

    final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;

    final baseVenueStyle =
        textTheme.titleLarge ?? const TextStyle(fontSize: 22.0);
    final venueStyle = baseVenueStyle
        .copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: colorScheme.onSurface)
        .apply(fontSizeFactor: scaleFactor);

    final baseDateStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final dateStyle = baseDateStyle
        .copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.15)
        .apply(fontSizeFactor: scaleFactor);

    Color backgroundColor = colorScheme.surface;
    if (isPlaying && settingsProvider.highlightCurrentShowCard) {
      String seed = show.name;
      if (show.sources.length > 1 && playingSourceId != null) {
        seed = playingSourceId!;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    Widget cardContent = Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        color: backgroundColor,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(28),
          onTap: onTap,
          onLongPress: onLongPress,
          child: Padding(
            padding: EdgeInsets.all(10.0 * scaleFactor),
            child: Stack(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: settingsProvider.showExpandIcon ? 32 : 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            SizedBox(
                              height: venueStyle.fontSize! * 1.3,
                              child: ConditionalMarquee(
                                text: settingsProvider.dateFirstInShowCard
                                    ? show.formattedDate
                                    : show.venue,
                                style: venueStyle,
                              ),
                            ),
                            SizedBox(height: 6 * scaleFactor),
                            Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Text(
                                settingsProvider.dateFirstInShowCard
                                    ? show.venue
                                    : show.formattedDate,
                                style: dateStyle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                if (settingsProvider.showExpandIcon)
                  Positioned(
                    left: 0,
                    bottom: 0,
                    child: AnimatedSwitcher(
                      duration: _animationDuration,
                      child: isLoading
                          ? Container(
                              key: ValueKey('loader_${show.name}'),
                              width: 28,
                              height: 28,
                              padding: const EdgeInsets.all(4),
                              child: const CircularProgressIndicator(
                                  strokeWidth: 2.5),
                            )
                          : AnimatedRotation(
                              key: ValueKey('icon_${show.name}'),
                              turns: isExpanded ? 0.5 : 0,
                              duration: _animationDuration,
                              curve: Curves.easeInOutCubicEmphasized,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: isExpanded
                                      ? colorScheme.primaryContainer
                                      : colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isExpanded
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(Icons.keyboard_arrow_down_rounded,
                                    color: isExpanded
                                        ? colorScheme.onPrimaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    size: 20),
                              ),
                            ),
                    ),
                  ),
                if (shouldShowBadge)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: _buildBadge(context, show),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    bool showGlow = settingsProvider.showGlowBorder;

    bool useRgb = false;

    if (settingsProvider.highlightPlayingWithRgb && isPlaying) {
      useRgb = true;
    }

    if (showGlow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: AnimatedGradientBorder(
          showGlow: true,
          borderRadius: 28,
          borderWidth: 2,
          colors: useRgb
              ? const [
                  Colors.red,
                  Colors.orange,
                  Colors.yellow,
                  Colors.green,
                  Colors.blue,
                  Colors.indigo,
                  Colors.purple,
                  Colors.red, // Repeat first color for smooth loop
                ]
              : null,
          backgroundColor: Colors.transparent,
          child: cardContent,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: cardBorderColor,
              width: (isPlaying || show.hasFeaturedTrack) ? 2 : 1),
        ),
        child: cardContent,
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final String badgeText;
    if (show.sources.length == 1 && settingsProvider.showSingleShnid) {
      badgeText = show.sources.first.id.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      badgeText = '${show.sources.length}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const BoxConstraints(maxWidth: 70),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer.withOpacity(0.7),
            colorScheme.secondaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }
}
