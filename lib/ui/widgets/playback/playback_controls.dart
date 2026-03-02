import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';

class PlaybackControls extends StatefulWidget {
  final double panelPosition;

  const PlaybackControls({
    super.key,
    this.panelPosition = 0.0,
  });

  @override
  State<PlaybackControls> createState() => _PlaybackControlsState();
}

class _PlaybackControlsState extends State<PlaybackControls> {
  bool _isPlayPressed = false;
  bool _isPrevPressed = false;
  bool _isNextPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final currentSource = audioProvider.currentSource;
    final isFruitNeumorphic = themeProvider.themeStyle == ThemeStyle.fruit &&
        kIsWeb &&
        settingsProvider.useNeumorphism &&
        !settingsProvider.useTrueBlack;

    if (currentSource == null) {
      return const SizedBox.shrink();
    }

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // Dynamic sizing based on panel position (0.0 = closed, 1.0 = open)
    double reductionFactor = 0.15;
    if (settingsProvider.appFont == 'default' ||
        settingsProvider.appFont == 'caveat') {
      reductionFactor = 0.25;
    }

    final double sizeMultiplier =
        1.0 - (reductionFactor * widget.panelPosition);
    final bool isFruitWeb =
        themeProvider.themeStyle == ThemeStyle.fruit && kIsWeb;
    final double iconSize =
        (isFruitWeb ? 34.0 : 32.0) * scaleFactor * sizeMultiplier;
    final double playButtonSize =
        (isFruitWeb ? 74.0 : 70.0) * scaleFactor * sizeMultiplier;
    final double playIconSize =
        (isFruitWeb ? 44.0 : 42.0) * scaleFactor * sizeMultiplier;

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
                    child: NeumorphicWrapper(
                      enabled: isFruitNeumorphic,
                      borderRadius: 12,
                      intensity: 1.1, // Softer skip buttons
                      offset: const Offset(4, 4),
                      blur: 18,
                      isPressed: _isPrevPressed,
                      child: IconButton(
                        icon: const Icon(LucideIcons.skipBack),
                        iconSize: iconSize,
                        color: colorScheme.onSurface,
                        onPressed: isFirstTrack
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                audioProvider.seekToPrevious();
                              },
                      ),
                    ),
                  ),
                ),
                AnimatedScale(
                  scale: _isPlayPressed ? 0.92 : 1.0,
                  duration: const Duration(milliseconds: 100),
                  curve: Curves.easeOutCubic,
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      audioProvider.stopAndClear();
                    },
                    onTapDown: (_) => setState(() => _isPlayPressed = true),
                    onTapUp: (_) => setState(() => _isPlayPressed = false),
                    onTapCancel: () => setState(() => _isPlayPressed = false),
                    child: NeumorphicWrapper(
                      enabled: isFruitNeumorphic,
                      isCircle: true,
                      isPressed: _isPlayPressed,
                      intensity: 1.5, // Stronger pop for main play
                      blur: 24,
                      child: Container(
                        width: playButtonSize,
                        height: playButtonSize,
                        decoration: BoxDecoration(
                          // Let NeumorphicWrapper handle the color/gradient
                          color: isFruitNeumorphic
                              ? Colors.transparent
                              : colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        child: (processingState == ProcessingState.loading ||
                                processingState == ProcessingState.buffering)
                            ? Padding(
                                padding: const EdgeInsets.all(18.0),
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    isFruitNeumorphic
                                        ? colorScheme.primary
                                        : colorScheme.onPrimary,
                                  ),
                                ),
                              )
                            : IconButton(
                                key: const ValueKey('play_pause_button'),
                                iconSize: playIconSize,
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
                                      ? LucideIcons.pause
                                      : LucideIcons.play,
                                  color: isFruitNeumorphic
                                      ? colorScheme.primary
                                      : colorScheme.onPrimary,
                                ),
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
                    child: NeumorphicWrapper(
                      enabled: isFruitNeumorphic,
                      borderRadius: 12,
                      intensity: 1.1, // Softer skip buttons
                      offset: const Offset(4, 4),
                      blur: 18,
                      isPressed: _isNextPressed,
                      child: IconButton(
                        icon: const Icon(LucideIcons.skipForward),
                        iconSize: iconSize,
                        color: colorScheme.onSurface,
                        onPressed: isLastTrack
                            ? null
                            : () {
                                HapticFeedback.selectionClick();
                                audioProvider.seekToNext();
                              },
                      ),
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
