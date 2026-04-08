part of 'playback_screen.dart';

extension _PlaybackScreenFruitBuild on PlaybackScreenState {
  void _scheduleFruitFloatingNowPlayingMeasurement() {
    if (_fruitFloatingNowPlayingMeasurementQueued) {
      return;
    }
    _fruitFloatingNowPlayingMeasurementQueued = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fruitFloatingNowPlayingMeasurementQueued = false;
      if (!mounted) return;
      final RenderBox? box =
          _fruitFloatingNowPlayingKey.currentContext?.findRenderObject()
              as RenderBox?;
      final double measuredHeight = box?.size.height ?? 0.0;
      if ((measuredHeight - _fruitFloatingNowPlayingHeight).abs() < 1.0) {
        return;
      }
      _updateFruitFloatingNowPlayingHeight(measuredHeight);
    });
  }

  double _resolveFruitTrackListBottomOffset({
    required BuildContext context,
    required AudioProvider audioProvider,
    required SettingsProvider settingsProvider,
    required double scaleFactor,
  }) {
    return computeFruitFloatingNowPlayingBottomOffset(
      stickyNowPlaying: settingsProvider.fruitStickyNowPlaying,
      hasCurrentTrack: audioProvider.currentTrack != null,
      showCompactHud: kIsWeb && settingsProvider.showDevAudioHud,
      scaleFactor: scaleFactor,
      bottomSafeArea: MediaQuery.paddingOf(context).bottom,
      measuredCardHeight: _fruitFloatingNowPlayingHeight,
    );
  }

  Widget _buildFruitTopBar(BuildContext context, double scaleFactor) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final bool isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final currentShow = audioProvider.currentShow;
    if (currentShow == null) return const SizedBox.shrink();

    String dateText = '';
    try {
      final dateTime = DateTime.parse(currentShow.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = currentShow.formattedDate;
    }

    final catalog = CatalogService();
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
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: FruitActionButton(
                icon: LucideIcons.chevronLeft,
                onPressed:
                    widget.onBackRequested ?? () => Navigator.of(context).pop(),
              ),
            ),
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
                    letterSpacing: 0.15,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 5 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        '${currentShow.venue}, ${currentShow.location}'
                            .toUpperCase(),
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
                    ),
                  ],
                ),
                SizedBox(height: 8 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildFruitCopyButton(
                      context,
                      scaleFactor,
                      currentShow,
                      currentSource,
                      dateText,
                    ),
                    SizedBox(width: 8 * scaleFactor),
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
                            final transformed = transformArchiveUrl(
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
          SizedBox(
            width: 44,
            height: 44,
            child: Center(
              child: FruitActionButton(
                icon: LucideIcons.moreHorizontal,
                tooltip: 'Playback options',
                onPressed: () {
                  final size = MediaQuery.sizeOf(context);
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
                        : Theme.of(
                            context,
                          ).colorScheme.surface.withValues(alpha: 0.85),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24 * scaleFactor),
                      side: BorderSide(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.1),
                        width: 1.0,
                      ),
                    ),
                    items: [
                      PopupMenuItem(
                        onTap: () =>
                            settingsProvider.toggleFruitStickyNowPlaying(),
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
                                style: TextStyle(
                                  fontFamily: isFruit ? 'Inter' : null,
                                  fontSize: 14 * scaleFactor,
                                ),
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
                              style: TextStyle(
                                fontFamily: isFruit ? 'Inter' : null,
                                fontSize: 14 * scaleFactor,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (kIsWeb)
                        PopupMenuItem(
                          onTap: () {
                            settingsProvider.toggleShowDevAudioHud();
                            if (settingsProvider.showPlaybackMessages !=
                                settingsProvider.showDevAudioHud) {
                              settingsProvider.toggleShowPlaybackMessages();
                            }
                          },
                          child: Row(
                            children: [
                              Icon(
                                settingsProvider.showDevAudioHud
                                    ? LucideIcons.checkCircle2
                                    : LucideIcons.circle,
                                size: 18 * scaleFactor,
                                color: settingsProvider.showDevAudioHud
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              SizedBox(width: 12 * scaleFactor),
                              Text(
                                'Audio HUD',
                                style: TextStyle(
                                  fontFamily: isFruit ? 'Inter' : null,
                                  fontSize: 14 * scaleFactor,
                                ),
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
                              style: TextStyle(
                                fontFamily: isFruit ? 'Inter' : null,
                                fontSize: 14 * scaleFactor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitCopyButton(
    BuildContext context,
    double scaleFactor,
    Show currentShow,
    Source? currentSource,
    String formattedDate,
  ) {
    final audioProvider = context.read<AudioProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: 'Copy show details',
      child: FruitTooltip(
        message: 'Copy show details',
        child: GestureDetector(
          onTap: () {
            final track = audioProvider.currentTrack;
            if (track == null || currentSource == null) return;
            final locationStr = currentSource.location != null
                ? ' - ${currentSource.location}'
                : '';
            final urlStr = settingsProvider.omitHttpPathInCopy
                ? ''
                : '\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}';
            final info =
                '${currentShow.venue}$locationStr - $formattedDate - ${currentSource.id}\n${track.title}$urlStr';
            Clipboard.setData(ClipboardData(text: info));
            AppHaptics.selectionClick(context.read<DeviceService>());
            showMessage(context, 'Details copied to clipboard');
          },
          child: Container(
            width: 20 * scaleFactor,
            height: 20 * scaleFactor,
            decoration: BoxDecoration(
              color: colorScheme.onSurface.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(6 * scaleFactor),
              border: Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Icon(
              LucideIcons.copy,
              size: 12 * scaleFactor,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.65),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFruitPlaybackScaffold({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required double immersiveTopPadding,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    final double trackListBottomOffset = _resolveFruitTrackListBottomOffset(
      context: context,
      audioProvider: audioProvider,
      settingsProvider: settingsProvider,
      scaleFactor: scaleFactor,
    );

    if (!settingsProvider.fruitStickyNowPlaying &&
        audioProvider.currentTrack != null) {
      _scheduleFruitFloatingNowPlayingMeasurement();
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          FruitTrackList(
            trackShow: currentShow,
            scaleFactor: scaleFactor,
            topOffset: immersiveTopPadding,
            bottomOffset: trackListBottomOffset,
            onWebStuckReset: _buildWebStuckResetHandler(),
          ),
          if (!settingsProvider.fruitStickyNowPlaying &&
              audioProvider.currentTrack != null)
            Positioned(
              left: 16 * scaleFactor,
              right: 16 * scaleFactor,
              bottom: 5.0 * scaleFactor + MediaQuery.paddingOf(context).bottom,
              child: SizedBox(
                key: _fruitFloatingNowPlayingKey,
                child: FruitNowPlayingCard(
                  trackShow: currentShow,
                  track: audioProvider.currentTrack!,
                  index: (audioProvider.audioPlayer.currentIndex ?? 0) + 1,
                  scaleFactor: scaleFactor,
                  showNext: false,
                  onWebStuckReset: _buildWebStuckResetHandler(),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FruitSurface(
              borderRadius: BorderRadius.zero,
              blur: 18,
              opacity: settingsProvider.performanceMode ? 0.96 : 0.82,
              child: Container(
                height:
                    MediaQuery.paddingOf(context).top +
                    14.0 +
                    (92.0 * scaleFactor),
                padding: EdgeInsets.only(
                  top: MediaQuery.paddingOf(context).top + 14.0,
                ),
                decoration: BoxDecoration(
                  color: settingsProvider.performanceMode
                      ? Theme.of(context).colorScheme.surface
                      : null,
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
}
