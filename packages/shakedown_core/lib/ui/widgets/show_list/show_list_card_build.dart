part of 'show_list_card.dart';

extension _ShowListCardBuild on _ShowListCardState {
  Widget _buildShowListCard(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.isFruit;
    final isFruitCarMode = isFruit && settingsProvider.carMode;

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
        : isFruitCarMode
        ? 20.0
        : (settingsProvider.performanceMode ? 8.0 : 16.0);
    final double vPadding = isFruitCarMode ? 6.0 : 2.0;
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
          allowInPerformanceMode: style.useRgb,
          colors: style.useRgb
              ? const [
                  Color(0xFFFF0000), // Red
                  Color(0xFFFFFF00), // Yellow
                  Color(0xFF00FF00), // Green
                  Color(0xFF00FFFF), // Cyan
                  Color(0xFF0000FF), // Blue
                  Color(0xFF8B00FF), // Purple
                  Color(0xFFFF0000), // Red
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
                    ? const Color(0x00000000)
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
        color: const Color(
          0x00000000,
        ), // Transparent, inner container draws the background
        margin: EdgeInsets.zero,
        elevation: widget.isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(isTv ? 12 : (isFruit ? 14 : 28)),
          side: BorderSide(
            color: isTv ? const Color(0x00000000) : style.cardBorderColor,
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
                  ? const Color(0x00000000)
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
        focusDecoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
        ),
        onFocusChange: _onHover,
        isPlaying: widget.isPlaying,
        showGlow: false,
        useRgbBorder: true,
        tightDecorativeBorder: true,
        decorativeBorderGap: 1.0,
        overridePremiumHighlight: false,
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
    final bool isFruitCarMode = isFruit && settingsProvider.carMode;
    final bool useMobileLayout =
        isWeb &&
        (screenWidth < 850 || deviceService.isPwa || deviceService.isMobile) &&
        !isTv;
    final bool usePremium = settingsProvider.useNeumorphism && isFruit;
    final bool isDesktopUnstackedWide =
        kIsWeb && !useMobileLayout && !isTv && !widget.isExpanded;

    if (isFruitCarMode && !isTv) {
      return _buildFruitCarModeCardContent(
        context: context,
        borderRadius: borderRadius,
        backgroundColor: backgroundColor,
        style: style,
        settingsProvider: settingsProvider,
        colorScheme: colorScheme,
      );
    }

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
        kIsWeb && isFruit && !useMobileLayout && !isTv && widget.isPlaying;
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
        color: const Color(0x00000000),
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
                  child: LayoutBuilder(
                    builder: (context, textConstraints) {
                      final hPadding = isTv
                          ? 24.0
                          : (settingsProvider.performanceMode ? 8.0 : 16.0);
                      final double textLaneWidth = textConstraints.maxWidth;
                      final String inlineLocationText =
                          (widget.playingSource?.location ??
                                  widget.show.location)
                              .trim();

                      String locationForLaneWidth(String location) {
                        if (location.isEmpty || !isDesktopUnstackedWide) {
                          return '';
                        }
                        if (textLaneWidth >= 1060) return location;
                        if (textLaneWidth >= 760) {
                          final compact = location.split(',').first.trim();
                          return compact.isEmpty ? '' : compact;
                        }
                        return '';
                      }

                      final String inlineLocationForWidth =
                          locationForLaneWidth(inlineLocationText);
                      final bool showInlineLocationAfterVenue =
                          inlineLocationForWidth.isNotEmpty &&
                          !widget.show.venue.toLowerCase().contains(
                            inlineLocationForWidth.toLowerCase(),
                          );
                      final String venueDisplayText =
                          showInlineLocationAfterVenue
                          ? '${widget.show.venue} | $inlineLocationForWidth'
                          : widget.show.venue;

                      String dateForLaneWidth() {
                        if (!isDesktopUnstackedWide) {
                          return style.formattedDate;
                        }
                        if (textLaneWidth >= 980) {
                          return style.formattedDate;
                        }
                        if (textLaneWidth >= 700) {
                          return AppDateUtils.formatDate(
                            widget.show.date,
                            settings: settingsProvider,
                            showDayOfWeek: settingsProvider.showDayOfWeek,
                            abbreviateDayOfWeek: true,
                          );
                        }
                        return AppDateUtils.formatDate(
                          widget.show.date,
                          settings: settingsProvider,
                          showDayOfWeek: false,
                          abbreviateDayOfWeek:
                              settingsProvider.abbreviateDayOfWeek,
                        );
                      }

                      final String responsiveDateText = dateForLaneWidth();
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
                                            ? responsiveDateText
                                            : venueDisplayText,
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
                                            ? venueDisplayText
                                            : responsiveDateText,
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
                                                        ? 0.0
                                                        : 0.0) *
                                                    style.effectiveScale
                                              : 254.0 * style.effectiveScale,
                                          maxWidth: isFruit
                                              ? (settingsProvider.fruitDenseList
                                                        ? 260.0
                                                        : 320.0) *
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
                                            useRgb: false,
                                            showFullDuration: true,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 5 * style.effectiveScale),
                                ],
                                Flexible(
                                  flex: isDesktopInlinePlaying ? 1 : 3,
                                  child: Container(
                                    alignment: Alignment.centerLeft,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        settingsProvider.dateFirstInShowCard
                                            ? responsiveDateText
                                            : venueDisplayText,
                                        style: isFruit
                                            ? style.topStyle
                                            : style.bottomStyle,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.left,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(
                                  width: isDesktopInlinePlaying
                                      ? 8.0
                                      : ((isDesktopUnstackedWide && isFruit)
                                            ? 4.0
                                            : (isFruit ? 24.0 : 0.0)),
                                ),
                                if (!isFruit) const Spacer(),
                                Flexible(
                                  flex: isDesktopInlinePlaying ? 0 : 1,
                                  child: Container(
                                    alignment: Alignment.centerRight,
                                    child: FittedBox(
                                      fit: BoxFit.scaleDown,
                                      alignment: Alignment.centerRight,
                                      child: Text(
                                        settingsProvider.dateFirstInShowCard
                                            ? venueDisplayText
                                            : responsiveDateText,
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
                            color: const Color(0x00000000),
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
                                      : const Color(0x00000000),
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
                right:
                    (kIsWeb && isFruit && !useMobileLayout && !isTv
                        ? 8.0
                        : 12.0) *
                    style.effectiveScale,
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
}
