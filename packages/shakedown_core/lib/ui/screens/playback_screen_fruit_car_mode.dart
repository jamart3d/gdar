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
                    child: FloatingSpheresBackground(
                      key: const ValueKey('fruit_car_mode_floating_spheres'),
                      colorScheme: colorScheme,
                      animate: !settingsProvider.performanceMode,
                      sphereCount: SphereAmount.tiny,
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

    Future<void> openRatingDialog() async {
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

    return GestureDetector(
      key: const ValueKey('fruit_car_mode_chip_row'),
      behavior: HitTestBehavior.opaque,
      onTap: toggleFruitCarModeHud,
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
                  final liveHud = snapshot.data ?? HudSnapshot.empty();

                  return StreamBuilder<PlayerState>(
                    stream: audioProvider.playerStateStream,
                    initialData: audioProvider.audioPlayer.playerState,
                    builder: (context, playerSnapshot) {
                      final playerState =
                          playerSnapshot.data ??
                          audioProvider.audioPlayer.playerState;
                      final isPlaying = playerState.playing;
                      final hud = isPlaying
                          ? (_fruitCarModeFrozenHud = liveHud)
                          : (_fruitCarModeFrozenHud ?? liveHud);

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
        final nextTracks = tracks.skip(currentIndex + 1).toList();

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
