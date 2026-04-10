part of 'show_list_card.dart';

extension _ShowListCardFruitMobileBuild on _ShowListCardState {
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
    final bool dateFirst = settingsProvider.dateFirstInShowCard;
    final String primaryText = dateFirst
        ? style.formattedDate
        : widget.show.venue;
    final String secondaryText = dateFirst
        ? widget.show.venue
        : style.formattedDate;

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
                padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
                child: Stack(
                  children: [
                    if (ratingKey != null ||
                        (settingsProvider.showSingleShnid &&
                            style.shouldShowBadge))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (ratingKey != null)
                              RatingControl(
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
                                            sourceUrl: targetSource
                                                ?.tracks
                                                .firstOrNull
                                                ?.url,
                                            isPlayed: isPlayed,
                                            onRatingChanged: (r) =>
                                                CatalogService().setRating(
                                                  ratingKey,
                                                  r,
                                                ),
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
                            if (settingsProvider.showSingleShnid &&
                                style.shouldShowBadge) ...[
                              const SizedBox(height: 4),
                              const SizedBox(height: 3),
                              _buildBadge(
                                context,
                                widget.show,
                                style.effectiveScale,
                                false,
                              ),
                            ],
                          ],
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(right: 72.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            primaryText,
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
                            secondaryText,
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
                          if (hasSrcLabel ||
                              (style.shouldShowBadge &&
                                  !settingsProvider.showSingleShnid))
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
                                if (hasSrcLabel &&
                                    style.shouldShowBadge &&
                                    !settingsProvider.showSingleShnid)
                                  const SizedBox(width: 8),
                                if (style.shouldShowBadge &&
                                    !settingsProvider.showSingleShnid)
                                  _buildBadge(
                                    context,
                                    widget.show,
                                    style.effectiveScale,
                                    false,
                                    tappable: true,
                                  ),
                              ],
                            ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 120),
                            curve: Curves.easeOutCubic,
                            child: widget.isPlaying
                                ? Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(height: miniPlayerGap),
                                      SizedBox(
                                        height: miniPlayerSlotHeight,
                                        child: EmbeddedMiniPlayer(
                                          scaleFactor: style.effectiveScale,
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
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
