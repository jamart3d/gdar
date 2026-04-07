part of 'show_list_card.dart';

extension _ShowListCardFruitCarModeBuild on _ShowListCardState {
  Widget _buildFruitCarModeCardContent({
    required BuildContext context,
    required double borderRadius,
    required Color backgroundColor,
    required CardStyle style,
    required SettingsProvider settingsProvider,
    required ColorScheme colorScheme,
  }) {
    final String currentTrackTitle =
        context.select<AudioProvider, String?>(
          (audioProvider) => audioProvider.currentTrack?.title.trim(),
        ) ??
        '';
    final Source? targetSource =
        (widget.isPlaying ? widget.playingSource : null) ??
        (widget.show.sources.length == 1
            ? widget.show.sources.firstOrNull
            : null);
    final String? ratingKey = targetSource?.id;
    final String locationText =
        (widget.playingSource?.location ?? widget.show.location).trim();
    final String? badgeSrc = targetSource?.src;
    final bool shouldShowSrcBadge = badgeSrc != null && badgeSrc.isNotEmpty;
    final bool dateFirst = settingsProvider.dateFirstInShowCard;
    final String primaryHeadline = dateFirst
        ? style.formattedDate
        : widget.show.venue;
    final bool isCurrentCard = widget.isPlaying;
    final bool showTrackTitle = isCurrentCard && currentTrackTitle.isNotEmpty;
    final bool showFooterRow = showTrackTitle || style.shouldShowBadge;
    final bool useCompactTextLayout = isCurrentCard && showFooterRow;
    final double cardHeight =
        (widget.isPlaying ? 232.0 : (style.shouldShowBadge ? 202.0 : 194.0)) *
        style.effectiveScale;
    final double horizontalPadding =
        (isCurrentCard ? 24.0 : 22.0) * style.effectiveScale;
    final double verticalPadding =
        (isCurrentCard ? 20.0 : 15.0) * style.effectiveScale;
    final double headlineFontSize =
        (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
    final double supportingFontSize =
        (isCurrentCard ? 28.0 : 26.0) * style.effectiveScale;
    final double locationFontSize =
        (isCurrentCard ? 22.0 : 20.0) * style.effectiveScale;
    final double ratingSize =
        (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
    final double footerRowHeight =
        (showTrackTitle ? 58.0 : 32.0) * style.effectiveScale;
    final double progressIndicatorScale = style.effectiveScale * 0.82;
    final double trackTitleFontSize =
        (isCurrentCard ? 27.0 : 25.0) * style.effectiveScale;
    final double trackBlockGap =
        (showTrackTitle ? 6.0 : 8.0) * style.effectiveScale;
    final bool shouldAllowWrappedPrimaryHeadline = isCurrentCard && !dateFirst;
    final int primaryHeadlineMaxLines =
        shouldAllowWrappedPrimaryHeadline ? 2 : (useCompactTextLayout ? 1 : 2);
    final int secondaryVenueMaxLines = isCurrentCard && dateFirst
        ? 2
        : (useCompactTextLayout ? 1 : 2);
    final double contentGap = 8.0 * style.effectiveScale;
    final double metadataGap =
        (useCompactTextLayout ? 4.0 : 5.0) * style.effectiveScale;
    final double compactSupportingFontSize =
        supportingFontSize * (useCompactTextLayout ? 0.94 : 1.0);
    final double compactLocationFontSize =
        locationFontSize * (useCompactTextLayout ? 0.95 : 1.0);

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, _) {
        final int rating = ratingKey != null
            ? CatalogService().getRating(ratingKey)
            : 0;
        final bool isPlayed = ratingKey != null
            ? CatalogService().isPlayed(ratingKey)
            : false;

        return LayoutBuilder(
          builder: (context, constraints) {
            final double cardWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : MediaQuery.sizeOf(context).width;
            final bool abbreviateWeekday =
                settingsProvider.showDayOfWeek &&
                !settingsProvider.abbreviateDayOfWeek &&
                cardWidth < 480 &&
                cardWidth >= 420;
            final bool omitWeekday =
                settingsProvider.showDayOfWeek && cardWidth < 420;
            final String displayDate = abbreviateWeekday || omitWeekday
                ? AppDateUtils.formatDate(
                    widget.show.date,
                    settings: settingsProvider,
                    showDayOfWeek: !omitWeekday,
                    abbreviateDayOfWeek:
                        abbreviateWeekday ||
                        settingsProvider.abbreviateDayOfWeek,
                  )
                : style.formattedDate;
            final venueTextStyle = TextStyle(
              fontFamily: 'Inter',
              fontSize: compactSupportingFontSize,
              fontWeight: FontWeight.w800,
              height: 1.05,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
            );
            final double trailingMetaWidth =
                (ratingKey != null || shouldShowSrcBadge)
                ? ((ratingSize + 16.0 + 72.0) * style.effectiveScale)
                : 0.0;
            final double primaryHeadlineWrapExtraHeight =
                shouldAllowWrappedPrimaryHeadline
                ? _measureWrappedTextExtraHeight(
                    text: primaryHeadline,
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: headlineFontSize,
                      fontWeight: FontWeight.w900,
                      height: 0.95,
                      letterSpacing: -0.8,
                    ),
                    maxWidth:
                        cardWidth -
                        (horizontalPadding * 2) -
                        trailingMetaWidth,
                    maxLines: primaryHeadlineMaxLines,
                    scaleFactor: style.effectiveScale,
                  )
                : 0.0;
            final double venueWrapExtraHeight = isCurrentCard && dateFirst
                ? _measureWrappedTextExtraHeight(
                    text: widget.show.venue,
                    style: venueTextStyle,
                    maxWidth: cardWidth - (horizontalPadding * 2),
                    maxLines: secondaryVenueMaxLines,
                    scaleFactor: style.effectiveScale,
                  )
                : 0.0;
            final double resolvedCardHeight =
                cardHeight +
                primaryHeadlineWrapExtraHeight +
                venueWrapExtraHeight;

            return Container(
              key: const ValueKey('fruit_show_list_car_mode_card'),
              height: resolvedCardHeight,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                color: backgroundColor,
              ),
              child: Material(
                color: const Color(0x00000000),
                child: InkWell(
                  canRequestFocus: true,
                  borderRadius: BorderRadius.circular(borderRadius),
                  onTap: () {
                    AppHaptics.selectionClick(context.read<DeviceService>());
                    widget.onTap();
                  },
                  onLongPress: widget.onLongPress,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      horizontalPadding,
                      verticalPadding,
                      horizontalPadding,
                      verticalPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                dateFirst ? displayDate : primaryHeadline,
                                maxLines: primaryHeadlineMaxLines,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: headlineFontSize,
                                  fontWeight: FontWeight.w900,
                                  height: 0.95,
                                  letterSpacing: -0.8,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                            ),
                            if (ratingKey != null || shouldShowSrcBadge) ...[
                              SizedBox(width: 16 * style.effectiveScale),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (ratingKey != null)
                                    RatingControl(
                                      rating: rating,
                                      isPlayed: isPlayed,
                                      size: ratingSize,
                                      compact: true,
                                      enforceMinTapTarget: true,
                                      onTap:
                                          (widget.isPlaying ||
                                              widget
                                                  .alwaysShowRatingInteraction ||
                                              widget.show.sources.length == 1)
                                          ? () async {
                                              await showDialog(
                                                context: context,
                                                builder: (context) =>
                                                    RatingDialog(
                                                      initialRating: rating,
                                                      sourceId: ratingKey,
                                                      sourceUrl: targetSource
                                                          ?.tracks
                                                          .firstOrNull
                                                          ?.url,
                                                      isPlayed: isPlayed,
                                                      onRatingChanged:
                                                          (newRating) {
                                                            CatalogService()
                                                                .setRating(
                                                                  ratingKey,
                                                                  newRating,
                                                                );
                                                          },
                                                      onPlayedChanged:
                                                          (newIsPlayed) {
                                                            if (newIsPlayed !=
                                                                CatalogService()
                                                                    .isPlayed(
                                                                      ratingKey,
                                                                    )) {
                                                              CatalogService()
                                                                  .togglePlayed(
                                                                    ratingKey,
                                                                  );
                                                            }
                                                          },
                                                    ),
                                              );
                                            }
                                          : null,
                                    ),
                                  if (ratingKey != null && shouldShowSrcBadge)
                                    SizedBox(height: 8 * style.effectiveScale),
                                  if (shouldShowSrcBadge)
                                    SrcBadge(
                                      src: badgeSrc,
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w800,
                                      padding: EdgeInsets.symmetric(
                                        horizontal: 10 * style.effectiveScale,
                                        vertical: 4 * style.effectiveScale,
                                      ),
                                      scaleFactor: style.effectiveScale,
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        SizedBox(height: contentGap),
                        if (dateFirst) ...[
                          Text(
                            widget.show.venue,
                            maxLines: secondaryVenueMaxLines,
                            overflow: TextOverflow.ellipsis,
                            style: venueTextStyle,
                          ),
                          SizedBox(height: metadataGap),
                        ],
                        if (locationText.isNotEmpty) ...[
                          Text(
                            locationText,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: compactLocationFontSize,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.88,
                              ),
                            ),
                          ),
                          SizedBox(height: metadataGap),
                        ],
                        if (!dateFirst)
                          Text(
                            displayDate,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: compactSupportingFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.74,
                              ),
                            ),
                          ),
                        if (showFooterRow) ...[
                          const Spacer(),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              if (style.shouldShowBadge)
                                _buildBadge(
                                  context,
                                  widget.show,
                                  style.effectiveScale * 1.1,
                                  false,
                                ),
                              SizedBox(
                                width: style.shouldShowBadge
                                    ? 12 * style.effectiveScale
                                    : 0,
                              ),
                              if (showTrackTitle)
                                Expanded(
                                  child: SizedBox(
                                    height: footerRowHeight,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      children: [
                                        SizedBox(
                                          height: 32 * style.effectiveScale,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: ConditionalMarquee(
                                              key: ValueKey(currentTrackTitle),
                                              text: currentTrackTitle,
                                              enableAnimation: settingsProvider
                                                  .marqueeEnabled,
                                              velocity: 44.0,
                                              blankSpace: 56.0,
                                              pauseAfterRound: const Duration(
                                                milliseconds: 1000,
                                              ),
                                              fadingEdgeStartFraction: 0.02,
                                              fadingEdgeEndFraction: 0.08,
                                              style: TextStyle(
                                                fontFamily: 'Inter',
                                                fontSize: trackTitleFontSize,
                                                fontWeight: FontWeight.w900,
                                                height: 0.96,
                                                letterSpacing: -0.8,
                                                color: colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: trackBlockGap),
                                        _buildFruitCarModeTrackProgress(
                                          context: context,
                                          colorScheme: colorScheme,
                                          scaleFactor: progressIndicatorScale,
                                          glassEnabled: settingsProvider
                                              .fruitEnableLiquidGlass,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildFruitCarModeTrackProgress({
    required BuildContext context,
    required ColorScheme colorScheme,
    required double scaleFactor,
    required bool glassEnabled,
  }) {
    final audioProvider = context.watch<AudioProvider>();

    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final total = durationSnapshot.data ?? Duration.zero;
            final totalMs = total.inMilliseconds;
            final positionMs = position.inMilliseconds.clamp(
              0,
              totalMs > 0 ? totalMs : 0,
            );

            return StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final bufferedMs = buffered.inMilliseconds.clamp(
                  0,
                  totalMs > 0 ? totalMs : 0,
                );

                return StreamBuilder<PlayerState>(
                  stream: audioProvider.playerStateStream,
                  initialData: audioProvider.audioPlayer.playerState,
                  builder: (context, stateSnapshot) {
                    final playerState =
                        stateSnapshot.data ??
                        audioProvider.audioPlayer.playerState;
                    final processingState = playerState.processingState;
                    final isLoading =
                        processingState == ProcessingState.loading;
                    final isBuffering =
                        processingState == ProcessingState.buffering;
                    final showPendingState = _shouldShowTrackPendingCue(
                      isLoading: isLoading,
                      isBuffering: isBuffering,
                      bufferedPositionMs: bufferedMs,
                      positionMs: positionMs,
                      durationMs: totalMs,
                    );
                    final bool pulseActive =
                        playerState.playing || isLoading || isBuffering;

                    return Row(
                      children: [
                        _FruitCarModeTrackPulse(
                          key: const ValueKey(
                            'fruit_show_list_car_mode_track_pulse',
                          ),
                          colorScheme: colorScheme,
                          scaleFactor: scaleFactor,
                          active: pulseActive,
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        Expanded(
                          child: KeyedSubtree(
                            key: const ValueKey(
                              'fruit_show_list_car_mode_track_progress',
                            ),
                            child: FruitNowPlayingProgressBar(
                              colorScheme: colorScheme,
                              scaleFactor: scaleFactor,
                              isLoading: isLoading,
                              bufferedPositionMs: bufferedMs,
                              positionMs: positionMs,
                              durationMs: totalMs,
                              glassEnabled: glassEnabled,
                              showPendingState: showPendingState,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  bool _shouldShowTrackPendingCue({
    required bool isLoading,
    required bool isBuffering,
    required int bufferedPositionMs,
    required int positionMs,
    required int durationMs,
  }) {
    final int remainingMs = durationMs - positionMs;
    final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
    final bool hasVisibleBufferHeadroom =
        bufferedPositionMs > (positionMs + 350);
    return isLoading ||
        isBuffering ||
        (hasPlayableTail && !hasVisibleBufferHeadroom);
  }

  double _measureWrappedTextExtraHeight({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required int maxLines,
    required double scaleFactor,
  }) {
    if (text.isEmpty || maxLines <= 1 || maxWidth <= 0) {
      return 0;
    }

    final painter = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: maxLines,
    )..layout(maxWidth: maxWidth);

    final int lineCount = painter.computeLineMetrics().length;
    if (lineCount <= 1) {
      return 0;
    }

    final double lineHeight = (style.fontSize ?? 0) * (style.height ?? 1.0);
    return ((lineCount - 1) * lineHeight) + (2 * scaleFactor);
  }
}

class _FruitCarModeTrackPulse extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool active;

  const _FruitCarModeTrackPulse({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.active,
  });

  @override
  State<_FruitCarModeTrackPulse> createState() =>
      _FruitCarModeTrackPulseState();
}

class _FruitCarModeTrackPulseState extends State<_FruitCarModeTrackPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant _FruitCarModeTrackPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.active != widget.active) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.active) {
      _controller.repeat(reverse: true);
    } else {
      _controller.stop();
      _controller.value = 0.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Color pulseColor = widget.active
        ? widget.colorScheme.primary
        : widget.colorScheme.onSurfaceVariant.withValues(alpha: 0.42);
    final double baseSize = 8 * widget.scaleFactor;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final double t = Curves.easeInOut.transform(_controller.value);
        final double scale = widget.active ? (0.9 + (t * 0.35)) : 1.0;
        final double alpha = widget.active ? (0.55 + (t * 0.35)) : 0.42;

        return Transform.scale(
          scale: scale,
          child: Container(
            width: baseSize,
            height: baseSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: pulseColor.withValues(alpha: alpha),
              boxShadow: widget.active
                  ? [
                      BoxShadow(
                        color: pulseColor.withValues(alpha: 0.22 + (t * 0.12)),
                        blurRadius: 6 * widget.scaleFactor,
                        spreadRadius: 0.8 * t,
                      ),
                    ]
                  : const [],
            ),
          ),
        );
      },
    );
  }
}
