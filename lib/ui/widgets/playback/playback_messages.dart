import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';

class PlaybackMessages extends StatelessWidget {
  final TextAlign textAlign;
  final bool showDivider;

  const PlaybackMessages({
    super.key,
    this.textAlign = TextAlign.center,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final double labelsFontSize = 12.0 * scaleFactor;

    if (!settingsProvider.showPlaybackMessages) {
      return const SizedBox.shrink();
    }

    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      initialData: audioProvider.audioPlayer.playerState,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        String statusText = '';
        if (processingState == ProcessingState.loading) {
          statusText = 'Loading...';
        } else if (processingState == ProcessingState.buffering) {
          statusText = 'Buffering...';
        } else if (processingState == ProcessingState.ready) {
          statusText = playing ? 'Playing' : 'Paused';
        } else if (processingState == ProcessingState.completed) {
          statusText = 'Completed';
        }

        if (statusText.isEmpty) return const SizedBox.shrink();

        final children = [
          Text(
            statusText,
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.bold,
              fontSize: labelsFontSize,
            ),
          ),
          if (showDivider) ...[
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: labelsFontSize,
              ),
            ),
            const SizedBox(width: 8),
          ],
          StreamBuilder<Duration>(
            stream: audioProvider.bufferedPositionStream,
            initialData: audioProvider.audioPlayer.bufferedPosition,
            builder: (context, bufferedSnapshot) {
              final buffered = bufferedSnapshot.data ?? Duration.zero;
              return Text(
                'Buffered: ${formatDuration(buffered)}',
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: labelsFontSize,
                ),
              );
            },
          ),
        ];

        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: textAlign == TextAlign.center
              ? MainAxisAlignment.center
              : textAlign == TextAlign.right
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
          children: children,
        );
      },
    );
  }
}
