import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_progress_bar.dart';
import 'package:shakedown_core/ui/widgets/show_list/fruit_car_mode/fruit_track_pulse.dart';

bool shouldShowFruitCarModeTrackPendingCue({
  required bool isLoading,
  required bool isBuffering,
  required int bufferedPositionMs,
  required int positionMs,
  required int durationMs,
}) {
  final int remainingMs = durationMs - positionMs;
  final bool hasPlayableTail = durationMs <= 0 || remainingMs > 900;
  final bool hasVisibleBufferHeadroom = bufferedPositionMs > (positionMs + 350);
  return isLoading ||
      isBuffering ||
      (hasPlayableTail && !hasVisibleBufferHeadroom);
}

class FruitCarModeTrackProgress extends StatelessWidget {
  const FruitCarModeTrackProgress({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.glassEnabled,
  });

  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool glassEnabled;

  @override
  Widget build(BuildContext context) {
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
            final total = durationSnapshot.data ?? Duration.zero;
            final totalMs = total.inMilliseconds;
            final positionMs = position.inMilliseconds.clamp(
              0,
              totalMs > 0 ? totalMs : 0,
            );

            return StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                final bufferedMs = buffered.inMilliseconds.clamp(
                  0,
                  totalMs > 0 ? totalMs : 0,
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
                    final showPendingState =
                        shouldShowFruitCarModeTrackPendingCue(
                          isLoading: isLoading,
                          isBuffering: isBuffering,
                          bufferedPositionMs: bufferedMs,
                          positionMs: positionMs,
                          durationMs: totalMs,
                        );
                    final bool pulseActive =
                        playerState.playing || isLoading || isBuffering;

                    return Row(
                      children: [
                        FruitCarModeTrackPulse(
                          key: const ValueKey(
                            'fruit_show_list_car_mode_track_pulse',
                          ),
                          colorScheme: colorScheme,
                          scaleFactor: scaleFactor,
                          active: pulseActive,
                        ),
                        SizedBox(width: 8 * scaleFactor),
                        Expanded(
                          child: KeyedSubtree(
                            key: const ValueKey(
                              'fruit_show_list_car_mode_track_progress',
                            ),
                            child: FruitNowPlayingProgressBar(
                              colorScheme: colorScheme,
                              scaleFactor: scaleFactor,
                              isLoading: isLoading,
                              bufferedPositionMs: bufferedMs,
                              positionMs: positionMs,
                              durationMs: totalMs,
                              glassEnabled: glassEnabled,
                              showPendingState: showPendingState,
                            ),
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
}
