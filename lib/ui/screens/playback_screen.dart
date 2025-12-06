import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:gdar/utils/utils.dart';
import 'package:gdar/utils/color_generator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:gdar/ui/widgets/rating_control.dart';

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
  StreamSubscription? _errorSubscription;

  static const double _trackItemHeight = 52.0;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Listen for errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      _errorSubscription = audioProvider.playbackErrorStream.listen((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Playback Error: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _pulseController.dispose();
    _errorSubscription?.cancel();
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
        _trackItemHeight * (settingsProvider.uiScale ? 1.4 : 1.0);

    Color backgroundColor = colorScheme.surface;

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    if (!isTrueBlackMode && settingsProvider.highlightCurrentShowCard) {
      String seed = currentShow.name;
      if (currentShow.sources.length > 1) {
        seed = currentSource.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
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
                  // Group tracks by set name
                  final Map<String, List<Track>> tracksBySet = {};
                  for (var track in currentSource.tracks) {
                    if (!tracksBySet.containsKey(track.setName)) {
                      tracksBySet[track.setName] = [];
                    }
                    tracksBySet[track.setName]!.add(track);
                  }

                  // Flatten the list with headers
                  final List<dynamic> listItems = [];
                  tracksBySet.forEach((setName, tracks) {
                    listItems.add(setName); // Add header
                    listItems.addAll(tracks); // Add tracks
                  });

                  if (index >= listItems.length) return null;

                  final item = listItems[index];
                  if (item is String) {
                    return _buildSetHeader(context, item);
                  } else if (item is Track) {
                    // Find the original index of this track in the source.tracks list
                    final originalIndex = currentSource.tracks.indexOf(item);
                    return _buildTrackItem(
                      context,
                      audioProvider,
                      item,
                      originalIndex,
                      trackItemHeight,
                      isTrueBlackMode,
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount: _calculateListItemCount(currentSource),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Stack(
        children: [
          Positioned.fill(
            child: Hero(
              tag: 'player',
              child: Material(
                color: isTrueBlackMode
                    ? Colors.black
                    : Theme.of(context).colorScheme.surfaceContainer,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                clipBehavior: Clip.antiAlias,
                elevation: 4.0,
                shadowColor:
                    Theme.of(context).colorScheme.shadow.withOpacity(0.1),
                child: Container(),
              ),
            ),
          ),
          Material(
            type: MaterialType.transparency,
            child: _buildBottomControlsPanel(context, audioProvider,
                currentShow, currentSource, trackItemHeight),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControlsPanel(
      BuildContext context,
      AudioProvider audioProvider,
      Show currentShow,
      Source currentSource,
      double trackItemHeight) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            16, 12, 16, 32 + MediaQuery.of(context).viewPadding.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _scrollToCurrentTrack(trackItemHeight),
                    child: SizedBox(
                      width: double.infinity,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: textTheme.headlineSmall!.fontSize! *
                                      scaleFactor *
                                      1.2,
                                  child: ConditionalMarquee(
                                    text: currentShow.venue,
                                    style: textTheme.headlineSmall
                                        ?.apply(fontSizeFactor: scaleFactor)
                                        .copyWith(
                                          color: colorScheme.onSurface,
                                        ),
                                    blankSpace: 60.0,
                                    pauseAfterRound: const Duration(seconds: 3),
                                  ),
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.copy_rounded,
                                    size: 20 * scaleFactor,
                                    color: colorScheme.onSurfaceVariant),
                                tooltip: 'Copy Show Details',
                                onPressed: () {
                                  final track = currentSource.tracks[
                                      audioProvider.audioPlayer.currentIndex ??
                                          0];
                                  final info =
                                      "${currentShow.venue} - ${currentShow.formattedDate} - ${currentSource.id}\n${track.title}\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}";
                                  Clipboard.setData(ClipboardData(text: info));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                          'Show details copied to clipboard',
                                          style: TextStyle(
                                              color: colorScheme
                                                  .onSecondaryContainer)),
                                      behavior: SnackBarBehavior.floating,
                                      backgroundColor:
                                          colorScheme.secondaryContainer,
                                      showCloseIcon: true,
                                      closeIconColor:
                                          colorScheme.onSecondaryContainer,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              Text(
                                currentShow.formattedDate,
                                style: textTheme.titleMedium
                                    ?.apply(fontSizeFactor: scaleFactor)
                                    .copyWith(
                                      color: colorScheme.onSurfaceVariant,
                                    ),
                              ),
                              const Spacer(),
                              IntrinsicWidth(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _buildRatingButton(context, currentShow,
                                        currentSource, settingsProvider),
                                    const SizedBox(height: 8),
                                    InkWell(
                                      onTap: () {
                                        if (currentSource.tracks.isNotEmpty) {
                                          launchArchivePage(
                                              currentSource.tracks.first.url);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        decoration: BoxDecoration(
                                          color: colorScheme.tertiaryContainer
                                              .withOpacity(0.7),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        alignment: Alignment.center,
                                        child: Text(
                                          currentSource.id,
                                          style: textTheme.bodyMedium?.copyWith(
                                            color:
                                                colorScheme.onTertiaryContainer,
                                            fontWeight: FontWeight.bold,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            _buildProgressBar(context, audioProvider),
            const SizedBox(height: 8),
            _buildControls(context, audioProvider, currentSource),
            if (settingsProvider.showPlaybackMessages) ...[
              const SizedBox(height: 16),
              _buildStatusMessages(context, audioProvider),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusMessages(
      BuildContext context, AudioProvider audioProvider) {
    final colorScheme = Theme.of(context).colorScheme;
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

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                return Text(
                  'Buffered: ${formatDuration(buffered)}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildControls(
      BuildContext context, AudioProvider audioProvider, Source currentSource) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
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
                  onPressed: isFirstTrack ? null : audioProvider.seekToPrevious,
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
                    child: Hero(
                      tag: 'play_pause_button',
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
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

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
                                    color: isTrueBlackMode
                                        ? Colors.white24
                                        : colorScheme.surfaceContainerHighest,
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
                                  value: position.inSeconds.toDouble().clamp(
                                      0.0, totalDuration.inSeconds.toDouble()),
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

  int _calculateListItemCount(Source source) {
    final Set<String> sets = source.tracks.map((t) => t.setName).toSet();
    return source.tracks.length + sets.length;
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
    int index,
    double trackItemHeight,
    bool isTrueBlackMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.4 : 1.0;

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        final isPlaying = currentIndex == index;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 1),
          decoration: BoxDecoration(
            color: (isPlaying && settingsProvider.highlightPlayingWithRgb)
                ? Colors.transparent
                : isPlaying
                    ? (isTrueBlackMode
                        ? Colors.black
                        : colorScheme.primaryContainer)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: (isPlaying && settingsProvider.highlightPlayingWithRgb)
              ? Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isTrueBlackMode
                        ? []
                        : [
                            BoxShadow(
                              color: Colors.red.withOpacity(0.4 *
                                  (settingsProvider.halfGlowDynamic
                                      ? 0.5
                                      : 1.0)),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                  ),
                  padding: const EdgeInsets.all(4), // Increased padding
                  child: AnimatedGradientBorder(
                    borderRadius: 12,
                    borderWidth: 4,
                    colors: const [
                      Colors.red,
                      Colors.yellow,
                      Colors.green,
                      Colors.cyan,
                      Colors.blue,
                      Colors.purple,
                      Colors.red,
                    ],
                    showGlow: true,
                    showShadow: !isTrueBlackMode,
                    glowOpacity:
                        0.5 * (settingsProvider.halfGlowDynamic ? 0.5 : 1.0),
                    animationSpeed: settingsProvider.rgbAnimationSpeed,
                    child: Material(
                      color: isTrueBlackMode
                          ? Colors.black
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: _buildTrackListTile(context, audioProvider, track,
                          index, currentIndex, scaleFactor),
                    ),
                  ),
                )
              : _buildTrackListTile(context, audioProvider, track, index,
                  currentIndex, scaleFactor),
        );
      },
    );
  }

  Widget _buildTrackListTile(BuildContext context, AudioProvider audioProvider,
      Track track, int index, int? currentIndex, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isPlaying = currentIndex == index;

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final titleStyle =
        baseTitleStyle.apply(fontSizeFactor: scaleFactor).copyWith(
              fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
              color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
            );

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: SizedBox(
        height: titleStyle.fontSize! * 1.2,
        child: ConditionalMarquee(
          text: settingsProvider.showTrackNumbers
              ? '${track.trackNumber}. ${track.title}'
              : track.title,
          style: titleStyle,
          textAlign: settingsProvider.hideTrackDuration
              ? TextAlign.center
              : TextAlign.start,
        ),
      ),
      trailing: settingsProvider.hideTrackDuration
          ? null
          : Text(
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
    );
  }

  Widget _buildRatingButton(BuildContext context, Show show, Source source,
      SettingsProvider settings) {
    // Determine the key for rating:
    // If multiple sources, rate the specific source ID.
    // If single source, rate the show name (consistent with ShowListCard).
    final String ratingKey = show.sources.length > 1 ? source.id : show.name;
    final rating = settings.getRating(ratingKey);

    return RatingControl(
      rating: rating,
      isPlayed: settings.isPlayed(ratingKey),
      size: 20,
      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) => RatingDialog(
            initialRating: rating,
            sourceId: show.sources.length > 1 ? source.id : null,
            sourceUrl: show.sources.length > 1 && source.tracks.isNotEmpty
                ? source.tracks.first.url
                : null,
            onRatingChanged: (newRating) {
              settings.setRating(ratingKey, newRating);
            },
          ),
        );
      },
    );
  }
}
