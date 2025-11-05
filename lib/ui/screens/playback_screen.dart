import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'dart:ui';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  late final Animation<double> _scaleAnimation;

  static const double _trackItemHeight = 64.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
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
    _scrollController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final currentShow = audioProvider.currentShow;
    final currentSource = audioProvider.currentSource;

    if (currentShow == null || currentSource == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No show selected.'),
        ),
      );
    }

    final colorScheme = Theme.of(context).colorScheme;

    return Hero(
      tag: 'player',
      child: Material(
        type: MaterialType.transparency,
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            title: Text(
              currentShow.venue,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            flexibleSpace: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.secondaryContainer,
                  ],
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.settings_rounded),
                tooltip: 'Settings',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
            ],
          ),
          body: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: _buildPlaybackInfo(
                    context, audioProvider, currentShow, currentSource),
              ),
              SliverPadding(
                padding: const EdgeInsets.only(bottom: 24.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (context, index) {
                      return _buildTrackItem(
                        context,
                        audioProvider,
                        currentSource.tracks[index],
                        index,
                      );
                    },
                    childCount: currentSource.tracks.length,
                  ),
                ),
              ),
            ],
          ),
          bottomNavigationBar:
          _buildBottomControlsPanel(context, audioProvider, currentSource),
        ),
      ),
    );
  }

  Widget _buildPlaybackInfo(BuildContext context, AudioProvider audioProvider,
      Show currentShow, Source currentSource) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final bool shouldShowShnidBadge = currentShow.sources.length > 1 ||
        (currentShow.sources.length == 1 && settingsProvider.showSingleShnid);

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 16,
                      color: colorScheme.onSecondaryContainer,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentShow.formattedDate,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (shouldShowShnidBadge)
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        currentSource.id,
                        style:
                        Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          StreamBuilder<int?>(
            stream: audioProvider.currentIndexStream,
            initialData: audioProvider.audioPlayer.currentIndex,
            builder: (context, snapshot) {
              final index = snapshot.data ?? 0;
              if (index >= currentSource.tracks.length) {
                return const SizedBox.shrink();
              }
              final track = currentSource.tracks[index];
              return Text(
                track.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlsPanel(BuildContext context,
      AudioProvider audioProvider, Source currentSource) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          16, 12, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, -4),
            )
          ]),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildProgressBar(context, audioProvider),
          _buildControls(context, audioProvider, currentSource),
        ],
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, AudioProvider audioProvider, Source currentSource) {
    final colorScheme = Theme.of(context).colorScheme;

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
                  iconSize: 32,
                  color: colorScheme.onSurface,
                  onPressed:
                  isFirstTrack ? null : audioProvider.seekToPrevious,
                ),
                ScaleTransition(
                  scale: _scaleAnimation,
                  child: GestureDetector(
                    onLongPress: () {
                      HapticFeedback.heavyImpact();
                      audioProvider.stopAndClear();
                      if (context.mounted) {
                        Navigator.of(context).pop();
                      }
                    },
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            colorScheme.primary,
                            colorScheme.tertiary,
                          ],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: processingState == ProcessingState.loading ||
                          processingState == ProcessingState.buffering
                          ? Padding(
                        padding: const EdgeInsets.all(14.0),
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colorScheme.onPrimary,
                          ),
                        ),
                      )
                          : IconButton(
                        icon: Icon(
                          playing
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                        ),
                        iconSize: 36,
                        color: colorScheme.onPrimary,
                        onPressed: playing
                            ? audioProvider.pause
                            : audioProvider.play,
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.skip_next_rounded),
                  iconSize: 32,
                  color: colorScheme.onSurface,
                  onPressed: isLastTrack ? null : audioProvider.seekToNext,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider audioProvider) {
    final colorScheme = Theme.of(context).colorScheme;

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
                Text(
                  formatDuration(position),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
                const SizedBox(width: 12),
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

                          return SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 8),
                              overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 18),
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: colorScheme.primary,
                              overlayColor:
                              colorScheme.primary.withOpacity(0.2),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: (totalDuration.inSeconds > 0
                                        ? bufferedPosition.inSeconds /
                                        totalDuration.inSeconds
                                        : 0.0)
                                        .clamp(0.0, 1.0),
                                    child: Container(
                                      height: 6,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            colorScheme.tertiary
                                                .withOpacity(0.3),
                                            colorScheme.tertiary
                                                .withOpacity(0.5),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(3),
                                      ),
                                    ),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: (totalDuration.inSeconds > 0
                                        ? position.inSeconds /
                                        totalDuration.inSeconds
                                        : 0.0)
                                        .clamp(0.0, 1.0),
                                    child: Stack(
                                      children: [
                                        Container(
                                          height: 6,
                                          decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                              colors: [
                                                colorScheme.primary,
                                                colorScheme.secondary,
                                              ],
                                            ),
                                            borderRadius:
                                            BorderRadius.circular(3),
                                          ),
                                        ),
                                        if (isBuffering)
                                          TweenAnimationBuilder<double>(
                                            tween: Tween(begin: 0.0, end: 1.0),
                                            duration: const Duration(
                                                milliseconds: 1500),
                                            builder: (context, value, child) {
                                              return Container(
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(3),
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
                                                          .withOpacity(0.4),
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
                                Slider(
                                  min: 0.0,
                                  max: totalDuration.inSeconds > 0
                                      ? totalDuration.inSeconds.toDouble()
                                      : 1.0,
                                  value: position.inSeconds
                                      .toDouble()
                                      .clamp(0.0,
                                      totalDuration.inSeconds.toDouble()),
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
                const SizedBox(width: 12),
                Text(
                  formatDuration(totalDuration),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [const FontFeature.tabularFigures()],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTrackItem(
      BuildContext context,
      AudioProvider audioProvider,
      Track track,
      int index,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        final isPlaying = currentIndex == index;

        return SizedBox(
          height: _trackItemHeight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
            decoration: BoxDecoration(
              color: isPlaying
                  ? colorScheme.primaryContainer.withOpacity(0.5)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              title: Text(
                settingsProvider.showTrackNumbers
                    ? '${track.trackNumber}. ${track.title}'
                    : track.title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight:
                  isPlaying ? FontWeight.w600 : FontWeight.normal,
                  color: isPlaying
                      ? colorScheme.primary
                      : colorScheme.onSurface,
                ),
              ),
              trailing: Text(
                formatDuration(Duration(seconds: track.duration)),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onTap: () {
                if (currentIndex != index) {
                  audioProvider.seekToTrack(index);
                }
              },
            ),
          ),
        );
      },
    );
  }
}
