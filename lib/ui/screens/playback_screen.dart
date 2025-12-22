import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/ui/widgets/animated_gradient_border.dart';
import 'package:gdar/ui/widgets/src_badge.dart';
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
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:gdar/ui/widgets/playback/playback_progress_bar.dart';
import 'package:gdar/ui/widgets/playback/playback_controls.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  late final ScrollController _scrollController;
  late final AnimationController _pulseController;
  final PanelController _panelController = PanelController();
  final ValueNotifier<double> _panelPositionNotifier = ValueNotifier(0.0);
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

    // Listen for errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      _errorSubscription = audioProvider.playbackErrorStream.listen((error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Playback Error: $error',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onErrorContainer),
              ),
              backgroundColor: Theme.of(context).colorScheme.errorContainer,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.all(12),
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
    _panelPositionNotifier.dispose();
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

    final panelColor = isTrueBlackMode
        ? Colors.black
        : Theme.of(context).colorScheme.surfaceContainer;

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // minHeight covering the drag handle + Venue/Copy row.
    // Matching correct MiniPlayer height (approx 92 with padding)
    // User wants height to match MiniPlayer.
    final double minPanelHeight = 92.0 * scaleFactor;

    // maxHeight constraint to ~40% of screen
    final double maxPanelHeight = MediaQuery.of(context).size.height * 0.40;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SlidingUpPanel(
        controller: _panelController,
        color: panelColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24.0),
          topRight: Radius.circular(24.0),
        ),
        boxShadow: isTrueBlackMode
            ? []
            : [
                BoxShadow(
                  blurRadius: 20.0,
                  color: Colors.black.withOpacity(0.2),
                )
              ],
        minHeight: minPanelHeight,
        maxHeight: maxPanelHeight,
        margin: EdgeInsets.zero,
        onPanelSlide: (position) {
          _panelPositionNotifier.value = position;
        },
        panel: _buildBottomControlsPanel(
          context,
          audioProvider,
          currentShow,
          currentSource,
          trackItemHeight,
          minPanelHeight,
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: _panelPositionNotifier,
          builder: (context, panelPosition, _) {
            // dynamic padding calculation
            // min: minPanelHeight + 60 (when collapsed)
            // max: maxPanelHeight + 60 (when expanded)
            final double dynamicBottomPadding = minPanelHeight +
                60.0 +
                ((maxPanelHeight - minPanelHeight) * panelPosition);

            return CustomScrollView(
              controller: _scrollController,
              slivers: [
                SliverAppBar(
                  backgroundColor: backgroundColor,
                  pinned: true,
                  title: SizedBox(
                    height: (Theme.of(context).textTheme.titleLarge?.fontSize ??
                            22.0) *
                        (settingsProvider.uiScale ? 1.25 : 1.0) *
                        1.6,
                    child: ConditionalMarquee(
                      text: currentShow.formattedDate,
                      style: Theme.of(context).textTheme.titleLarge?.apply(
                          fontSizeFactor:
                              settingsProvider.uiScale ? 1.25 : 1.0),
                    ),
                  ),
                  actions: [
                    Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Consumer<SettingsProvider>(
                            builder: (context, settings, _) {
                              // Always use Source ID for ratings.
                              final String ratingKey = currentSource.id;

                              final isPlayed = settings.isPlayed(ratingKey);

                              return RatingControl(
                                key: ValueKey(
                                    '${ratingKey}_${settings.getRating(ratingKey)}_$isPlayed'),
                                rating: settings.getRating(ratingKey),
                                size: 16 * (settings.uiScale ? 1.25 : 1.0),
                                isPlayed: isPlayed,
                                onTap: () async {
                                  final currentRating =
                                      settings.getRating(ratingKey);
                                  await showDialog(
                                    context: context,
                                    builder: (context) => RatingDialog(
                                      initialRating: currentRating,
                                      sourceId: currentSource.id,
                                      sourceUrl: currentSource.tracks.isNotEmpty
                                          ? currentSource.tracks.first.url
                                          : null,
                                      isPlayed: settings.isPlayed(ratingKey),
                                      onRatingChanged: (newRating) {
                                        settings.setRating(
                                            ratingKey, newRating);
                                      },
                                      onPlayedChanged: (bool newIsPlayed) {
                                        if (newIsPlayed !=
                                            settings.isPlayed(ratingKey)) {
                                          settings.togglePlayed(ratingKey);
                                        }
                                      },
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                          const SizedBox(height: 2),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (currentSource.src != null) ...[
                                SrcBadge(src: currentSource.src!),
                                const SizedBox(width: 4),
                              ],
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .secondaryContainer
                                      .withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  currentSource.id,
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelSmall
                                      ?.copyWith(
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                        fontSize: 10 *
                                            (settingsProvider.uiScale
                                                ? 1.25
                                                : 1.0),
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings_rounded),
                      iconSize: 24 * (settingsProvider.uiScale ? 1.25 : 1.0),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const SettingsScreen()),
                        );
                      },
                    ),
                  ],
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 16)),
                ...(() {
                  final Map<String, List<Track>> tracksBySet = {};
                  for (var track in currentSource.tracks) {
                    if (!tracksBySet.containsKey(track.setName)) {
                      tracksBySet[track.setName] = [];
                    }
                    tracksBySet[track.setName]!.add(track);
                  }

                  final List<Widget> slivers = [];
                  tracksBySet.forEach((setName, tracks) {
                    slivers.add(
                      SliverPersistentHeader(
                        pinned: true,
                        delegate: _SetHeaderDelegate(
                          setName,
                          Theme.of(context),
                          settingsProvider.uiScale,
                          backgroundColor,
                        ),
                      ),
                    );
                    slivers.add(
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final track = tracks[index];
                              final originalIndex =
                                  currentSource.tracks.indexOf(track);
                              return _buildTrackItem(
                                context,
                                audioProvider,
                                track,
                                originalIndex,
                                trackItemHeight,
                                isTrueBlackMode,
                              );
                            },
                            childCount: tracks.length,
                          ),
                        ),
                      ),
                    );
                  });
                  return slivers;
                })(),
                SliverPadding(
                    padding: EdgeInsets.only(bottom: dynamicBottomPadding)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomControlsPanel(
      BuildContext context,
      AudioProvider audioProvider,
      Show currentShow,
      Source currentSource,
      double trackItemHeight,
      double minHeight) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // Check for True Black mode for mini-player styling
    // final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // final isTrueBlackMode = isDarkMode &&
    //    (!settingsProvider.useDynamicColor || settingsProvider.halfGlowDynamic);

    return Column(
      children: [
        // Collapsed / Header Area
        SizedBox(
          height: minHeight,
          child: Column(
            mainAxisAlignment:
                MainAxisAlignment.spaceBetween, // Push content to edges
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 32,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              // Venue + Copy
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  _scrollToCurrentTrack(trackItemHeight);
                  if (_panelController.isAttached) {
                    if (_panelController.isPanelClosed) {
                      _panelController.open();
                    }
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.only(
                      left: 16.0,
                      right: 16.0,
                      bottom: 30.0), // Reduced to 30.0 to prevent overflow
                  child: Row(
                    children: [
                      Flexible(
                        child: SizedBox(
                          height: textTheme.headlineSmall!.fontSize! *
                              scaleFactor *
                              1.6, // Increased height for better fit with Rock Salt
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
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        // Expanded Content
        Expanded(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
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
                    const SizedBox(width: 8),
                    IconButton(
                      icon: Icon(Icons.copy_rounded,
                          size: 20 * scaleFactor,
                          color: colorScheme.onSurfaceVariant),
                      onPressed: () {
                        final track = currentSource.tracks[
                            audioProvider.audioPlayer.currentIndex ?? 0];
                        final info =
                            "${currentShow.venue} - ${currentShow.formattedDate} - ${currentSource.id}\n${track.title}\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}";
                        Clipboard.setData(ClipboardData(text: info));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Show details copied to clipboard',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onInverseSurface)),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor:
                                Theme.of(context).colorScheme.inverseSurface,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.all(12),
                            showCloseIcon: true,
                            closeIconColor:
                                Theme.of(context).colorScheme.onInverseSurface,
                          ),
                        );
                      },
                    ),
                    const Spacer(),
                    IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Align(
                            alignment: Alignment.centerRight,
                            child: _buildRatingButton(context, currentShow,
                                currentSource, settingsProvider),
                          ),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () {
                              if (currentSource.tracks.isNotEmpty) {
                                launchArchivePage(
                                    currentSource.tracks.first.url);
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (currentSource.src != null) ...[
                                  SrcBadge(
                                      src: currentSource.src!, isPlaying: true),
                                  const SizedBox(width: 6),
                                ],
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: colorScheme.tertiaryContainer
                                        .withOpacity(0.7),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    currentSource.id,
                                    style: textTheme.bodyMedium?.copyWith(
                                      color: colorScheme.onTertiaryContainer,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const PlaybackProgressBar(),
                const SizedBox(height: 8),
                const PlaybackControls(),
                if (settingsProvider.showPlaybackMessages) ...[
                  const SizedBox(height: 16),
                  _buildStatusMessages(context, audioProvider),
                ],
              ],
            ),
          ),
        ),
      ],
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
        height: titleStyle.fontSize! * 1.6,
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
    // Always use Source ID for rating.
    final String ratingKey = source.id;
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
            sourceId: source.id,
            sourceUrl:
                source.tracks.isNotEmpty ? source.tracks.first.url : null,
            isPlayed: settings.isPlayed(ratingKey),
            onRatingChanged: (newRating) {
              settings.setRating(ratingKey, newRating);
            },
            onPlayedChanged: (bool isPlayed) {
              if (isPlayed != settings.isPlayed(ratingKey)) {
                settings.togglePlayed(ratingKey);
              }
            },
          ),
        );
      },
    );
  }
}

class _SetHeaderDelegate extends SliverPersistentHeaderDelegate {
  final String setName;
  final ThemeData theme;
  final bool uiScale;
  final Color backgroundColor;

  _SetHeaderDelegate(
      this.setName, this.theme, this.uiScale, this.backgroundColor);

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Determine background color based on theme
    // We want it to be opaque to hide the scrolling content
    // final backgroundColor = theme.scaffoldBackgroundColor; // Removed

    double scaleFactor = uiScale ? 1.25 : 1.0;

    return Container(
      color: backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      alignment: Alignment.centerLeft,
      child: Text(
        setName,
        style: theme.textTheme.titleSmall?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize:
              (theme.textTheme.titleSmall?.fontSize ?? 14.0) * scaleFactor,
        ),
      ),
    );
  }

  @override
  double get maxExtent {
    double scaleFactor = uiScale ? 1.25 : 1.0;
    // Estimate height: 16 (padding) + ~20 (text) + 4 (padding) -> ~40
    // Previous _buildSetHeader had padding: fromLTRB(16, 16, 16, 4)
    // So top 16 + bottom 4 = 20 vertical padding + text height.
    return 24.0 + (20.0 * scaleFactor);
  }

  @override
  double get minExtent => maxExtent;

  @override
  bool shouldRebuild(_SetHeaderDelegate oldDelegate) {
    return oldDelegate.setName != setName ||
        oldDelegate.theme != theme ||
        oldDelegate.uiScale != uiScale;
  }
}
