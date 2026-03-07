import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';

class EmbeddedMiniPlayer extends StatelessWidget {
  final double scaleFactor;

  const EmbeddedMiniPlayer({
    super.key,
    this.scaleFactor = 1.0,
  });

  String _formatDuration(Duration duration) {
    if (duration == Duration.zero) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    if (duration.inHours > 0) {
      return '${duration.inHours}:$twoDigitMinutes:$twoDigitSeconds';
    }
    return '${duration.inMinutes}:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final currentTrack = audioProvider.currentTrack;

    if (currentTrack == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // Play/Pause Button
          StreamBuilder<PlayerState>(
            stream: audioProvider.playerStateStream,
            builder: (context, snapshot) {
              final playerState = snapshot.data;
              final processingState = playerState?.processingState;
              final playing = playerState?.playing;

              bool isLoading = processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering;

              return GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact(context.read<DeviceService>());
                  if (playing == true) {
                    audioProvider.audioPlayer.pause();
                  } else {
                    audioProvider.audioPlayer.play();
                  }
                },
                child: Container(
                  width: 32 * scaleFactor,
                  height: 32 * scaleFactor,
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: isLoading
                        ? SizedBox(
                            width: 14 * scaleFactor,
                            height: 14 * scaleFactor,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.onPrimary),
                            ),
                          )
                        : Icon(
                            playing == true
                                ? LucideIcons.pause
                                : LucideIcons.play,
                            size: 16 * scaleFactor,
                            color: colorScheme.onPrimary,
                          ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          // Info & Progress
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        currentTrack.title,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12 * scaleFactor,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    StreamBuilder<Duration>(
                      stream: audioProvider.positionStream,
                      initialData: audioProvider.audioPlayer.position,
                      builder: (context, posSnap) {
                        final pos = posSnap.data ?? Duration.zero;
                        return StreamBuilder<Duration?>(
                          stream: audioProvider.durationStream,
                          initialData: audioProvider.audioPlayer.duration,
                          builder: (context, durSnap) {
                            final dur = durSnap.data ?? Duration.zero;
                            return Text(
                              '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: 10 * scaleFactor,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.5),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Progress Bar
                StreamBuilder<Duration>(
                  stream: audioProvider.positionStream,
                  initialData: audioProvider.audioPlayer.position,
                  builder: (context, posSnap) {
                    final pos = posSnap.data ?? Duration.zero;
                    return StreamBuilder<Duration?>(
                      stream: audioProvider.durationStream,
                      initialData: audioProvider.audioPlayer.duration,
                      builder: (context, durSnap) {
                        final dur = durSnap.data ?? Duration.zero;
                        final double progress = dur.inMilliseconds > 0
                            ? (pos.inMilliseconds / dur.inMilliseconds)
                                .clamp(0.0, 1.0)
                            : 0.0;

                        return Stack(
                          children: [
                            Container(
                              height: 2,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(1),
                              ),
                            ),
                            FractionallySizedBox(
                              widthFactor: progress,
                              child: Container(
                                height: 2,
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
