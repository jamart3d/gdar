import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:provider/provider.dart';

import 'package:gdar/ui/widgets/rating_control.dart';
import 'package:gdar/ui/widgets/src_badge.dart';
import 'package:gdar/utils/color_generator.dart';

class ShowListCard extends StatefulWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final Source? playingSource;
  final bool isLoading;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final bool alwaysShowRatingInteraction;

  const ShowListCard({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    this.playingSource,
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

    // Date Formatting Logic
    String dateFormatPattern = '';
    if (settingsProvider.showDayOfWeek) {
      dateFormatPattern +=
          settingsProvider.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
    }
    dateFormatPattern += settingsProvider.abbreviateMonth ? 'MMM' : 'MMMM';
    dateFormatPattern += ' d, y';

    final String formattedDate = () {
      try {
        final date = DateTime.parse(widget.show.date);
        return DateFormat(dateFormatPattern).format(date);
      } catch (e) {
        return widget.show.date;
      }
    }();

    final baseDateStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final dateStyle = baseDateStyle
        .copyWith(color: colorScheme.onSurfaceVariant, letterSpacing: 0.15)
        .apply(fontSizeFactor: scaleFactor);

    Color backgroundColor = colorScheme.surface;

    // Only apply custom background color if NOT in "True Black" mode.
    // True Black mode applies if:
    // 1. Dynamic Color is OFF (Strict True Black)
    // 2. [REMOVED] Half Glow no longer implies True Black background logic directly here,
    //    but we still want to respect the user's "True Black" intent if they had it.
    //    However, per new requirements, "True Black" background is now just !useDynamicColor.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if ((!isTrueBlackMode || settingsProvider.halfGlowDynamic) &&
        widget.isPlaying &&
        settingsProvider.highlightCurrentShowCard) {
      String seed = widget.show.name;
      if (widget.playingSource != null) {
        seed = widget.playingSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    // Determine if we should show the outer glow.
    // If the card is expanded and has multiple sources, we want the specific source item
    // inside to glow, NOT the outer card.
    bool suppressOuterGlow =
        widget.isExpanded && widget.show.sources.length > 1;

    // Glow Mode: 0 = Off, 10-100 = Intensity percentage
    bool showGlow = settingsProvider.glowMode > 0;
    bool useRgb = false;

    if (settingsProvider.highlightPlayingWithRgb && widget.isPlaying) {
      useRgb = true;
    }

    // Shadow Visibility:
    // 1. Glow Mode is 0 (Off): NO Shadow.
    // 2. True Black Mode: NO Shadow (User preference for pitch black).
    // 3. Otherwise: YES Shadow if Glow is On (>0).
    bool showShadow = settingsProvider.glowMode > 0 &&
        !(isDarkMode && settingsProvider.useTrueBlack);

    // Glow Strength Logic:
    // Base opacity from percentage: glowMode / 100 (e.g., 50% = 0.5)
    // Playing: Full percentage strength
    // Not Playing: Quarter of percentage strength
    double baseOpacity = settingsProvider.glowMode / 100.0;
    double glowOpacity = widget.isPlaying ? baseOpacity : baseOpacity * 0.25;

    if ((showGlow || useRgb) && !suppressOuterGlow) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: (showShadow &&
                    !useRgb) // Only use standard shadow if NOT using RGB
                ? [
                    BoxShadow(
                      // Cut non-RGB glow by 80% (so utilize 20% of original strength)
                      color: colorScheme.primary
                          .withValues(alpha: 0.2 * 0.2 * glowOpacity),
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
            // RGB: 50% base * percentage * playing multiplier
            // Non-RGB: 20% base * percentage * playing multiplier
            glowOpacity: (useRgb ? 0.5 : 0.2) * glowOpacity,
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
              formattedDate: formattedDate,
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
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
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
          formattedDate: formattedDate,
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
    required String formattedDate,
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
                '${widget.show.venue} on $formattedDate. ${widget.isPlaying ? "Playing" : ""}',
            hint: widget.isExpanded
                ? 'Double tap to collapse'
                : 'Double tap to expand',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: () {
                  HapticFeedback.selectionClick();
                  widget.onTap();
                },
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
                                    height: venueStyle.fontSize! * 1.6,
                                    child: ConditionalMarquee(
                                      text: settingsProvider.dateFirstInShowCard
                                          ? formattedDate
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
                                          : formattedDate,
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
                          child: _buildBottomBadgeArea(
                            context,
                            widget.show,
                            settingsProvider,
                            scaleFactor,
                          ),
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
            child: _buildRatingButton(context, widget.show, settingsProvider,
                showSrcBadge: !(!settingsProvider.uiScale && shouldShowBadge)),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBadgeArea(BuildContext context, Show show,
      SettingsProvider settingsProvider, double scaleFactor) {
    // Calculate if we should show the src badge here
    String? badgeSrc;
    if (widget.isPlaying && widget.playingSource != null) {
      badgeSrc = widget.playingSource!.src;
    } else if (show.sources.length == 1) {
      badgeSrc = show.sources.first.src;
    }

    final bool placeSrcBadgeAtBottom =
        !settingsProvider.uiScale && badgeSrc != null;

    if (placeSrcBadgeAtBottom) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 2.0, right: 4.0),
            child: SrcBadge(src: badgeSrc),
          ),
          _buildBadge(context, show),
        ],
      );
    }

    return _buildBadge(context, show);
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final String badgeText;
    if (widget.isPlaying &&
        widget.playingSource != null &&
        settingsProvider.showSingleShnid) {
      badgeText = widget.playingSource!.id.replaceAll(RegExp(r'[^0-9]'), '');
    } else if (show.sources.length == 1 && settingsProvider.showSingleShnid) {
      badgeText = show.sources.first.id.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      badgeText = '${show.sources.length}';
    }

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors;
    if (isTrueBlackMode) {
      gradientColors = [
        Colors.black,
        Colors.black,
      ];
    } else {
      gradientColors = [
        colorScheme.secondaryContainer.withValues(alpha: 0.7),
        colorScheme.secondaryContainer.withValues(alpha: 0.5),
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
              color: colorScheme.shadow.withValues(alpha: 0.05),
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
      BuildContext context, Show show, SettingsProvider settings,
      {bool showSrcBadge = true}) {
    if (widget.isPlaying && widget.playingSource != null) {
      final source = widget.playingSource!;
      final rating = settings.getRating(source.id);
      bool isPlayed = settings.isPlayed(source.id);

      // determine badge string
      String? badgeSrc = source.src;

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RatingControl(
              rating: rating,
              isPlayed: isPlayed,
              size: 20,
              onTap: () async {
                await showDialog(
                  context: context,
                  builder: (context) => RatingDialog(
                    initialRating: rating,
                    sourceId: source.id,
                    isPlayed: isPlayed,
                    onRatingChanged: (newRating) {
                      settings.setRating(source.id, newRating);
                    },
                    onPlayedChanged: (bool isPlayed) {
                      if (isPlayed != settings.isPlayed(source.id)) {
                        settings.togglePlayed(source.id);
                      }
                    },
                  ),
                );
              },
            ),
            if (badgeSrc != null && showSrcBadge) ...[
              const SizedBox(height: 4),
              SrcBadge(src: badgeSrc),
            ],
          ],
        ),
      );
    }

    // If there are multiple sources visible (not filtered to 1), we don't show the rating on the card.
    if (show.sources.length > 1) {
      return const SizedBox.shrink();
    }

    // Always use the SOURCE ID for ratings/played status, even if only one source exists.
    final source = show.sources.first;
    final ratingKey = source.id;

    final rating = settings.getRating(ratingKey);
    bool isPlayed = settings.isPlayed(ratingKey);

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RatingControl(
            rating: rating,
            isPlayed: isPlayed,
            size: 20,
            onTap: (widget.isPlaying || widget.alwaysShowRatingInteraction)
                ? () async {
                    await showDialog(
                      context: context,
                      builder: (context) => RatingDialog(
                        initialRating: rating,
                        sourceId: ratingKey, // Always pass Source ID
                        isPlayed: isPlayed,
                        onRatingChanged: (newRating) {
                          settings.setRating(ratingKey, newRating);
                        },
                        onPlayedChanged: (bool newIsPlayed) {
                          if (newIsPlayed != settings.isPlayed(ratingKey)) {
                            settings.togglePlayed(ratingKey);
                          }
                        },
                      ),
                    );
                  }
                : null,
          ),
          if (source.src != null && showSrcBadge) ...[
            const SizedBox(height: 4),
            SrcBadge(src: source.src!),
          ],
        ],
      ),
    );
  }
}
