import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final Show? currentShow = audioProvider.currentShow;
    final Source? currentSource = audioProvider.currentSource;

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
      child: Scaffold(
        backgroundColor: colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(
              expandedHeight: 200,
              pinned: true,
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
              flexibleSpace: FlexibleSpaceBar(
                title: Text(
                  currentShow.venue,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorScheme.primaryContainer,
                        colorScheme.secondaryContainer,
                        colorScheme.tertiaryContainer,
                      ],
                    ),
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(
                                  color: colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (currentShow.sources.length > 1)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: colorScheme.tertiaryContainer,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.source_rounded,
                                  size: 16,
                                  color: colorScheme.onTertiaryContainer,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  currentSource.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelLarge
                                      ?.copyWith(
                                    color: colorScheme.onTertiaryContainer,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 32),
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
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                          textAlign: TextAlign.center,
                        );
                      },
                    ),
                    const SizedBox(height: 40),
                    _buildProgressBar(context, audioProvider),
                    const SizedBox(height: 32),
                    _buildControls(context, audioProvider, currentSource),
                    const SizedBox(height: 48),
                  ],
                ),
              ),
            ),
            SliverList(
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
            const SliverToBoxAdapter(
              child: SizedBox(height: 24),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context, AudioProvider audioProvider,
      Source currentSource) {
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

            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(28),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_previous_rounded),
                      iconSize: 32,
                      color: colorScheme.onSurface,
                      onPressed:
                      isFirstTrack ? null : audioProvider.seekToPrevious,
                    ),
                  ),
                  Container(
                    width: 72,
                    height: 72,
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
                      padding: const EdgeInsets.all(20.0),
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
                      iconSize: 40,
                      color: colorScheme.onPrimary,
                      onPressed: playing
                          ? audioProvider.pause
                          : audioProvider.play,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.skip_next_rounded),
                      iconSize: 32,
                      color: colorScheme.onSurface,
                      onPressed: isLastTrack ? null : audioProvider.seekToNext,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProgressBar(BuildContext context, AudioProvider audioProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioPlayer = audioProvider.audioPlayer;

    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      initialData: audioPlayer.position,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        return StreamBuilder<Duration?>(
          stream: audioPlayer.durationStream,
          initialData: audioPlayer.duration,
          builder: (context, durationSnapshot) {
            final totalDuration = durationSnapshot.data ?? Duration.zero;

            return StreamBuilder<Duration?>(
              stream: audioPlayer.bufferedPositionStream,
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

                    return Column(
                      children: [
                        SizedBox(
                          height: 60,
                          child: SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              trackHeight: 6,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 10,
                              ),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 24,
                              ),
                              activeTrackColor: Colors.transparent,
                              inactiveTrackColor: Colors.transparent,
                              thumbColor: colorScheme.primary,
                              overlayColor:
                              colorScheme.primary.withOpacity(0.2),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Container(
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color:
                                      colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (totalDuration
                                          .inSeconds >
                                          0
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
                                          borderRadius:
                                          BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 24),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: (totalDuration
                                          .inSeconds >
                                          0
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
                                              boxShadow: [
                                                BoxShadow(
                                                  color: colorScheme.primary
                                                      .withOpacity(0.4),
                                                  blurRadius: 8,
                                                  offset:
                                                  const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (isBuffering)
                                            TweenAnimationBuilder<double>(
                                              tween: Tween(begin: 0.0, end: 1.0),
                                              duration: const Duration(
                                                  milliseconds: 1500),
                                              builder:
                                                  (context, value, child) {
                                                return Container(
                                                  height: 6,
                                                  decoration: BoxDecoration(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        3),
                                                    gradient: LinearGradient(
                                                      begin: Alignment
                                                          .centerLeft,
                                                      end: Alignment
                                                          .centerRight,
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
                                                            .withOpacity(
                                                            0.4),
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
                                ),
                                Slider(
                                  min: 0.0,
                                  max: totalDuration.inSeconds > 0
                                      ? totalDuration.inSeconds.toDouble()
                                      : 1.0,
                                  value: position.inSeconds
                                      .toDouble()
                                      .clamp(
                                      0.0,
                                      totalDuration.inSeconds
                                          .toDouble()),
                                  onChanged: totalDuration.inSeconds > 0
                                      ? (value) {
                                    audioProvider.seek(Duration(
                                        seconds: value.round()));
                                  }
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                        Padding(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _formatDuration(position),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                              Text(
                                _formatDuration(totalDuration),
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: [
                                    const FontFeature.tabularFigures()
                                  ],
                                ),
                              ),
                            ],
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

        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          initialData: audioProvider.audioPlayer.playerState,
          builder: (context, stateSnapshot) {
            final titleText = settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title;

            return Container(
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
                  titleText,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    fontWeight:
                    isPlaying ? FontWeight.w600 : FontWeight.normal,
                    color: isPlaying
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
                trailing: Text(
                  _formatDuration(Duration(seconds: track.duration)),
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
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }
}

