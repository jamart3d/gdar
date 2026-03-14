import 'package:flutter/material.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:gdar_mobile/ui/widgets/conditional_marquee.dart';

import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:gdar_mobile/ui/styles/app_typography.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/color_generator.dart';

class MiniPlayer extends StatefulWidget {
  final VoidCallback onTap;
  final bool hideControls;

  const MiniPlayer({
    super.key,
    required this.onTap,
    this.hideControls = false,
  });

  @override
  State<MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<MiniPlayer> {
  @override
  void dispose() {
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

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    Color backgroundColor = colorScheme.surfaceContainerHigh;

    // Only apply custom background color if NOT in "True Black" mode.
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
              elevation: settingsProvider.performanceMode ? 0.0 : 4.0,
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
                                      SizedBox(
                                        height: 4,
                                        child: LinearProgressIndicator(
                                          backgroundColor: Colors.transparent,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.primary,
                                          ),
                                        ),
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
                  padding: EdgeInsets.only(
                    left: 4.0,
                    top: 20.0 * scaleFactor,
                    bottom: 20.0 * scaleFactor,
                    right: 4.0 * scaleFactor,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: StreamBuilder<SequenceState?>(
                          stream: audioProvider.audioPlayer.sequenceStateStream,
                          builder: (context, snapshot) {
                            final currentTrack = audioProvider.currentTrack;
                            final baseTitleStyle = textTheme.titleMedium
                                    ?.copyWith(fontSize: 19.0) ??
                                const TextStyle(fontSize: 19.0);
                            final titleStyle = baseTitleStyle.copyWith(
                              fontSize: AppTypography.responsiveFontSize(
                                  context, 19.0),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.1,
                              color: colorScheme.onSurface,
                            );

                            // Calculate the fixed height needed for titles (2.2x font size)
                            final double fixedTitleHeight =
                                titleStyle.fontSize! * 2.2;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  height: fixedTitleHeight,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 2.0),
                                    child: Material(
                                      type: MaterialType.transparency,
                                      child: AnimatedSwitcher(
                                        duration:
                                            const Duration(milliseconds: 300),
                                        child: currentTrack == null
                                            ? SizedBox(
                                                key: const ValueKey(
                                                    'loading_placeholder'),
                                                height: fixedTitleHeight)
                                            : ConditionalMarquee(
                                                key: ValueKey(currentTrack.url),
                                                text: currentTrack.title,
                                                style: titleStyle.copyWith(
                                                    height: 1.2),
                                                textAlign: TextAlign.center,
                                              ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                      if (!widget.hideControls) ...[
                        const SizedBox(width: 8),
                        // Skip Previous, Play/Pause, Skip Next
                        StreamBuilder<int?>(
                          stream: audioProvider.currentIndexStream,
                          initialData: audioProvider.audioPlayer.currentIndex,
                          builder: (context, indexSnapshot) {
                            final index = indexSnapshot.data ?? 0;
                            final sequence = audioProvider.audioPlayer.sequence;
                            final isFirstTrack = index == 0;
                            final isLastTrack = index >= sequence.length - 1;

                            return Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 40.0 * scaleFactor,
                                  height: 40.0 * scaleFactor,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon:
                                        const Icon(Icons.skip_previous_rounded),
                                    iconSize: 28.0 * scaleFactor,
                                    color: colorScheme.onSurface,
                                    onPressed: isFirstTrack
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick(
                                                context.read<DeviceService>());
                                            audioProvider.seekToPrevious();
                                          },
                                  ),
                                ),
                                SizedBox(width: 10.0 * scaleFactor),
                                StreamBuilder<PlayerState>(
                                  stream: audioProvider.playerStateStream,
                                  builder: (context, snapshot) {
                                    final playerState = snapshot.data;
                                    final processingState =
                                        playerState?.processingState;
                                    final playing = playerState?.playing;

                                    if (processingState ==
                                            ProcessingState.loading ||
                                        processingState ==
                                            ProcessingState.buffering) {
                                      return Container(
                                        margin:
                                            EdgeInsets.all(8.0 * scaleFactor),
                                        width: 38.0 * scaleFactor,
                                        height: 38.0 * scaleFactor,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                            colorScheme.onSurface,
                                          ),
                                        ),
                                      );
                                    }

                                    Widget playIcon;
                                    VoidCallback? onPressed;

                                    if (playing != true) {
                                      playIcon =
                                          const Icon(Icons.play_arrow_rounded);
                                      onPressed =
                                          audioProvider.audioPlayer.play;
                                    } else if (processingState !=
                                        ProcessingState.completed) {
                                      playIcon =
                                          const Icon(Icons.pause_rounded);
                                      onPressed =
                                          audioProvider.audioPlayer.pause;
                                    } else {
                                      playIcon =
                                          const Icon(Icons.replay_rounded);
                                      onPressed = () => audioProvider
                                          .audioPlayer
                                          .seek(Duration.zero);
                                    }

                                    return IconButton(
                                      icon: playIcon,
                                      iconSize: 38.0 * scaleFactor,
                                      onPressed: onPressed,
                                      color: colorScheme.onSurface,
                                    );
                                  },
                                ),
                                SizedBox(width: 10.0 * scaleFactor),
                                SizedBox(
                                  width: 40.0 * scaleFactor,
                                  height: 40.0 * scaleFactor,
                                  child: IconButton(
                                    padding: EdgeInsets.zero,
                                    icon: const Icon(Icons.skip_next_rounded),
                                    iconSize: 28.0 * scaleFactor,
                                    color: colorScheme.onSurface,
                                    onPressed: isLastTrack
                                        ? null
                                        : () {
                                            AppHaptics.selectionClick(
                                                context.read<DeviceService>());
                                            audioProvider.seekToNext();
                                          },
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ],
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
