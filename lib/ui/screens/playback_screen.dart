import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/playback/playback_panel.dart';
import 'package:shakedown/ui/widgets/playback/playback_messages.dart';
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
  final VoidCallback? onTrackListLeft;
  final VoidCallback? onTrackListRight;

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
  // Map of track index to FocusNode
  final Map<int, FocusNode> _trackFocusNodes = {};

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
      _scrollToCurrentTrack(false);
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
    super.dispose();
  }

  void _scrollToCurrentTrack(
    bool animate, {
    bool force = false,
    int? forceTargetIndex,
    double alignment = 0.3,
    double maxVisibleY = 1.0,
  }) {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentTrack = audioProvider.currentTrack;
    final currentSource = audioProvider.currentSource;
    if (currentTrack == null && forceTargetIndex == null) return;
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

    if (targetIndex != -1 && _itemScrollController.isAttached) {
      final positions = _itemPositionsListener.itemPositions.value;

      // Smart check to prevent jank
      if (positions.isNotEmpty) {
        if (force) {
          // If forced (manual tap/focus), only skip if we are already close to the target alignment
          final isAligned = positions.any((position) =>
              position.index == targetIndex &&
              (position.itemLeadingEdge - alignment).abs() <
                  0.05); // 5% tolerance
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

  void _focusTrack(int index) {
    if (index < 0) return;

    // Ensure the focus node exists
    if (!_trackFocusNodes.containsKey(index)) {
      _trackFocusNodes[index] = FocusNode();
    }

    // Scroll to the track to ensure it's built and visible
    _itemScrollController.jumpTo(index: index, alignment: 0.3);

    // Wait for a frame to ensure the PlaybackScreen is rebuilt and the Focus widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _trackFocusNodes[index]?.requestFocus();
    });
  }

  void _handleScrollbarLeft() {
    // 1. Try to find the middle visible item
    final positions = _itemPositionsListener.itemPositions.value;
    int targetIndex = -1;

    if (positions.isNotEmpty) {
      // Sort positions by index just in case
      final sorted = positions.toList()
        ..sort((a, b) => a.index.compareTo(b.index));

      // Find item closest to center (0.5)
      double bestDistance = 999.0;

      for (var pos in sorted) {
        // Center of the item
        final itemCenter = (pos.itemLeadingEdge + pos.itemTrailingEdge) / 2;
        final distance = (itemCenter - 0.5).abs();

        if (distance < bestDistance) {
          bestDistance = distance;
          targetIndex = pos.index;
        }
      }
    }

    // 2. If valid target found, focus it
    if (targetIndex != -1) {
      _focusTrack(targetIndex);
      return;
    }

    // 3. Fallback: Current Playing Track
    final audioProvider = context.read<AudioProvider>();
    if (audioProvider.audioPlayer.currentIndex != null) {
      _focusTrack(audioProvider.audioPlayer.currentIndex!);
      return;
    }

    // 4. Fallback: First track
    _focusTrack(0);
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
        _scrollToCurrentTrack(true, maxVisibleY: isPanelOpen ? 0.4 : 1.0);
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          currentShow.formattedDate,
                          style: TextStyle(
                            fontFamily: 'Rock Salt',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        if (settingsProvider.showPlaybackMessages)
                          const PlaybackMessages(
                            textAlign: TextAlign.right,
                            showDivider: true,
                          ),
                      ],
                    ),
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.stadium_rounded,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              currentShow.venue,
                              style: TextStyle(
                                fontSize: 16,
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
                                Icons.place_outlined,
                                size: 18,
                                color: colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                currentSource.location!,
                                style: TextStyle(
                                  fontSize: 16,
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
                        source: currentSource,
                        bottomPadding:
                            16.0, // Reduced padding as bar is floating
                        topPadding: 0.0,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        audioProvider: audioProvider,
                        trackFocusNodes: _trackFocusNodes,
                        onFocusLeft: () {
                          // Center the current playing track when navigating away (to keep it visible in side pane)
                          _scrollToCurrentTrack(true,
                              force: true, alignment: 0.5);
                          widget.onTrackListLeft?.call();
                        },
                        onFocusRight: widget
                            .onTrackListRight, // Or internal scrollbar focus?
                        onTrackFocused: (index) {
                          // Auto-scroll when navigating with D-pad
                          _scrollToCurrentTrack(true,
                              force: true, forceTargetIndex: index);
                        },
                        onWrapAround: _focusTrack,
                      ),
                    ),
                    if (context.read<DeviceService>().isTv)
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
    );
  }
}
