part of 'playback_screen.dart';

extension _PlaybackScreenFruitCarModeBuild on PlaybackScreenState {
  Widget _buildFruitCarModeScaffold({
    required BuildContext context,
    required AudioProvider audioProvider,
    required Color backgroundColor,
    required Show currentShow,
    required Source currentSource,
    required double scaleFactor,
    required SettingsProvider settingsProvider,
  }) {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: Container(
        key: const ValueKey('fruit_car_mode_layout'),
        decoration: BoxDecoration(
          gradient: _fruitCarModeBackgroundGradient(context),
        ),
        child: Stack(
          children: [
            _buildFruitCarModeFloatingSpheres(
              context: context,
              settingsProvider: settingsProvider,
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: _fruitCarModePagePadding(context, scaleFactor),
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
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
                          Expanded(
                            child: SingleChildScrollView(
                              key: const ValueKey(
                                'fruit_car_mode_upcoming_scroll',
                              ),
                              padding: EdgeInsets.only(
                                bottom: 20 * scaleFactor,
                              ),
                              child: _buildFruitCarModeUpcomingTracks(
                                context: context,
                                audioProvider: audioProvider,
                                currentSource: currentSource,
                                scaleFactor: scaleFactor,
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

  Widget _buildFruitCarModeFloatingSpheres({
    required BuildContext context,
    required SettingsProvider settingsProvider,
  }) {
    if (!settingsProvider.fruitFloatingSpheres) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: IgnorePointer(
        child: RepaintBoundary(
          child: FloatingSpheresBackground(
            key: const ValueKey('fruit_car_mode_floating_spheres'),
            colorScheme: Theme.of(context).colorScheme,
            animate: !settingsProvider.performanceMode,
            sphereCount: SphereAmount.tiny,
          ),
        ),
      ),
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
    final String? locationText = currentSource.location;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          currentShow.venue,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: _fruitCarModeTextStyle(
            scaleFactor: scaleFactor,
            fontSize: 34,
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
            style: _fruitCarModeTextStyle(
              scaleFactor: scaleFactor,
              fontSize: 19,
              fontWeight: FontWeight.w700,
              height: 1.1,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
          SizedBox(height: 6 * scaleFactor),
        ],
        Text(
          _fruitCarModeDateText(currentShow),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: _fruitCarModeTextStyle(
            scaleFactor: scaleFactor,
            fontSize: 25,
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
            style: _fruitCarModeTextStyle(
              scaleFactor: scaleFactor,
              fontSize: 46,
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
    final chipRowHeight = _fruitCarModeChipCardHeight(scaleFactor);

    return GestureDetector(
      key: const ValueKey('fruit_car_mode_chip_row'),
      behavior: HitTestBehavior.opaque,
      onTap: toggleFruitCarModeHud,
      child: SizedBox(
        height: chipRowHeight,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          layoutBuilder: (currentChild, previousChildren) => Stack(
            alignment: Alignment.centerLeft,
            children: [...previousChildren, ?currentChild],
          ),
          child: _fruitCarModeHudShowsMeta
              ? _buildFruitCarModeHudMeta(
                  context: context,
                  currentSource: currentSource,
                  scaleFactor: scaleFactor,
                  chipRowHeight: chipRowHeight,
                )
              : _buildFruitCarModeHudStats(
                  context: context,
                  audioProvider: audioProvider,
                  scaleFactor: scaleFactor,
                ),
        ),
      ),
    );
  }

  Widget _buildFruitCarModeHudMeta({
    required BuildContext context,
    required Source currentSource,
    required double scaleFactor,
    required double chipRowHeight,
  }) {
    final catalog = CatalogService();
    final rating = catalog.getRating(currentSource.id);
    final isPlayed = catalog.isPlayed(currentSource.id);

    return SizedBox.expand(
      key: const ValueKey('fruit_car_mode_chip_row_meta'),
      child: Row(
        children: [
          SizedBox(
            width: 220 * scaleFactor,
            height: chipRowHeight,
            child: Semantics(
              button: true,
              label: 'Rate source ${currentSource.id}',
              child: GestureDetector(
                key: const ValueKey('fruit_car_mode_rating_zone'),
                behavior: HitTestBehavior.opaque,
                onTap: () => _showFruitCarModeRatingDialog(
                  context,
                  currentSource: currentSource,
                  catalog: catalog,
                  rating: rating,
                  isPlayed: isPlayed,
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12 * scaleFactor),
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
            child: _buildFruitCarModeMetaDetails(
              context: context,
              currentSource: currentSource,
              scaleFactor: scaleFactor,
              chipRowHeight: chipRowHeight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitCarModeMetaDetails({
    required BuildContext context,
    required Source currentSource,
    required double scaleFactor,
    required double chipRowHeight,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final String sourceLabel = (currentSource.src ?? '').toUpperCase();
    final bool hasSourceLabel = sourceLabel.isNotEmpty;

    return SizedBox(
      height: chipRowHeight,
      child: Align(
        alignment: Alignment.centerLeft,
        child: Column(
          key: const ValueKey('fruit_car_mode_meta_stack'),
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasSourceLabel)
              Text(
                sourceLabel,
                key: const ValueKey('fruit_car_mode_src_label'),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: _fruitCarModeTextStyle(
                  scaleFactor: scaleFactor,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: 0.9,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.92),
                ),
              ),
            if (hasSourceLabel) SizedBox(height: 4 * scaleFactor),
            Text(
              currentSource.id,
              key: const ValueKey('fruit_car_mode_shnid_label'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: _fruitCarModeTextStyle(
                scaleFactor: scaleFactor,
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                height: 1.0,
                letterSpacing: 0.2,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFruitCarModeHudStats({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox.expand(
      key: const ValueKey('fruit_car_mode_chip_row_stats'),
      child: StreamBuilder<HudSnapshot>(
        stream: audioProvider.hudSnapshotStream,
        initialData: audioProvider.currentHudSnapshot,
        builder: (context, snapshot) {
          final liveHud = snapshot.data ?? HudSnapshot.empty();

          return StreamBuilder<PlayerState>(
            stream: audioProvider.playerStateStream,
            initialData: audioProvider.audioPlayer.playerState,
            builder: (context, playerSnapshot) {
              final playerState =
                  playerSnapshot.data ?? audioProvider.audioPlayer.playerState;
              final hud = _resolveFruitCarModeHudSnapshot(
                liveHud: liveHud,
                isPlaying: playerState.playing,
              );

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
                  SizedBox(width: 6 * scaleFactor),
                  Expanded(
                    child: _FruitCarModeStatCard(
                      label: 'HD',
                      value: hud.headroom,
                      accentColor: colorScheme.secondary,
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  SizedBox(width: 6 * scaleFactor),
                  Expanded(
                    child: _FruitCarModeStatCard(
                      label: 'NXT',
                      value: hud.nextBuffered,
                      accentColor: colorScheme.tertiary,
                      scaleFactor: scaleFactor,
                    ),
                  ),
                  SizedBox(width: 6 * scaleFactor),
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
          );
        },
      ),
    );
  }

  Widget _buildFruitCarModeProgress({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
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

            return StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final metrics = computeFruitCarModeProgressMetrics(
                  position: position,
                  buffered: buffered,
                  total: total,
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
                    final showPendingState = computeFruitCarModePendingCue(
                      isLoading: isLoading,
                      isBuffering: isBuffering,
                      bufferedPositionMs: metrics.bufferedMs,
                      positionMs: metrics.positionMs,
                      durationMs: metrics.totalMs,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFruitCarModeProgressTrack(
                          context: context,
                          audioProvider: audioProvider,
                          scaleFactor: scaleFactor,
                          metrics: metrics,
                          showPendingState: showPendingState,
                          isLoading: isLoading,
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 4 * scaleFactor,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildFruitCarModeDurationText(
                                context,
                                formatDuration(position),
                                scaleFactor,
                              ),
                              _buildFruitCarModeDurationText(
                                context,
                                metrics.totalMs <= 0
                                    ? '--:--'
                                    : formatDuration(total),
                                scaleFactor,
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

  Widget _buildFruitCarModeProgressTrack({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
    required FruitCarModeProgressMetrics metrics,
    required bool showPendingState,
    required bool isLoading,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final trackWidth = constraints.maxWidth;
        final trackHeight = 16 * scaleFactor;
        final thumbSize = 28 * scaleFactor;
        final thumbLeft =
            (trackWidth - thumbSize) * metrics.progress.clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) => _seekFruitCarModeProgress(
            audioProvider: audioProvider,
            trackWidth: trackWidth,
            totalMs: metrics.totalMs,
            localDx: details.localPosition.dx,
          ),
          onHorizontalDragUpdate: (details) => _seekFruitCarModeProgress(
            audioProvider: audioProvider,
            trackWidth: trackWidth,
            totalMs: metrics.totalMs,
            localDx: details.localPosition.dx,
          ),
          child: SizedBox(
            height: 40 * scaleFactor,
            child: Stack(
              alignment: Alignment.centerLeft,
              children: [
                _buildFruitCarModeProgressSegment(
                  height: trackHeight,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.45,
                    ),
                    borderRadius: BorderRadius.circular(trackHeight / 2),
                  ),
                ),
                FractionallySizedBox(
                  widthFactor: metrics.bufferedProgress.clamp(0.0, 1.0),
                  child: _buildFruitCarModeProgressSegment(
                    height: trackHeight,
                    decoration: BoxDecoration(
                      color: colorScheme.secondary.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                if (showPendingState)
                  _FruitCarModePendingProgressOverlay(
                    key: const Key('fruit_car_mode_pending_progress_overlay'),
                    colorScheme: colorScheme,
                    scaleFactor: scaleFactor,
                    isLoading: isLoading,
                  ),
                FractionallySizedBox(
                  widthFactor: metrics.progress.clamp(0.0, 1.0),
                  child: _buildFruitCarModeProgressSegment(
                    height: trackHeight,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary,
                          colorScheme.primary.withValues(alpha: 0.74),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(trackHeight / 2),
                    ),
                  ),
                ),
                Positioned(
                  left: thumbLeft,
                  child: _buildFruitCarModeProgressThumb(
                    context: context,
                    scaleFactor: scaleFactor,
                    thumbSize: thumbSize,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFruitCarModeProgressSegment({
    required double height,
    required BoxDecoration decoration,
  }) {
    return Container(height: height, decoration: decoration);
  }

  Widget _buildFruitCarModeProgressThumb({
    required BuildContext context,
    required double scaleFactor,
    required double thumbSize,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: thumbSize,
      height: thumbSize,
      decoration: BoxDecoration(
        color: colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: colorScheme.surface, width: 4 * scaleFactor),
        boxShadow: [
          BoxShadow(
            color: colorScheme.primary.withValues(alpha: 0.24),
            blurRadius: 18 * scaleFactor,
            offset: Offset(0, 6 * scaleFactor),
          ),
        ],
      ),
    );
  }

  Widget _buildFruitCarModeDurationText(
    BuildContext context,
    String text,
    double scaleFactor,
  ) {
    return Text(
      text,
      style: _fruitCarModeTextStyle(
        scaleFactor: scaleFactor,
        fontSize: 24,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
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
              key: const ValueKey('fruit_car_mode_controls_row'),
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
                  onLongPress: _buildWebStuckResetHandler(),
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
        final nextTracks = currentSource.tracks.skip(currentIndex + 1).toList();

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
                style: _fruitCarModeTextStyle(
                  scaleFactor: scaleFactor,
                  fontSize: _fruitCarModeUpcomingFontSize(i),
                  fontWeight: _fruitCarModeUpcomingFontWeight(i),
                  height: 1.04,
                  color: colorScheme.onSurface.withValues(
                    alpha: _fruitCarModeUpcomingOpacity(i),
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

  Future<void> _showFruitCarModeRatingDialog(
    BuildContext context, {
    required Source currentSource,
    required CatalogService catalog,
    required int rating,
    required bool isPlayed,
  }) async {
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
  }

  HudSnapshot _resolveFruitCarModeHudSnapshot({
    required HudSnapshot liveHud,
    required bool isPlaying,
  }) {
    return isPlaying
        ? (_fruitCarModeFrozenHud = liveHud)
        : (_fruitCarModeFrozenHud ?? liveHud);
  }

  void _seekFruitCarModeProgress({
    required AudioProvider audioProvider,
    required double trackWidth,
    required int totalMs,
    required double localDx,
  }) {
    if (totalMs <= 0 || trackWidth <= 0) {
      return;
    }

    final normalized = (localDx / trackWidth).clamp(0.0, 1.0);
    audioProvider.seek(Duration(milliseconds: (normalized * totalMs).round()));
  }

  LinearGradient _fruitCarModeBackgroundGradient(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        colorScheme.surface,
        colorScheme.surfaceContainerLowest,
        colorScheme.surface,
      ],
    );
  }

  EdgeInsets _fruitCarModePagePadding(
    BuildContext context,
    double scaleFactor,
  ) {
    final topPadding = MediaQuery.paddingOf(context).top;
    return EdgeInsets.fromLTRB(
      16 * scaleFactor,
      math.max(8.0, topPadding * 0.15),
      16 * scaleFactor,
      0,
    );
  }

  String _fruitCarModeDateText(Show currentShow) {
    try {
      return DateFormat('MMMM d, y').format(DateTime.parse(currentShow.date));
    } catch (_) {
      return currentShow.formattedDate;
    }
  }

  TextStyle _fruitCarModeTextStyle({
    required double scaleFactor,
    required double fontSize,
    required FontWeight fontWeight,
    required Color color,
    double height = 1.0,
    double letterSpacing = 0.0,
  }) {
    return TextStyle(
      fontFamily: FontConfig.resolve('Inter'),
      fontSize: fontSize * scaleFactor,
      fontWeight: fontWeight,
      height: height,
      letterSpacing: letterSpacing,
      color: color,
    );
  }

  double _fruitCarModeUpcomingFontSize(int index) {
    return switch (index) {
      0 => 24,
      1 => 21,
      2 => 19,
      _ => 17,
    };
  }

  FontWeight _fruitCarModeUpcomingFontWeight(int index) {
    return switch (index) {
      0 => FontWeight.w700,
      1 => FontWeight.w600,
      _ => FontWeight.w500,
    };
  }

  double _fruitCarModeUpcomingOpacity(int index) {
    return switch (index) {
      0 => 0.68,
      1 => 0.48,
      2 => 0.34,
      _ => 0.24,
    };
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
