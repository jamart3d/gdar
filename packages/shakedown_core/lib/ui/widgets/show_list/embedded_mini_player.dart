import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:just_audio/just_audio.dart';

class EmbeddedMiniPlayer extends StatelessWidget {
  final double scaleFactor;
  final bool compact;

  const EmbeddedMiniPlayer({
    super.key,
    this.scaleFactor = 1.0,
    this.compact = false,
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

    final horizontalPad = compact ? 8.0 : 10.0;
    final verticalPad = compact ? 5.0 : 8.0;
    final buttonSize = (compact ? 26.0 : 32.0) * scaleFactor;
    final iconSize = (compact ? 14.0 : 16.0) * scaleFactor;
    final loaderSize = (compact ? 12.0 : 14.0) * scaleFactor;
    final titleSize = (compact ? 10.5 : 12.0) * scaleFactor;
    final timeSize = (compact ? 8.5 : 10.0) * scaleFactor;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
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

              bool isLoading =
                  processingState == ProcessingState.loading ||
                  processingState == ProcessingState.buffering;
              final bool isPlaying = playing == true;

              void activate() {
                AppHaptics.lightImpact(context.read<DeviceService>());
                if (isPlaying) {
                  audioProvider.audioPlayer.pause();
                } else {
                  audioProvider.audioPlayer.play();
                }
              }

              return Semantics(
                button: true,
                toggled: isPlaying,
                label: isPlaying ? 'Pause playback' : 'Resume playback',
                child: ExcludeSemantics(
                  child: FocusableActionDetector(
                    enabled: true,
                    mouseCursor: SystemMouseCursors.click,
                    shortcuts: const <ShortcutActivator, Intent>{
                      SingleActivator(LogicalKeyboardKey.enter):
                          ActivateIntent(),
                      SingleActivator(LogicalKeyboardKey.space):
                          ActivateIntent(),
                    },
                    actions: <Type, Action<Intent>>{
                      ActivateIntent: CallbackAction<ActivateIntent>(
                        onInvoke: (_) {
                          activate();
                          return null;
                        },
                      ),
                    },
                    child: GestureDetector(
                      onTap: activate,
                      child: Container(
                        width: buttonSize,
                        height: buttonSize,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: isLoading
                              ? SizedBox(
                                  width: loaderSize,
                                  height: loaderSize,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      colorScheme.onPrimary,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isPlaying
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  size: iconSize,
                                  color: colorScheme.onPrimary,
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          SizedBox(width: compact ? 8 : 12),
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
                          fontSize: titleSize,
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: compact ? 6 : 8),
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
                              compact
                                  ? _formatDuration(pos)
                                  : '${_formatDuration(pos)} / ${_formatDuration(dur)}',
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontSize: timeSize,
                                fontWeight: FontWeight.w400,
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
                SizedBox(height: compact ? 3 : 6),
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
                            ? (pos.inMilliseconds / dur.inMilliseconds).clamp(
                                0.0,
                                1.0,
                              )
                            : 0.0;

                        return Stack(
                          children: [
                            Container(
                              height: 2,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.1,
                                ),
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
