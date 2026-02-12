import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown/ui/widgets/playback/track_list_view.dart';
import 'package:shakedown/ui/widgets/playback/playback_app_bar.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/source.dart';
import 'dart:async';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_scrollbar.dart';

class PlaybackScreen extends StatefulWidget {
  final bool initiallyOpen;
  final bool isPane;
  final VoidCallback? onTitleTap;
  final bool enableDiceHaptics;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onScrollbarRight;

  const PlaybackScreen({
    super.key,
    this.initiallyOpen = false,
    this.onTitleTap,
    this.isPane = false,
    this.enableDiceHaptics = false,
    this.scrollbarFocusNode,
    this.onScrollbarRight,
  });

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

  int _calculateTotalItems(Source source) {
    // Logic must match what TrackListView uses to build its list.
    // TrackListView uses grouping by set.
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }
    int count = 0;
    tracksBySet.forEach((key, value) {
      count++; // Header
      count += value.length; // Tracks
    });
    return count;
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
    // Adjusted: If scaled, use 75.0 base (75*1.35~=101.25) to accomodate Caveat + Scale
    final double baseHeight = settingsProvider.uiScale ? 75.0 : 96.0;
    final double minPanelHeight = (baseHeight * scaleFactor) + bottomPadding;

    // maxHeight constraint to ~40% of screen (0.42 if scaled).
    // user enforced strict height regardless of font.
    final double maxPanelHeight = MediaQuery.of(context).size.height *
        (settingsProvider.uiScale ? 0.42 : 0.40);

    final Widget playbackContent = ValueListenableBuilder<double>(
      valueListenable: _panelPositionNotifier,
      builder: (context, panelPosition, _) {
        if (widget.isPane) {
          // TV Layout: Header + Track List + Scrollbar
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Text(
                  'TRACK LIST',
                  style: TextStyle(
                    fontFamily: 'Rock Salt',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
              Expanded(
                child: Row(
                  children: [
                    Expanded(
                      child: TrackListView(
                        source: currentSource,
                        bottomPadding:
                            16.0, // Reduced padding as bar is floating
                        topPadding: 0.0,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        audioProvider: audioProvider,
                      ),
                    ),
                    if (context.read<DeviceService>().isTv)
                      TvScrollbar(
                        itemPositionsListener: _itemPositionsListener,
                        itemScrollController: _itemScrollController,
                        itemCount: _calculateTotalItems(currentSource),
                        focusNode: widget.scrollbarFocusNode,
                        onRight: widget.onScrollbarRight,
                        onLeft: () {
                          // Move focus left back to the track list
                          FocusScope.of(context)
                              .focusInDirection(TraversalDirection.left);
                        },
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

        // M3 Expressive: Immersive track list aligned to standard AppBar height
        const double topGap = 0.0;
        const double appBarHeight = kToolbarHeight;
        final double immersiveTopPadding =
            MediaQuery.paddingOf(context).top + topGap + appBarHeight;

        return Stack(
          children: [
            // Layer 1: Track list scrolls under the status bar area
            TrackListView(
              source: currentSource,
              bottomPadding: dynamicBottomPadding,
              topPadding: immersiveTopPadding,
              itemScrollController: _itemScrollController,
              itemPositionsListener: _itemPositionsListener,
              audioProvider: audioProvider,
            ),
            // Layer 2: Top barrier to hide tracks in the gap (fades out with App Bar)
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
            // Layer 3: Adaptive App Bar positioned on top
            Positioned(
              top: MediaQuery.paddingOf(context).top + topGap,
              left: 0,
              right: 0,
              child: PlaybackAppBar(
                  currentShow: currentShow,
                  currentSource: currentSource,
                  backgroundColor: backgroundColor,
                  panelPosition: panelPosition),
            ),
          ],
        );
      },
    );

    if (widget.isPane) {
      return Container(
        color: backgroundColor.withValues(alpha: 0.7),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0),
            child: playbackContent,
          ),
        ),
      );
    }

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
        panel: PlaybackPanel(
            currentShow: currentShow,
            currentSource: currentSource,
            minHeight: minPanelHeight,
            bottomPadding: bottomPadding,
            panelPositionNotifier: _panelPositionNotifier,
            onVenueTap: () {
              _scrollToCurrentTrack(force: true);
              if (_panelController.isAttached) {
                if (_panelController.isPanelClosed) {
                  _panelController.open();
                }
              }
            }),
        body: playbackContent,
      ),
    );
  }
}
