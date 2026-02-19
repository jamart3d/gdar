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
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:async';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_scrollbar.dart';

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
        return Icon(
          i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 16,
          color: color,
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
        bool listHasFocus = false;
        for (var node in _trackFocusNodes.values) {
          if (node.hasFocus) {
            listHasFocus = true;
            break;
          }
        }
        if (listHasFocus) {
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

    bool needsRebuild = false;
    if (!_trackFocusNodes.containsKey(index)) {
      _trackFocusNodes[index] = FocusNode();
      needsRebuild = true;
    }

    if (needsRebuild) {
      if (mounted) setState(() {});
    }

    if (shouldScroll && _itemScrollController.isAttached) {
      _itemScrollController.jumpTo(index: index, alignment: 0.3);
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
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

    if (audioProvider.currentTrack?.title != _lastTrackTitle) {
      _lastTrackTitle = audioProvider.currentTrack?.title;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final isPanelOpen = _panelPositionNotifier.value > 0.1;
        _scrollToCurrentTrack(true,
            maxVisibleY: isPanelOpen ? 0.4 : 1.0, syncFocus: true);
      });
    }

    final colorScheme = Theme.of(context).colorScheme;
    Color backgroundColor = colorScheme.surface;

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

    final double bottomPadding = MediaQuery.of(context).padding.bottom;
    final double baseHeight = settingsProvider.uiScale ? 75.0 : 96.0;
    final double minPanelHeight = (baseHeight * scaleFactor) + bottomPadding;

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
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Row 1: date (left) + right column: rating stars + src badge
                    Row(
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
                                    color: colorScheme.primary,
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
                              Icons.stadium_rounded,
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
                                Icons.place_outlined,
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
                        source: currentSource,
                        bottomPadding: 16.0,
                        topPadding: 0.0,
                        itemScrollController: _itemScrollController,
                        itemPositionsListener: _itemPositionsListener,
                        audioProvider: audioProvider,
                        trackFocusNodes: _trackFocusNodes,
                        onFocusLeft: () {
                          _scrollToCurrentTrack(true,
                              force: true, alignment: 0.5);
                          widget.onTrackListLeft?.call();
                        },
                        onFocusRight: widget.onTrackListRight,
                        onTrackFocused: (index) {
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

        const double topGap = 0.0;
        const double appBarHeight = kToolbarHeight;
        final double immersiveTopPadding =
            MediaQuery.paddingOf(context).top + topGap + appBarHeight;

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
