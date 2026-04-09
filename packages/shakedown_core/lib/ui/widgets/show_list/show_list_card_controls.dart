part of 'show_list_card.dart';

extension _ShowListCardControls on _ShowListCardState {
  Widget _buildBadge(
    BuildContext context,
    Show show,
    double effectiveScale,
    bool isTv, {
    bool tappable = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();
    final bool isFruit = context.read<ThemeProvider>().isFruit;

    final String badgeText;
    if (settingsProvider.showSingleShnid && show.sources.length == 1) {
      badgeText = show.sources.first.id;
    } else if (widget.isPlaying &&
        widget.playingSource != null &&
        settingsProvider.showSingleShnid) {
      badgeText = widget.playingSource!.id;
    } else {
      badgeText = show.sources.length > 1
          ? '${show.sources.length} SOURCES'
          : '1 SOURCE';
    }

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final gradientColors = isTrueBlackMode
        ? [
            colorScheme.surface.withValues(alpha: 0.8),
            colorScheme.surface.withValues(alpha: 0.8),
          ]
        : [
            colorScheme.primaryContainer.withValues(alpha: 0.9),
            colorScheme.secondaryContainer.withValues(alpha: 0.9),
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

    Widget badge = Container(
      padding: isTv
          ? const EdgeInsets.symmetric(horizontal: 4, vertical: 0.0)
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
          ? ShnidBadge(
              text: badgeText,
              scaleFactor: effectiveScale,
              interactive: !tappable,
            )
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

    if (tappable) {
      badge = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          AppHaptics.selectionClick(context.read<DeviceService>());
          widget.onTap();
        },
        child: kIsWeb
            ? MouseRegion(cursor: SystemMouseCursors.click, child: badge)
            : badge,
      );
    }

    return badge;
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
            final bool suppressCurrentShowMeta =
                !settings.filterHighestShnid &&
                !widget.isExpanded &&
                widget.isPlaying;

            final catalog = CatalogService();
            final bool usePremium =
                settings.useNeumorphism &&
                isFruit &&
                !settings.useTrueBlack &&
                !isTv;
            final bool isDense = settings.fruitDenseList;
            final double fruitCompactRatingSize = settings.performanceMode
                ? (isDense ? 18 : 20)
                : (isDense ? 22 : 24);
            int rating = 0;
            bool isPlayed = false;

            if (ratingKey != null) {
              rating = catalog.getRating(ratingKey);
              isPlayed = catalog.isPlayed(ratingKey);
            }

            final String? badgeSrc = targetSource?.src;
            final bool shouldShowSrcBadge =
                badgeSrc != null &&
                !widget.isExpanded &&
                !suppressCurrentShowMeta;
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
                fontSize:
                    (shouldShowBadge
                        ? (isFruit ? 8.5 : (isTv ? 3.5 : (kIsWeb ? 7.5 : 4.5)))
                        : (isFruit
                              ? 10.5
                              : (isTv ? 5.0 : (kIsWeb ? 9.0 : 7.0)))) *
                    effectiveScale,
                padding: EdgeInsets.symmetric(
                  horizontal: (isTv ? 2.0 : 3.0) * effectiveScale,
                  vertical: isFruit ? 1.0 * effectiveScale : 0.0,
                ),
              );

              if (isTv) {
                srcBadge = ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 9.0 * effectiveScale),
                  child: srcBadge,
                );
              } else if (isFruit && !useMobileLayout) {
                srcBadge = ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: 26.0 * effectiveScale),
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
              Widget badge = _buildBadge(
                context,
                show,
                effectiveScale,
                isTv,
                tappable:
                    isFruit &&
                    !isTv &&
                    show.sources.length > 1 &&
                    !settings.showSingleShnid,
              );
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
            if (showRating && ratingKey != null && !suppressCurrentShowMeta) {
              ratingWidget = RatingControl(
                rating: rating,
                isPlayed: isPlayed,
                size: isFruit
                    ? (kIsWeb && useMobileLayout
                          ? fruitCompactRatingSize
                          : (settings.performanceMode ? 26 : 32) *
                                effectiveScale)
                    : (isTv
                          ? 28
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
                right: (kIsWeb && isFruit && !useMobileLayout && !isTv)
                    ? 4.0
                    : 8.0,
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
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    ?ratingWidget,
                                    if (ratingWidget != null &&
                                        badges.isNotEmpty)
                                      SizedBox(height: usePremium ? 4 : 6),
                                    if (badges.isNotEmpty)
                                      Column(
                                        mainAxisSize: MainAxisSize.min,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: badges
                                            .asMap()
                                            .entries
                                            .map(
                                              (e) => Padding(
                                                padding: EdgeInsets.only(
                                                  top: e.key > 0 ? 4 : 0,
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
                        if (showRating &&
                            ratingKey != null &&
                            !suppressCurrentShowMeta)
                          RatingControl(
                            rating: rating,
                            isPlayed: isPlayed,
                            size: isFruit
                                ? (settings.performanceMode ? 26 : 32) *
                                      effectiveScale
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
}
