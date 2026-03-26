part of 'track_list_screen.dart';

extension _TrackListScreenFruit on _TrackListScreenState {
  Widget _buildFruitHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    String dateText = '';
    try {
      final dateTime = DateTime.parse(widget.show.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = AppDateUtils.formatDate(
        widget.show.date,
        settings: settingsProvider,
      );
    }

    final catalog = CatalogService();
    final String ratingKey = widget.source.id;
    final Uri archiveUri = _archiveUriForSource(widget.source);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFruitNavButton(
            context,
            icon: LucideIcons.chevronLeft,
            onPressed: () => Navigator.of(context).pop(),
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.15,
                    color: colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFruitInlinePlayButton(
                      context,
                      onPressed: _playShowFromHeader,
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    Flexible(
                      child: Text(
                        '${widget.show.venue}, ${widget.show.location}'
                            .toUpperCase(),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 10 * scaleFactor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.6,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6 * scaleFactor),
                ValueListenableBuilder(
                  valueListenable: CatalogService().ratingsListenable,
                  builder: (context, _, _) {
                    final int rating = catalog.getRating(ratingKey);
                    final bool isPlayed = catalog.isPlayed(ratingKey);
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        RatingControl(
                          key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                          rating: rating,
                          isPlayed: isPlayed,
                          compact: true,
                          size: 20 * scaleFactor,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => RatingDialog(
                                initialRating: rating,
                                sourceId: widget.source.id,
                                sourceUrl: widget.source.tracks.isNotEmpty
                                    ? widget.source.tracks.first.url
                                    : null,
                                isPlayed: isPlayed,
                                onRatingChanged: (newRating) {
                                  catalog.setRating(ratingKey, newRating);
                                },
                                onPlayedChanged: (bool newIsPlayed) {
                                  if (newIsPlayed != isPlayed) {
                                    catalog.togglePlayed(ratingKey);
                                  }
                                },
                              ),
                            );
                          },
                        ),
                        if ((widget.source.src ?? '').isNotEmpty) ...[
                          SizedBox(width: 8 * scaleFactor),
                          SrcBadge(
                            src: widget.source.src ?? '',
                            scaleFactor: scaleFactor,
                          ),
                        ],
                        SizedBox(width: 4 * scaleFactor),
                        ShnidBadge(
                          text: widget.source.id,
                          scaleFactor: scaleFactor,
                          uri: archiveUri,
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          _buildFruitMenuButton(
            context,
            onPressed: () => _showFruitOptionsMenu(context, scaleFactor),
          ),
        ],
      ),
    );
  }

  Future<void> _showFruitOptionsMenu(
    BuildContext context,
    double scaleFactor,
  ) async {
    final settingsProvider = context.read<SettingsProvider>();
    final size = MediaQuery.sizeOf(context);
    final double topPadding = MediaQuery.paddingOf(context).top;

    final RelativeRect position = RelativeRect.fromLTRB(
      size.width - 24 * scaleFactor,
      topPadding + 70 * scaleFactor,
      24 * scaleFactor,
      0,
    );

    await showMenu(
      context: context,
      position: position,
      elevation: settingsProvider.performanceMode ? 4 : 0,
      color: settingsProvider.performanceMode
          ? Theme.of(context).colorScheme.surface
          : Theme.of(context).colorScheme.surface.withValues(alpha: 0.85),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24 * scaleFactor),
        side: BorderSide(
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.1),
          width: 1.0,
        ),
      ),
      items: [
        PopupMenuItem(
          onTap: () => settingsProvider.toggleShowTrackNumbers(),
          child: Row(
            children: [
              Icon(
                settingsProvider.showTrackNumbers
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 18 * scaleFactor,
                color: settingsProvider.showTrackNumbers
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'Track Numbers',
                style: TextStyle(fontSize: 14 * scaleFactor),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          onTap: () => settingsProvider.toggleHideTrackDuration(),
          child: Row(
            children: [
              Icon(
                !settingsProvider.hideTrackDuration
                    ? LucideIcons.checkCircle2
                    : LucideIcons.circle,
                size: 18 * scaleFactor,
                color: !settingsProvider.hideTrackDuration
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
              SizedBox(width: 12 * scaleFactor),
              Text(
                'Track Duration',
                style: TextStyle(fontSize: 14 * scaleFactor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFruitMenuButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: FruitActionButton(
          icon: LucideIcons.moreHorizontal,
          onPressed: onPressed,
          tooltip: 'Track list options',
        ),
      ),
    );
  }

  Widget _buildFruitInlinePlayButton(
    BuildContext context, {
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: colorScheme.primary.withValues(alpha: 0.12),
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.18),
            width: 0.8,
          ),
        ),
        child: Icon(LucideIcons.play, size: 12, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildFruitNavButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: Center(
        child: FruitActionButton(icon: icon, onPressed: onPressed),
      ),
    );
  }
}
