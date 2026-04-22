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
    return _buildFruitCarModeScaffoldContent(
      context: context,
      audioProvider: audioProvider,
      backgroundColor: backgroundColor,
      currentShow: currentShow,
      currentSource: currentSource,
      scaleFactor: scaleFactor,
      settingsProvider: settingsProvider,
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
    final baseHud = isPlaying
        ? (_fruitCarModeFrozenHud = liveHud)
        : (_fruitCarModeFrozenHud ?? liveHud);

    final liveGap = baseHud.lastGapMs;
    if (liveGap != null && liveGap.isFinite && liveGap > 0) {
      _fruitCarModeLastMeasuredGapMs = liveGap;
      return baseHud;
    }

    final cachedGap = _fruitCarModeLastMeasuredGapMs;
    if (cachedGap != null && cachedGap.isFinite) {
      return baseHud.copyWith(lastGapMs: cachedGap);
    }

    return baseHud;
  }

  void _recordFruitCarModeRenderedProgress({
    required Duration renderedPosition,
    required Duration renderedTotal,
    required double renderedProgress,
    required PlayerState playerState,
  }) {
    _fruitCarModeRenderedPosition = renderedPosition;
    _fruitCarModeRenderedTotal = renderedTotal;
    _fruitCarModeRenderedProgress = renderedProgress.clamp(0.0, 1.0);
    _fruitCarModeRenderedAt = DateTime.now();
    _fruitCarModeRenderedPlayerState = playerState;
  }

  void _startFruitCarModeSyncProbe({
    required String trigger,
    required AudioProvider audioProvider,
  }) {
    audioProvider.audioPlayer.startSyncDebugProbe(trigger);
    _fruitCarModeSyncProbeTimer?.cancel();
    _fruitCarModeSyncProbeTrigger = trigger;
    _fruitCarModeSyncProbeUntil = DateTime.now().add(
      const Duration(seconds: 6),
    );

    logger.i('FruitCarModeSyncProbe[$trigger]: started');
    _logFruitCarModeSyncProbeSample(audioProvider, phase: 'start');

    _fruitCarModeSyncProbeTimer = Timer.periodic(
      const Duration(milliseconds: 500),
      (_) {
        if (!mounted) {
          _fruitCarModeSyncProbeTimer?.cancel();
          _fruitCarModeSyncProbeTimer = null;
          return;
        }

        final probeUntil = _fruitCarModeSyncProbeUntil;
        if (probeUntil == null || DateTime.now().isAfter(probeUntil)) {
          _logFruitCarModeSyncProbeSample(audioProvider, phase: 'done');
          _fruitCarModeSyncProbeTimer?.cancel();
          _fruitCarModeSyncProbeTimer = null;
          return;
        }

        _logFruitCarModeSyncProbeSample(audioProvider, phase: 'tick');
      },
    );
  }

  void _logFruitCarModeSyncProbeSample(
    AudioProvider audioProvider, {
    required String phase,
  }) {
    final livePosition = audioProvider.audioPlayer.position;
    final liveTotal = audioProvider.audioPlayer.duration ?? Duration.zero;
    final liveTotalMs = liveTotal.inMilliseconds;
    final clampedLiveMs = livePosition.inMilliseconds.clamp(
      0,
      liveTotalMs > 0 ? liveTotalMs : 0,
    );
    final liveProgress = liveTotalMs <= 0 ? 0.0 : clampedLiveMs / liveTotalMs;
    final renderAgeMs = _fruitCarModeRenderedAt == null
        ? -1
        : DateTime.now().difference(_fruitCarModeRenderedAt!).inMilliseconds;
    final positionDeltaMs = (_fruitCarModeRenderedPosition - livePosition)
        .inMilliseconds
        .abs();
    final progressDelta = (_fruitCarModeRenderedProgress - liveProgress).abs();
    final liveState = audioProvider.audioPlayer.playerState;
    final renderedState = _fruitCarModeRenderedPlayerState;
    final renderInSync =
        _fruitCarModeRenderedAt != null &&
        renderAgeMs <= 900 &&
        positionDeltaMs <= 350 &&
        progressDelta <= 0.03;

    logger.i(
      'FruitCarModeSyncProbe[${_fruitCarModeSyncProbeTrigger ?? 'unknown'}]'
      '[$phase]: '
      'renderElapsed=${formatDuration(_fruitCarModeRenderedPosition)} '
      'liveElapsed=${formatDuration(livePosition)} '
      'renderTotal=${_fruitCarModeRenderedTotal > Duration.zero ? formatDuration(_fruitCarModeRenderedTotal) : '--:--'} '
      'liveTotal=${liveTotal > Duration.zero ? formatDuration(liveTotal) : '--:--'} '
      'renderProgress=${_fruitCarModeRenderedProgress.toStringAsFixed(3)} '
      'liveProgress=${liveProgress.toStringAsFixed(3)} '
      'deltaMs=$positionDeltaMs '
      'deltaProgress=${progressDelta.toStringAsFixed(3)} '
      'renderAgeMs=$renderAgeMs '
      'renderPlaying=${renderedState?.playing ?? false} '
      'livePlaying=${liveState.playing} '
      'renderProcessing=${renderedState?.processingState.name ?? 'unknown'} '
      'liveProcessing=${liveState.processingState.name} '
      'sync=${renderInSync ? 'LIVE' : 'STALE'}',
    );
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
}
