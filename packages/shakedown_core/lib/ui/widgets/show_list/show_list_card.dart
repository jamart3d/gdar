import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:provider/provider.dart';

import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/show_list/embedded_mini_player.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/show_list/card_style_utils.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';

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
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;

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
    this.focusNode,
    this.onKeyEvent,
    this.onFocusChange,
  });

  @override
  State<ShowListCard> createState() => _ShowListCardState();
}

class _ShowListCardState extends State<ShowListCard> {
  static const Duration _animationDuration = Duration(milliseconds: 80);
  bool _isHovered = false;

  void _onHover(bool isHovering) {
    if (_isHovered != isHovering) {
      setState(() => _isHovered = isHovering);
    }
    widget.onFocusChange?.call(isHovering);
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.isFruit;

    final style = CardStyle.compute(
      context: context,
      show: widget.show,
      isExpanded: widget.isExpanded,
      isPlaying: widget.isPlaying,
      playingSource: widget.playingSource,
      settings: settingsProvider,
      isHovered: _isHovered,
    );

    final hPadding = isTv
        ? 24.0
        : (settingsProvider.performanceMode ? 8.0 : 16.0);
    final vPadding = (isFruit && settingsProvider.fruitDenseList) ? 2.0 : 6.0;
    final outerPadding = EdgeInsets.fromLTRB(
      hPadding,
      isTv ? 2 : vPadding,
      hPadding,
      widget.isExpanded ? 2 : (isTv ? 2 : vPadding),
    );

    Widget content;

    if (!isTv && (style.showGlow || style.useRgb) && !style.suppressOuterGlow) {
      content = Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(isFruit ? 14 : 28),
          boxShadow:
              (style.showShadow &&
                  !style.useRgb &&
                  !settingsProvider.performanceMode)
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(
                      alpha:
                          (0.2 + (_isHovered ? 0.1 : 0)) *
                          0.2 *
                          style.glowOpacity,
                    ),
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
              enabled: isFruit && settingsProvider.fruitEnableLiquidGlass,
              borderRadius: BorderRadius.circular(isFruit ? 14 : 28),
              blur: 15,
              opacity: _isHovered ? 0.6 : 0.65,
              color: style.backgroundColor,
              child: _buildCardContent(
                context: context,
                borderRadius: isTv ? 12 : (isFruit ? 14 : 28),
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
    } else {
      content = Card(
        margin: EdgeInsets.zero,
        elevation: widget.isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            isTv ? 12 : (isFruit ? 14 : 28),
          ), // Refined Fruit radius
          side: BorderSide(
            color: isTv ? Colors.transparent : style.cardBorderColor,
            width: isFruit ? 0.8 : (isTv ? 0 : style.cardBorderWidth),
          ),
        ),
        child: NeumorphicWrapper(
          enabled:
              isFruit &&
              settingsProvider.useNeumorphism &&
              !settingsProvider.performanceMode,
          borderRadius: isTv ? 12 : (isFruit ? 14 : 28),
          intensity: 1.2, // Increased for stronger effect
          child: LiquidGlassWrapper(
            enabled: isFruit && settingsProvider.fruitEnableLiquidGlass,
            borderRadius: BorderRadius.circular(
              isTv ? 12 : (isFruit ? 14 : 28),
            ),
            blur: 15,
            opacity: _isHovered ? 0.6 : 0.7,
            color: style.backgroundColor,
            child: _buildCardContent(
              context: context,
              borderRadius: isTv ? 12 : (isFruit ? 14 : 28),
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
      );
    }

    if (isFruit && !settingsProvider.performanceMode && !isTv) {
      content = AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        curve: Curves.fastOutSlowIn,
        transform: Matrix4.identity()
          ..scaleByDouble(
            _isHovered ? 1.012 : 1.0,
            _isHovered ? 1.012 : 1.0,
            1.0,
            1.0,
          ),
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

    if (isTv) {
      content = TvFocusWrapper(
        focusNode: widget.focusNode,
        onKeyEvent: widget.onKeyEvent,
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        borderRadius: BorderRadius.circular(12),
        onFocusChange: _onHover,
        isPlaying: widget.isPlaying,
        showGlow: true,
        // Prevent the playing show from stealing the premium glow —
        // that glow is strictly reserved for the actively focused item.
        overridePremiumHighlight: widget.isPlaying ? false : null,
        child: content,
      );
    }

    return Padding(padding: outerPadding, child: content);
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
    final bool isFruit = context.read<ThemeProvider>().isFruit;
    final double screenWidth = MediaQuery.of(context).size.width;
    final deviceService = context.watch<DeviceService>();
    final bool useMobileLayout =
        isWeb &&
        (screenWidth < 850 || deviceService.isPwa || deviceService.isMobile) &&
        !isTv;
    final bool usePremium = settingsProvider.useNeumorphism && isFruit;

    // --- Fruit Mobile: vertical card layout (Stitch design) ---
    if (isFruit && useMobileLayout && !isTv) {
      return _buildFruitMobileCardContent(
        context: context,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        style: style,
        settingsProvider: settingsProvider,
        colorScheme: colorScheme,
        usePremium: usePremium,
      );
    }

    // Use tighter mobile-style heights for both themes on narrow screens
    final double baseHeight = isTv
        ? 48.0
        : (useMobileLayout
              ? 54.0
              : (isFruit
                    ? 48.0
                    : 58.0)); // v135 standard height for phone: 58.0
    final double cardHeight = baseHeight * style.effectiveScale;
    final bool isDesktopInlinePlaying =
        kIsWeb && !useMobileLayout && !isTv && widget.isPlaying;
    final double controlZoneWidth = (kIsWeb)
        ? ((isFruit || !useMobileLayout)
                  ? (useMobileLayout ? 84.0 : (isFruit ? 180.0 : 140.0))
                  : style.config.baseControlZoneWidth) *
              style.effectiveScale
        : (style.config.baseControlZoneWidth * style.effectiveScale);
    final double effectiveControlZoneWidth = isDesktopInlinePlaying
        ? (340.0 * style.effectiveScale)
        : controlZoneWidth;

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
            if (!isTv) {
              AppHaptics.selectionClick(context.read<DeviceService>());
            }
            widget.onTap();
          },
          onLongPress: widget.onLongPress,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                right: effectiveControlZoneWidth,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: settingsProvider.showDebugLayout
                          ? Colors.blue.withValues(alpha: 0.3)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Container(
                    alignment: Alignment.centerLeft,
                    padding: EdgeInsets.symmetric(
                      horizontal: isTv ? 6.0 : 12.0,
                    ),
                    child: Builder(
                      builder: (context) {
                        final Widget textArea = (!kIsWeb || useMobileLayout)
                            ? Column(
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
                                          text:
                                              settingsProvider
                                                  .dateFirstInShowCard
                                              ? style.formattedDate
                                              : widget.show.venue,
                                          style: style.topStyle.copyWith(
                                            height: 1.3,
                                          ),
                                          enableAnimation:
                                              settingsProvider.marqueeEnabled,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 43,
                                    child: Container(
                                      alignment: Alignment.centerLeft,
                                      margin: const EdgeInsets.only(
                                        left: 4.0,
                                      ), // v134 offset
                                      width: double.infinity,
                                      child: FittedBox(
                                        fit: BoxFit.scaleDown,
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          settingsProvider.dateFirstInShowCard
                                              ? widget.show.venue
                                              : style.formattedDate,
                                          style: style.bottomStyle.copyWith(
                                            height: 1.3,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                children: [
                                  if (settingsProvider.dateFirstInShowCard) ...[
                                    Text(
                                      style.formattedDate,
                                      style: isFruit
                                          ? style.topStyle
                                          : style.bottomStyle,
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      widget.show.venue,
                                      style: isFruit
                                          ? style.bottomStyle
                                          : style.topStyle,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (!settingsProvider
                                      .dateFirstInShowCard) ...[
                                    const SizedBox(width: 12),
                                    Text(
                                      style.formattedDate,
                                      style: isFruit
                                          ? style.topStyle
                                          : style.bottomStyle,
                                    ),
                                  ],
                                ],
                              );

                        if (usePremium) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: NeumorphicWrapper(
                              borderRadius: 12.0,
                              intensity: 0.4,
                              isPressed: true,
                              color: Colors.transparent,
                              child: LiquidGlassWrapper(
                                enabled: true,
                                borderRadius: BorderRadius.circular(12.0),
                                opacity: 0.03,
                                blur: 4.0,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10.0,
                                    vertical: 4.0,
                                  ),
                                  child: textArea,
                                ),
                              ),
                            ),
                          );
                        }

                        return textArea;
                      },
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
                              strokeWidth: 2.5,
                            ),
                          )
                        : AnimatedRotation(
                            key: ValueKey('icon_${widget.show.name}'),
                            turns: widget.isExpanded ? 0.5 : 0,
                            duration: _animationDuration,
                            curve: Curves.fastOutSlowIn,
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
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: widget.isExpanded
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                size: 16 * style.effectiveScale,
                              ),
                            ),
                          ),
                  ),
                ),
              Positioned(
                top: (isTv ? 4.0 : 6.0) * style.effectiveScale,
                bottom: (isTv ? 6.0 : 4.0) * style.effectiveScale,
                right: 12.0 * style.effectiveScale,
                child: _buildBalancedControls(
                  context,
                  widget.show,
                  settingsProvider,
                  style.effectiveScale,
                  style.shouldShowBadge,
                  isTv,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(
    BuildContext context,
    Show show,
    double effectiveScale,
    bool isTv,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();
    final bool isFruit = context.read<ThemeProvider>().isFruit;

    final String badgeText;
    if (settingsProvider.showSingleShnid && show.sources.length == 1) {
      badgeText = '#${show.sources.first.id}';
    } else if (widget.isPlaying &&
        widget.playingSource != null &&
        settingsProvider.showSingleShnid) {
      badgeText = '#${widget.playingSource!.id}';
    } else {
      badgeText = show.sources.length > 1
          ? '${show.sources.length} SOURCES'
          : '1 SOURCE';
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors = isTrueBlackMode
        ? [Colors.black, Colors.black]
        : [
            colorScheme.secondaryContainer.withValues(alpha: 0.7),
            colorScheme.secondaryContainer.withValues(alpha: 0.5),
          ];

    final TextStyle style = Theme.of(context).textTheme.labelSmall!.copyWith(
      color: colorScheme.onSecondaryContainer,
      fontWeight: FontWeight.w600,
      fontSize: (settingsProvider.activeAppFont == 'rock_salt')
          ? (isFruit ? 7.5 : (isTv ? 3.5 : 4.5)) * effectiveScale
          : (isFruit ? 9.5 : (isTv ? 5.5 : 7.0)) * effectiveScale,
      height: isTv
          ? 1.0
          : (settingsProvider.activeAppFont == 'rock_salt' ? 2.0 : 1.5),
      letterSpacing:
          (settingsProvider.activeAppFont == 'rock_salt' ||
              settingsProvider.activeAppFont == 'permanent_marker')
          ? 1.5
          : 0.0,
    );

    return Container(
      padding: isTv
          ? const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 0.0,
            ) // Minimal padding for TV
          : ((isTv || isFruit)
                ? const EdgeInsets.symmetric(horizontal: 6, vertical: 1.0)
                : const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0)),
      constraints: BoxConstraints(
        minWidth: 16.0 * effectiveScale,
        maxHeight: isTv ? (9.0 * effectiveScale) : double.infinity,
      ),
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
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: isFruit
          ? ShnidBadge(text: badgeText, scaleFactor: effectiveScale)
          : (isTv
                ? FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      badgeText,
                      style: style,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      textAlign: TextAlign.center,
                    ),
                  )
                : Text(
                    badgeText,
                    style: style,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    textAlign: TextAlign.center,
                  )),
    );
  }

  Widget _buildBalancedControls(
    BuildContext context,
    Show show,
    SettingsProvider settings,
    double effectiveScale,
    bool shouldShowBadge,
    bool isTv,
  ) {
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
      builder: (context, _, _) {
        return ValueListenableBuilder(
          valueListenable: CatalogService().historyListenable,
          builder: (context, _, _) {
            final themeProvider = context.read<ThemeProvider>();
            final bool isFruit = themeProvider.isFruit;
            final double screenWidth = MediaQuery.of(context).size.width;
            final deviceService = context.watch<DeviceService>();
            final bool useMobileLayout =
                (screenWidth < 850 ||
                    deviceService.isPwa ||
                    deviceService.isMobile) &&
                !isTv;
            final bool showDesktopEmbeddedPlayer =
                kIsWeb && !useMobileLayout && !isTv && widget.isPlaying;

            final catalog = CatalogService();
            final bool usePremium =
                settings.useNeumorphism &&
                isFruit &&
                !settings.useTrueBlack &&
                !isTv;
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

            Widget wrapItemForPremium(
              Widget child, {
              bool isPressed = true,
              double paddingH = 6,
              double paddingV = 2,
            }) {
              if (usePremium) {
                return NeumorphicWrapper(
                  borderRadius: 12.0,
                  intensity: 0.7,
                  isPressed: isPressed,
                  color: Colors.transparent,
                  child: LiquidGlassWrapper(
                    enabled: true,
                    borderRadius: BorderRadius.circular(12.0),
                    opacity: 0.05,
                    blur: 8.0,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: paddingH,
                        vertical: paddingV,
                      ),
                      child: child,
                    ),
                  ),
                );
              }
              return child;
            }

            if (shouldShowSrcBadge) {
              Widget srcBadge = SrcBadge(
                src: badgeSrc,
                fontSize: shouldShowBadge
                    ? (isFruit ? 8.5 : (isTv ? 3.5 : (kIsWeb ? 7.5 : 4.5)))
                    : (isFruit ? 10.5 : (isTv ? 5.0 : (kIsWeb ? 9.0 : 7.0))),
                padding: (shouldShowBadge || isTv)
                    ? EdgeInsets.symmetric(
                        horizontal: (isTv ? 2.0 : 3.0) * effectiveScale,
                        vertical: 0.0,
                      )
                    : null,
              );

              if (isTv) {
                srcBadge = ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 9.0 * effectiveScale),
                  child: srcBadge,
                );
              }

              if (!shouldShowBadge && !isTv && !usePremium) {
                srcBadge = Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: srcBadge,
                );
              }

              srcBadge = wrapItemForPremium(
                srcBadge,
                isPressed: true,
                paddingH: 4,
                paddingV: 2,
              );

              badgeRowChildren.add(srcBadge);
            }

            if (shouldShowBadge) {
              Widget badge = _buildBadge(context, show, effectiveScale, isTv);
              badge = wrapItemForPremium(
                badge,
                isPressed: true,
                paddingH: 4,
                paddingV: 2,
              );

              if (badgeRowChildren.isNotEmpty) {
                badgeRowChildren.add(
                  SizedBox(width: isFruit ? (usePremium ? 6.0 : 8.0) : 4.0),
                );
              }
              badgeRowChildren.add(badge);
            }

            Widget? ratingWidget;
            if (showRating && ratingKey != null) {
              ratingWidget = RatingControl(
                rating: rating,
                isPlayed: isPlayed,
                size: isFruit
                    ? (settings.performanceMode
                          ? (useMobileLayout ? 22 : 26)
                          : (useMobileLayout ? 26 : 30))
                    : (isTv
                          ? 28 // Increased size for TV as requested
                          : (kIsWeb && useMobileLayout
                                ? 30
                                : useMobileLayout
                                ? 19
                                : 20)),
                compact: true,
                enforceMinTapTarget: !isTv,
                onTap:
                    (widget.isPlaying ||
                        widget.alwaysShowRatingInteraction ||
                        show.sources.length == 1)
                    ? () async {
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: rating,
                            sourceId: ratingKey,
                            sourceUrl:
                                (targetSource != null &&
                                    targetSource.tracks.isNotEmpty)
                                ? targetSource.tracks.first.url
                                : null,
                            isPlayed: isPlayed,
                            onRatingChanged: (newRating) {
                              catalog.setRating(ratingKey, newRating);
                            },
                            onPlayedChanged: (bool newIsPlayed) {
                              if (newIsPlayed != catalog.isPlayed(ratingKey)) {
                                catalog.togglePlayed(ratingKey);
                              }
                            },
                          ),
                        );
                      }
                    : null,
              );

              // Use isPressed: false to make the stars pop out slightly, distinguishing them from the badges.
              ratingWidget = wrapItemForPremium(
                ratingWidget,
                isPressed: false,
                paddingH: 6,
                paddingV: 4,
              );
            }

            if (!kIsWeb) {
              if (ratingWidget != null) {
                columnChildren.add(ratingWidget);
              }

              if (badgeRowChildren.isNotEmpty) {
                columnChildren.add(
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: badgeRowChildren,
                    ),
                  ),
                );
              }
            }

            return Padding(
              padding: EdgeInsets.only(
                right: 8.0, // v134 standard gutter
                top: isTv ? 2.0 : 4.0,
                bottom: isTv ? 2.0 : 4.0,
              ),
              child: isTv
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          ?ratingWidget,
                          if (ratingWidget != null &&
                              badgeRowChildren.isNotEmpty)
                            SizedBox(height: 4 * effectiveScale),
                          if (badgeRowChildren.isNotEmpty)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: badgeRowChildren,
                            ),
                        ],
                      ),
                    )
                  : !kIsWeb
                  ? FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Column(
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
                      ),
                    )
                  : useMobileLayout
                  ? (isFruit
                        ? Builder(
                            builder: (context) {
                              final badges = badgeRowChildren
                                  .where((w) => w is! SizedBox)
                                  .toList();
                              return FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerRight,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    ?ratingWidget,
                                    if (ratingWidget != null &&
                                        badges.isNotEmpty)
                                      SizedBox(height: usePremium ? 4 : 6),
                                    if (badges.isNotEmpty)
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: badges
                                            .asMap()
                                            .entries
                                            .map(
                                              (e) => Padding(
                                                padding: EdgeInsets.only(
                                                  right:
                                                      e.key < badges.length - 1
                                                      ? 4
                                                      : 0,
                                                ),
                                                child: e.value,
                                              ),
                                            )
                                            .toList(),
                                      ),
                                  ],
                                ),
                              );
                            },
                          )
                        : FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (ratingWidget != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: ratingWidget,
                                  ),
                                const SizedBox(height: 2),
                                if (badgeRowChildren.isNotEmpty)
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: badgeRowChildren,
                                  ),
                              ],
                            ),
                          ))
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (showDesktopEmbeddedPlayer) ...[
                          SizedBox(
                            width: (isFruit ? 172.0 : 166.0) * effectiveScale,
                            child: EmbeddedMiniPlayer(
                              scaleFactor: effectiveScale * 0.88,
                              compact: true,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (showRating && ratingKey != null)
                          RatingControl(
                            rating: rating,
                            isPlayed: isPlayed,
                            size: isFruit
                                ? (settings.performanceMode ? 24 : 28)
                                : (kIsWeb ? 28 : 19),
                            compact: true,
                            enforceMinTapTarget: true,
                            onTap:
                                (widget.isPlaying ||
                                    widget.alwaysShowRatingInteraction ||
                                    show.sources.length == 1)
                                ? () async {
                                    await showDialog(
                                      context: context,
                                      builder: (context) => RatingDialog(
                                        initialRating: rating,
                                        sourceId: ratingKey,
                                        sourceUrl:
                                            (targetSource != null &&
                                                targetSource.tracks.isNotEmpty)
                                            ? targetSource.tracks.first.url
                                            : null,
                                        isPlayed: isPlayed,
                                        onRatingChanged: (newRating) {
                                          catalog.setRating(
                                            ratingKey,
                                            newRating,
                                          );
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
                          SizedBox(width: isFruit ? 24 : 8),
                        if (badgeRowChildren.isNotEmpty)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                int i = 0;
                                i < badgeRowChildren.length;
                                i++
                              ) ...[
                                if (badgeRowChildren[i] is SizedBox)
                                  badgeRowChildren[i]
                                else if (usePremium &&
                                    badgeRowChildren[i] is NeumorphicWrapper)
                                  // Unwrap premium glass shell in non-stacked Fruit layout
                                  (((badgeRowChildren[i] as NeumorphicWrapper)
                                                      .child
                                                  as LiquidGlassWrapper)
                                              .child
                                          as Padding)
                                      .child!
                                else
                                  badgeRowChildren[i],
                              ],
                            ],
                          ),
                      ],
                    ),
            );
          },
        );
      },
    );
  }

  /// Builds the Stitch-design vertical card for Fruit theme on web/PWA.
  /// Dense mode = same structure, less padding (controlled by fruitDenseList).
  Widget _buildFruitMobileCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required CardStyle style,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
    required bool usePremium,
  }) {
    final bool isDense = settingsProvider.fruitDenseList;
    final double vPad = isDense ? 12.0 : 18.0;
    const double hPad = 16.0;
    final double miniPlayerGap = isDense ? 10.0 : 12.0;
    final double miniPlayerSlotHeight = 48.0 * style.effectiveScale;

    // Duration: sum all tracks from the primary source
    final Source? primarySource =
        (widget.isPlaying ? widget.playingSource : null) ??
        widget.show.sources.firstOrNull;

    final String srcLabel = (primarySource?.src ?? '').toUpperCase();
    final bool hasSrcLabel = srcLabel.isNotEmpty;
    // Star rating
    final Source? targetSource =
        (widget.isPlaying ? widget.playingSource : null) ??
        (widget.show.sources.length == 1
            ? widget.show.sources.firstOrNull
            : null);
    final String? ratingKey = targetSource?.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, _) {
        final int rating = ratingKey != null
            ? CatalogService().getRating(ratingKey)
            : 0;
        final bool isPlayed = ratingKey != null
            ? CatalogService().isPlayed(ratingKey)
            : false;

        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            color: backgroundColor,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              canRequestFocus: true,
              borderRadius: BorderRadius.circular(borderRadius),
              onTap: () {
                AppHaptics.selectionClick(context.read<DeviceService>());
                widget.onTap();
              },
              onLongPress: widget.onLongPress,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                child: Stack(
                  children: [
                    // Stars: top-right, absolutely positioned
                    if (ratingKey != null)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: RatingControl(
                          rating: rating,
                          isPlayed: isPlayed,
                          size: settingsProvider.performanceMode
                              ? (isDense ? 18 : 20)
                              : (isDense ? 22 : 24),
                          compact: true,
                          enforceMinTapTarget: true,
                          onTap:
                              (widget.isPlaying ||
                                  widget.alwaysShowRatingInteraction ||
                                  widget.show.sources.length == 1)
                              ? () async {
                                  await showDialog(
                                    context: context,
                                    builder: (ctx) => RatingDialog(
                                      initialRating: rating,
                                      sourceId: ratingKey,
                                      sourceUrl:
                                          targetSource?.tracks.firstOrNull?.url,
                                      isPlayed: isPlayed,
                                      onRatingChanged: (r) => CatalogService()
                                          .setRating(ratingKey, r),
                                      onPlayedChanged: (v) {
                                        if (v !=
                                            CatalogService().isPlayed(
                                              ratingKey,
                                            )) {
                                          CatalogService().togglePlayed(
                                            ratingKey,
                                          );
                                        }
                                      },
                                    ),
                                  );
                                }
                              : null,
                        ),
                      ),

                    // Main content column (left side, with right padding for stars)
                    Padding(
                      padding: const EdgeInsets.only(right: 72.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Date (bold, top)
                          Text(
                            style.formattedDate,
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 15.0,
                              fontWeight: FontWeight.w700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          // Venue (secondary)
                          Text(
                            widget.show.venue,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 13.0,
                              fontWeight: FontWeight.w400,
                              color: colorScheme.onSurface.withValues(
                                alpha: 0.55,
                              ),
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),

                          SizedBox(height: isDense ? 8.0 : 10.0),
                          // Divider
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          SizedBox(height: isDense ? 6.0 : 8.0),
                          // Footer: ● SOUNDBOARD  [Badge]
                          if (hasSrcLabel || style.shouldShowBadge)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (hasSrcLabel) ...[
                                  // Colored dot
                                  Container(
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Flexible(
                                    child: Text(
                                      srcLabel,
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 0.8,
                                        color: colorScheme.onSurface.withValues(
                                          alpha: 0.45,
                                        ),
                                        height: 1.0,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                                if (hasSrcLabel && style.shouldShowBadge)
                                  const SizedBox(width: 8),
                                if (style.shouldShowBadge)
                                  _buildBadge(
                                    context,
                                    widget.show,
                                    style.effectiveScale,
                                    false,
                                  ),
                              ],
                            ),
                          SizedBox(height: miniPlayerGap),
                          SizedBox(
                            height: miniPlayerSlotHeight,
                            child: AnimatedOpacity(
                              duration: const Duration(milliseconds: 120),
                              curve: Curves.easeOutCubic,
                              opacity: widget.isPlaying ? 1.0 : 0.0,
                              child: IgnorePointer(
                                ignoring: !widget.isPlaying,
                                child: widget.isPlaying
                                    ? EmbeddedMiniPlayer(
                                        scaleFactor: style.effectiveScale,
                                      )
                                    : const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
