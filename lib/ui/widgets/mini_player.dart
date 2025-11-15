import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

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

    final double scaleFactor = settingsProvider.scalePlayer ? 1.25 : 1.0;
    final double iconSize = 28 * scaleFactor;
    final double buttonSize = 48 * scaleFactor;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
      child: Material(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(28),
        clipBehavior: Clip.antiAlias,
        elevation: 4.0,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
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
                            final isBuffering =
                                processingState == ProcessingState.buffering ||
                                    processingState == ProcessingState.loading;
                            return SizedBox(
                              height: 4,
                              child: Stack(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      color:
                                      colorScheme.surfaceContainerHighest,
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
                                                .withOpacity(0.3),
                                            colorScheme.tertiary
                                                .withOpacity(0.5),
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
                                                .withOpacity(0.8),
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
                                                    .withOpacity(0.4),
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
                      child: StreamBuilder<int?>(
                        stream: audioProvider.currentIndexStream,
                        initialData: audioProvider.audioPlayer.currentIndex,
                        builder: (context, snapshot) {
                          final index = snapshot.data ?? 0;
                          if (index >= currentSource.tracks.length) {
                            return const SizedBox.shrink();
                          }
                          final track = currentSource.tracks[index];

                          final baseTitleStyle = textTheme.titleLarge ??
                              const TextStyle(fontSize: 22.0);
                          final titleStyle = baseTitleStyle
                              .apply(fontSizeFactor: scaleFactor)
                              .copyWith(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1,
                            color: colorScheme.onSurface,
                          );

                          final baseVenueStyle = textTheme.bodyLarge ??
                              const TextStyle(fontSize: 16.0);
                          final venueStyle = baseVenueStyle
                              .apply(fontSizeFactor: scaleFactor)
                              .copyWith(
                            color: colorScheme.onSurfaceVariant,
                            letterSpacing: 0.15,
                          );

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              SizedBox(
                                height: titleStyle.fontSize! * 1.3,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: ConditionalMarquee(
                                    text: track.title,
                                    style: titleStyle,
                                  ),
                                ),
                              ),
                              SizedBox(height: 6 * scaleFactor),
                              SizedBox(
                                height: venueStyle.fontSize! * 1.3,
                                child: Material(
                                  type: MaterialType.transparency,
                                  child: ConditionalMarquee(
                                    text: currentShow.venue,
                                    style: venueStyle,
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    StreamBuilder<int?>(
                      stream: audioProvider.currentIndexStream,
                      initialData: audioProvider.audioPlayer.currentIndex,
                      builder: (context, snapshot) {
                        final index = snapshot.data ?? 0;
                        final isFirstTrack = index == 0;
                        final isLastTrack =
                            index >= currentSource.tracks.length - 1;
                        return Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.skip_previous_rounded),
                              iconSize: iconSize,
                              color: colorScheme.onSurfaceVariant,
                              onPressed: isFirstTrack
                                  ? null
                                  : audioProvider.seekToPrevious,
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
                                        padding:
                                        const EdgeInsets.all(12.0),
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
                                        onPressed: playing
                                            ? audioProvider.pause
                                            : audioProvider.play,
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
                              onPressed: isLastTrack
                                  ? null
                                  : audioProvider.seekToNext,
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
    );
  }
}
