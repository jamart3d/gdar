import 'package:flutter/material.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/utils.dart'; // for formatDuration
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackProgressBar extends StatelessWidget {
  const PlaybackProgressBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final audioProvider = context.watch<AudioProvider>();

    return StreamBuilder<Duration>(
      stream: audioProvider.positionStream,
      initialData: audioProvider.audioPlayer.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: audioProvider.durationStream,
          initialData: audioProvider.audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final totalDuration = durationSnapshot.data ?? Duration.zero;
            return Row(
              children: [
                SizedBox(
                  width: 56 * scaleFactor,
                  child: Text(
                    formatDuration(position),
                    textAlign: TextAlign.right,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.apply(fontSizeFactor: scaleFactor)
                        .copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StreamBuilder<Duration>(
                    stream: audioProvider.bufferedPositionStream,
                    initialData: audioProvider.audioPlayer.bufferedPosition,
                    builder: (context, bufferedSnapshot) {
                      final bufferedPosition =
                          bufferedSnapshot.data ?? Duration.zero;
                      return StreamBuilder<PlayerState>(
                        stream: audioProvider.playerStateStream,
                        initialData: audioProvider.audioPlayer.playerState,
                        builder: (context, stateSnapshot) {
                          final processingState =
                              stateSnapshot.data?.processingState;
                          final isBuffering =
                              processingState == ProcessingState.buffering ||
                                  processingState == ProcessingState.loading;
                          final bufferingPercentage =
                              (totalDuration.inSeconds > 0
                                      ? bufferedPosition.inSeconds /
                                          totalDuration.inSeconds
                                      : 0.0)
                                  .clamp(0.0, 1.0);
                          final positionPercentage = (totalDuration.inSeconds >
                                      0
                                  ? position.inSeconds / totalDuration.inSeconds
                                  : 0.0)
                              .clamp(0.0, 1.0);

                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight:
                                  12 * scaleFactor, // Expressive height
                              thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 10 * scaleFactor),
                              overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 22 * scaleFactor),
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: colorScheme.primary,
                              overlayColor:
                                  colorScheme.primary.withValues(alpha: 0.2),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Background Track
                                Container(
                                  height: 12 * scaleFactor,
                                  decoration: BoxDecoration(
                                    color: isTrueBlackMode
                                        ? Colors.white12
                                        : colorScheme.onSurface
                                            .withValues(alpha: 0.2),
                                    borderRadius:
                                        BorderRadius.circular(6 * scaleFactor),
                                  ),
                                ),
                                // Buffered Progress
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: bufferingPercentage,
                                    child: Container(
                                      height: 12 * scaleFactor,
                                      decoration: BoxDecoration(
                                        color: colorScheme.tertiary
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(
                                            6 * scaleFactor),
                                      ),
                                    ),
                                  ),
                                ),
                                // Active Progress
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: positionPercentage,
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 12 * scaleFactor,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme
                                                    .tertiary, // Expressive gradient
                                              ],
                                            ),
                                            borderRadius: BorderRadius.circular(
                                                6 * scaleFactor),
                                          ),
                                        ),
                                        if (isBuffering)
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(
                                                milliseconds: 1500),
                                            builder: (context, value, child) {
                                              return Container(
                                                height: 12 * scaleFactor,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6 * scaleFactor),
                                                  gradient: LinearGradient(
                                                    begin: Alignment.centerLeft,
                                                    end: Alignment.centerRight,
                                                    stops: [
                                                      (value - 0.2)
                                                          .clamp(0.0, 1.0),
                                                      value,
                                                      (value + 0.2)
                                                          .clamp(0.0, 1.0),
                                                    ],
                                                    colors: [
                                                      Colors.transparent,
                                                      colorScheme.onPrimary
                                                          .withValues(
                                                              alpha: 0.4),
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
                                  ),
                                ),
                                // Interactive Slider (Transparent Overlay)
                                Slider(
                                  min: 0.0,
                                  max: totalDuration.inSeconds > 0
                                      ? totalDuration.inSeconds.toDouble()
                                      : 1.0,
                                  value: position.inSeconds.toDouble().clamp(
                                      0.0, totalDuration.inSeconds.toDouble()),
                                  onChanged: totalDuration.inSeconds > 0
                                      ? (value) {
                                          audioProvider.seek(
                                              Duration(seconds: value.round()));
                                        }
                                      : null,
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 56 * scaleFactor,
                  child: Text(
                    formatDuration(totalDuration),
                    textAlign: TextAlign.left,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.apply(fontSizeFactor: scaleFactor)
                        .copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Roboto',
                      fontFeatures: [const FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
