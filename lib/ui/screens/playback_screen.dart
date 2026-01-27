import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:just_audio/just_audio.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'dart:async';

import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:shakedown/ui/widgets/playback/playback_progress_bar.dart';
import 'package:shakedown/ui/widgets/playback/playback_controls.dart';

import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/ui/styles/app_typography.dart';

class PlaybackScreen extends StatefulWidget {
  final bool initiallyOpen;
  const PlaybackScreen({super.key, this.initiallyOpen = false});

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initiallyOpen) {
        _panelController.open();
      }
    });

    // Listen for errors
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      _errorSubscription = audioProvider.playbackErrorStream.listen((error) {
        if (mounted && error.isNotEmpty) {
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
        // If panel is open (or opening), limit visibility to top 40%
        final isPanelOpen = _panelPositionNotifier.value > 0.1;
        _scrollToCurrentTrack(maxVisibleY: isPanelOpen ? 0.4 : 1.0);
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

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // minHeight covering the drag handle + Venue/Copy row.
    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    // Bumped from 92.0 to 96.0 to accommodate larger fonts like Caveat
    final double minPanelHeight = (96.0 * scaleFactor) + bottomPadding;

    // maxHeight constraint to ~40% of screen (0.45 if scaled).
    // User enforced strict height regardless of font.
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
                _buildAppBar(
                    currentShow, currentSource, backgroundColor, panelPosition),
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

  Widget _buildAppBar(
      Show show, Source source, Color backgroundColor, double panelPosition) {
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
          height: AppTypography.responsiveFontSize(context, 11.0) * 2.2,
          child: ConditionalMarquee(
            text: formattedDate,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: AppTypography.responsiveFontSize(
                    context,
                    settingsProvider.appFont == 'caveat' ? 13.0 : 11.0,
                  ),
                ),
          ),
        ),
      ),
      actions: [
        Opacity(
          opacity: (1.0 - (panelPosition * 1.5)).clamp(0.0, 1.0),
          child: Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ValueListenableBuilder<Box<bool>>(
                    valueListenable: CatalogService().historyListenable,
                    builder: (context, historyBox, _) {
                      return ValueListenableBuilder<Box<Rating>>(
                        valueListenable: CatalogService().ratingsListenable,
                        builder: (context, ratingsBox, _) {
                          final String ratingKey = source.id;
                          final isPlayed = historyBox.get(ratingKey) ?? false;
                          final ratingObj = ratingsBox.get(ratingKey);
                          final int rating = ratingObj?.rating ?? 0;

                          return RatingControl(
                            key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                            rating: rating,
                            size:
                                AppTypography.responsiveFontSize(context, 16.0),
                            isPlayed: isPlayed,
                            onTap: () async {
                              final currentRating =
                                  ratingsBox.get(ratingKey)?.rating ?? 0;
                              await showDialog(
                                context: context,
                                builder: (context) => RatingDialog(
                                  initialRating: currentRating,
                                  sourceId: source.id,
                                  sourceUrl: source.tracks.isNotEmpty
                                      ? source.tracks.first.url
                                      : null,
                                  isPlayed: historyBox.get(ratingKey) ?? false,
                                  onRatingChanged: (newRating) {
                                    CatalogService()
                                        .setRating(ratingKey, newRating);
                                  },
                                  onPlayedChanged: (bool newIsPlayed) {
                                    if (newIsPlayed !=
                                        (historyBox.get(ratingKey) ?? false)) {
                                      CatalogService().togglePlayed(ratingKey);
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  if (source.src != null) ...[
                    SrcBadge(
                      src: source.src!,
                      matchShnidLook: true,
                    ),
                    const SizedBox(height: 4),
                  ],
                  // Unified ShnidBadge
                  ShnidBadge(text: source.id),
                  const SizedBox(height: 2), // Gap from bottom
                ],
              ),
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          iconSize: AppTypography.responsiveFontSize(context, 24.0),
          onPressed: () async {
            // Pause global clock before navigating away to prevent visual jumps
            try {
              context.read<AnimationController>().stop();
            } catch (_) {}

            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SettingsScreen(),
                transitionDuration: Duration.zero,
              ),
            );

            // Resume global clock on return
            if (mounted) {
              try {
                final controller = context.read<AnimationController>();
                if (!controller.isAnimating) controller.repeat();
              } catch (_) {}
            }
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontSize: AppTypography.responsiveFontSize(context, 14.0),
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
    bool isTrueBlackMode,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        // Use currentTrack equality for robust highlighting (handles seamless playback)
        // Use robust value comparison for highlighting
        final currentTrack = audioProvider.currentTrack;
        final isPlaying = currentTrack != null &&
            currentTrack.title == track.title &&
            currentTrack.trackNumber == track.trackNumber;

        final double scaleFactor =
            FontLayoutConfig.getEffectiveScale(context, settingsProvider);

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
                    glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
                    animationSpeed: settingsProvider.rgbAnimationSpeed,
                    child: Material(
                      color: isTrueBlackMode
                          ? Colors.black
                          : colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: _buildTrackListTile(context, audioProvider, track,
                          index, isPlaying, scaleFactor),
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: _buildTrackListTile(context, audioProvider, track,
                      index, isPlaying, scaleFactor),
                ),
        );
      },
    );
  }

  Widget _buildTrackListTile(BuildContext context, AudioProvider audioProvider,
      Track track, int index, bool isPlaying, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);

    // Simplified centralized font sizing
    final double titleFontSize =
        AppTypography.responsiveFontSize(context, 16.0);

    final titleStyle = baseTitleStyle.copyWith(
      fontSize: titleFontSize,
      fontWeight: isPlaying ? FontWeight.w600 : FontWeight.normal,
      color: isPlaying ? colorScheme.primary : colorScheme.onSurface,
      height: 1.1, // Fix vertical jump when bolding
    );

    return ListTile(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      title: SizedBox(
        height: titleStyle.fontSize! *
            (settingsProvider.appFont == 'rock_salt' ? 2.0 : 1.6),
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
          HapticFeedback.lightImpact();
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
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

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
                    // Reduced bottom padding to prevent overflow with large fonts (Caveat)
                    padding: EdgeInsets.only(
                        left: 16.0, right: 16.0, bottom: 24.0 + bottomPadding),
                    child: Row(
                      mainAxisAlignment: settingsProvider.hideTrackDuration
                          ? MainAxisAlignment.center
                          : MainAxisAlignment.start,
                      children: [
                        Flexible(
                          child: SizedBox(
                            // Slightly reduced multiplier from 2.2 to 2.0 to tighten vertical space
                            height: AppTypography.responsiveFontSize(
                                    context, 18.0) *
                                2.0,
                            child: ConditionalMarquee(
                              text: currentShow.venue,
                              style: textTheme.headlineSmall?.copyWith(
                                fontSize: AppTypography.responsiveFontSize(
                                    context, 18.0),
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
                // Open (1.0): -24 (Up more to create gap from bottom)
                // We keep the offset logic but now allow scrolling
                final double yOffset = (100.0 - 124.0 * value) * scaleFactor;
                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: SingleChildScrollView(
                    physics: const NeverScrollableScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        16,
                        0,
                        16,
                        (settingsProvider.uiScale &&
                                settingsProvider.appFont == 'caveat')
                            ? 56 * scaleFactor
                            : 32 * scaleFactor),
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
                                        fontSize:
                                            AppTypography.responsiveFontSize(
                                                context, 16.0),
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
                                      Flexible(
                                        child: Transform.translate(
                                          offset: const Offset(0, 2),
                                          child: SizedBox(
                                            height: AppTypography
                                                    .responsiveFontSize(
                                                        context, 14.0) *
                                                2.2,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 4.0),
                                              child: ConditionalMarquee(
                                                text: formattedDate,
                                                style: textTheme.titleMedium
                                                    ?.copyWith(
                                                  fontSize: AppTypography
                                                      .responsiveFontSize(
                                                          context, 14.0),
                                                  color: colorScheme
                                                      .onSurfaceVariant,
                                                  height: 1.2,
                                                ),
                                              ),
                                            ),
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
                                          HapticFeedback
                                              .selectionClick(); // Confirm copy action
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Row(
                                                children: [
                                                  Icon(
                                                    Icons
                                                        .check_circle_outline_rounded,
                                                    color: colorScheme
                                                        .onPrimaryContainer,
                                                    size: 20 * scaleFactor,
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Text(
                                                      'Details copied to clipboard',
                                                      style: textTheme
                                                          .labelLarge
                                                          ?.copyWith(
                                                        color: colorScheme
                                                            .onPrimaryContainer,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              behavior:
                                                  SnackBarBehavior.floating,
                                              backgroundColor:
                                                  colorScheme.primaryContainer,
                                              elevation: 4,
                                              duration: const Duration(
                                                  milliseconds: 1500),
                                              margin: EdgeInsets.only(
                                                bottom: (MediaQuery.of(context)
                                                            .size
                                                            .height *
                                                        (settingsProvider
                                                                .uiScale
                                                            ? 0.45
                                                            : 0.40)) -
                                                    minHeight +
                                                    (75 * scaleFactor),
                                                left: 48,
                                                right: 48,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(100),
                                                side: BorderSide(
                                                  color: colorScheme
                                                      .onPrimaryContainer
                                                      .withValues(alpha: 0.1),
                                                  width: 1,
                                                ),
                                              ),
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Rating Stars
                                ConstrainedBox(
                                  constraints: const BoxConstraints(
                                      minWidth: 48, minHeight: 48),
                                  child: Center(
                                    child: _buildRatingButton(
                                        context, currentShow, currentSource),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // SrcBadge
                                // SrcBadge
                                if (currentSource.src != null)
                                  SrcBadge(
                                    src: currentSource.src!,
                                    matchShnidLook: true,
                                  ),
                                const SizedBox(height: 4),
                                // Shnid Badge
                                InkWell(
                                  onTap: () {
                                    if (currentSource.tracks.isNotEmpty) {
                                      launchArchivePage(
                                          currentSource.tracks.first.url);
                                    }
                                  },
                                  borderRadius: BorderRadius.circular(8),
                                  child: ShnidBadge(
                                    text: currentSource.id,
                                    showUnderline: true,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 8), // Reduced from 16 to 8
                        const PlaybackProgressBar(),
                        const SizedBox(height: 8),
                        ValueListenableBuilder<double>(
                          valueListenable: panelPositionNotifier,
                          builder: (context, position, _) {
                            return PlaybackControls(panelPosition: position);
                          },
                        ),
                        if (settingsProvider.showPlaybackMessages) ...[
                          const SizedBox(
                              height:
                                  8), // Reduced from 16 to fit in fixed height
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
    final settingsProvider = context.read<SettingsProvider>();
    final isScaled = settingsProvider.uiScale;
    // Reduce status font size if scaled to prevent cramping
    final double labelsFontSize = isScaled ? 10.0 : 12.0;

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
                fontSize: labelsFontSize,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: labelsFontSize,
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
                    fontSize: labelsFontSize,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingButton(BuildContext context, Show show, Source source) {
    final String ratingKey = source.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, __) {
        final catalog = CatalogService();
        final rating = catalog.getRating(ratingKey);
        final isPlayed = catalog.isPlayed(ratingKey);

        return RatingControl(
          rating: rating,
          isPlayed: isPlayed,
          size: AppTypography.responsiveFontSize(context, 24.0),
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => RatingDialog(
                initialRating: rating,
                sourceId: source.id,
                sourceUrl:
                    source.tracks.isNotEmpty ? source.tracks.first.url : null,
                isPlayed: isPlayed,
                onRatingChanged: (newRating) {
                  catalog.setRating(ratingKey, newRating);
                },
                onPlayedChanged: (bool newIsPlayed) {
                  if (newIsPlayed != catalog.isPlayed(ratingKey)) {
                    catalog.togglePlayed(ratingKey);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}
