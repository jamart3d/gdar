import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';

import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/utils/color_generator.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;

  const MiniPlayer({
    super.key,
    required this.onTap,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer>
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
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final Show? currentShow = audioProvider.currentShow;
    final Source? currentSource = audioProvider.currentSource;

    if (currentShow == null || currentSource == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
    final double iconSize = 28 * scaleFactor;
    final double buttonSize = 48 * scaleFactor;

    Color backgroundColor = colorScheme.surfaceContainerHigh;

    // Only apply custom background color if NOT in "True Black" mode.
    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!isTrueBlackMode && settingsProvider.highlightCurrentShowCard) {
      String seed = currentShow.name;
      if (currentShow.sources.length > 1) {
        seed = currentSource.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    Widget miniPlayerContent = Stack(
      children: [
        Positioned.fill(
          child: Hero(
            tag: 'player',
            child: Material(
              color: backgroundColor,
              borderRadius: BorderRadius.zero,
              clipBehavior: Clip.antiAlias,
              elevation: 4.0,
              shadowColor: colorScheme.shadow.withValues(alpha: 0.1),
              child: Container(), // Empty container for background
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              StreamBuilder<Duration>(
                stream: audioProvider.positionStream,
                initialData: audioProvider.audioPlayer.position,
                builder: (context, positionSnapshot) {
                  final position = positionSnapshot.data ?? Duration.zero;
                  return StreamBuilder<Duration?>(
                    stream: audioProvider.durationStream,
                    initialData: audioProvider.audioPlayer.duration,
                    builder: (context, durationSnapshot) {
                      final duration = durationSnapshot.data ?? Duration.zero;
                      final progress = duration.inMilliseconds > 0
                          ? position.inMilliseconds / duration.inMilliseconds
                          : 0.0;
                      return StreamBuilder<Duration>(
                        stream: audioProvider.bufferedPositionStream,
                        initialData: audioProvider.audioPlayer.bufferedPosition,
                        builder: (context, bufferedSnapshot) {
                          final bufferedPosition =
                              bufferedSnapshot.data ?? Duration.zero;
                          final bufferedProgress = duration.inMilliseconds > 0
                              ? bufferedPosition.inMilliseconds /
                                  duration.inMilliseconds
                              : 0.0;
                          return StreamBuilder<PlayerState>(
                            stream: audioProvider.playerStateStream,
                            initialData: audioProvider.audioPlayer.playerState,
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
                                        color: isTrueBlackMode
                                            ? Colors.white24
                                            : colorScheme
                                                .surfaceContainerHighest,
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor:
                                          bufferedProgress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.tertiary
                                                  .withValues(alpha: 0.3),
                                              colorScheme.tertiary
                                                  .withValues(alpha: 0.5),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    FractionallySizedBox(
                                      widthFactor: progress.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            colors: [
                                              colorScheme.primary,
                                              colorScheme.primary
                                                  .withValues(alpha: 0.8),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (isBuffering)
                                      TweenAnimationBuilder<double>(
                                        tween: Tween(begin: 0.0, end: 1.0),
                                        duration:
                                            const Duration(milliseconds: 1500),
                                        builder: (context, value, child) {
                                          return Container(
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                stops: [
                                                  (value - 0.3).clamp(0.0, 1.0),
                                                  value,
                                                  (value + 0.3).clamp(0.0, 1.0),
                                                ],
                                                colors: [
                                                  Colors.transparent,
                                                  colorScheme.tertiary
                                                      .withValues(alpha: 0.4),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          );
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
                onTap: widget.onTap,
                child: Padding(
                  padding: EdgeInsets.all(20.0 * scaleFactor),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<SequenceState?>(
                          stream: audioProvider.audioPlayer.sequenceStateStream,
                          builder: (context, snapshot) {
                            final currentTrack = audioProvider.currentTrack;
                            if (currentTrack == null) {
                              return const SizedBox.shrink();
                            }

                            final baseTitleStyle = textTheme.titleMedium
                                    ?.copyWith(fontSize: 19.0) ??
                                const TextStyle(fontSize: 19.0);
                            final titleStyle = baseTitleStyle
                                .apply(fontSizeFactor: scaleFactor)
                                .copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: colorScheme.onSurface,
                                );

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: titleStyle.fontSize! * 2.2,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0),
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: ConditionalMarquee(
                                        text: currentTrack.title,
                                        style: titleStyle.copyWith(height: 1.2),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      StreamBuilder<SequenceState?>(
                        stream: audioProvider.audioPlayer.sequenceStateStream,
                        builder: (context, snapshot) {
                          final sequenceState = snapshot.data;
                          final sequence = sequenceState?.sequence ?? [];
                          final currentIndex = sequenceState?.currentIndex ?? 0;
                          final hasPrevious = currentIndex > 0;
                          final hasNext = currentIndex < sequence.length - 1;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.skip_previous_rounded),
                                iconSize: iconSize,
                                color: colorScheme.onSurfaceVariant,
                                onPressed: hasPrevious
                                    ? audioProvider.seekToPrevious
                                    : null,
                              ),
                              StreamBuilder<PlayerState>(
                                stream: audioProvider.playerStateStream,
                                initialData:
                                    audioProvider.audioPlayer.playerState,
                                builder: (context, snapshot) {
                                  final playerState = snapshot.data;
                                  final processingState =
                                      playerState?.processingState;
                                  final playing = playerState?.playing ?? false;

                                  if (playing &&
                                      !_pulseController.isAnimating) {
                                    _pulseController.repeat(reverse: true);
                                  } else if (!playing &&
                                      _pulseController.isAnimating) {
                                    _pulseController.stop();
                                    _pulseController.animateTo(0.0,
                                        duration:
                                            const Duration(milliseconds: 200),
                                        curve: Curves.easeOut);
                                  }

                                  return ScaleTransition(
                                    scale: _scaleAnimation,
                                    child: GestureDetector(
                                      onLongPress: () {
                                        HapticFeedback.heavyImpact();
                                        audioProvider.stopAndClear();
                                      },
                                      child: Hero(
                                        tag: 'play_pause_button',
                                        child: Container(
                                          width: buttonSize,
                                          height: buttonSize,
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
                                                  iconSize: iconSize,
                                                  color: colorScheme.onPrimary,
                                                  onPressed: () {
                                                    HapticFeedback
                                                        .selectionClick();
                                                    if (playing) {
                                                      audioProvider.pause();
                                                    } else {
                                                      audioProvider.play();
                                                    }
                                                  },
                                                ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.skip_next_rounded),
                                iconSize: iconSize,
                                color: colorScheme.onSurfaceVariant,
                                onPressed:
                                    hasNext ? audioProvider.seekToNext : null,
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
      ],
    );

    return miniPlayerContent;
  }
}
