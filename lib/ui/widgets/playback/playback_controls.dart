import 'package:flutter/material.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackControls extends StatelessWidget {
  const PlaybackControls({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final currentSource = audioProvider.currentSource;

    if (currentSource == null) {
      return const SizedBox.shrink();
    }

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
    final double iconSize = 32 * scaleFactor;

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, indexSnapshot) {
        final index = indexSnapshot.data ?? 0;
        final isFirstTrack = index == 0;
        final isLastTrack = index >= currentSource.tracks.length - 1;

        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          initialData: audioProvider.audioPlayer.playerState,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: iconSize,
                  color: colorScheme.onSurface,
                  onPressed: isFirstTrack ? null : audioProvider.seekToPrevious,
                  tooltip: 'Previous Track',
                ),
                if (processingState == ProcessingState.loading ||
                    processingState == ProcessingState.buffering)
                  SizedBox(
                    width: 56.0 * scaleFactor,
                    height: 56.0 * scaleFactor,
                    child: const CircularProgressIndicator(),
                  )
                else
                  IconButton(
                    key: const ValueKey('play_pause_button'),
                    iconSize: 56.0 * scaleFactor,
                    onPressed: () {
                      if (playing) {
                        audioProvider.pause();
                      } else {
                        audioProvider.play();
                      }
                    },
                    icon: Icon(
                      playing
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_fill_rounded,
                      color: colorScheme.primary,
                    ),
                    tooltip: playing ? 'Pause' : 'Play',
                  ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: iconSize,
                  color: colorScheme.onSurface,
                  onPressed: isLastTrack ? null : audioProvider.seekToNext,
                  tooltip: 'Next Track',
                ),
              ],
            );
          },
        );
      },
    );
  }
}
