import 'package:flutter/material.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:provider/provider.dart';

import 'package:gdar/ui/widgets/rating_control.dart';
import 'package:gdar/utils/color_generator.dart';

class ShowListCard extends StatefulWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final String? playingSourceId;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool alwaysShowRatingInteraction;

  const ShowListCard({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    this.playingSourceId,
    required this.isLoading,
    required this.onTap,
    required this.onLongPress,
    this.alwaysShowRatingInteraction = false,
  });

  @override
  State<ShowListCard> createState() => _ShowListCardState();
}

class _ShowListCardState extends State<ShowListCard> {
  static const Duration _animationDuration = Duration(milliseconds: 300);
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final cardBorderColor = widget.isPlaying
        ? colorScheme.primary
        : widget.show.hasFeaturedTrack
            ? colorScheme.tertiary
            : colorScheme.outlineVariant;
    final bool shouldShowBadge = widget.show.sources.length > 1 ||
        (widget.show.sources.length == 1 && settingsProvider.showSingleShnid);

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

    // Only apply custom background color if NOT in "True Black" mode.
    // True Black mode applies if:
    // 1. Dynamic Color is OFF (Strict True Black)
    // 2. Dynamic Color is ON AND Half Glow is ON (Hybrid True Black)
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    if (!isTrueBlackMode &&
        widget.isPlaying &&
        settingsProvider.highlightCurrentShowCard) {
      String seed = widget.show.name;
      if (widget.show.sources.length > 1 && widget.playingSourceId != null) {
        seed = widget.playingSourceId!;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    // Determine if we should show the outer glow.
    // If the card is expanded and has multiple sources, we want the specific source item
    // inside to glow, NOT the outer card.
    bool suppressOuterGlow =
        widget.isExpanded && widget.show.sources.length > 1;

    bool showGlow = settingsProvider.showGlowBorder;
    bool useRgb = false;

    if (settingsProvider.highlightPlayingWithRgb && widget.isPlaying) {
      useRgb = true;
    }

    // In Strict True Black mode (!useDynamicColor), we ONLY show the border/glow if it's the playing card.
    // In Half Glow mode (useDynamicColor && halfGlowDynamic), we allow glow but reduced.
    if (isDarkMode && !settingsProvider.useDynamicColor && !widget.isPlaying) {
      showGlow = false;
    }

    // Shadow Visibility:
    // 1. Strict True Black (!useDynamicColor): NO Shadow.
    // 2. Half Glow (useDynamicColor && halfGlowDynamic): YES Shadow (Half Opacity).
    // 3. Standard Dark (useDynamicColor && !halfGlowDynamic): YES Shadow (Full Opacity).
    bool showShadow = !(isDarkMode &&
        !settingsProvider.useDynamicColor); // Only hide in strict true black

    double glowOpacity = settingsProvider.halfGlowDynamic ? 0.5 : 1.0;

    if ((showGlow || useRgb) && !suppressOuterGlow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: showShadow
                ? [
                    BoxShadow(
                      color: (useRgb ? Colors.red : colorScheme.primary)
                          .withOpacity((useRgb ? 0.4 : 0.2) * glowOpacity),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedGradientBorder(
            borderRadius: 28,
            borderWidth: useRgb ? 4 : 2,
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
            showShadow: showShadow,
            glowOpacity: 0.5 * glowOpacity, // Base 0.5 * factor
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: _buildCardContent(
              context: context,
              borderRadius: useRgb ? 24 : 26,
              backgroundColor: backgroundColor,
              scaleFactor: scaleFactor,
              venueStyle: venueStyle,
              dateStyle: dateStyle,
              shouldShowBadge: shouldShowBadge,
              settingsProvider: settingsProvider,
              colorScheme: colorScheme,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: widget.isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: (isTrueBlackMode && !widget.isPlaying)
              ? BorderSide(color: colorScheme.outlineVariant, width: 1)
              : BorderSide(
                  color: cardBorderColor,
                  width: (widget.isPlaying || widget.show.hasFeaturedTrack)
                      ? 2
                      : 1),
        ),
        child: _buildCardContent(
          context: context,
          borderRadius: 28,
          backgroundColor: backgroundColor,
          scaleFactor: scaleFactor,
          venueStyle: venueStyle,
          dateStyle: dateStyle,
          shouldShowBadge: shouldShowBadge,
          settingsProvider: settingsProvider,
          colorScheme: colorScheme,
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required double scaleFactor,
    required TextStyle venueStyle,
    required TextStyle dateStyle,
    required bool shouldShowBadge,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
  }) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
      ),
      child: Stack(
        children: [
          Semantics(
            label:
                '${widget.show.venue} on ${widget.show.formattedDate}. ${widget.isPlaying ? "Playing" : ""}',
            hint: widget.isExpanded
                ? 'Double tap to collapse'
                : 'Double tap to expand',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: widget.onTap,
                onLongPress: widget.onLongPress,
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
                                  left:
                                      settingsProvider.showExpandIcon ? 32 : 0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  SizedBox(
                                    height: venueStyle.fontSize! * 1.3,
                                    child: ConditionalMarquee(
                                      text: settingsProvider.dateFirstInShowCard
                                          ? widget.show.formattedDate
                                          : widget.show.venue,
                                      style: venueStyle,
                                    ),
                                  ),
                                  SizedBox(height: 6 * scaleFactor),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      settingsProvider.dateFirstInShowCard
                                          ? widget.show.venue
                                          : widget.show.formattedDate,
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
                            child: widget.isLoading
                                ? Container(
                                    key: ValueKey('loader_${widget.show.name}'),
                                    width: 28,
                                    height: 28,
                                    padding: const EdgeInsets.all(4),
                                    child: const CircularProgressIndicator(
                                        strokeWidth: 2.5),
                                  )
                                : AnimatedRotation(
                                    key: ValueKey('icon_${widget.show.name}'),
                                    turns: widget.isExpanded ? 0.5 : 0,
                                    duration: _animationDuration,
                                    curve: Curves.easeInOutCubicEmphasized,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: widget.isExpanded
                                            ? colorScheme.primaryContainer
                                            : colorScheme
                                                .surfaceContainerHighest,
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: widget.isExpanded
                                              ? colorScheme.primary
                                              : Colors.transparent,
                                          width: 1,
                                        ),
                                      ),
                                      child: Icon(
                                          Icons.keyboard_arrow_down_rounded,
                                          color: widget.isExpanded
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
                          child: _buildBadge(context, widget.show),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 10.0 * scaleFactor,
            top: 10.0 * scaleFactor,
            child: _buildRatingButton(context, widget.show, settingsProvider),
          ),
        ],
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

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    final List<Color> gradientColors;
    if (isTrueBlackMode) {
      gradientColors = [
        Colors.black,
        Colors.black,
      ];
    } else {
      gradientColors = [
        colorScheme.secondaryContainer.withOpacity(0.7),
        colorScheme.secondaryContainer.withOpacity(0.5),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      constraints: const BoxConstraints(maxWidth: 70),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
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

  Widget _buildRatingButton(
      BuildContext context, Show show, SettingsProvider settings) {
    // If multiple sources, ratings are handled on the individual source items.
    if (show.sources.length > 1) {
      return const SizedBox.shrink();
    }

    final rating = settings.getRating(show.name);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: RatingControl(
        rating: rating,
        isPlayed: settings.isPlayed(show.name),
        size: 20,
        onTap: (widget.isPlaying || widget.alwaysShowRatingInteraction)
            ? () async {
                await showDialog(
                  context: context,
                  builder: (context) => RatingDialog(
                    initialRating: rating,
                    sourceId: null,
                    isPlayed: settings.isPlayed(show.name),
                    onRatingChanged: (newRating) {
                      settings.setRating(show.name, newRating);
                    },
                    onPlayedChanged: (bool isPlayed) {
                      if (isPlayed != settings.isPlayed(show.name)) {
                        settings.togglePlayed(show.name);
                      }
                    },
                  ),
                );
              }
            : null,
      ),
    );
  }
}
