import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/ui/widgets/playback/fruit_track_list.dart';
import 'package:shakedown/ui/widgets/playback/fruit_now_playing_card.dart';
import 'package:shakedown/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown/ui/widgets/playback/track_list_view.dart';
import 'package:shakedown/ui/widgets/playback/playback_app_bar.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_scrollbar.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Small private widgets ─────────────────────────────────────────────────────

class _RatingStars extends StatelessWidget {
  final int rating; // 1–3
  final Color color;

  const _RatingStars({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    const int total = 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: List.generate(total, (i) {
        final bool filled = i < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? color : color.withValues(alpha: 0.3),
        );
      }),
    );
  }
}

// ── Main widget ───────────────────────────────────────────────────────────────

class PlaybackScreen extends StatefulWidget {
  final bool initiallyOpen;
  final bool isPane;
  final VoidCallback? onTitleTap;
  final bool enableDiceHaptics;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onScrollbarRight;
  final VoidCallback? onTrackListLeft;
  final VoidCallback? onTrackListRight;
  final bool isActive;
  final bool showFruitTabBar;
  final VoidCallback? onBackRequested;

  const PlaybackScreen({
    super.key,
    this.initiallyOpen = false,
    this.onTitleTap,
    this.isPane = false,
    this.enableDiceHaptics = false,
    this.scrollbarFocusNode,
    this.onScrollbarRight,
    this.onTrackListLeft,
    this.onTrackListRight,
    this.isActive = true,
    this.showFruitTabBar = true,
    this.onBackRequested,
  });

  @override
  State<PlaybackScreen> createState() => PlaybackScreenState();
}

class PlaybackScreenState extends State<PlaybackScreen>
    with SingleTickerProviderStateMixin {
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  late final AnimationController _pulseController;
  final PanelController _panelController = PanelController();
  final ValueNotifier<double> _panelPositionNotifier = ValueNotifier(0.0);
  StreamSubscription? _errorSubscription;
  String? _lastTrackTitle;
  bool? _lastStickyState;
  final Map<int, FocusNode> _trackFocusNodes = {};
  final FocusNode _trackListFocusNode = FocusNode(canRequestFocus: false);

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final audioProvider = context.read<AudioProvider>();
      _errorSubscription = audioProvider.playbackErrorStream.listen((error) {
        if (mounted && error.isNotEmpty) {
          showMessage(context, 'Playback Error: $error');
        }
      });
      // Removed to prevent "bounce scroll" glitch; TrackListView now handles
      // initial positioning via initialScrollIndex.
      // _scrollToCurrentTrack(false);
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _panelPositionNotifier.dispose();
    _errorSubscription?.cancel();
    for (var node in _trackFocusNodes.values) {
      node.dispose();
    }
    _trackListFocusNode.dispose();
    super.dispose();
  }

  void _scrollToCurrentTrack(
    bool animate, {
    bool force = false,
    int? forceTargetIndex,
    double alignment = 0.3,
    double maxVisibleY = 1.0,
    bool syncFocus = false,
  }) {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    final currentSource = audioProvider.currentSource;
    if (currentTrack == null && forceTargetIndex == null) return;
    if (currentSource == null) return;

    final Map<String, List<Track>> tracksBySet = {};
    for (var track in currentSource.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName] = tracksBySet[track.setName]!..add(track);
    }

    final List<dynamic> listItems = [];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    int targetIndex = forceTargetIndex ?? -1;
    if (targetIndex == -1 && currentTrack != null) {
      for (int i = 0; i < listItems.length; i++) {
        final item = listItems[i];
        if (item is Track &&
            item.title == currentTrack.title &&
            item.trackNumber == currentTrack.trackNumber) {
          targetIndex = i;
          break;
        }
      }
    }

    if (targetIndex != -1) {
      if (_itemScrollController.isAttached) {
        final positions = _itemPositionsListener.itemPositions.value;

        bool skipScroll = false;
        if (positions.isNotEmpty) {
          if (force) {
            final isAligned = positions.any((position) =>
                position.index == targetIndex &&
                (position.itemLeadingEdge - alignment).abs() < 0.05);
            if (isAligned) skipScroll = true;
          } else {
            final isVisible = positions.any((position) =>
                position.index == targetIndex &&
                position.itemLeadingEdge >= 0 &&
                position.itemTrailingEdge <= maxVisibleY);
            if (isVisible) skipScroll = true;
          }
        }

        if (!skipScroll) {
          if (animate) {
            _itemScrollController.scrollTo(
              index: targetIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOutCubic,
              alignment: alignment,
            );
          } else {
            _itemScrollController.jumpTo(
              index: targetIndex,
              alignment: alignment,
            );
          }
        }
      }

      if (syncFocus && context.read<DeviceService>().isTv) {
        // Only snatch focus if the list does NOT already have it.
        // We check the container-level node which covers the whole track area.
        if (!_trackListFocusNode.hasFocus) {
          _focusTrack(targetIndex, shouldScroll: false);
        }
      }
    }
  }

  void focusCurrentTrack() {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    final currentSource = audioProvider.currentSource;

    if (currentSource == null) return;

    if (currentTrack == null) {
      _focusTrack(1);
      return;
    }

    final Map<String, List<Track>> tracksBySet = {};
    for (var track in currentSource.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName] = tracksBySet[track.setName]!..add(track);
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

    if (targetIndex != -1) {
      _focusTrack(targetIndex);
    } else {
      _focusTrack(1);
    }
  }

  int _calculateTotalItems(Source source) {
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName] = tracksBySet[track.setName]!..add(track);
    }
    int count = 0;
    tracksBySet.forEach((key, value) {
      count++;
      count += value.length;
    });
    return count;
  }

  void _focusTrack(int index, {bool shouldScroll = true}) {
    if (index < 0) return;
    final audioProvider = context.read<AudioProvider>();
    final currentSource = audioProvider.currentSource;
    if (currentSource == null) return;

    // Safety: ensure all other track nodes lose focus before we request focus
    // on the target. This prevents "ghost" highlights where multiple nodes
    // claim to have focus during rapid scrolling or widget recycling.
    for (final node in _trackFocusNodes.values) {
      if (node.hasFocus) node.unfocus();
    }

    final keysToRemove = _trackFocusNodes.keys
        .where((k) =>
            (k - index).abs() > 20 &&
            !(_trackFocusNodes[k]?.hasPrimaryFocus ?? false))
        .toList();
    for (final k in keysToRemove) {
      _trackFocusNodes[k]?.dispose();
      _trackFocusNodes.remove(k);
    }

    bool needsRebuild = false;
    if (!_trackFocusNodes.containsKey(index)) {
      _trackFocusNodes[index] = FocusNode();
      needsRebuild = true;
    }

    if (needsRebuild) {
      if (mounted) setState(() {});
    }

    if (shouldScroll && _itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;

      // If the list exists but has no positions yet, it's likely just mounting.
      // Trust the initialScrollIndex of the widget for the first frame.
      if (positions.isEmpty) return;

      bool alreadyAligned = false;
      final target = positions.where((p) => p.index == index).firstOrNull;

      if (target != null) {
        final double currentEdge = target.itemLeadingEdge;
        // 1. Is it exactly where we want it (within 3% margin)?
        if ((currentEdge - 0.3).abs() < 0.03) {
          alreadyAligned = true;
        } else {
          // 2. Are we at the edges? (Slack logic)
          final last = positions.reduce((a, b) => a.index > b.index ? a : b);
          final first = positions.reduce((a, b) => a.index < b.index ? a : b);

          // Total items for this source
          final int totalItems = _calculateTotalItems(currentSource);

          if (last.index == totalItems - 1 && last.itemTrailingEdge <= 1.05) {
            // We are at the bottom. If item is visible, don't force it up to 0.3.
            if (target.itemLeadingEdge >= 0 &&
                target.itemTrailingEdge <= 1.05) {
              alreadyAligned = true;
            }
          } else if (first.index == 0 && first.itemLeadingEdge >= -0.05) {
            // We are at the top. If item is visible, don't force it down to 0.3.
            if (target.itemLeadingEdge >= -0.05 &&
                target.itemTrailingEdge <= 1.0) {
              alreadyAligned = true;
            }
          }
        }
      }

      if (!alreadyAligned) {
        _itemScrollController.jumpTo(index: index, alignment: 0.3);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && (_trackFocusNodes[index]?.canRequestFocus ?? false)) {
        _trackFocusNodes[index]?.requestFocus();
      }
    });
  }

  void _handleScrollbarLeft() {
    final positions = _itemPositionsListener.itemPositions.value;
    int targetIndex = -1;

    if (positions.isNotEmpty) {
      final sorted = positions.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      double bestDistance = 999.0;
      for (var pos in sorted) {
        final itemCenter = (pos.itemLeadingEdge + pos.itemTrailingEdge) / 2;
        final distance = (itemCenter - 0.5).abs();
        if (distance < bestDistance) {
          bestDistance = distance;
          targetIndex = pos.index;
        }
      }
    }

    if (targetIndex != -1) {
      _focusTrack(targetIndex, shouldScroll: false);
      return;
    }

    final audioProvider = context.read<AudioProvider>();
    final currentSource = audioProvider.currentSource;
    final trackIndex = audioProvider.audioPlayer.currentIndex;

    if (currentSource != null && trackIndex != null) {
      int listIdx = 0;
      int tIdx = 0;
      final Map<String, List<Track>> tracksBySet = {};
      for (var track in currentSource.tracks) {
        if (!tracksBySet.containsKey(track.setName)) {
          tracksBySet[track.setName] = [];
        }
        tracksBySet[track.setName]!.add(track);
      }

      bool found = false;
      tracksBySet.forEach((setName, tracks) {
        if (found) return;
        listIdx++;
        for (var _ in tracks) {
          if (tIdx == trackIndex) {
            targetIndex = listIdx;
            found = true;
            return;
          }
          listIdx++;
          tIdx++;
        }
      });

      if (found) {
        _focusTrack(targetIndex, shouldScroll: false);
        return;
      }
    }

    _focusTrack(1, shouldScroll: false);
  }

  Widget _buildFruitTopBar(BuildContext context, double scaleFactor) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final currentShow = audioProvider.currentShow;
    if (currentShow == null) return const SizedBox.shrink();

    // Tuesday, July 4, 1989
    String dateText = '';
    try {
      final dateTime = DateTime.parse(currentShow.date);
      dateText = DateFormat('EEEE, MMMM d, y').format(dateTime);
    } catch (_) {
      dateText = currentShow.formattedDate;
    }

    final catalog = CatalogService();
    final String? ratingKey = audioProvider.currentSource?.id;
    final Source? currentSource = audioProvider.currentSource;
    int rating = 0;
    bool isPlayed = false;

    if (ratingKey != null) {
      rating = catalog.getRating(ratingKey);
      isPlayed = catalog.isPlayed(ratingKey);
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.0 * scaleFactor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FruitHeaderButton(
            onTap: widget.onBackRequested ?? () => Navigator.of(context).pop(),
            icon: LucideIcons.chevronLeft,
            scaleFactor: scaleFactor,
            semanticLabel: 'Back to library',
          ),
          // Center: Metadata
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor, // text-base equivalent
                    fontWeight: FontWeight.bold, // font-bold
                    letterSpacing: -0.5, // tracking-tight
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2 * scaleFactor),
                Text(
                  '${currentShow.venue}, ${currentShow.location}'.toUpperCase(),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 10 * scaleFactor, // text-[10px]
                    fontWeight: FontWeight.bold, // font-bold
                    letterSpacing: 1.5, // tracking-widest
                    color: Theme.of(context)
                        .colorScheme
                        .onSurfaceVariant
                        .withValues(alpha: 0.6),
                  ),
                ),
                SizedBox(height: 6 * scaleFactor),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    RatingControl(
                      rating: rating,
                      isPlayed: isPlayed,
                      compact: true,
                      size: 20 * scaleFactor,
                      onTap: () async {
                        if (ratingKey == null) return;
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: rating,
                            sourceId: ratingKey,
                            isPlayed: isPlayed,
                            onRatingChanged: (newRating) {
                              catalog.setRating(ratingKey, newRating);
                            },
                          ),
                        );
                      },
                    ),
                    SizedBox(width: 8 * scaleFactor),
                    SrcBadge(
                      src: audioProvider.currentSource?.src ?? '',
                      scaleFactor: scaleFactor,
                    ),
                    if (audioProvider.currentSource?.id != null) ...[
                      SizedBox(width: 4 * scaleFactor),
                      ShnidBadge(
                        text: audioProvider.currentSource!.id,
                        scaleFactor: scaleFactor,
                        uri: () {
                          if (currentSource == null) return null;
                          if (currentSource.tracks.isNotEmpty) {
                            final transformed = transformArchiveUrl(
                                currentSource.tracks.first.url);
                            if (transformed != null && transformed.isNotEmpty) {
                              return Uri.parse(transformed);
                            }
                          }
                          return Uri.parse(
                              'https://archive.org/details/${currentSource.id}');
                        }(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          _FruitHeaderButton(
            onTap: () {
              final size = MediaQuery.sizeOf(context);
              final double topPadding = MediaQuery.paddingOf(context).top;

              // Force alignment to the right
              final RelativeRect position = RelativeRect.fromLTRB(
                size.width - 24 * scaleFactor,
                topPadding + 70 * scaleFactor,
                24 * scaleFactor,
                0,
              );

              showMenu(
                context: context,
                position: position,
                elevation: settingsProvider.performanceMode ? 4 : 0,
                color: settingsProvider.performanceMode
                    ? Theme.of(context).colorScheme.surface
                    : Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.85),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24 * scaleFactor),
                  side: BorderSide(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.1),
                    width: 1.0,
                  ),
                ),
                items: [
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleFruitStickyNowPlaying(),
                    child: SizedBox(
                      width: 200 * scaleFactor,
                      child: Row(
                        children: [
                          Icon(
                            settingsProvider.fruitStickyNowPlaying
                                ? LucideIcons.checkCircle2
                                : LucideIcons.circle,
                            size: 18 * scaleFactor,
                            color: settingsProvider.fruitStickyNowPlaying
                                ? Theme.of(context).colorScheme.primary
                                : null,
                          ),
                          SizedBox(width: 12 * scaleFactor),
                          Text(
                            'Sticky Now Playing',
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ],
                      ),
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleShowTrackNumbers(),
                    child: Row(
                      children: [
                        Icon(
                          settingsProvider.showTrackNumbers
                              ? LucideIcons.checkCircle2
                              : LucideIcons.circle,
                          size: 18 * scaleFactor,
                          color: settingsProvider.showTrackNumbers
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Text(
                          'Track Numbers',
                          style: TextStyle(fontSize: 14 * scaleFactor),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    onTap: () => settingsProvider.toggleHideTrackDuration(),
                    child: Row(
                      children: [
                        Icon(
                          !settingsProvider.hideTrackDuration
                              ? LucideIcons.checkCircle2
                              : LucideIcons.circle,
                          size: 18 * scaleFactor,
                          color: !settingsProvider.hideTrackDuration
                              ? Theme.of(context).colorScheme.primary
                              : null,
                        ),
                        SizedBox(width: 12 * scaleFactor),
                        Text(
                          'Track Duration',
                          style: TextStyle(fontSize: 14 * scaleFactor),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
            icon: LucideIcons.moreHorizontal,
            scaleFactor: scaleFactor,
            semanticLabel: 'Playback options',
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.watch<DeviceService>().isTv;

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

    final stickyNowPlaying = settingsProvider.fruitStickyNowPlaying;
    final bool trackChanged =
        audioProvider.currentTrack?.title != _lastTrackTitle;
    final bool stickyToggledOn = stickyNowPlaying && _lastStickyState == false;
    final bool isInitialBuild = _lastStickyState == null;

    if (trackChanged || stickyToggledOn || (isInitialBuild && isFruit)) {
      _lastTrackTitle = audioProvider.currentTrack?.title;
      _lastStickyState = stickyNowPlaying;

      final bool capturedIsTv = isTv;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Only force focus to the new playing track if we aren't currently exploring the list
        // on TV. Otherwise, just scroll it into view naturally without hijacking the user's remote.
        final bool listHasFocus = capturedIsTv && _trackListFocusNode.hasFocus;

        final isPanelOpen = _panelPositionNotifier.value > 0.1;
        _scrollToCurrentTrack(
          true,
          maxVisibleY: isPanelOpen ? 0.4 : 1.0,
          syncFocus:
              !listHasFocus, // Don't snatch focus if user is actively navigating
        );
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.surface;

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    if (!isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        !isFruit) {
      String seed = currentShow.name;
      if (currentShow.sources.length > 1) {
        seed = currentSource.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double baseHeight = settingsProvider.uiScale ? 75.0 : 96.0;
    final double minPanelHeight = (baseHeight * scaleFactor) + bottomPadding;

    final double screenHeight = MediaQuery.of(context).size.height;
    // Ensure we have enough room for the expanded content column even on small phones.
    // 210 is roughly the height of Location + Date + Progress + Controls at 1.0 scale.
    final double minExpandedHeight = 180.0 * scaleFactor;
    final double targetMaxHeight = minPanelHeight + minExpandedHeight;

    // Clamp between default percentage and 85% of screen height.
    final double maxPanelHeight = targetMaxHeight.clamp(
      screenHeight * (settingsProvider.uiScale ? 0.42 : 0.40),
      screenHeight * 0.85,
    );

    const double appBarHeight = 80.0;
    final double immersiveTopPadding =
        MediaQuery.paddingOf(context).top + appBarHeight;

    final Widget playbackContent = ValueListenableBuilder<double>(
      valueListenable: _panelPositionNotifier,
      builder: (context, panelPosition, _) {
        if (widget.isPane) {
          // TV Layout: Header + Track List + Scrollbar
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 200),
                      opacity: widget.isActive ? 1.0 : 0.4,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            currentShow.formattedDate,
                            style: TextStyle(
                              fontFamily: 'RockSalt',
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color:
                                  colorScheme.onSurface.withValues(alpha: 0.70),
                            ),
                          ),
                          const Spacer(),
                          // Stars + badge stacked, both 3pt from right edge
                          Padding(
                            padding: const EdgeInsets.only(right: 3),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ValueListenableBuilder<Box<Rating>>(
                                  valueListenable:
                                      CatalogService().ratingsListenable,
                                  builder: (context, _, __) {
                                    final r = CatalogService()
                                        .getRating(currentSource.id);
                                    return _RatingStars(
                                      rating: r,
                                      color: Colors.amber,
                                    );
                                  },
                                ),
                                if (currentSource.src != null) ...[
                                  const SizedBox(height: 4),
                                  SrcBadge(
                                    src: currentSource.src!,
                                    isPlaying: false,
                                    matchShnidLook: true,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Row 2: venue + location only
                    Wrap(
                      spacing: 14,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.landmark,
                              size: 17,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 7),
                            Text(
                              currentShow.venue,
                              style: TextStyle(
                                fontFamily: 'RockSalt',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                        if (currentSource.location != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                LucideIcons.mapPin,
                                size: 17,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                currentSource.location!,
                                style: TextStyle(
                                  fontFamily: 'RockSalt',
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TrackListView(
                        key: ValueKey(currentSource.id),
                        source: currentSource,
                        bottomPadding: 16.0,
                        topPadding: 0.0,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        audioProvider: audioProvider,
                        trackFocusNodes: _trackFocusNodes,
                        trackListFocusNode: _trackListFocusNode,
                        initialScrollAlignment: 0.3,
                        onFocusLeft: () {
                          // Keep constant alignment at 0.3 instead of 0.5 to prevent "bounce"
                          // when re-entering the pane.
                          _scrollToCurrentTrack(true,
                              force: true, alignment: 0.3);
                          widget.onTrackListLeft?.call();
                        },
                        onFocusRight: widget.onTrackListRight,
                        onTrackFocused: (index) {
                          if (!_itemScrollController.isAttached) return;

                          // SAFE-ZONE SCROLLING:
                          // Only scroll if the newly focused item is near the viewport edges.
                          // This prevents the "wacky flow" caused by constant re-centering.
                          final positions =
                              _itemPositionsListener.itemPositions.value;
                          if (positions.isEmpty) return;

                          final firstVisible = positions.first.index;
                          final lastVisible = positions.last.index;

                          // If we are looking at the top few or bottom few items, trigger a gentle scroll.
                          // We use a 1-item buffer to keep things smooth.
                          if (index <= firstVisible + 1 ||
                              index >= lastVisible - 1) {
                            _scrollToCurrentTrack(true,
                                forceTargetIndex: index);
                          }
                        },
                        onWrapAround: _focusTrack,
                      ),
                    ),
                    if (context.watch<DeviceService>().isTv)
                      TvScrollbar(
                        itemPositionsListener: _itemPositionsListener,
                        itemScrollController: _itemScrollController,
                        itemCount: _calculateTotalItems(currentSource),
                        focusNode: widget.scrollbarFocusNode,
                        onRight: widget.onScrollbarRight,
                        onLeft: _handleScrollbarLeft,
                      ),
                  ],
                ),
              ),
            ],
          );
        }

        final double dynamicBottomPadding = minPanelHeight +
            60.0 +
            ((maxPanelHeight - minPanelHeight) * panelPosition);

        return Stack(
          children: [
            TrackListView(
              source: currentSource,
              bottomPadding: dynamicBottomPadding,
              topPadding: immersiveTopPadding,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              audioProvider: audioProvider,
            ),
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: immersiveTopPadding,
              child: Opacity(
                opacity: (1.0 - (panelPosition * 5.0)).clamp(0.0, 1.0),
                child: Container(
                  color: backgroundColor,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (widget.isPane) {
      return Container(
        color: backgroundColor.withValues(alpha: 0.7),
        child: playbackContent,
      );
    }

    if (isFruit && !widget.isPane) {
      // ── FRUIT WEB / MOBILE LAYOUT (UNIFIED TRACKLIST) ──
      return Scaffold(
        backgroundColor: backgroundColor,
        body: Stack(
          children: [
            FruitTrackList(
              trackShow: currentShow,
              scaleFactor: scaleFactor,
              topOffset: immersiveTopPadding,
              bottomOffset: settingsProvider.fruitStickyNowPlaying ? 0 : 80,
            ),
            if (!settingsProvider.fruitStickyNowPlaying &&
                audioProvider.currentTrack != null)
              Positioned(
                left: 16 * scaleFactor,
                right: 16 * scaleFactor,
                bottom: 12 * scaleFactor,
                child: FruitNowPlayingCard(
                  trackShow: currentShow,
                  track: audioProvider.currentTrack!,
                  index: (audioProvider.audioPlayer.currentIndex ?? 0) + 1,
                  scaleFactor: scaleFactor,
                  showNext: false,
                ),
              ),
            // ── FRUIT STICKY HEADER ──
            if (isFruit)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: LiquidGlassWrapper(
                  enabled: isFruit &&
                      settingsProvider.fruitEnableLiquidGlass &&
                      !settingsProvider.performanceMode,
                  blur: 20,
                  opacity: 0.8,
                  borderRadius: BorderRadius.zero,
                  child: Container(
                    height: MediaQuery.paddingOf(context).top + 80,
                    padding: EdgeInsets.only(
                      top: MediaQuery.paddingOf(context).top,
                    ),
                    decoration: BoxDecoration(
                      color: settingsProvider.performanceMode
                          ? Theme.of(context).colorScheme.surface
                          : null,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.05),
                          width: 1.0,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: _buildFruitTopBar(context, scaleFactor),
                  ),
                ),
              ),
          ],
        ),
        bottomNavigationBar: widget.showFruitTabBar
            ? FruitTabBar(
                selectedIndex: 0, // NOW
                onTabSelected: (index) {
                  if (index == 1) {
                    if (widget.onBackRequested != null) {
                      widget.onBackRequested!.call();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  } else if (index == 2) {
                    context.read<AudioProvider>().playRandomShow();
                  } else if (index == 3) {
                    Navigator.of(context).push(
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            SettingsScreen(
                          onBackRequested: widget.onBackRequested,
                        ),
                        transitionDuration: const Duration(milliseconds: 300),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          const begin = Offset(0.0, 1.0);
                          const end = Offset.zero;
                          const curve = Curves.easeInOut;
                          final tween = Tween(begin: begin, end: end)
                              .chain(CurveTween(curve: curve));
                          return SlideTransition(
                            position: animation.drive(tween),
                            child: child,
                          );
                        },
                      ),
                    );
                  }
                },
              )
            : null,
      );
    }

    // ── DEFAULT LAYOUT (SLIDING UP PANEL) ──
    return Scaffold(
      primary: false,
      backgroundColor: backgroundColor,
      body: Stack(
        children: [
          SlidingUpPanel(
            controller: _panelController,
            color: Colors.transparent,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24.0)),
            boxShadow: isTrueBlackMode
                ? []
                : (settingsProvider.useNeumorphism)
                    ? NeumorphicWrapper.getShadows(
                        context: context,
                        offset: const Offset(0, -8),
                        blur: 24,
                        intensity: 1.1,
                      )
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
              _scrollToCurrentTrack(true, maxVisibleY: 0.4);
            },
            panel: PlaybackPanel(
                currentShow: currentShow,
                currentSource: currentSource,
                minHeight: minPanelHeight,
                bottomPadding: bottomPadding,
                panelPositionNotifier: _panelPositionNotifier,
                onVenueTap: () {
                  _scrollToCurrentTrack(true, force: true);
                  if (_panelController.isAttached) {
                    if (_panelController.isPanelClosed) {
                      _panelController.open();
                    }
                  }
                }),
            body: playbackContent,
          ),
          ValueListenableBuilder<double>(
            valueListenable: _panelPositionNotifier,
            builder: (context, panelPosition, child) {
              const double topGap = 0.0;
              return Positioned(
                top: topGap,
                left: 0,
                right: 0,
                child: PlaybackAppBar(
                    currentShow: currentShow,
                    currentSource: currentSource,
                    backgroundColor: backgroundColor,
                    panelPosition: panelPosition),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _FruitHeaderButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double scaleFactor;
  final String semanticLabel;

  const _FruitHeaderButton({
    required this.onTap,
    required this.icon,
    required this.scaleFactor,
    required this.semanticLabel,
  });

  @override
  State<_FruitHeaderButton> createState() => _FruitHeaderButtonState();
}

class _FruitHeaderButtonState extends State<_FruitHeaderButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isSimple = settingsProvider.performanceMode;

    Widget content = SizedBox(
      width: 44 * widget.scaleFactor,
      height: 44 * widget.scaleFactor,
      child: Icon(
        widget.icon,
        size: 24 * widget.scaleFactor,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    if (!isSimple) {
      content = NeumorphicWrapper(
        intensity: 0.6,
        borderRadius: 12 * widget.scaleFactor,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: true,
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) {
            setState(() => _isFocused = value);
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _isPressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
