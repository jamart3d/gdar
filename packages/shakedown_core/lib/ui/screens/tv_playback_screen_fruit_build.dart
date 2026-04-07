part of 'tv_playback_screen.dart';

extension _PlaybackScreenFruitBuild on PlaybackScreenState {
  Widget _buildFruitTopBar(BuildContext context, double scaleFactor) {
    final AudioProvider audioProvider = context.watch<AudioProvider>();
    final SettingsProvider settingsProvider = context.watch<SettingsProvider>();
    final Show? currentShow = audioProvider.currentShow;
    if (currentShow == null) return const SizedBox.shrink();

    String dateText = '';
    try {
      final DateTime dateTime = DateTime.parse(currentShow.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = currentShow.formattedDate;
    }

    final CatalogService catalog = CatalogService();
    final String? ratingKey = audioProvider.currentSource?.id;
    final Source? currentSource = audioProvider.currentSource;
    int rating = 0;
    bool isPlayed = false;

    if (ratingKey != null) {
      rating = catalog.getRating(ratingKey);
      isPlayed = catalog.isPlayed(ratingKey);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FruitHeaderButton(
            onTap: widget.onBackRequested ?? () => Navigator.of(context).pop(),
            icon: LucideIcons.chevronLeft,
            scaleFactor: scaleFactor,
            semanticLabel: 'Back to library',
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2 * scaleFactor),
                Text(
                  '${currentShow.venue}, ${currentShow.location}'.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10 * scaleFactor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.5,
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingControl(
                      rating: rating,
                      isPlayed: isPlayed,
                      compact: true,
                      size: 20 * scaleFactor,
                      onTap: () async {
                        if (ratingKey == null) return;
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: rating,
                            sourceId: ratingKey,
                            isPlayed: isPlayed,
                            onRatingChanged: (newRating) {
                              catalog.setRating(ratingKey, newRating);
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    SrcBadge(
                      src: audioProvider.currentSource?.src ?? '',
                      scaleFactor: scaleFactor,
                    ),
                    if (audioProvider.currentSource?.id != null) ...[
                      SizedBox(width: 4 * scaleFactor),
                      ShnidBadge(
                        text: audioProvider.currentSource!.id,
                        scaleFactor: scaleFactor,
                        uri: () {
                          if (currentSource == null) return null;
                          if (currentSource.tracks.isNotEmpty) {
                            final String? transformed = transformArchiveUrl(
                              currentSource.tracks.first.url,
                            );
                            if (transformed != null && transformed.isNotEmpty) {
                              return Uri.parse(transformed);
                            }
                          }
                          return Uri.parse(
                            'https://archive.org/details/${currentSource.id}',
                          );
                        }(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _FruitHeaderButton(
            onTap: () => _showFruitPlaybackOptionsMenu(
              context: context,
              scaleFactor: scaleFactor,
              settingsProvider: settingsProvider,
            ),
            icon: LucideIcons.moreHorizontal,
            scaleFactor: scaleFactor,
            semanticLabel: 'Playback options',
          ),
        ],
      ),
    );
  }

  void _showFruitPlaybackOptionsMenu({
    required BuildContext context,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    final Size size = MediaQuery.sizeOf(context);
    final double topPadding = MediaQuery.paddingOf(context).top;
    final RelativeRect position = RelativeRect.fromLTRB(
      size.width - 24 * scaleFactor,
      topPadding + 70 * scaleFactor,
      24 * scaleFactor,
      0,
    );

    showMenu(
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
          onTap: () => settingsProvider.toggleFruitStickyNowPlaying(),
          child: SizedBox(
            width: 200 * scaleFactor,
            child: Row(
              children: [
                Icon(
                  settingsProvider.fruitStickyNowPlaying
                      ? LucideIcons.checkCircle2
                      : LucideIcons.circle,
                  size: 18 * scaleFactor,
                  color: settingsProvider.fruitStickyNowPlaying
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                SizedBox(width: 12 * scaleFactor),
                Text(
                  'Sticky Now Playing',
                  style: TextStyle(fontSize: 14 * scaleFactor),
                ),
              ],
            ),
          ),
        ),
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

  Widget _buildFruitPlaybackScaffold({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          FruitTrackList(
            trackShow: currentShow,
            scaleFactor: scaleFactor,
            topOffset: MediaQuery.paddingOf(context).top + 80,
            bottomOffset: settingsProvider.fruitStickyNowPlaying ? 0 : 80,
          ),
          if (!settingsProvider.fruitStickyNowPlaying &&
              audioProvider.currentTrack != null)
            Positioned(
              left: 16 * scaleFactor,
              right: 16 * scaleFactor,
              bottom: 100.0 * scaleFactor,
              child: FruitNowPlayingCard(
                trackShow: currentShow,
                track: audioProvider.currentTrack!,
                index: (audioProvider.audioPlayer.currentIndex ?? 0) + 1,
                scaleFactor: scaleFactor,
                showNext: false,
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LiquidGlassWrapper(
              enabled:
                  settingsProvider.fruitEnableLiquidGlass &&
                  !settingsProvider.performanceMode,
              blur: 20,
              opacity: 0.8,
              borderRadius: BorderRadius.zero,
              child: Container(
                height: MediaQuery.paddingOf(context).top + 80,
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top,
                ),
                decoration: BoxDecoration(
                  color: settingsProvider.performanceMode
                      ? Theme.of(context).colorScheme.surface
                      : null,
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.05),
                      width: 1.0,
                    ),
                  ),
                ),
                alignment: Alignment.center,
                child: _buildFruitTopBar(context, scaleFactor),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.showFruitTabBar
          ? FruitTabBar(
              selectedIndex: 0,
              onTabSelected: (index) =>
                  _handleFruitTabSelection(context, index),
            )
          : null,
    );
  }

  void _handleFruitTabSelection(BuildContext context, int index) {
    if (index == 1) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FruitTabHostScreen(initialTab: 1),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
      return;
    }

    if (index == 2) {
      final ShowListProvider showListProvider = context
          .read<ShowListProvider>();
      showListProvider.setIsChoosingRandomShow(true);
      final int resetMs = context.read<SettingsProvider>().performanceMode
          ? 600
          : 2400;
      unawaited(
        Future<void>.delayed(Duration(milliseconds: resetMs), () {
          if (showListProvider.isChoosingRandomShow) {
            showListProvider.setIsChoosingRandomShow(false);
          }
        }),
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FruitTabHostScreen(
                initialTab: 1,
                triggerRandomOnStart: true,
              ),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
      return;
    }

    if (index == 3) {
      Navigator.of(context).pushAndRemoveUntil(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const FruitTabHostScreen(initialTab: 3),
          transitionDuration: Duration.zero,
        ),
        (route) => false,
      );
    }
  }
}
