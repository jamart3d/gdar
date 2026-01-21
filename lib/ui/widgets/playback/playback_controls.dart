import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackControls extends StatefulWidget {
  const PlaybackControls({super.key});

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

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
        final sequence = audioProvider.audioPlayer.sequence;
        final totalLength = sequence.length;
        final isLastTrack = index >= totalLength - 1;

        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          initialData: audioProvider.audioPlayer.playerState,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing ?? false;

            if (playing && !_pulseController.isAnimating) {
              _pulseController.repeat(reverse: true);
            } else if (!playing && _pulseController.isAnimating) {
              _pulseController.stop();
              _pulseController.animateTo(0.0,
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOut);
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  icon: const Icon(Icons.skip_previous_rounded),
                  iconSize: iconSize,
                  color: colorScheme.onSurface,
                  onPressed: isFirstTrack
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          audioProvider.seekToPrevious();
                        },
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      audioProvider.stopAndClear();
                    },
                    child: Hero(
                      tag: 'play_pause_button',
                      child: Container(
                        width:
                            70.0 * scaleFactor, // Adjusted size (midway 56-84)
                        height: 70.0 * scaleFactor,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering)
                            ? Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : IconButton(
                                key: const ValueKey('play_pause_button'),
                                iconSize: 42.0 * scaleFactor,
                                onPressed: () {
                                  HapticFeedback.selectionClick();
                                  if (playing) {
                                    audioProvider.pause();
                                  } else {
                                    audioProvider.play();
                                  }
                                },
                                icon: Icon(
                                  playing
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: colorScheme.onPrimary,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: iconSize,
                  color: colorScheme.onSurface,
                  onPressed: isLastTrack
                      ? null
                      : () {
                          HapticFeedback.selectionClick();
                          audioProvider.seekToNext();
                        },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
