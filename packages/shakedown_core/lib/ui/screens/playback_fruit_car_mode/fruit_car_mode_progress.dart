part of '../playback_screen.dart';

extension _PlaybackScreenFruitCarModeProgress on PlaybackScreenState {
  Widget _buildFruitCarModeProgress({
    required BuildContext context,
    required AudioProvider audioProvider,
    required double scaleFactor,
  }) {
    return StreamBuilder<DngSnapshot>(
      stream: audioProvider.diagnosticsStream,
      initialData: audioProvider.createSnapshot(),
      builder: (context, snapshot) {
        final dng = snapshot.data ?? audioProvider.createSnapshot();
        final position = dng.position;
        final buffered = dng.buffered;
        final playerState =
            dng.playerState ?? audioProvider.audioPlayer.playerState;
        final processingState = playerState.processingState;
        final total = audioProvider.audioPlayer.duration ?? Duration.zero;

        final metrics = computeFruitCarModeProgressMetrics(
          position: position,
          buffered: buffered,
          total: total,
        );

        final isLoading = processingState == ProcessingState.loading;
        final isBuffering = processingState == ProcessingState.buffering;

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
              padding: EdgeInsets.symmetric(horizontal: 4 * scaleFactor),
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
                    metrics.totalMs <= 0 ? '--:--' : formatDuration(total),
                    scaleFactor,
                  ),
                ],
              ),
            ),
          ],
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
}
