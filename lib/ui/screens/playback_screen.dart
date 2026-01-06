import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
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
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlaybackScreen extends StatefulWidget {
  const PlaybackScreen({super.key});

  @override
  State<PlaybackScreen> createState() => _PlaybackScreenState();
}

class _PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final AnimationController _pulseController;
  final PanelController _panelController = PanelController();
  final ValueNotifier<double> _panelPositionNotifier = ValueNotifier(0.0);
  StreamSubscription? _errorSubscription;
  String? _lastTrackTitle;

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _lastTrackTitle = audioProvider.currentTrack?.title;
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
      _scrollToCurrentTrack(animate: false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _panelPositionNotifier.dispose();
    _errorSubscription?.cancel();
    super.dispose();
  }

  void _scrollToCurrentTrack(
      {bool animate = true, bool force = false, double maxVisibleY = 1.0}) {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    if (currentTrack == null) return;

    final currentSource = audioProvider.currentSource;
    if (currentSource == null) return;

    // Build the list structure to find the index
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in currentSource.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    int targetIndex = -1;
    for (int i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      if (item is Track &&
          item.title == currentTrack.title &&
          item.trackNumber == currentTrack.trackNumber) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != -1 && _itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;

      // Smart check to prevent jank
      if (positions.isNotEmpty) {
        if (force) {
          // If forced (manual tap), only skip if we are already close to the target alignment (0.3)
          final isAligned = positions.any((position) =>
              position.index == targetIndex &&
              (position.itemLeadingEdge - 0.3).abs() < 0.05); // 5% tolerance
          if (isAligned) return;
        } else {
          // If auto-scroll, skip if fully visible within the allowed range
          final isVisible = positions.any((position) =>
              position.index == targetIndex &&
              position.itemLeadingEdge >= 0 &&
              position.itemTrailingEdge <= maxVisibleY);
          if (isVisible) return;
        }
      }

      if (animate) {
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.3,
        );
      } else {
        _itemScrollController.jumpTo(
          index: targetIndex,
          alignment: 0.3,
        );
      }
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

    // Auto-scroll when track changes
    if (audioProvider.currentTrack?.title != _lastTrackTitle) {
      _lastTrackTitle = audioProvider.currentTrack?.title;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTrack();
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.surface;

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

    final panelColor = isTrueBlackMode
        ? Colors.black
        : Theme.of(context).colorScheme.surfaceContainer;

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // minHeight covering the drag handle + Venue/Copy row.
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double minPanelHeight = (92.0 * scaleFactor) + bottomPadding;

    // maxHeight constraint to ~40% of screen (0.45 if scaled)
    final double maxPanelHeight = MediaQuery.of(context).size.height *
        (settingsProvider.uiScale ? 0.45 : 0.40);

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
                  color: Colors.black.withValues(alpha: 0.2),
                )
              ],
        minHeight: minPanelHeight,
        maxHeight: maxPanelHeight,
        margin: EdgeInsets.zero,
        onPanelSlide: (position) {
          _panelPositionNotifier.value = position;
        },
        onPanelOpened: () {
          // Panel covers significant portion, ensure track is in top 40%
          _scrollToCurrentTrack(maxVisibleY: 0.4);
        },
        panel: _buildBottomControlsPanel(
          context,
          audioProvider,
          currentShow,
          currentSource,
          minPanelHeight,
          bottomPadding,
          _panelPositionNotifier,
        ),
        body: ValueListenableBuilder<double>(
          valueListenable: _panelPositionNotifier,
          builder: (context, panelPosition, _) {
            final double dynamicBottomPadding = minPanelHeight +
                60.0 +
                ((maxPanelHeight - minPanelHeight) * panelPosition);

            return Column(
              children: [
                _buildAppBar(context, currentShow, currentSource,
                    backgroundColor, panelPosition),
                Expanded(
                  child: _buildTrackList(context, audioProvider, currentSource,
                      dynamicBottomPadding, isTrueBlackMode),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, Show show, Source source,
      Color backgroundColor, double panelPosition) {
    final settingsProvider = context.watch<SettingsProvider>();

    // Date Formatting Logic
    String dateFormatPattern = '';
    if (settingsProvider.showDayOfWeek) {
      dateFormatPattern +=
          settingsProvider.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
    }
    dateFormatPattern += settingsProvider.abbreviateMonth ? 'MMM' : 'MMMM';
    dateFormatPattern += ' d, y';

    final String formattedDate = () {
      try {
        final date = DateTime.parse(show.date);
        return DateFormat(dateFormatPattern).format(date);
      } catch (e) {
        return show.date;
      }
    }();

    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      title: Opacity(
        opacity: (1.0 - (panelPosition * 1.5)).clamp(0.0, 1.0),
        child: SizedBox(
          height: (Theme.of(context).textTheme.titleLarge?.fontSize ?? 22.0) *
              (settingsProvider.uiScale ? 1.25 : 1.0) *
              1.6,
          child: ConditionalMarquee(
            text: formattedDate,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.apply(fontSizeFactor: settingsProvider.uiScale ? 1.25 : 1.0),
          ),
        ),
      ),
      actions: [
        Opacity(
          opacity: (1.0 - (panelPosition * 1.5)).clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    final String ratingKey = source.id;
                    final isPlayed = settings.isPlayed(ratingKey);

                    return RatingControl(
                      key: ValueKey(
                          '${ratingKey}_${settings.getRating(ratingKey)}_$isPlayed'),
                      rating: settings.getRating(ratingKey),
                      size: 16 * (settings.uiScale ? 1.25 : 1.0),
                      isPlayed: isPlayed,
                      onTap: () async {
                        final currentRating = settings.getRating(ratingKey);
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: currentRating,
                            sourceId: source.id,
                            sourceUrl: source.tracks.isNotEmpty
                                ? source.tracks.first.url
                                : null,
                            isPlayed: settings.isPlayed(ratingKey),
                            onRatingChanged: (newRating) {
                              settings.setRating(ratingKey, newRating);
                            },
                            onPlayedChanged: (bool newIsPlayed) {
                              if (newIsPlayed != settings.isPlayed(ratingKey)) {
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
                    if (source.src != null) ...[
                      SrcBadge(src: source.src!),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        source.id,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontSize:
                                  10 * (settingsProvider.uiScale ? 1.25 : 1.0),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          iconSize: 24 * (settingsProvider.uiScale ? 1.25 : 1.0),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildTrackList(BuildContext context, AudioProvider audioProvider,
      Source source, double bottomPadding, bool isTrueBlackMode) {
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    final Map<int, int> listItemToTrackIndex = {};
    int currentTrackIndex = 0;

    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      for (var track in tracks) {
        listItemToTrackIndex[listItems.length] = currentTrackIndex++;
        listItems.add(track);
      }
    });

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: EdgeInsets.fromLTRB(8, 16, 8, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          final trackIndex = listItemToTrackIndex[index] ?? 0;
          return _buildTrackItem(
              context, audioProvider, item, trackIndex, isTrueBlackMode);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
            .apply(fontSizeFactor: settingsProvider.uiScale ? 1.25 : 1.0),
      ),
    );
  }

  Widget _buildTrackItem(
    BuildContext context,
    AudioProvider audioProvider,
    Track track,
    int index,
    bool isTrueBlackMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        final isPlaying = currentIndex == index;

        final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

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
                    boxShadow: const [],
                  ),
                  padding: const EdgeInsets.all(4),
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
                    showShadow: settingsProvider.glowMode > 0,
                    glowOpacity:
                        0.5 * (settingsProvider.glowMode / 100.0),
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
        if (!isPlaying) {
          audioProvider.seekToTrack(index);
        }
      },
    );
  }

  Widget _buildBottomControlsPanel(
      BuildContext context,
      AudioProvider audioProvider,
      Show currentShow,
      Source currentSource,
      double minHeight,
      double bottomPadding,
      ValueNotifier<double> panelPositionNotifier) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    // Date Formatting Logic
    String dateFormatPattern = '';
    if (settingsProvider.showDayOfWeek) {
      dateFormatPattern +=
          settingsProvider.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
    }
    dateFormatPattern += settingsProvider.abbreviateMonth ? 'MMM' : 'MMMM';
    dateFormatPattern += ' d, y';

    final String formattedDate = () {
      try {
        final date = DateTime.parse(currentShow.date);
        return DateFormat(dateFormatPattern).format(date);
      } catch (e) {
        return currentShow.date;
      }
    }();

    return Container(
      decoration: BoxDecoration(
        borderRadius: isTrueBlackMode
            ? const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              )
            : null,
        border: isTrueBlackMode
            ? Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1.0,
              )
            : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: minHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    _scrollToCurrentTrack(force: true);
                    if (_panelController.isAttached) {
                      if (_panelController.isPanelClosed) {
                        _panelController.open();
                      }
                    }
                  },
                  child: Padding(
                    padding: EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 30.0 + bottomPadding),
                    child: Row(
                      mainAxisAlignment: settingsProvider.hideTrackDuration
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: SizedBox(
                            height: textTheme.headlineSmall!.fontSize! *
                                scaleFactor *
                                1.6,
                            child: ConditionalMarquee(
                              text: currentShow.venue,
                              style: textTheme.headlineSmall
                                  ?.apply(fontSizeFactor: scaleFactor)
                                  .copyWith(
                                    color: colorScheme.onSurface,
                                  ),
                              blankSpace: 60.0,
                              pauseAfterRound: const Duration(seconds: 3),
                              textAlign: settingsProvider.hideTrackDuration
                                  ? TextAlign.center
                                  : TextAlign.start,
                            ),
                          ),
                        ),
                        if (!settingsProvider.hideTrackDuration)
                          const SizedBox(width: 8),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: panelPositionNotifier,
              builder: (context, value, child) {
                // Closed (0.0): +100 (Hidden down)
                // Open (1.0): -32 (Up more to compensate for larger gap)
                final double yOffset = (100.0 - 132.0 * value) * scaleFactor;
                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(16, 0, 16, 32 * scaleFactor),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      currentSource.location ?? 'Location N/A',
                                      style: textTheme.titleSmall?.copyWith(
                                        fontSize: 16 *
                                            scaleFactor, // Reduced from 18 to differentiate from Venue
                                        color: colorScheme.secondary,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(
                                      height:
                                          4), // Reduced from 8 to bring Location closer to Date
                                  Row(
                                    children: [
                                      const SizedBox(
                                          width:
                                              4), // Slight indentation for Date
                                      Transform.translate(
                                        offset: const Offset(0,
                                            2), // Push Date down closer to Green Line
                                        child: Text(
                                          formattedDate,
                                          style: textTheme.titleMedium
                                              ?.apply(
                                                  fontSizeFactor: scaleFactor)
                                              .copyWith(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                height: 1.0,
                                              ),
                                        ),
                                      ),
                                      IconButton(
                                        constraints: const BoxConstraints(),
                                        padding: const EdgeInsets.only(left: 8),
                                        icon: Icon(Icons.copy_rounded,
                                            size: 20 * scaleFactor,
                                            color:
                                                colorScheme.onSurfaceVariant),
                                        onPressed: () {
                                          final track = currentSource.tracks[
                                              audioProvider.audioPlayer
                                                      .currentIndex ??
                                                  0];
                                          final locationStr = currentSource
                                                      .location !=
                                                  null
                                              ? " - ${currentSource.location}"
                                              : "";
                                          final info =
                                              "${currentShow.venue}$locationStr - $formattedDate - ${currentSource.id}\n${track.title}\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}";
                                          Clipboard.setData(
                                              ClipboardData(text: info));
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  'Show details copied to clipboard',
                                                  style: TextStyle(
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .onInverseSurface)),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor: Theme.of(context)
                                                  .colorScheme
                                                  .inverseSurface,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          12)),
                                              margin: const EdgeInsets.all(12),
                                              showCloseIcon: true,
                                              closeIconColor: Theme.of(context)
                                                  .colorScheme
                                                  .onInverseSurface,
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            IntrinsicWidth(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Align(
                                    alignment: Alignment.centerRight,
                                    child: _buildRatingButton(
                                        context,
                                        currentShow,
                                        currentSource,
                                        settingsProvider),
                                  ),
                                  const SizedBox(
                                      height:
                                          16), // Increased from 8 to compensate for -6px offset
                                  Transform.translate(
                                    offset: const Offset(
                                        0, -8), // Move UP 8px total
                                    child: InkWell(
                                      onTap: () {
                                        if (currentSource.tracks.isNotEmpty) {
                                          launchArchivePage(
                                              currentSource.tracks.first.url);
                                        }
                                      },
                                      borderRadius: BorderRadius.circular(6),
                                      child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            if (currentSource.src != null) ...[
                                              SrcBadge(
                                                  src: currentSource.src!,
                                                  isPlaying: true,
                                                  fontSize:
                                                      11.0), // Larger badge
                                              const SizedBox(width: 6),
                                            ],
                                            Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                      vertical: 6),
                                              decoration: BoxDecoration(
                                                color: colorScheme
                                                    .tertiaryContainer
                                                    .withValues(alpha: 0.7),
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                              child: Container(
                                                padding: const EdgeInsets.only(
                                                    bottom:
                                                        1.0), // Gap for underline
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: colorScheme
                                                          .onTertiaryContainer,
                                                      width: 1.0,
                                                    ),
                                                  ),
                                                ),
                                                child: Text(
                                                  currentSource.id,
                                                  style: textTheme.bodyMedium
                                                      ?.copyWith(
                                                    color: colorScheme
                                                        .onTertiaryContainer,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ]),
                                    ),
                                  ), // Close Transform.translate
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced from 16 to 8
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
                );
              },
            ),
          ),
        ],
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

  Widget _buildRatingButton(BuildContext context, Show show, Source source,
      SettingsProvider settings) {
    final String ratingKey = source.id;
    final rating = settings.getRating(ratingKey);

    return RatingControl(
      rating: rating,
      isPlayed: settings.isPlayed(ratingKey),
      size: 24, // Increased from 20 to be larger than SHNID chip
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
