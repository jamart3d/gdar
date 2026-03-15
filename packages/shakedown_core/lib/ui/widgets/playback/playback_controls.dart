import 'package:flutter/material.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/device_service.dart';

class PlaybackControls extends StatefulWidget {
  final double panelPosition;

  const PlaybackControls({super.key, this.panelPosition = 0.0});

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls>
    with SingleTickerProviderStateMixin {
  bool _isPlayPressed = false;
  bool _isPrevPressed = false;
  bool _isNextPressed = false;
  late AnimationController _breathingController;
  late Animation<double> _breathingAnimation;

  @override
  void initState() {
    super.initState();
    _breathingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _breathingAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _breathingController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _breathingController.dispose();
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

    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    // Standard Material 3 sizes
    final double iconSize = 32.0 * scaleFactor;
    final double playButtonSize = 70.0 * scaleFactor;
    final double playIconSize = 42.0 * scaleFactor;

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

            // Handle breathing animation lifecycle
            if (playing && processingState == ProcessingState.ready) {
              if (!_breathingController.isAnimating) {
                _breathingController.repeat(reverse: true);
              }
            } else {
              if (_breathingController.isAnimating) {
                _breathingController.stop();
                _breathingController.animateTo(
                  0,
                  duration: const Duration(milliseconds: 300),
                );
              }
            }

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                AnimatedScale(
                  scale: _isPrevPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPrevPressed = true),
                    onTapUp: (_) => setState(() => _isPrevPressed = false),
                    onTapCancel: () => setState(() => _isPrevPressed = false),
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: iconSize,
                      onPressed: isFirstTrack
                          ? null
                          : () {
                              AppHaptics.selectionClick(
                                context.read<DeviceService>(),
                              );
                              audioProvider.seekToPrevious();
                            },
                      tooltip: 'Skip Previous',
                    ),
                  ),
                ),
                ScaleTransition(
                  scale: _breathingAnimation,
                  child: AnimatedScale(
                    scale: _isPlayPressed ? 0.92 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                    child: GestureDetector(
                      onTapDown: (_) => setState(() => _isPlayPressed = true),
                      onTapUp: (_) => setState(() => _isPlayPressed = false),
                      onTapCancel: () => setState(() => _isPlayPressed = false),
                      onLongPress: () {
                        AppHaptics.heavyImpact(context.read<DeviceService>());
                        audioProvider.stopAndClear();
                      },
                      child: Container(
                        width: playButtonSize,
                        height: playButtonSize,
                        decoration: BoxDecoration(
                          color: colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child:
                            (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering)
                            ? Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3,
                                  color: colorScheme.onPrimary,
                                ),
                              )
                            : IconButton(
                                key: const ValueKey('play_pause_button'),
                                iconSize: playIconSize,
                                onPressed: () {
                                  AppHaptics.selectionClick(
                                    context.read<DeviceService>(),
                                  );
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
                                padding: EdgeInsets.zero,
                                tooltip: playing ? 'Pause' : 'Play',
                              ),
                      ),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: _isNextPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isNextPressed = true),
                    onTapUp: (_) => setState(() => _isNextPressed = false),
                    onTapCancel: () => setState(() => _isNextPressed = false),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: iconSize,
                      onPressed: isLastTrack
                          ? null
                          : () {
                              AppHaptics.selectionClick(
                                context.read<DeviceService>(),
                              );
                              audioProvider.seekToNext();
                            },
                      tooltip: 'Skip Next',
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
