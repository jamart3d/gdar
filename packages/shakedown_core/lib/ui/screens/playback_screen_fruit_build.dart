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

  Widget _buildFruitCarModeScaffold({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        key: const ValueKey('fruit_car_mode_layout'),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              colorScheme.surface,
              colorScheme.surfaceContainerLowest,
              colorScheme.surface,
            ],
          ),
        ),
        child: Stack(
          children: [
            if (settingsProvider.fruitFloatingSpheres)
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: _FruitFloatingSpheres(
                      key: const ValueKey('fruit_car_mode_floating_spheres'),
                      colorScheme: colorScheme,
                      animate: !settingsProvider.performanceMode,
                    ),
                  ),
                ),
              ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16 * scaleFactor,
                  math.max(8.0, topPadding * 0.15),
                  16 * scaleFactor,
                  0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFruitCarModeHud(
                      context: context,
                      audioProvider: audioProvider,
                      currentSource: currentSource,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 18 * scaleFactor),
                    _buildFruitCarModeHero(
                      context: context,
                      audioProvider: audioProvider,
                      currentShow: currentShow,
                      currentSource: currentSource,
                      scaleFactor: scaleFactor,
                      settingsProvider: settingsProvider,
                    ),
                    SizedBox(height: 18 * scaleFactor),
                    _buildFruitCarModeProgress(
                      context: context,
                      audioProvider: audioProvider,
                      scaleFactor: scaleFactor,
                    ),
                    SizedBox(height: 4 * scaleFactor),
                    Expanded(
                      child: Column(
                        children: [
                          const SizedBox.shrink(),
                          Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 4 * scaleFactor,
                            ),
                            child: _buildFruitCarModeControls(
                              context: context,
                              audioProvider: audioProvider,
                              scaleFactor: scaleFactor,
                            ),
                          ),
                          SizedBox(height: 18 * scaleFactor),
                          _buildFruitCarModeUpcomingTracks(
                            context: context,
                            audioProvider: audioProvider,
                            currentSource: currentSource,
                            scaleFactor: scaleFactor,
                          ),
                          const Spacer(flex: 5),
                          _buildFruitCarModeSecondaryCards(
                            context: context,
                            currentShow: currentShow,
                            currentSource: currentSource,
                            scaleFactor: scaleFactor,
                          ),
                          SizedBox(height: 20 * scaleFactor),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
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

  Widget _buildFruitCarModeHero({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    String dateText;
    try {
      dateText = DateFormat(
        'MMMM d, y',
      ).format(DateTime.parse(currentShow.date));
    } catch (_) {
      dateText = currentShow.formattedDate;
    }

    final locationText = currentSource.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentShow.venue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: FontConfig.resolve('Inter'),
            fontSize: 34 * scaleFactor,
            fontWeight: FontWeight.w800,
            height: 1.0,
            letterSpacing: -0.8,
            color: colorScheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        SizedBox(height: 8 * scaleFactor),
        if (locationText != null && locationText.isNotEmpty) ...[
          Text(
            locationText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: FontConfig.resolve('Inter'),
              fontSize: 19 * scaleFactor,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 6 * scaleFactor),
        ],
        Text(
          dateText,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: FontConfig.resolve('Inter'),
            fontSize: 25 * scaleFactor,
            fontWeight: FontWeight.w800,
            height: 1.1,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
          ),
        ),
        SizedBox(height: 18 * scaleFactor),
        SizedBox(
          height: 52 * scaleFactor,
          child: ConditionalMarquee(
            key: ValueKey(audioProvider.currentTrack?.url ?? currentShow.key),
            text: audioProvider.currentTrack?.title ?? 'Picking show...',
            enableAnimation: settingsProvider.marqueeEnabled,
            velocity: 48.0,
            blankSpace: 72.0,
            pauseAfterRound: const Duration(milliseconds: 1200),
            fadingEdgeStartFraction: 0.03,
            fadingEdgeEndFraction: 0.08,
            style: TextStyle(
              fontFamily: FontConfig.resolve('Inter'),
              fontSize: 46 * scaleFactor,
              fontWeight: FontWeight.w900,
              height: 0.92,
              letterSpacing: -2.0,
              color: colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFruitCarModeHud({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Source currentSource,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final catalog = CatalogService();
    final rating = catalog.getRating(currentSource.id);
    final isPlayed = catalog.isPlayed(currentSource.id);
    final Future<void> Function() openRatingDialog = () async {
      await showDialog(
        context: context,
        builder: (context) => RatingDialog(
          initialRating: rating,
          sourceId: currentSource.id,
          sourceUrl: currentSource.tracks.firstOrNull?.url,
          isPlayed: isPlayed,
          onRatingChanged: (newRating) {
            catalog.setRating(currentSource.id, newRating);
          },
          onPlayedChanged: (newIsPlayed) {
            if (newIsPlayed != catalog.isPlayed(currentSource.id)) {
              catalog.togglePlayed(currentSource.id);
            }
          },
        ),
      );
    };

    return GestureDetector(
      key: const ValueKey('fruit_car_mode_chip_row'),
      behavior: HitTestBehavior.opaque,
      onTap: () {
        setState(() {
          _fruitCarModeHudShowsMeta = !_fruitCarModeHudShowsMeta;
        });
      },
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 180),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        child: _fruitCarModeHudShowsMeta
            ? Row(
                key: const ValueKey('fruit_car_mode_chip_row_meta'),
                children: [
                  SizedBox(
                    width: 220 * scaleFactor,
                    height: _fruitCarModeChipCardHeight(scaleFactor),
                    child: Semantics(
                      button: true,
                      label: 'Rate source ${currentSource.id}',
                      child: GestureDetector(
                        key: const ValueKey('fruit_car_mode_rating_zone'),
                        behavior: HitTestBehavior.opaque,
                        onTap: openRatingDialog,
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12 * scaleFactor,
                          ),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: IgnorePointer(
                              child: RatingControl(
                                rating: rating,
                                isPlayed: isPlayed,
                                compact: true,
                                size: 56 * scaleFactor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 10 * scaleFactor),
                  Expanded(
                    child: SizedBox(
                      height: _fruitCarModeChipCardHeight(scaleFactor),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Column(
                          key: const ValueKey('fruit_car_mode_meta_stack'),
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((currentSource.src ?? '').isNotEmpty)
                              Text(
                                (currentSource.src ?? '').toUpperCase(),
                                key: const ValueKey('fruit_car_mode_src_label'),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: FontConfig.resolve('Inter'),
                                  fontSize: 12.5 * scaleFactor,
                                  fontWeight: FontWeight.w800,
                                  height: 1.0,
                                  letterSpacing: 0.9,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.92),
                                ),
                              ),
                            if ((currentSource.src ?? '').isNotEmpty)
                              SizedBox(height: 4 * scaleFactor),
                            Text(
                              currentSource.id,
                              key: const ValueKey('fruit_car_mode_shnid_label'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: FontConfig.resolve('Inter'),
                                fontSize: 12.5 * scaleFactor,
                                fontWeight: FontWeight.w700,
                                height: 1.0,
                                letterSpacing: 0.2,
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.78,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : StreamBuilder<HudSnapshot>(
                key: const ValueKey('fruit_car_mode_chip_row_stats'),
                stream: audioProvider.hudSnapshotStream,
                initialData: audioProvider.currentHudSnapshot,
                builder: (context, snapshot) {
                  final hud = snapshot.data ?? HudSnapshot.empty();

                  return Row(
                    children: [
                      Expanded(
                        child: _FruitCarModeStatCard(
                          label: 'DFT',
                          value: hud.drift,
                          accentColor: colorScheme.primary,
                          scaleFactor: scaleFactor,
                        ),
                      ),
                      SizedBox(width: 10 * scaleFactor),
                      Expanded(
                        child: _FruitCarModeStatCard(
                          label: 'HD',
                          value: hud.headroom,
                          accentColor: colorScheme.secondary,
                          scaleFactor: scaleFactor,
                        ),
                      ),
                      SizedBox(width: 10 * scaleFactor),
                      Expanded(
                        child: _FruitCarModeStatCard(
                          label: 'NXT',
                          value: hud.nextBuffered,
                          accentColor: colorScheme.tertiary,
                          scaleFactor: scaleFactor,
                        ),
                      ),
                      SizedBox(width: 10 * scaleFactor),
                      Expanded(
                        child: _FruitCarModeStatCard(
                          label: 'LG',
                          value: hud.lastGapMs == null
                              ? '--'
                              : '${hud.lastGapMs!.toStringAsFixed(0)}ms',
                          accentColor: colorScheme.onSurface,
                          scaleFactor: scaleFactor,
                        ),
                      ),
                    ],
                  );
                },
              ),
      ),
    );
  }

  Widget _buildFruitCarModeProgress({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

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
            final progress = totalMs <= 0 ? 0.0 : positionMs / totalMs;
            return StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final bufferedMs = buffered.inMilliseconds.clamp(
                  0,
                  totalMs > 0 ? totalMs : 0,
                );
                final bufferedProgress = totalMs <= 0
                    ? 0.0
                    : bufferedMs / totalMs;
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
                    final showPendingState = _shouldShowFruitCarModePendingCue(
                      isLoading: isLoading,
                      isBuffering: isBuffering,
                      bufferedPositionMs: bufferedMs,
                      positionMs: positionMs,
                      durationMs: totalMs,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final trackWidth = constraints.maxWidth;
                            final trackHeight = 16 * scaleFactor;
                            final thumbSize = 28 * scaleFactor;
                            final thumbLeft =
                                (trackWidth - thumbSize) *
                                progress.clamp(0.0, 1.0);

                            void seekToLocalDx(double localDx) {
                              if (totalMs <= 0) return;
                              final normalized = (localDx / trackWidth).clamp(
                                0.0,
                                1.0,
                              );
                              audioProvider.seek(
                                Duration(
                                  milliseconds: (normalized * totalMs).round(),
                                ),
                              );
                            }

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTapDown: (details) =>
                                  seekToLocalDx(details.localPosition.dx),
                              onHorizontalDragUpdate: (details) =>
                                  seekToLocalDx(details.localPosition.dx),
                              child: SizedBox(
                                height: 40 * scaleFactor,
                                child: Stack(
                                  alignment: Alignment.centerLeft,
                                  children: [
                                    Container(
                                      height: trackHeight,
                                      decoration: BoxDecoration(
                                        color: colorScheme
                                            .surfaceContainerHighest
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(
                                          trackHeight / 2,
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: bufferedProgress.clamp(
                                        0.0,
                                        1.0,
                                      ),
                                      child: Container(
                                        height: trackHeight,
                                        decoration: BoxDecoration(
                                          color: colorScheme.secondary
                                              .withValues(alpha: 0.5),
                                          borderRadius: BorderRadius.circular(
                                            trackHeight / 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (showPendingState)
                                      _FruitCarModePendingProgressOverlay(
                                        key: const Key(
                                          'fruit_car_mode_pending_progress_overlay',
                                        ),
                                        colorScheme: colorScheme,
                                        scaleFactor: scaleFactor,
                                        isLoading: isLoading,
                                      ),
                                    FractionallySizedBox(
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        height: trackHeight,
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.primary.withValues(
                                                alpha: 0.74,
                                              ),
                                            ],
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            trackHeight / 2,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: thumbLeft,
                                      child: Container(
                                        width: thumbSize,
                                        height: thumbSize,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: colorScheme.surface,
                                            width: 4 * scaleFactor,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: colorScheme.primary
                                                  .withValues(alpha: 0.24),
                                              blurRadius: 18 * scaleFactor,
                                              offset: Offset(
                                                0,
                                                6 * scaleFactor,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4 * scaleFactor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                formatDuration(position),
                                style: TextStyle(
                                  fontFamily: FontConfig.resolve('Inter'),
                                  fontSize: 24 * scaleFactor,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                totalMs <= 0 ? '--:--' : formatDuration(total),
                                style: TextStyle(
                                  fontFamily: FontConfig.resolve('Inter'),
                                  fontSize: 24 * scaleFactor,
                                  fontWeight: FontWeight.w800,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
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

  bool _shouldShowFruitCarModePendingCue({
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

  Widget _buildFruitCarModeControls({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, indexSnapshot) {
        final index = indexSnapshot.data ?? 0;
        final sequenceLength = audioProvider.audioPlayer.sequence.length;
        final isFirstTrack = index == 0;
        final isLastTrack = sequenceLength == 0 || index >= sequenceLength - 1;

        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          initialData: audioProvider.audioPlayer.playerState,
          builder: (context, stateSnapshot) {
            final playerState =
                stateSnapshot.data ?? audioProvider.audioPlayer.playerState;
            final processingState = playerState.processingState;
            final isPlaying = playerState.playing;
            final isBusy =
                processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _FruitCarModeControlButton(
                    icon: LucideIcons.chevronLeft,
                    onPressed: isFirstTrack
                        ? null
                        : () {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            audioProvider.seekToPrevious();
                          },
                    scaleFactor: scaleFactor,
                  ),
                ),
                SizedBox(width: 16 * scaleFactor),
                _FruitCarModePlayButton(
                  isBusy: isBusy,
                  isPlaying: isPlaying,
                  onPressed: () {
                    AppHaptics.heavyImpact(context.read<DeviceService>());
                    if (isPlaying) {
                      audioProvider.pause();
                    } else {
                      audioProvider.resume();
                    }
                  },
                  scaleFactor: scaleFactor,
                ),
                SizedBox(width: 16 * scaleFactor),
                Expanded(
                  child: _FruitCarModeControlButton(
                    icon: LucideIcons.chevronRight,
                    onPressed: isLastTrack
                        ? null
                        : () {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            audioProvider.seekToNext();
                          },
                    scaleFactor: scaleFactor,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildFruitCarModeUpcomingTracks({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Source currentSource,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data ?? 0;
        final tracks = currentSource.tracks;
        final nextTracks = tracks.skip(currentIndex + 1).take(4).toList();

        if (nextTracks.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (int i = 0; i < nextTracks.length; i++) ...[
              Text(
                nextTracks[i].title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontConfig.resolve('Inter'),
                  fontSize: switch (i) {
                    0 => 24 * scaleFactor,
                    1 => 21 * scaleFactor,
                    2 => 19 * scaleFactor,
                    _ => 17 * scaleFactor,
                  },
                  fontWeight: switch (i) {
                    0 => FontWeight.w700,
                    1 => FontWeight.w600,
                    _ => FontWeight.w500,
                  },
                  height: 1.04,
                  color: colorScheme.onSurface.withValues(
                    alpha: switch (i) {
                      0 => 0.68,
                      1 => 0.48,
                      2 => 0.34,
                      _ => 0.24,
                    },
                  ),
                ),
              ),
              if (i != nextTracks.length - 1) SizedBox(height: 6 * scaleFactor),
            ],
          ],
        );
      },
    );
  }

  Widget _buildFruitCarModeSecondaryCards({
    required BuildContext context,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: _FruitCarModeDetailCard(
            label: 'Venue',
            value: currentShow.venue,
            icon: LucideIcons.activity,
            iconColor: colorScheme.primary,
            scaleFactor: scaleFactor,
          ),
        ),
        SizedBox(width: 12 * scaleFactor),
        Expanded(
          child: _FruitCarModeDetailCard(
            label: 'Source',
            value: currentSource.id,
            icon: LucideIcons.playCircle,
            iconColor: colorScheme.secondary,
            scaleFactor: scaleFactor,
          ),
        ),
      ],
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
      final showListProvider = context.read<ShowListProvider>();
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
      if (mounted) {
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
      }
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

class _FruitCarModeStatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color accentColor;
  final double scaleFactor;

  const _FruitCarModeStatCard({
    required this.label,
    required this.value,
    required this.accentColor,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FruitSurface(
      borderRadius: BorderRadius.circular(18 * scaleFactor),
      blur: 14,
      opacity: 0.82,
      child: SizedBox(
        height: _fruitCarModeChipCardHeight(scaleFactor),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor,
            vertical: 12 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18 * scaleFactor),
            border: Border.all(color: accentColor.withValues(alpha: 0.16)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontFamily: FontConfig.resolve('Inter'),
                  fontSize: 9 * scaleFactor,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.8,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
              SizedBox(height: 10 * scaleFactor),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: FontConfig.resolve('Inter'),
                  fontSize: 17 * scaleFactor,
                  fontWeight: FontWeight.w900,
                  color: accentColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FruitCarModeControlButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final double scaleFactor;

  const _FruitCarModeControlButton({
    required this.icon,
    required this.onPressed,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEnabled = onPressed != null;

    return SizedBox(
      height: 112 * scaleFactor,
      child: GestureDetector(
        onTap: onPressed,
        child: FruitSurface(
          borderRadius: BorderRadius.circular(28 * scaleFactor),
          blur: 16,
          opacity: 0.84,
          child: Container(
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(28 * scaleFactor),
              border: Border.all(
                color: colorScheme.onSurface.withValues(
                  alpha: isEnabled ? 0.08 : 0.04,
                ),
              ),
            ),
            child: Center(
              child: Icon(
                icon,
                size: 42 * scaleFactor,
                color: isEnabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FruitCarModeEmbeddedCard extends StatelessWidget {
  const _FruitCarModeEmbeddedCard({
    this.label,
    required this.child,
    required this.scaleFactor,
  });

  final String? label;
  final Widget child;
  final double scaleFactor;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FruitSurface(
      borderRadius: BorderRadius.circular(18 * scaleFactor),
      blur: 14,
      opacity: 0.82,
      child: SizedBox(
        height: _fruitCarModeChipCardHeight(scaleFactor),
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12 * scaleFactor,
            vertical: 12 * scaleFactor,
          ),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(18 * scaleFactor),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (label != null) ...[
                Text(
                  label!,
                  style: TextStyle(
                    fontFamily: FontConfig.resolve('Inter'),
                    fontSize: 9 * scaleFactor,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.8,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
                SizedBox(height: 10 * scaleFactor),
              ],
              child,
            ],
          ),
        ),
      ),
    );
  }
}

double _fruitCarModeChipCardHeight(double scaleFactor) => 74 * scaleFactor;

class _FruitCarModePlayButton extends StatelessWidget {
  final bool isBusy;
  final bool isPlaying;
  final VoidCallback onPressed;
  final double scaleFactor;

  const _FruitCarModePlayButton({
    required this.isBusy,
    required this.isPlaying,
    required this.onPressed,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.watch<SettingsProvider>();
    final glassEnabled = settings.fruitEnableLiquidGlass;
    final BorderRadius borderRadius = BorderRadius.circular(999);

    final innerButton = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: glassEnabled
              ? [
                  colorScheme.primary.withValues(alpha: 0.94),
                  colorScheme.primaryContainer.withValues(alpha: 0.72),
                ]
              : [
                  colorScheme.primary,
                  colorScheme.primary.withValues(alpha: 0.78),
                ],
        ),
        border: Border.all(
          color: glassEnabled
              ? Colors.white.withValues(alpha: 0.22)
              : colorScheme.primary.withValues(alpha: 0.08),
          width: 1.1,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(
              alpha: glassEnabled ? 0.18 : 0.24,
            ),
            blurRadius: (glassEnabled ? 20 : 28) * scaleFactor,
            spreadRadius: glassEnabled ? 0 : 2 * scaleFactor,
            offset: Offset(0, (glassEnabled ? 6 : 10) * scaleFactor),
          ),
        ],
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: glassEnabled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: 0.18),
                    Colors.transparent,
                  ],
                )
              : null,
        ),
        child: Center(
          child: isBusy
              ? SizedBox(
                  width: 34 * scaleFactor,
                  height: 34 * scaleFactor,
                  child: CircularProgressIndicator(
                    strokeWidth: 3.2,
                    color: colorScheme.onPrimary,
                  ),
                )
              : Icon(
                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                  size: 58 * scaleFactor,
                  color: colorScheme.onPrimary,
                ),
        ),
      ),
    );

    return SizedBox(
      width: 152 * scaleFactor,
      height: 152 * scaleFactor,
      child: GestureDetector(
        onTap: onPressed,
        child: glassEnabled
            ? FruitSurface(
                borderRadius: borderRadius,
                blur: 20,
                opacity: 0.34,
                padding: EdgeInsets.all(10 * scaleFactor),
                child: innerButton,
              )
            : innerButton,
      ),
    );
  }
}

class _FruitCarModeDetailCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final double scaleFactor;

  const _FruitCarModeDetailCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FruitSurface(
      borderRadius: BorderRadius.circular(24 * scaleFactor),
      blur: 14,
      opacity: 0.82,
      child: Container(
        padding: EdgeInsets.all(18 * scaleFactor),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.72),
          borderRadius: BorderRadius.circular(24 * scaleFactor),
        ),
        child: Row(
          children: [
            Icon(icon, size: 24 * scaleFactor, color: iconColor),
            SizedBox(width: 12 * scaleFactor),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontFamily: FontConfig.resolve('Inter'),
                      fontSize: 10 * scaleFactor,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.5,
                      color: colorScheme.onSurfaceVariant.withValues(
                        alpha: 0.72,
                      ),
                    ),
                  ),
                  SizedBox(height: 4 * scaleFactor),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: FontConfig.resolve('Inter'),
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w900,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FruitCarModePendingProgressOverlay extends StatefulWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool isLoading;

  const _FruitCarModePendingProgressOverlay({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.isLoading,
  });

  @override
  State<_FruitCarModePendingProgressOverlay> createState() =>
      _FruitCarModePendingProgressOverlayState();
}

class _FruitCarModePendingProgressOverlayState
    extends State<_FruitCarModePendingProgressOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1450),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final double barHeight = 16.0 * widget.scaleFactor;
    final BorderRadius borderRadius = BorderRadius.circular(
      999 * widget.scaleFactor,
    );
    final Color sweepColor = widget.isLoading
        ? widget.colorScheme.primary
        : widget.colorScheme.tertiary;

    return RepaintBoundary(
      child: SizedBox(
        height: barHeight,
        width: double.infinity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final double travel = _controller.value;
                final double pulse = 1.0 - ((travel - 0.5).abs() * 2.0);
                final double sweepWidth = 88.0 * widget.scaleFactor;
                final double sweepOverflow = sweepWidth * 0.18;
                final double sweepTravelWidth =
                    (constraints.maxWidth + (sweepOverflow * 2.0) - sweepWidth)
                        .clamp(0.0, double.infinity);
                final double sweepLeft =
                    -sweepOverflow + (sweepTravelWidth * travel);
                final double beadWidth = 18.0 * widget.scaleFactor;
                final double beadTravelWidth =
                    (constraints.maxWidth - beadWidth).clamp(
                      0.0,
                      double.infinity,
                    );
                final double beadLeft = beadTravelWidth * travel;

                return ClipRRect(
                  borderRadius: borderRadius,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                widget.colorScheme.primary.withValues(
                                  alpha: 0.14,
                                ),
                                widget.colorScheme.tertiary.withValues(
                                  alpha: 0.14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        bottom: 0,
                        left: sweepLeft,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                sweepColor.withValues(alpha: 0.0),
                                Colors.white.withValues(alpha: 0.2),
                                sweepColor.withValues(alpha: 0.6),
                                Colors.white.withValues(alpha: 0.2),
                                sweepColor.withValues(alpha: 0.0),
                                Colors.transparent,
                              ],
                              stops: const [
                                0.0,
                                0.12,
                                0.28,
                                0.5,
                                0.72,
                                0.88,
                                1.0,
                              ],
                            ),
                          ),
                          child: SizedBox(width: sweepWidth, height: barHeight),
                        ),
                      ),
                      Positioned(
                        left: beadLeft,
                        top: 0,
                        child: Container(
                          key: const Key(
                            'fruit_car_mode_pending_progress_bead',
                          ),
                          width: beadWidth,
                          height: barHeight,
                          decoration: BoxDecoration(
                            borderRadius: borderRadius,
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.white.withValues(
                                  alpha: 0.8 + (pulse * 0.08),
                                ),
                                sweepColor.withValues(alpha: 0.9),
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: sweepColor.withValues(alpha: 0.26),
                                blurRadius: 8,
                                spreadRadius: 0.4 * pulse,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _FruitFloatingSpheres extends StatefulWidget {
  const _FruitFloatingSpheres({
    super.key,
    required this.colorScheme,
    required this.animate,
  });

  final ColorScheme colorScheme;
  final bool animate;

  @override
  State<_FruitFloatingSpheres> createState() => _FruitFloatingSpheresState();
}

class _FruitFloatingSpheresState extends State<_FruitFloatingSpheres> {
  static const Duration _frameStep = Duration(milliseconds: 48);
  static const double _wrapMargin = 0.28;
  Timer? _timer;
  late List<_FruitSphereNode> _spheres;
  int _tickCount = 0;

  @override
  void initState() {
    super.initState();
    _spheres = _FruitSphereNode.seeded();
    _syncAnimationState();
  }

  @override
  void didUpdateWidget(covariant _FruitFloatingSpheres oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.animate != widget.animate) {
      _syncAnimationState();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _syncAnimationState() {
    _timer?.cancel();
    if (!widget.animate) {
      return;
    }

    _timer = Timer.periodic(_frameStep, (_) {
      if (!mounted) return;
      setState(() {
        _tickCount++;
        _spheres = _spheres.map(_advanceSphere).toList(growable: false);
      });
    });
  }

  _FruitSphereNode _advanceSphere(_FruitSphereNode sphere) {
    double x = sphere.x + sphere.vx;
    double y = sphere.y + sphere.vy;
    double vx = sphere.vx;
    double vy = sphere.vy;

    if (x < -_wrapMargin) x = 1 + _wrapMargin;
    if (x > 1 + _wrapMargin) x = -_wrapMargin;
    if (y < -_wrapMargin) y = 1 + _wrapMargin;
    if (y > 1 + _wrapMargin) y = -_wrapMargin;

    // Rare micro-adjustments keep drift from feeling mechanically linear
    // without introducing expensive per-frame trig work.
    if (_tickCount % 18 == 0) {
      vx = (vx + (sphere.ax * 0.0009)).clamp(-0.0036, 0.0036);
      vy = (vy + (sphere.ay * 0.0009)).clamp(-0.0036, 0.0036);
    }

    return sphere.copyWith(x: x, y: y, vx: vx, vy: vy);
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FruitFloatingSpheresPainter(
        spheres: _spheres,
        colorScheme: widget.colorScheme,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _FruitFloatingSpheresPainter extends CustomPainter {
  const _FruitFloatingSpheresPainter({
    required this.spheres,
    required this.colorScheme,
  });

  final List<_FruitSphereNode> spheres;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final shortestSide = math.min(size.width, size.height);

    for (final sphere in spheres) {
      final center = Offset(size.width * sphere.x, size.height * sphere.y);
      final radius = shortestSide * sphere.radiusFactor;
      final color = _resolveColor(sphere.paletteIndex);

      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.08)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.18);
      final corePaint = Paint()
        ..color = color.withValues(alpha: 0.2)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.04);

      canvas.drawCircle(center, radius, glowPaint);
      canvas.drawCircle(center, radius * 0.52, corePaint);
    }
  }

  Color _resolveColor(int paletteIndex) {
    return switch (paletteIndex) {
      0 => colorScheme.primary,
      1 => colorScheme.secondary,
      2 => colorScheme.tertiary,
      _ => colorScheme.primaryContainer,
    };
  }

  @override
  bool shouldRepaint(covariant _FruitFloatingSpheresPainter oldDelegate) {
    return oldDelegate.spheres != spheres ||
        oldDelegate.colorScheme != colorScheme;
  }
}

class _FruitSphereNode {
  const _FruitSphereNode({
    required this.x,
    required this.y,
    required this.radiusFactor,
    required this.vx,
    required this.vy,
    required this.ax,
    required this.ay,
    required this.paletteIndex,
  });

  final double x;
  final double y;
  final double radiusFactor;
  final double vx;
  final double vy;
  final double ax;
  final double ay;
  final int paletteIndex;

  _FruitSphereNode copyWith({
    double? x,
    double? y,
    double? radiusFactor,
    double? vx,
    double? vy,
    double? ax,
    double? ay,
    int? paletteIndex,
  }) {
    return _FruitSphereNode(
      x: x ?? this.x,
      y: y ?? this.y,
      radiusFactor: radiusFactor ?? this.radiusFactor,
      vx: vx ?? this.vx,
      vy: vy ?? this.vy,
      ax: ax ?? this.ax,
      ay: ay ?? this.ay,
      paletteIndex: paletteIndex ?? this.paletteIndex,
    );
  }

  static List<_FruitSphereNode> seeded() {
    return const [
      _FruitSphereNode(
        x: 0.18,
        y: 0.14,
        radiusFactor: 0.22,
        vx: 0.0015,
        vy: 0.0011,
        ax: 0.7,
        ay: -0.4,
        paletteIndex: 0,
      ),
      _FruitSphereNode(
        x: 0.82,
        y: 0.18,
        radiusFactor: 0.18,
        vx: -0.0013,
        vy: 0.0010,
        ax: -0.5,
        ay: 0.6,
        paletteIndex: 1,
      ),
      _FruitSphereNode(
        x: 0.72,
        y: 0.42,
        radiusFactor: 0.16,
        vx: -0.0010,
        vy: -0.0014,
        ax: 0.4,
        ay: -0.6,
        paletteIndex: 2,
      ),
      _FruitSphereNode(
        x: 0.28,
        y: 0.52,
        radiusFactor: 0.14,
        vx: 0.0012,
        vy: -0.0011,
        ax: -0.6,
        ay: -0.3,
        paletteIndex: 3,
      ),
      _FruitSphereNode(
        x: 0.14,
        y: 0.78,
        radiusFactor: 0.20,
        vx: 0.0010,
        vy: -0.0008,
        ax: 0.5,
        ay: 0.5,
        paletteIndex: 1,
      ),
      _FruitSphereNode(
        x: 0.84,
        y: 0.84,
        radiusFactor: 0.24,
        vx: -0.0009,
        vy: -0.0012,
        ax: -0.4,
        ay: 0.4,
        paletteIndex: 0,
      ),
    ];
  }
}
