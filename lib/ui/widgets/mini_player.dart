import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class MiniPlayer extends StatelessWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final Show? currentShow = audioProvider.currentShow;
    final Source? currentSource = audioProvider.currentSource;

    if (currentShow == null || currentSource == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'player',
      child: Material(
        color: Colors.transparent,
        child: Container(
          // Adjusted margin to align with show list items
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHigh,
            // Adjusted border radius to match show list items
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            // Adjusted border radius to match show list items
            borderRadius: BorderRadius.circular(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                StreamBuilder<Duration>(
                  stream: audioProvider.audioPlayer.positionStream,
                  initialData: audioProvider.audioPlayer.position,
                  builder: (context, positionSnapshot) {
                    final position = positionSnapshot.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: audioProvider.audioPlayer.durationStream,
                      initialData: audioProvider.audioPlayer.duration,
                      builder: (context, durationSnapshot) {
                        final duration = durationSnapshot.data ?? Duration.zero;
                        final progress = duration.inMilliseconds > 0
                            ? position.inMilliseconds /
                            duration.inMilliseconds
                            : 0.0;

                        return StreamBuilder<Duration>(
                          stream: audioProvider.bufferedPositionStream,
                          initialData:
                          audioProvider.audioPlayer.bufferedPosition,
                          builder: (context, bufferedSnapshot) {
                            final bufferedPosition =
                                bufferedSnapshot.data ?? Duration.zero;
                            final bufferedProgress =
                            duration.inMilliseconds > 0
                                ? bufferedPosition.inMilliseconds /
                                duration.inMilliseconds
                                : 0.0;

                            return StreamBuilder<PlayerState>(
                              stream: audioProvider.playerStateStream,
                              initialData:
                              audioProvider.audioPlayer.playerState,
                              builder: (context, stateSnapshot) {
                                final processingState =
                                    stateSnapshot.data?.processingState;
                                final isBuffering = processingState ==
                                    ProcessingState.buffering ||
                                    processingState == ProcessingState.loading;

                                return SizedBox(
                                  height: 4,
                                  child: Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: colorScheme
                                              .surfaceContainerHighest,
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor:
                                        bufferedProgress.clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.tertiary
                                                    .withOpacity(0.3),
                                                colorScheme.tertiary
                                                    .withOpacity(0.5),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      FractionallySizedBox(
                                        widthFactor: progress.clamp(0.0, 1.0),
                                        alignment: Alignment.centerLeft,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme.primary
                                                    .withOpacity(0.8),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (isBuffering)
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: const Duration(
                                              milliseconds: 1500),
                                          builder: (context, value, child) {
                                            return Container(
                                              decoration: BoxDecoration(
                                                gradient: LinearGradient(
                                                  begin: Alignment.centerLeft,
                                                  end: Alignment.centerRight,
                                                  stops: [
                                                    (value - 0.3)
                                                        .clamp(0.0, 1.0),
                                                    value,
                                                    (value + 0.3)
                                                        .clamp(0.0, 1.0),
                                                  ],
                                                  colors: [
                                                    Colors.transparent,
                                                    colorScheme.tertiary
                                                        .withOpacity(0.4),
                                                    Colors.transparent,
                                                  ],
                                                ),
                                              ),
                                            );
                                          },
                                          onEnd: () {
                                            if (isBuffering &&
                                                context.mounted) {
                                              (context as Element)
                                                  .markNeedsBuild();
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        );
                      },
                    );
                  },
                ),
                InkWell(
                  onTap: onTap,
                  child: Padding(
                    // Adjusted padding to match show list items
                    padding: const EdgeInsets.all(20.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<int?>(
                            stream: audioProvider.currentIndexStream,
                            initialData: audioProvider.audioPlayer.currentIndex,
                            builder: (context, snapshot) {
                              final index = snapshot.data ?? 0;
                              if (index >= currentSource.tracks.length) {
                                return const SizedBox.shrink();
                              }
                              final track = currentSource.tracks[index];

                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    track.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleLarge
                                        ?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.1,
                                      color: colorScheme.onSurface,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    currentShow.venue,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                      letterSpacing: 0.15,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        StreamBuilder<int?>(
                          stream: audioProvider.currentIndexStream,
                          initialData: audioProvider.audioPlayer.currentIndex,
                          builder: (context, snapshot) {
                            final index = snapshot.data ?? 0;
                            final isFirstTrack = index == 0;
                            final isLastTrack =
                                index >= currentSource.tracks.length - 1;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.skip_previous_rounded),
                                  iconSize: 28,
                                  color: colorScheme.onSurfaceVariant,
                                  onPressed: isFirstTrack
                                      ? null
                                      : audioProvider.seekToPrevious,
                                ),
                                StreamBuilder<PlayerState>(
                                  stream: audioProvider.playerStateStream,
                                  initialData:
                                  audioProvider.audioPlayer.playerState,
                                  builder: (context, snapshot) {
                                    final playerState = snapshot.data;
                                    final processingState =
                                        playerState?.processingState;
                                    final playing =
                                        playerState?.playing ?? false;

                                    return GestureDetector(
                                      onLongPress: () {
                                        HapticFeedback.heavyImpact();
                                        audioProvider.stopAndClear();
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: processingState ==
                                            ProcessingState.loading ||
                                            processingState ==
                                                ProcessingState.buffering
                                            ? Padding(
                                          padding: const EdgeInsets.all(
                                              12.0),
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor:
                                            AlwaysStoppedAnimation<
                                                Color>(
                                              colorScheme.onPrimary,
                                            ),
                                          ),
                                        )
                                            : IconButton(
                                          icon: Icon(
                                            playing
                                                ? Icons.pause_rounded
                                                : Icons
                                                .play_arrow_rounded,
                                          ),
                                          iconSize: 28,
                                          color: colorScheme.onPrimary,
                                          onPressed: playing
                                              ? audioProvider.pause
                                              : audioProvider.play,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.skip_next_rounded),
                                  iconSize: 28,
                                  color: colorScheme.onSurfaceVariant,
                                  onPressed: isLastTrack
                                      ? null
                                      : audioProvider.seekToNext,
                                ),
                              ],
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
