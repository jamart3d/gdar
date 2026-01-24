import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:provider/provider.dart';

import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/font_layout_config.dart';

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
    final bool shouldShowBadge = !widget.isExpanded &&
        (widget.show.sources.length > 1 ||
            (widget.show.sources.length == 1 &&
                settingsProvider.showSingleShnid));

    // Get configuration for current font
    final config = FontLayoutConfig.getConfig(settingsProvider.appFont);

    // Text Scaling Logic
    // Use shared logic ensuring consistency across all screens
    final effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // Force Base 15 to prevent clipping in compact card
    final baseVenueStyle = textTheme.bodyLarge?.copyWith(fontSize: 15.0) ??
        const TextStyle(fontSize: 15.0);
    final venueStyle =
        baseVenueStyle.apply(fontSizeFactor: effectiveScale).copyWith(
              color: colorScheme.onSurface,
            );

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

    // Force Base 9.5 to prevent clipping in compact card (Standard).
    final baseDateStyle = textTheme.bodySmall?.copyWith(fontSize: 9.5) ??
        const TextStyle(fontSize: 9.5);
    final dateStyle =
        baseDateStyle.apply(fontSizeFactor: effectiveScale).copyWith(
              color: colorScheme.onSurfaceVariant,
              letterSpacing: 0.15,
            );

    // Determine font sizes based on content placement and font type.
    // Goal: Reduce DATE size for Rock Salt to avoid marquee, but keep VENUE legible.
    final bool isRockSalt = settingsProvider.appFont == 'rock_salt';
    final bool isCaveat = settingsProvider.appFont == 'caveat';
    final bool dateFirst = settingsProvider.dateFirstInShowCard;

    // Default Sizes
    double topSize = 15.0;
    double bottomSize = 9.5;

    if (isRockSalt) {
      if (dateFirst) {
        // Date is Top. Shrink Top slightly (15 -> 12) to help fit.
        // Venue is Bottom. Keep Bottom standard (9.5) so it doesn't get tiny.
        topSize = 12.0;
      } else {
        // Date is Bottom. Shrink Bottom (9.5 -> 7.0) to fit long dates.
        // Venue is Top. Keep Top standard (15.0).
        bottomSize = 7.0;
      }
    } else if (isCaveat) {
      if (settingsProvider.uiScale) {
        // UI Scale ON: Use smaller base because scaleFactor (1.2x) will boost it.
        topSize = 16.5;
        bottomSize = 10.0;
      } else {
        // UI Scale OFF: Use larger base for legibility.
        topSize = 22.0;
        bottomSize = 14.0;
      }
    }

    // Apply calculated sizes directly to the "Slot" base styles.
    // Top Slot always uses 'venueStyle' (BodyLarge base).
    // Bottom Slot always uses 'dateStyle' (BodySmall base).
    final finalTopStyle =
        venueStyle.copyWith(fontSize: topSize * effectiveScale);
    final finalBottomStyle =
        dateStyle.copyWith(fontSize: bottomSize * effectiveScale);

    Color backgroundColor = colorScheme.surface;

    // Only apply custom background color if NOT in "True Black" mode.
    // True Black mode applies if:
    // 1. Dynamic Color is OFF (Strict True Black)
    // 2. [REMOVED] Half Glow no longer implies True Black background logic directly here,
    //    but we still want to respect the user's "True Black" intent if they had it.
    //    However, per new requirements, "True Black" background is now just !useDynamicColor.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if ((!isTrueBlackMode || settingsProvider.glowMode == 50) &&
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
        padding: EdgeInsets.fromLTRB(16, 6, 16, widget.isExpanded ? 2 : 6),
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
            borderWidth:
                3, // Constant width to prevent shift (compromise between 2 and 4)
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
              // Tighten radius: Outer (28) - BorderWidth (4 or 2) = Inner (24 or 26)
              // Previously was hardcoded, ensuring exact math prevents gaps.
              borderRadius: 25, // Outer (28) - BorderWidth (3) = Inner (25)
              backgroundColor: backgroundColor,
              effectiveScale: effectiveScale,
              topStyle: finalTopStyle,
              bottomStyle: finalBottomStyle,
              shouldShowBadge: shouldShowBadge,
              settingsProvider: settingsProvider,
              colorScheme: colorScheme,
              formattedDate: formattedDate,
              config: config,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 6, 16, widget.isExpanded ? 2 : 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: widget.isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: cardBorderColor,
            width: 3, // Match AnimatedGradientBorder width to prevent shift
          ),
        ),
        child: _buildCardContent(
          context: context,
          borderRadius: 28,
          backgroundColor: backgroundColor,
          effectiveScale: effectiveScale,
          topStyle: finalTopStyle,
          bottomStyle: finalBottomStyle,
          shouldShowBadge: shouldShowBadge,
          settingsProvider: settingsProvider,
          colorScheme: colorScheme,
          formattedDate: formattedDate,
          config: config,
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required double effectiveScale,
    required TextStyle topStyle,
    required TextStyle bottomStyle,
    required bool shouldShowBadge,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
    required String formattedDate,
    required FontLayoutConfig config,
  }) {
    // Height scales exclusively by UI Scale (effectiveScale)
    // Base height 58.0 (Very Compact).
    final double cardHeight = 58.0 * effectiveScale;

    // Control zone width from config
    final double controlZoneWidth =
        config.baseControlZoneWidth * effectiveScale;

    // Left padding for expand icon if enabled
    final double leftContentPadding = 0.0 * effectiveScale;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
        // DEBUG: Show card boundary
        border: settingsProvider.showDebugLayout
            ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          child: Stack(
            clipBehavior: Clip
                .none, // Allow slight overlap if needed for precise corner placement
            children: [
              // 1. MAIN CONTENT (Review/Date)
              // Vertically centered in the fixed height
              Positioned.fill(
                right: controlZoneWidth, // Keep text away from controls
                child: Container(
                  // DEBUG: Show content area boundary
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: settingsProvider.showDebugLayout
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 2),
                  ),
                  padding: EdgeInsets.only(left: leftContentPadding),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 57,
                        child: Container(
                          alignment: Alignment
                              .centerLeft, // Center vertically to avoid clipping
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: settingsProvider.showDebugLayout
                                    ? Colors.yellow.withValues(alpha: 0.5)
                                    : Colors.transparent,
                                width: 1),
                          ),
                          padding: EdgeInsets.zero,
                          child: Container(
                            // Keep horizontal cushion, let centering handle vertical
                            padding:
                                const EdgeInsets.symmetric(horizontal: 4.0),
                            decoration: BoxDecoration(
                              color: settingsProvider.showDebugLayout
                                  ? Colors.green.withValues(alpha: 0.2)
                                  : Colors.transparent,
                              border: Border.all(
                                  color: settingsProvider.showDebugLayout
                                      ? Colors.green.withValues(alpha: 0.8)
                                      : Colors.transparent,
                                  width: 2),
                            ),
                            child: ConditionalMarquee(
                              text: settingsProvider.dateFirstInShowCard
                                  ? formattedDate
                                  : widget.show.venue,
                              style: topStyle.copyWith(
                                  height:
                                      1.3), // Relaxed line-height to prevent clipping
                              enableAnimation: settingsProvider.marqueeEnabled,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 43,
                        child: Container(
                          alignment: Alignment
                              .centerLeft, // Center vertically to avoid clipping
                          margin: const EdgeInsets.only(left: 4.0),
                          decoration: BoxDecoration(
                            color: settingsProvider.showDebugLayout
                                ? Colors.orange.withValues(alpha: 0.2)
                                : Colors.transparent,
                            border: Border.all(
                                color: settingsProvider.showDebugLayout
                                    ? Colors.orange.withValues(alpha: 0.8)
                                    : Colors.transparent,
                                width: 2),
                          ),
                          width: double.infinity,
                          // Keep horizontal cushion, let centering handle vertical
                          padding: const EdgeInsets.symmetric(horizontal: 4.0),
                          child: Text(
                            settingsProvider.dateFirstInShowCard
                                ? widget.show.venue
                                : formattedDate,
                            style: bottomStyle.copyWith(
                                height:
                                    1.3), // Relaxed line-height to prevent clipping
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. EXPAND ICON (Bottom Left)
              if (settingsProvider.showExpandIcon)
                Positioned(
                  left: 8.0 * effectiveScale,
                  bottom: 8.0 * effectiveScale,
                  child: AnimatedSwitcher(
                    duration: _animationDuration,
                    child: widget.isLoading
                        ? Container(
                            key: ValueKey('loader_${widget.show.name}'),
                            width: 24 * effectiveScale,
                            height: 24 * effectiveScale,
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
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: widget.isExpanded
                                      ? colorScheme.primary
                                      : Colors.transparent,
                                  width: 1,
                                ),
                              ),
                              child: Icon(Icons.keyboard_arrow_down_rounded,
                                  color: widget.isExpanded
                                      ? colorScheme.onPrimaryContainer
                                      : colorScheme.onSurfaceVariant,
                                  size: 16 * effectiveScale),
                            ),
                          ),
                  ),
                ),

              // 3. RIGHT CONTROLS: Rating & Badges
              // Pinned top-to-bottom to balance elements
              Positioned(
                top: 6.0 * effectiveScale,
                bottom: 4.0 * effectiveScale,
                right: 12.0 * effectiveScale,
                child: _buildBalancedControls(context, widget.show,
                    settingsProvider, effectiveScale, shouldShowBadge),
              ),
            ],
          ),
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0),
      constraints: const BoxConstraints(maxWidth: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            fontSize: (settingsProvider.appFont == 'rock_salt')
                ? 4.5 *
                    FontLayoutConfig.getEffectiveScale(
                        context, settingsProvider)
                : 7 *
                    FontLayoutConfig.getEffectiveScale(
                        context, settingsProvider),
            height: (settingsProvider.appFont == 'rock_salt') ? 2.0 : 1.5,
            letterSpacing: (settingsProvider.appFont == 'rock_salt' ||
                    settingsProvider.appFont == 'permanent_marker')
                ? 1.5
                : 0.0),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildBalancedControls(BuildContext context, Show show,
      SettingsProvider settings, double effectiveScale, bool shouldShowBadge) {
    // Determine the source to show ratings for
    Source? targetSource;

    if (widget.isPlaying && widget.playingSource != null) {
      targetSource = widget.playingSource!;
    } else if (show.sources.length == 1) {
      targetSource = show.sources.first;
    }

    final String? badgeSrc = targetSource?.src;
    // Show rating if we have a specific target source
    final bool showRating = targetSource != null;
    final String? ratingKey = targetSource?.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: CatalogService().historyListenable,
          builder: (context, __, ___) {
            final catalog = CatalogService();
            // Rating vars
            int rating = 0;
            bool isPlayed = false;

            if (ratingKey != null) {
              rating = catalog.getRating(ratingKey);
              isPlayed = catalog.isPlayed(ratingKey);
            }

            // 1. Rating Stars
            // 2. Src Badge
            // 3. Shnid Badge

            // Determine visibility for SrcBadge
            final bool shouldShowSrcBadge =
                badgeSrc != null && !widget.isExpanded;

            final List<Widget> columnChildren = [];

            if (showRating && ratingKey != null) {
              columnChildren.add(
                Padding(
                  padding: const EdgeInsets.only(bottom: 0.0, top: 0.0),
                  child: RatingControl(
                    rating: rating,
                    isPlayed: isPlayed,
                    size: 20, // Constant size to prevent shift
                    compact: true,
                    onTap: (widget.isPlaying ||
                            widget.alwaysShowRatingInteraction ||
                            show.sources.length == 1)
                        ? () async {
                            await showDialog(
                              context: context,
                              builder: (context) => RatingDialog(
                                initialRating: rating,
                                sourceId: ratingKey,
                                isPlayed: isPlayed,
                                onRatingChanged: (newRating) {
                                  catalog.setRating(ratingKey, newRating);
                                },
                                onPlayedChanged: (bool newIsPlayed) {
                                  if (newIsPlayed !=
                                      catalog.isPlayed(ratingKey)) {
                                    catalog.togglePlayed(ratingKey);
                                  }
                                },
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              );
            }

            if (shouldShowSrcBadge) {
              Widget srcBadge = SrcBadge(
                src: badgeSrc,
                fontSize: shouldShowBadge ? 4.5 : 7.0,
                padding: shouldShowBadge
                    ? EdgeInsets.symmetric(
                        horizontal: 3.0 * effectiveScale,
                        vertical: 1.0,
                      )
                    : null,
              );

              if (!shouldShowBadge) {
                srcBadge = Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: srcBadge,
                );
              }

              columnChildren.add(srcBadge);
            }

            if (shouldShowBadge) {
              columnChildren.add(_buildBadge(context, show));
            }

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: columnChildren.map((widget) {
                return Container(
                  // DEBUG: Show weighted distribution
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: settings.showDebugLayout
                          ? Colors.purple.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  child: widget,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
