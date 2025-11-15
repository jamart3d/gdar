import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:gdar/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

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

  static const double _trackItemHeight = 52.0;

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

  void _scrollToCurrentTrack(double trackItemHeight) {
    final audioProvider = context.read<AudioProvider>();
    final index = audioProvider.audioPlayer.currentIndex;

    if (index != null && _scrollController.hasClients) {
      final viewportHeight = _scrollController.position.viewportDimension;
      final maxScroll = _scrollController.position.maxScrollExtent;
      final itemTopPosition = trackItemHeight * index;

      final targetOffset =
      (itemTopPosition - (viewportHeight / 2) + (trackItemHeight / 2))
          .clamp(0.0, maxScroll);

      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
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
    final double trackItemHeight =
        _trackItemHeight * (settingsProvider.scaleTrackList ? 1.4 : 1.0);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        backgroundColor: colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: Theme.of(context).textTheme.titleMedium!.fontSize! * 1.2,
              child: ConditionalMarquee(
                text: currentShow.venue,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface),
                blankSpace: 60.0,
                pauseAfterRound: const Duration(seconds: 3),
              ),
            ),
            const SizedBox(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  currentShow.formattedDate,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer.withOpacity(0.7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    currentSource.id,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onTertiaryContainer,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
              ],
            ),
          ],
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
          SliverPadding(
            padding: const EdgeInsets.only(top: 16.0, left: 8.0, right: 8.0),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) {
                  return _buildTrackItem(
                    context,
                    audioProvider,
                    currentSource.tracks[index],
                    index,
                    trackItemHeight,
                  );
                },
                childCount: currentSource.tracks.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Hero(
        tag: 'player',
        child: Material(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          clipBehavior: Clip.antiAlias,
          elevation: 4.0,
          shadowColor: Theme.of(context).colorScheme.shadow.withOpacity(0.1),
          child: _buildBottomControlsPanel(
              context, audioProvider, currentShow, currentSource, trackItemHeight),
        ),
      ),
    );
  }

  Widget _buildBottomControlsPanel(BuildContext context,
      AudioProvider audioProvider, Show currentShow, Source currentSource, double trackItemHeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final bool shouldShowShnidBadge = currentShow.sources.length > 1 ||
        (currentShow.sources.length == 1 && settingsProvider.showSingleShnid);

    final double scaleFactor = settingsProvider.scalePlayer ? 1.25 : 1.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 16 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  StreamBuilder<int?>(
                    stream: audioProvider.currentIndexStream,
                    initialData: audioProvider.audioPlayer.currentIndex,
                    builder: (context, snapshot) {
                      final index = snapshot.data ?? 0;
                      if (index >= currentSource.tracks.length) {
                        return const SizedBox.shrink();
                      }
                      final track = currentSource.tracks[index];
                      return AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder:
                            (Widget child, Animation<double> animation) {
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        child: GestureDetector(
                          key: ValueKey<String>(track.title),
                          onTap: () => _scrollToCurrentTrack(trackItemHeight),
                          child: SizedBox(
                            height: textTheme.titleLarge!
                                .apply(fontSizeFactor: scaleFactor)
                                .fontSize! *
                                1.3,
                            child: Material(
                              type: MaterialType.transparency,
                              child: ConditionalMarquee(
                                text: track.title,
                                style: textTheme.titleLarge
                                    ?.apply(fontSizeFactor: scaleFactor)
                                    .copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                                pauseAfterRound: const Duration(seconds: 3),
                                blankSpace: 60.0,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            _buildProgressBar(context, audioProvider),
            const SizedBox(height: 8),
            _buildControls(context, audioProvider, currentSource),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(
      BuildContext context, AudioProvider audioProvider, Source currentSource) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.scalePlayer ? 1.25 : 1.0;
    final double iconSize = 32 * scaleFactor;
    final double playButtonSize = 60 * scaleFactor;
    final double playIconSize = 36 * scaleFactor;

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
                  iconSize: iconSize,
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
                      width: playButtonSize,
                      height: playButtonSize,
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
                        iconSize: playIconSize,
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
                  iconSize: iconSize,
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
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.scalePlayer ? 1.25 : 1.0;

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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.apply(fontSizeFactor: scaleFactor)
                      .copyWith(
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
                              trackHeight: 6 * scaleFactor,
                              thumbShape: RoundSliderThumbShape(
                                  enabledThumbRadius: 8 * scaleFactor),
                              overlayShape: RoundSliderOverlayShape(
                                  overlayRadius: 18 * scaleFactor),
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
                                  height: 6 * scaleFactor,
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
                                      height: 6 * scaleFactor,
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
                                          height: 6 * scaleFactor,
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
                                                height: 6 * scaleFactor,
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                  BorderRadius.circular(3),
                                                  gradient: LinearGradient(
                                                    begin:
                                                    Alignment.centerLeft,
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
                                      .clamp(
                                      0.0,
                                      totalDuration.inSeconds
                                          .toDouble()),
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.apply(fontSizeFactor: scaleFactor)
                      .copyWith(
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
      double trackItemHeight,
      ) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.scaleTrackList ? 1.4 : 1.0;

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        final isPlaying = currentIndex == index;

        final baseTitleStyle =
            textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
        final titleStyle = baseTitleStyle
            .apply(fontSizeFactor: scaleFactor)
            .copyWith(
          fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
          color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
        );

        return SizedBox(
          height: trackItemHeight,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
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
              const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              title: SizedBox(
                height: titleStyle.fontSize! * 1.2,
                child: ConditionalMarquee(
                  text: settingsProvider.showTrackNumbers
                      ? '${track.trackNumber}. ${track.title}'
                      : track.title,
                  style: titleStyle,
                ),
              ),
              trailing: Text(
                formatDuration(Duration(seconds: track.duration)),
                style: textTheme.bodyMedium
                    ?.apply(fontSizeFactor: scaleFactor)
                    .copyWith(
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
