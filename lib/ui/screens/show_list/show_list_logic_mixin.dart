import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/track_list_screen.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/tv/tv_interaction_modal.dart';

/// Mixin providing business logic and event handlers for [ShowListScreen].
mixin ShowListLogicMixin<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  // These must be provided by the state class
  ItemScrollController get itemScrollController;
  AnimationController get animationController;
  TextEditingController get searchController;
  FocusNode get searchFocusNode;

  bool isRandomShowLoading = false;
  bool isResettingRandomShow = false;
  bool userInitiatedRoll = false;
  bool isAnimationTest = false;
  bool showPasteFeedback = false;

  Timer? _loadingTimer;

  // Track pending selection for when app resumes from background
  ({Show show, Source source})? _pendingBackgroundSelection;

  DateTime? lastRollStartTime;

  @override
  void dispose() {
    _loadingTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed &&
        _pendingBackgroundSelection != null) {
      logger.i(
          'ShowListScreen: App resumed, handling pending random show selection.');
      final selection = _pendingBackgroundSelection!;
      _pendingBackgroundSelection = null;
      handleRandomShowSelection(selection);
    }
  }

  void toggleSearch() {
    final deviceService = context.read<DeviceService>();
    AppHaptics.lightImpact(deviceService);
    context.read<ShowListProvider>().toggleSearchVisible();
  }

  Future<void> reliablyScrollToShow(Show show,
      {Duration duration = const Duration(milliseconds: 300)}) async {
    final showListProvider = context.read<ShowListProvider>();
    final targetIndex = showListProvider.filteredShows.indexOf(show);
    logger.i('Attempting to scroll to "${show.name}" at index $targetIndex.');

    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list for scrolling.');
      return;
    }

    final key = showListProvider.getShowKey(show);
    final isExpanded = showListProvider.expandedShowKey == key;
    double alignment = 0.4;

    if (isExpanded) {
      if (show.sources.length > 4) {
        alignment = 0.05;
      } else if (show.sources.length > 2) {
        alignment = 0.15;
      } else if (show.sources.length > 1) {
        alignment = 0.25;
      }
    }

    try {
      await itemScrollController.scrollTo(
        index: targetIndex,
        duration: duration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: alignment,
      );
    } catch (e) {
      logger.e('Error during scroll to show: $e');
    }
  }

  Future<void> onShowTapped(Show show) async {
    final audioProvider = context.read<AudioProvider>();
    final isPlayingThisShow = audioProvider.currentShow == show;
    if (isPlayingThisShow) {
      if (context.read<DeviceService>().isTv) {
        unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
        // For active shows, ensure it's expanded if multi-source (for context) and flow.
        if (show.sources.length > 1) {
          final showListProvider = context.read<ShowListProvider>();
          final key = showListProvider.getShowKey(show);
          if (showListProvider.expandedShowKey != key) {
            showListProvider.expandShow(key);
            unawaited(animationController.forward(from: 0.0));
          }
        }
        try {
          (widget as dynamic).onFocusPlayback?.call();
        } catch (_) {}
      } else if (show.sources.length > 1) {
        await handleShowExpansion(show);
      } else {
        await openPlaybackScreen();
      }
    } else {
      if (context.read<DeviceService>().isTv) {
        // v135 style: Single click a non-playing show flows to the full-screen TrackListScreen.
        await navigateTo(
          TrackListScreen(show: show, source: show.sources.first),
        );
      } else if (show.sources.length > 1) {
        await handleShowExpansion(show);
      } else {
        final shouldOpenPlayer = await navigateTo(
          TrackListScreen(show: show, source: show.sources.first),
        );
        if (shouldOpenPlayer == true && mounted) {
          await openPlaybackScreen();
        }
      }
    }
  }

  Future<void> handleShowExpansion(Show show) async {
    final showListProvider = context.read<ShowListProvider>();
    final previouslyExpanded = showListProvider.expandedShowKey;
    final key = showListProvider.getShowKey(show);
    final isCollapsingCurrent = previouslyExpanded == key;

    if (isCollapsingCurrent) {
      unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
      showListProvider.collapseCurrentShow();
      unawaited(animationController.reverse());
      return;
    }

    unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
    final wasSomethingExpanded = previouslyExpanded != null;
    showListProvider.toggleShowExpansion(key);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      if (wasSomethingExpanded) {
        await animationController.forward(from: 0.0);
      } else {
        await animationController.forward();
      }
      if (!mounted) return;
      await reliablyScrollToShow(show);
    });
  }

  Future<void> onSourceTapped(Show show, Source source) async {
    final audioProvider = context.read<AudioProvider>();
    final isPlayingThisSource = audioProvider.currentSource?.id == source.id;

    if (isPlayingThisSource) {
      // Guard: No full-screen player on TV. Shift focus to the track list.
      if (context.read<DeviceService>().isTv) {
        unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));
        try {
          (widget as dynamic).onFocusPlayback?.call();
        } catch (_) {}
      } else {
        await openPlaybackScreen();
      }
    } else {
      final singleSourceShow = Show(
        name: show.name,
        artist: show.artist,
        date: show.date,
        venue: show.venue,
        sources: [source],
        hasFeaturedTrack: show.hasFeaturedTrack,
      );
      if (context.read<DeviceService>().isTv) {
        // v135 style: Single click a non-playing source flows to the full-screen TrackListScreen.
        await navigateTo(
          TrackListScreen(
              show: singleSourceShow, source: singleSourceShow.sources.first),
        );
      } else {
        final shouldOpenPlayer = await navigateTo(
          TrackListScreen(
              show: singleSourceShow, source: singleSourceShow.sources.first),
        );
        if (shouldOpenPlayer == true && mounted) {
          // Guard: No full-screen player on TV.
          if (!context.read<DeviceService>().isTv) {
            await openPlaybackScreen();
          }
        }
      }
    }
  }

  Future<void> onCardLongPressed(Show show) async {
    if (show.sources.isEmpty) return;

    final catalog = context.read<CatalogService>();

    // Find the highest rated source, or fallback to the first one
    Source sourceToPlay = show.sources.first;
    int maxRating = -100;

    for (var src in show.sources) {
      final rating = catalog.getRating(src.id);
      if (rating > maxRating) {
        maxRating = rating;
        sourceToPlay = src;
      }
    }

    if (context.read<DeviceService>().isTv) {
      unawaited(TvInteractionModal.show(
        context,
        title: show.venue,
        subtitle: AppDateUtils.formatDate(show.date,
            settings: context.read<SettingsProvider>()),
        onPlay: () => _playSource(show, sourceToPlay),
        onRate: () {
          showDialog(
            context: context,
            builder: (context) => RatingDialog(
              initialRating: catalog.getRating(sourceToPlay.id),
              sourceId: sourceToPlay.id,
              sourceUrl: sourceToPlay.tracks.isNotEmpty
                  ? sourceToPlay.tracks.first.url
                  : null,
              isPlayed: catalog.isPlayed(sourceToPlay.id),
              onRatingChanged: (newRating) {
                catalog.setRating(sourceToPlay.id, newRating);
              },
              onPlayedChanged: (bool newIsPlayed) {
                if (newIsPlayed != catalog.isPlayed(sourceToPlay.id)) {
                  catalog.togglePlayed(sourceToPlay.id);
                }
              },
            ),
          );
        },
      ));
      return;
    }

    _playSource(show, sourceToPlay);
    await openPlaybackScreen();
  }

  void onSourceLongPressed(Show show, Source source) {
    if (context.read<DeviceService>().isTv) {
      final catalog = context.read<CatalogService>();
      unawaited(TvInteractionModal.show(
        context,
        title: show.venue,
        subtitle: AppDateUtils.formatDate(show.date,
            settings: context.read<SettingsProvider>()),
        onPlay: () => _playSource(show, source),
        onRate: () async {
          await showDialog(
            context: context,
            builder: (context) => RatingDialog(
              initialRating: catalog.getRating(source.id),
              sourceId: source.id,
              sourceUrl:
                  source.tracks.isNotEmpty ? source.tracks.first.url : null,
              isPlayed: catalog.isPlayed(source.id),
              onRatingChanged: (newRating) {
                catalog.setRating(source.id, newRating);
              },
              onPlayedChanged: (bool newIsPlayed) {
                if (newIsPlayed != catalog.isPlayed(source.id)) {
                  catalog.togglePlayed(source.id);
                }
              },
            ),
          );
          if (context.mounted) {
            onSourceLongPressed(show, source);
          }
        },
      ));
      return;
    }
    _playSource(show, source);
  }

  void _playSource(Show show, Source source) {
    unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final key = showListProvider.getShowKey(show);

    showListProvider.setLoadingShow(key);
    if (show.sources.length > 1 && showListProvider.expandedShowKey != key) {
      showListProvider.expandShow(key);
      animationController.forward(from: 0.0);
    }
    audioProvider.playSource(show, source);
    if (context.read<DeviceService>().isTv) {
      audioProvider.requestPlaybackFocus();
    }
  }

  Future<dynamic> navigateTo(Widget screen, {bool instant = true}) async {
    // Pause global clock before navigating
    try {
      context.read<AnimationController>().stop();
    } catch (_) {}

    final isTv = context.read<DeviceService>().isTv;
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => screen,
        transitionDuration: (instant || isTv)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        transitionsBuilder: (instant || isTv)
            ? (context, animation, secondaryAnimation, child) => child
            : (context, animation, secondaryAnimation, child) {
                const begin = Offset(0.0, 1.0);
                const end = Offset.zero;
                const curve = Curves.easeInOut;
                var tween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                return SlideTransition(
                    position: animation.drive(tween), child: child);
              },
      ),
    );

    // Resume clock on return if needed
    if (mounted) {
      try {
        final controller = context.read<AnimationController>();
        unawaited(controller.repeat());
      } catch (_) {}
    }

    return result;
  }

  Future<void> openPlaybackScreen() async {
    if (context.read<DeviceService>().isTv) {
      // No full-screen player on TV.
      return;
    }

    final widgetInstance = widget as dynamic;
    if (widgetInstance.onOpenPlaybackRequested != null) {
      widgetInstance.onOpenPlaybackRequested!();
      return;
    }

    await navigateTo(const PlaybackScreen(), instant: false);

    if (!mounted) return;
    collapseAndScrollOnReturn();
  }

  void collapseAndScrollOnReturn() {
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final currentShow = audioProvider.currentShow;

    if (currentShow == null) return;

    if (currentShow.sources.length > 1) {
      final key = showListProvider.getShowKey(currentShow);
      if (showListProvider.expandedShowKey != key) {
        showListProvider.expandShow(key);
        animationController.forward(from: 0.0);
      }
    } else if (showListProvider.expandedShowKey != null) {
      showListProvider.collapseCurrentShow();
      animationController.reverse();
    }

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          final freshCurrentShow = context.read<AudioProvider>().currentShow;
          if (freshCurrentShow != null) {
            unawaited(reliablyScrollToShow(freshCurrentShow));
          }
        }
      }
    });
  }

  void handleRandomShowSelection(({Show show, Source source}) selection) {
    if (!mounted) return;

    if (AppLifecycleState.paused == WidgetsBinding.instance.lifecycleState ||
        AppLifecycleState.inactive == WidgetsBinding.instance.lifecycleState) {
      logger.i(
          'ShowListScreen: App in background. Deferring random show selection.');
      setState(() => _pendingBackgroundSelection = selection);
      return;
    }

    final showListProvider = context.read<ShowListProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final isSimpleTheme = settingsProvider.performanceMode;
    final show = selection.show;

    if (show.sources.length > 1) {
      showListProvider.expandShow(showListProvider.getShowKey(show));
      if (!isSimpleTheme) {
        animationController.forward(from: 0.0);
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        reliablyScrollToShow(
          show,
          duration: isSimpleTheme
              ? const Duration(milliseconds: 120)
              : const Duration(milliseconds: 1200),
        );
      }
    });

    if (!isRandomShowLoading) {
      context.read<ShowListProvider>().setIsChoosingRandomShow(true);
      setState(() {
        lastRollStartTime = DateTime.now();
        isRandomShowLoading = true;
        isResettingRandomShow = false;
        isAnimationTest = false;
      });
    }
  }

  Future<void> handlePlayRandomShow() async {
    unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.isChoosingRandomShow || isRandomShowLoading) {
      return;
    }

    if (audioProvider.pendingRandomShowRequest != null) {
      await audioProvider.playPendingSelection();
      return;
    }

    if (!showListProvider.hasUsedRandomButton) {
      showListProvider.markRandomButtonUsed();
    }

    if (showListProvider.expandedShowKey != null) {
      showListProvider.collapseCurrentShow();
      unawaited(animationController.reverse());
    }

    logger.d(
        'ShowListScreen: handlePlayRandomShow() - Triggering random show roll.');
    showListProvider.setIsChoosingRandomShow(true);
    setState(() {
      lastRollStartTime = DateTime.now();
      isRandomShowLoading = true;
      isResettingRandomShow = false;
      userInitiatedRoll = true;
    });

    final isTv = context.read<DeviceService>().isTv;
    await audioProvider.playRandomShow(
        filterBySearch: true, delayPlayback: isTv);
  }

  Future<bool> handleClipboardPlayback(String text,
      {required VoidCallback onSuccess}) async {
    setState(() => showPasteFeedback = true);
    final audioProvider = context.read<AudioProvider>();
    final success = await audioProvider.playFromShareString(text);

    if (mounted) {
      if (success) {
        unawaited(AppHaptics.mediumImpact(context.read<DeviceService>()));
        searchController.clear();
        searchFocusNode.unfocus();
        context.read<ShowListProvider>().setSearchVisible(false);
        setState(() => showPasteFeedback = false);

        final show = audioProvider.currentShow;
        final source = audioProvider.currentSource;
        if (show != null && source != null) {
          handleRandomShowSelection((show: show, source: source));
        }
        onSuccess();
      } else {
        setState(() => showPasteFeedback = false);
      }
    }
    return success;
  }

  void onSearchSubmitted(String text) {
    if (text.isEmpty) return;
    if (text.contains('https://archive.org/details/gd')) {
      handleClipboardPlayback(text, onSuccess: openPlaybackScreen);
      return;
    }

    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.filteredShows.isNotEmpty) {
      AppHaptics.selectionClick(context.read<DeviceService>());
      final topShow = showListProvider.filteredShows.first;
      if (topShow.sources.isNotEmpty) {
        final topSource = topShow.sources.first;
        audioProvider.playSource(topShow, topSource);
        handleRandomShowSelection((show: topShow, source: topSource));
        if (mounted && !context.read<DeviceService>().isTv) {
          openPlaybackScreen();
        }
        searchController.clear();
        searchFocusNode.unfocus();
      }
    }
  }
}
