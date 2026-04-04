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
    final bool showFooterRow = widget.isPlaying || style.shouldShowBadge;
    final bool useCompactTextLayout = isCurrentCard && showFooterRow;
    final double cardHeight =
        (widget.isPlaying ? 254.0 : (style.shouldShowBadge ? 212.0 : 204.0)) *
        style.effectiveScale;
    final double horizontalPadding =
        (isCurrentCard ? 24.0 : 22.0) * style.effectiveScale;
    final double verticalPadding =
        (isCurrentCard ? 20.0 : 18.0) * style.effectiveScale;
    final double headlineFontSize =
        (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
    final double supportingFontSize =
        (isCurrentCard ? 28.0 : 26.0) * style.effectiveScale;
    final double locationFontSize =
        (isCurrentCard ? 22.0 : 20.0) * style.effectiveScale;
    final double ratingSize =
        (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
    final double playerRowHeight =
        (isCurrentCard ? 62.0 : 56.0) * style.effectiveScale;
    final double playerScale =
        style.effectiveScale * (isCurrentCard ? 1.12 : 1.0);
    final int primaryHeadlineMaxLines = useCompactTextLayout ? 1 : 2;
    final int secondaryVenueMaxLines = useCompactTextLayout ? 1 : 2;
    final double contentGap =
        (useCompactTextLayout ? 8.0 : 10.0) * style.effectiveScale;
    final double metadataGap =
        (useCompactTextLayout ? 4.0 : 6.0) * style.effectiveScale;
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

            return Container(
              key: const ValueKey('fruit_show_list_car_mode_card'),
              height: cardHeight,
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
                            style: TextStyle(
                              fontFamily: 'Inter',
                              fontSize: compactSupportingFontSize,
                              fontWeight: FontWeight.w800,
                              height: 1.05,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.9,
                              ),
                            ),
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
                              Expanded(
                                child: SizedBox(
                                  height: playerRowHeight,
                                  child: AnimatedOpacity(
                                    duration: const Duration(milliseconds: 120),
                                    curve: Curves.easeOutCubic,
                                    opacity: widget.isPlaying ? 1.0 : 0.0,
                                    child: IgnorePointer(
                                      ignoring: !widget.isPlaying,
                                      child: widget.isPlaying
                                          ? EmbeddedMiniPlayer(
                                              scaleFactor: playerScale,
                                              compact: true,
                                              showFullDuration: true,
                                            )
                                          : const SizedBox.shrink(),
                                    ),
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
}
