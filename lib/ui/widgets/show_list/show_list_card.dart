import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:provider/provider.dart';

import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/show_list/card_style_utils.dart';

/// A card displaying summary information for a [Show].
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
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;

    final style = CardStyle.compute(
      context: context,
      show: widget.show,
      isExpanded: widget.isExpanded,
      isPlaying: widget.isPlaying,
      playingSource: widget.playingSource,
      settings: settingsProvider,
    );

    final outerPadding = EdgeInsets.fromLTRB(
      16,
      isTv ? 12 : 6,
      16,
      widget.isExpanded ? 2 : (isTv ? 12 : 6),
    );

    if ((style.showGlow || style.useRgb) && !style.suppressOuterGlow) {
      return Padding(
        padding: outerPadding,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: (style.showShadow && !style.useRgb)
                ? [
                    BoxShadow(
                      color: colorScheme.primary
                          .withValues(alpha: 0.2 * 0.2 * style.glowOpacity),
                      blurRadius: 12,
                      spreadRadius: 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedGradientBorder(
            borderRadius: 28,
            borderWidth: 3,
            colors: style.useRgb
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
            showShadow: !isTv && style.showShadow,
            glowOpacity: (style.useRgb ? 0.5 : 0.2) * style.glowOpacity,
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            child: _buildCardContent(
              context: context,
              borderRadius: 25,
              backgroundColor: style.backgroundColor,
              style: style,
              settingsProvider: settingsProvider,
              colorScheme: colorScheme,
              isTv: isTv,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: outerPadding,
      child: Card(
        margin: EdgeInsets.zero,
        elevation: widget.isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTv ? 100 : 28),
          side: BorderSide(
            color: style.cardBorderColor,
            width: 3,
          ),
        ),
        child: _buildCardContent(
          context: context,
          borderRadius: 28,
          backgroundColor: style.backgroundColor,
          style: style,
          settingsProvider: settingsProvider,
          colorScheme: colorScheme,
          isTv: isTv,
        ),
      ),
    );
  }

  Widget _buildCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required CardStyle style,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
    required bool isTv,
  }) {
    final double cardHeight = (isTv ? 76.0 : 58.0) * style.effectiveScale;
    final double controlZoneWidth =
        style.config.baseControlZoneWidth * style.effectiveScale;

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
        border: settingsProvider.showDebugLayout
            ? Border.all(color: Colors.red.withValues(alpha: 0.3), width: 2)
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          canRequestFocus: !isTv,
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                right: controlZoneWidth,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                        color: settingsProvider.showDebugLayout
                            ? Colors.blue.withValues(alpha: 0.3)
                            : Colors.transparent,
                        width: 2),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Column(
                    children: [
                      Expanded(
                        flex: 57,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: ConditionalMarquee(
                              text: settingsProvider.dateFirstInShowCard
                                  ? style.formattedDate
                                  : widget.show.venue,
                              style: style.topStyle.copyWith(height: 1.3),
                              enableAnimation: settingsProvider.marqueeEnabled,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 43,
                        child: Container(
                          alignment: Alignment.centerLeft,
                          margin: const EdgeInsets.only(left: 4.0),
                          width: double.infinity,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              settingsProvider.dateFirstInShowCard
                                  ? widget.show.venue
                                  : style.formattedDate,
                              style: style.bottomStyle.copyWith(height: 1.3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (settingsProvider.showExpandIcon)
                Positioned(
                  left: 8.0 * style.effectiveScale,
                  bottom: 8.0 * style.effectiveScale,
                  child: AnimatedSwitcher(
                    duration: _animationDuration,
                    child: widget.isLoading
                        ? Container(
                            key: ValueKey('loader_${widget.show.name}'),
                            width: 24 * style.effectiveScale,
                            height: 24 * style.effectiveScale,
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
                                  size: 16 * style.effectiveScale),
                            ),
                          ),
                  ),
                ),
              Positioned(
                top: 6.0 * style.effectiveScale,
                bottom: 4.0 * style.effectiveScale,
                right: 12.0 * style.effectiveScale,
                child: _buildBalancedControls(
                    context,
                    widget.show,
                    settingsProvider,
                    style.effectiveScale,
                    style.shouldShowBadge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Show show, double effectiveScale) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();

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

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors = isTrueBlackMode
        ? [Colors.black, Colors.black]
        : [
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ];

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
                ? 4.5 * effectiveScale
                : 7 * effectiveScale,
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
    Source? targetSource;

    if (widget.isPlaying && widget.playingSource != null) {
      targetSource = widget.playingSource!;
    } else if (show.sources.length == 1) {
      targetSource = show.sources.first;
    }

    final String? badgeSrc = targetSource?.src;
    final bool showRating = targetSource != null;
    final String? ratingKey = targetSource?.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: CatalogService().historyListenable,
          builder: (context, __, ___) {
            final catalog = CatalogService();
            int rating = 0;
            bool isPlayed = false;

            if (ratingKey != null) {
              rating = catalog.getRating(ratingKey);
              isPlayed = catalog.isPlayed(ratingKey);
            }

            final bool shouldShowSrcBadge =
                badgeSrc != null && !widget.isExpanded;
            final List<Widget> columnChildren = [];

            if (showRating && ratingKey != null) {
              columnChildren.add(
                RatingControl(
                  rating: rating,
                  isPlayed: isPlayed,
                  size: 20,
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
              columnChildren.add(_buildBadge(context, show, effectiveScale));
            }

            return Column(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: columnChildren.map((w) {
                return Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: settings.showDebugLayout
                          ? Colors.purple.withValues(alpha: 0.5)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  alignment: Alignment.centerRight,
                  child: w,
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}
