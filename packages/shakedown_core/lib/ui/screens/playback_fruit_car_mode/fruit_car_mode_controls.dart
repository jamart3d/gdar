part of '../playback_screen.dart';

extension _PlaybackScreenFruitCarModeControls on PlaybackScreenState {
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
                  fontSize: fruitCarModeUpcomingFontSize(i),
                  fontWeight: fruitCarModeUpcomingFontWeight(i),
                  height: 1.04,
                  color: colorScheme.onSurface.withValues(
                    alpha: fruitCarModeUpcomingOpacity(i),
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
