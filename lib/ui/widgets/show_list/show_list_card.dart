import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/show_list/card_style_utils.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';

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
  bool _isHovered = false;

  void _onHover(bool isHovering) {
    if (_isHovered != isHovering) {
      setState(() => _isHovered = isHovering);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit && kIsWeb;

    final style = CardStyle.compute(
      context: context,
      show: widget.show,
      isExpanded: widget.isExpanded,
      isPlaying: widget.isPlaying,
      playingSource: widget.playingSource,
      settings: settingsProvider,
      isHovered: _isHovered,
    );

    final hPadding = settingsProvider.performanceMode ? 8.0 : 16.0;
    final outerPadding = EdgeInsets.fromLTRB(
      hPadding,
      isTv ? 2 : 6, // Minimal top padding for TV
      hPadding,
      widget.isExpanded ? 2 : (isTv ? 2 : 6), // Minimal bottom padding for TV
    );

    Widget content;

    if ((style.showGlow || style.useRgb) && !style.suppressOuterGlow) {
      content = Padding(
        padding: outerPadding,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(isFruit ? 14 : 28),
            boxShadow: (style.showShadow &&
                    !style.useRgb &&
                    !settingsProvider.performanceMode)
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(
                          alpha: (0.2 + (_isHovered ? 0.1 : 0)) *
                              0.2 *
                              style.glowOpacity),
                      blurRadius: _isHovered ? 16 : 12,
                      spreadRadius: _isHovered ? 3 : 2,
                    ),
                  ]
                : [],
          ),
          child: AnimatedGradientBorder(
            borderRadius: isTv ? 12 : (isFruit ? 14 : 28),
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
            child: NeumorphicWrapper(
              enabled: isFruit && settingsProvider.useNeumorphism,
              borderRadius: isFruit ? 14 : 28,
              intensity: 1.2, // Increased for stronger effect
              child: LiquidGlassWrapper(
                enabled: isFruit && !settingsProvider.useTrueBlack,
                borderRadius: BorderRadius.circular(isFruit ? 14 : 28),
                blur: 15,
                opacity: _isHovered ? 0.6 : 0.7,
                color: style.backgroundColor,
                child: _buildCardContent(
                  context: context,
                  borderRadius: isFruit ? 14 : 28,
                  backgroundColor: isFruit && !settingsProvider.useTrueBlack
                      ? Colors.transparent
                      : style.backgroundColor,
                  style: style,
                  settingsProvider: settingsProvider,
                  colorScheme: colorScheme,
                  isTv: isTv,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      content = Padding(
        padding: outerPadding,
        child: Card(
          margin: EdgeInsets.zero,
          elevation: widget.isExpanded ? 2 : 0,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
                isTv ? 12 : (isFruit ? 14 : 28)), // Refined Fruit radius
            side: BorderSide(
              color: style.cardBorderColor,
              width: style.cardBorderWidth,
            ),
          ),
          child: NeumorphicWrapper(
            enabled: isFruit &&
                settingsProvider.useNeumorphism &&
                !settingsProvider.performanceMode,
            borderRadius: isTv ? 12 : (isFruit ? 14 : 28),
            intensity: 1.2, // Increased for stronger effect
            child: LiquidGlassWrapper(
              enabled: isFruit && !settingsProvider.useTrueBlack,
              borderRadius:
                  BorderRadius.circular(isTv ? 12 : (isFruit ? 14 : 28)),
              blur: 15,
              opacity: _isHovered ? 0.6 : 0.7,
              color: style.backgroundColor,
              child: _buildCardContent(
                context: context,
                borderRadius: isFruit ? 14 : 28,
                backgroundColor: isFruit && !settingsProvider.useTrueBlack
                    ? Colors.transparent
                    : style.backgroundColor,
                style: style,
                settingsProvider: settingsProvider,
                colorScheme: colorScheme,
                isTv: isTv,
              ),
            ),
          ),
        ),
      );
    }

    if (isFruit && !settingsProvider.performanceMode) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        transform: Matrix4.identity()
          ..scaleByDouble(
              _isHovered ? 1.012 : 1.0, _isHovered ? 1.012 : 1.0, 1.0, 1.0),
        transformAlignment: Alignment.center,
        child: content,
      );

      if (kIsWeb) {
        content = MouseRegion(
          onEnter: (_) => _onHover(true),
          onExit: (_) => _onHover(false),
          cursor: SystemMouseCursors.click,
          child: content,
        );
      }
    }

    return content;
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
    const bool isWeb = kIsWeb;
    final bool isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool useMobileLayout = isWeb && screenWidth < 768;

    // Use tighter mobile-style heights for both themes on narrow screens
    final double baseHeight = isTv
        ? 48.0
        : (useMobileLayout
            ? 54.0
            : (isFruit ? 34.0 : 40.0)); // Shorter Android row height (40)
    final double cardHeight = baseHeight * style.effectiveScale;
    final double controlZoneWidth = (isFruit || !useMobileLayout)
        ? (useMobileLayout ? 84.0 : 140.0) * style.effectiveScale
        : (style.config.baseControlZoneWidth * style.effectiveScale);

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
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.only(
                      left:
                          (useMobileLayout ? 16.0 : 8.0) * style.effectiveScale,
                    ),
                    child: (!useMobileLayout)
                        ? Row(
                            children: [
                              Text(
                                style.formattedDate,
                                style: style.topStyle.copyWith(
                                    fontSize: 14 * style.effectiveScale,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.show.venue,
                                  style: style.bottomStyle.copyWith(
                                    fontSize: 13 * style.effectiveScale,
                                    color: style.bottomStyle.color
                                        ?.withValues(alpha: 0.6),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                style.formattedDate,
                                style: style.topStyle.copyWith(
                                    fontSize: 14 * style.effectiveScale,
                                    fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                widget.show.venue,
                                style: style.bottomStyle.copyWith(
                                  fontSize: 13 * style.effectiveScale,
                                  color: style.bottomStyle.color
                                      ?.withValues(alpha: 0.6),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
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
    final bool isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit && kIsWeb;

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
      padding: isFruit
          ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1.0)
          : const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0),
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
                ? (isFruit ? 7.5 : 4.5) * effectiveScale
                : (isFruit ? 9.5 : 7.0) * effectiveScale,
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

    final bool showRating = targetSource != null;
    final String? ratingKey = targetSource?.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, __) {
        return ValueListenableBuilder(
          valueListenable: CatalogService().historyListenable,
          builder: (context, __, ___) {
            final isFruit =
                context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit &&
                    kIsWeb;
            final double screenWidth = MediaQuery.of(context).size.width;
            final bool useMobileLayout = isFruit && screenWidth < 768;

            final catalog = CatalogService();
            int rating = 0;
            bool isPlayed = false;

            if (ratingKey != null) {
              rating = catalog.getRating(ratingKey);
              isPlayed = catalog.isPlayed(ratingKey);
            }

            final String? badgeSrc = targetSource?.src;
            final bool shouldShowSrcBadge =
                badgeSrc != null && !widget.isExpanded;
            final List<Widget> columnChildren = [];
            final List<Widget> badgeRowChildren = [];

            if (shouldShowSrcBadge) {
              Widget srcBadge = SrcBadge(
                src: badgeSrc,
                fontSize: shouldShowBadge
                    ? (isFruit ? 8.5 : 9.0)
                    : (isFruit ? 10.5 : 11.0),
                padding: shouldShowBadge
                    ? EdgeInsets.symmetric(
                        horizontal: 6.0 * effectiveScale,
                        vertical: isFruit ? 2.0 : 3.0,
                      )
                    : null,
              );

              if (!shouldShowBadge) {
                srcBadge = Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: srcBadge,
                );
              }
              badgeRowChildren.add(srcBadge);
            }

            if (shouldShowBadge) {
              if (badgeRowChildren.isNotEmpty) {
                badgeRowChildren.add(const SizedBox(width: 4.0));
              }
              badgeRowChildren.add(_buildBadge(context, show, effectiveScale));
            }

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

            if (badgeRowChildren.isNotEmpty) {
              columnChildren.add(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: badgeRowChildren,
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: useMobileLayout
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (showRating && ratingKey != null)
                            RatingControl(
                              rating: rating,
                              isPlayed: isPlayed,
                              size: 19,
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
                                            catalog.setRating(
                                                ratingKey, newRating);
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
                          const SizedBox(height: 2),
                          if (badgeRowChildren.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: badgeRowChildren,
                            ),
                        ],
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showRating && ratingKey != null)
                          RatingControl(
                            rating: rating,
                            isPlayed: isPlayed,
                            size: 19,
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
                                          catalog.setRating(
                                              ratingKey, newRating);
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
                        if (showRating &&
                            ratingKey != null &&
                            badgeRowChildren.isNotEmpty)
                          const SizedBox(width: 8),
                        if (badgeRowChildren.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: badgeRowChildren,
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }
}
