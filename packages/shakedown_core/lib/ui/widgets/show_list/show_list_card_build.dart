part of 'show_list_card.dart';

extension _ShowListCardBuild on _ShowListCardState {
  Widget _buildShowListCard(BuildContext context) {
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
    const vPadding = 2.0;
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
            intensity: 1.2,
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
          borderRadius: BorderRadius.circular(isTv ? 12 : (isFruit ? 14 : 28)),
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
          intensity: 1.2,
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
        overridePremiumHighlight: null,
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

    final double baseHeight = isTv
        ? 48.0
        : useMobileLayout
        ? 54.0
        : isFruit
        ? (settingsProvider.fruitDenseList ? 54.0 : 72.0)
        : 58.0;
    final double cardHeight = baseHeight * style.effectiveScale;
    final bool isDesktopInlinePlaying =
        kIsWeb && !useMobileLayout && !isTv && widget.isPlaying;
    final double controlZoneWidth = (kIsWeb)
        ? ((isFruit || !useMobileLayout)
                  ? (useMobileLayout ? 84.0 : (isFruit ? 180.0 : 140.0))
                  : style.config.baseControlZoneWidth) *
              style.effectiveScale
        : (style.config.baseControlZoneWidth * style.effectiveScale);

    return Container(
      height: cardHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        color: backgroundColor,
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
                right: controlZoneWidth,
                child: Container(
                  alignment: Alignment.centerLeft,
                  clipBehavior: Clip.none,
                  padding: EdgeInsets.symmetric(horizontal: isTv ? 6.0 : 12.0),
                  child: Builder(
                    builder: (context) {
                      final hPadding = isTv
                          ? 24.0
                          : (settingsProvider.performanceMode ? 8.0 : 16.0);
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
                                            settingsProvider.dateFirstInShowCard
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
                                    margin: const EdgeInsets.only(left: 4.0),
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
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                if (isDesktopInlinePlaying) ...[
                                  Flexible(
                                    flex: 0,
                                    child: Transform.translate(
                                      offset: Offset(
                                        isTv ? -4.0 : (-hPadding + 10.0),
                                        0,
                                      ),
                                      child: ConstrainedBox(
                                        constraints: BoxConstraints(
                                          minWidth: isFruit
                                              ? (settingsProvider.fruitDenseList
                                                        ? 240.0
                                                        : 300.0) *
                                                    style.effectiveScale
                                              : 254.0 * style.effectiveScale,
                                          maxWidth: isFruit
                                              ? (settingsProvider.fruitDenseList
                                                        ? 310.0
                                                        : 370.0) *
                                                    style.effectiveScale
                                              : 310.0 * style.effectiveScale,
                                        ),
                                        child: AnimatedSize(
                                          clipBehavior: Clip.none,
                                          duration: const Duration(
                                            milliseconds: 300,
                                          ),
                                          curve: Curves.easeInOut,
                                          alignment: Alignment.centerLeft,
                                          child: EmbeddedMiniPlayer(
                                            scaleFactor:
                                                style.effectiveScale *
                                                (isFruit &&
                                                        !settingsProvider
                                                            .fruitDenseList
                                                    ? 1.0
                                                    : 0.88),
                                            compact: true,
                                            useRgb: style.useRgb,
                                            showFullDuration: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 5 * style.effectiveScale),
                                ],
                                Flexible(
                                  flex: 3,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        settingsProvider.dateFirstInShowCard
                                            ? style.formattedDate
                                            : widget.show.venue,
                                        style: isFruit
                                            ? style.topStyle
                                            : style.bottomStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: isFruit ? 24.0 : 0.0),
                                if (!isFruit) const Spacer(),
                                Flexible(
                                  flex: 1,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        settingsProvider.dateFirstInShowCard
                                            ? widget.show.venue
                                            : style.formattedDate,
                                        style: isFruit
                                            ? style.bottomStyle
                                            : style.topStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                      ),
                                    ),
                                  ),
                                ),
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
              if (settingsProvider.showExpandIcon)
                Positioned(
                  left: 8.0 * style.effectiveScale,
                  bottom: 8.0 * style.effectiveScale,
                  child: AnimatedSwitcher(
                    duration: _ShowListCardState._animationDuration,
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
                            duration: _ShowListCardState._animationDuration,
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

    final Source? primarySource =
        (widget.isPlaying ? widget.playingSource : null) ??
        widget.show.sources.firstOrNull;

    final String srcLabel = (primarySource?.src ?? '').toUpperCase();
    final bool hasSrcLabel = srcLabel.isNotEmpty;
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
                    Padding(
                      padding: const EdgeInsets.only(right: 72.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
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
                          Divider(
                            height: 1,
                            thickness: 0.5,
                            color: colorScheme.onSurface.withValues(
                              alpha: 0.12,
                            ),
                          ),
                          SizedBox(height: isDense ? 6.0 : 8.0),
                          if (hasSrcLabel || style.shouldShowBadge)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                if (hasSrcLabel) ...[
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
