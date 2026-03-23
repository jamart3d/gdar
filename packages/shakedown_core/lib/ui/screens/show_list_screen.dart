import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/screens/settings_screen.dart';

import 'package:shakedown_core/utils/color_generator.dart';
import 'package:shakedown_core/utils/logger.dart';
import 'package:shakedown_core/utils/utils.dart';

import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/ui/screens/show_list/show_list_logic_mixin.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_shell.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_body.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';

class ShowListScreen extends StatefulWidget {
  final bool isPane;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onFocusLeft;
  final VoidCallback? onFocusPlayback;
  final bool showFruitTabBar;
  final VoidCallback? onOpenPlaybackRequested;
  final VoidCallback? onSettingsRequested;
  final bool skipStartupRandom;

  const ShowListScreen({
    super.key,
    this.isPane = false,
    this.scrollbarFocusNode,
    this.onFocusLeft,
    this.onFocusPlayback,
    this.showFruitTabBar = true,
    this.onOpenPlaybackRequested,
    this.onSettingsRequested,
    this.skipStartupRandom = false,
  });

  @override
  State<ShowListScreen> createState() => ShowListScreenState();
}

class ShowListScreenState extends State<ShowListScreen>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        ShowListLogicMixin<ShowListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  bool _pendingSearchSync = false;
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  @override
  ItemScrollController get itemScrollController => _itemScrollController;
  @override
  AnimationController get animationController => _animationController;
  @override
  TextEditingController get searchController => _searchController;
  @override
  FocusNode get searchFocusNode => _searchFocusNode;

  late AnimationController _animationController;
  final Map<int, FocusNode> _showFocusNodes =
      {}; // Added for TV focus management

  void focusShow(int index, {bool shouldScroll = true}) {
    if (index < 0) return;

    bool nodeCreated = false;
    // Ensure the focus node exists
    if (!_showFocusNodes.containsKey(index)) {
      _showFocusNodes[index] = FocusNode();
      nodeCreated = true;
    }

    // Scroll to the show to ensure it's built and visible
    if (shouldScroll) {
      _itemScrollController.jumpTo(index: index, alignment: 0.3);
    }

    if (nodeCreated) {
      setState(() {});
    }

    // Wait for a frame to ensure the Focus widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _showFocusNodes[index]?.requestFocus();
      }
    });
  }

  void focusCurrentShow() {
    if (!mounted) return;
    final currentShow = _audioProvider.currentShow;
    if (currentShow != null) {
      final index = _showListProvider.filteredShows.indexOf(currentShow);
      if (index != -1) {
        focusShow(index);
        return;
      }
    }
    // Fallback: focus first visible show
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisible = positions
          .where((p) => p.itemTrailingEdge > 0)
          .reduce((min, p) => p.index < min.index ? p : min)
          .index;
      focusShow(firstVisible, shouldScroll: false);
    }
  }

  void focusShowByObject(Show show) {
    final index = _showListProvider.filteredShows.indexOf(show);
    if (index != -1) {
      focusShow(index);
    }
  }

  void _onShowFocused(int index) {
    if (!mounted || !context.read<DeviceService>().isTv) return;

    // Check visibility and scroll if needed
    final positions = _itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    final targetPos = positions.where((p) => p.index == index).toList();

    bool needsScroll = true;
    if (targetPos.isNotEmpty) {
      final pos = targetPos.first;
      // If comfortably visible (between 10% and 90% of viewport), don't scroll
      if (pos.itemLeadingEdge > 0.1 && pos.itemTrailingEdge < 0.9) {
        needsScroll = false;
      }
    }

    if (needsScroll) {
      _itemScrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOutCubic,
        alignment: 0.3, // Keep focused items 30% from the top
      );
    }
  }

  late Animation<double> _animation;
  late AnimationController _searchPulseController;
  late Animation<double> _searchPulseAnimation;
  late AnimationController _randomPulseController;
  late Animation<double> _randomPulseAnimation;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<({Show show, Source source})>? _randomShowSubscription;
  late ShowListProvider _showListProvider;
  late AudioProvider _audioProvider;

  bool _randomShowPlayed = false;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    // Search icon pulse animation
    _searchPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _searchPulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _searchPulseController, curve: Curves.easeInOut),
    );

    // Random button pulse animation (Material 3 style)
    _randomPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _randomPulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _randomPulseController,
        curve: Curves.easeInOutSine, // Smooth breathing curve
      ),
    );

    // Initial check for random button usage
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final showListProvider = context.read<ShowListProvider>();
        if (!showListProvider.hasUsedRandomButton) {
          _randomPulseController.repeat(reverse: true);
        }
        // Sync local animation state with provider
        _syncSearchState();
      }
    });

    // Subscribe to random show requests from AudioProvider (unified logic)
    _audioProvider = context.read<AudioProvider>();
    _randomShowSubscription = _audioProvider.randomShowRequestStream.listen((
      selection,
    ) {
      if (mounted) {
        handleRandomShowSelection(selection);
      }
    });

    // Subscribe to ShowListProvider for search visibility changes
    _showListProvider = context.read<ShowListProvider>();
    _showListProvider.addListener(_syncSearchState);

    _audioProvider.addListener(_onAudioProviderUpdate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final pending = _audioProvider.pendingRandomShowRequest;
        if (pending != null) {
          logger.i('ShowListScreen: Found pending random selection on mount.');
          handleRandomShowSelection(pending);
          _audioProvider.clearPendingRandomShowRequest();
        }
      }
    });

    final settingsProvider = context.read<SettingsProvider>();

    // Check for a saved engine-restart resume session first
    final resumeSession = settingsProvider.consumeResumeSession();
    if (resumeSession != null) {
      _handleResumeSession(resumeSession, _showListProvider, _audioProvider);
    } else if (settingsProvider.playRandomOnStartup &&
        !widget.skipStartupRandom) {
      _handleStartupRandomPlay(_showListProvider, _audioProvider);
    }

    _searchController.addListener(() {
      final text = _searchController.text;
      final isPastePattern = RegExp(
        r'(19[6-9]\d|20[0-2]\d).*?-\s*\d+',
      ).hasMatch(text);
      final hasArchiveUrl = text.contains('archive.org/details/gd');

      if (isPastePattern || hasArchiveUrl) {
        handleClipboardPlayback(text, onSuccess: openPlaybackScreen);
      } else {
        context.read<ShowListProvider>().setSearchQuery(text);
      }
    });

    _searchFocusNode.addListener(() {
      setState(() {});
    });

    _playerStateSubscription = _audioProvider.playerStateStream.listen((state) {
      _onPlayerStateChange(state);
    });
  }

  // Resume a session saved before an engine-restart browser reload.
  void _handleResumeSession(
    ({String sourceId, int trackIndex, int positionMs}) session,
    ShowListProvider showListProvider,
    AudioProvider audioProvider,
  ) {
    void resumeWhenReady() {
      if (showListProvider.isLoading) return;
      showListProvider.removeListener(resumeWhenReady);

      for (final show in showListProvider.allShows) {
        for (final source in show.sources) {
          if (source.id == session.sourceId) {
            logger.i(
              'Resuming session: ${show.name} '
              'track=${session.trackIndex} '
              'pos=${session.positionMs}ms',
            );
            audioProvider.playSource(
              show,
              source,
              initialIndex: session.trackIndex,
              initialPosition: Duration(milliseconds: session.positionMs),
            );
            // Navigate to playback screen after resume
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) openPlaybackScreen();
            });
            return;
          }
        }
      }
      logger.w(
        'Resume session: source ${session.sourceId} '
        'not found, skipping.',
      );
    }

    if (!showListProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        resumeWhenReady();
      });
    } else {
      showListProvider.addListener(resumeWhenReady);
    }
  }

  // Refactored helper to handling startup play to keep init clean
  void _handleStartupRandomPlay(
    ShowListProvider showListProvider,
    AudioProvider audioProvider,
  ) {
    void playRandomShowAndRemoveListener() {
      if (!_randomShowPlayed &&
          !showListProvider.isLoading &&
          showListProvider.error == null) {
        setState(() {
          _randomShowPlayed = true;
        });
        logger.i('Startup setting enabled, playing random show.');
        audioProvider.playRandomShow();
        showListProvider.removeListener(playRandomShowAndRemoveListener);
      } else if (!showListProvider.isLoading) {
        showListProvider.removeListener(playRandomShowAndRemoveListener);
      }
    }

    if (!showListProvider.isLoading) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        playRandomShowAndRemoveListener();
      });
    } else {
      showListProvider.addListener(playRandomShowAndRemoveListener);
    }
  }

  void _onAudioProviderUpdate() {
    final audioProvider = context.read<AudioProvider>();
    if (audioProvider.error != null) {
      if (mounted) _showErrorSnackBar(audioProvider.error!);
      audioProvider.clearError();
    }

    // Handle Dice Reset for TV (Delayed Playback)
    // On TV, AudioProvider.playRandomShow sets delayPlayback: true.
    // This means ProcessingState.ready is NEVER reached because we haven't
    // called playSource yet. We must reset the dice when the provider
    // signals that the selection is complete (even if delayed).
    if (isRandomShowLoading && !isResettingRandomShow) {
      final isTv = context.read<DeviceService>().isTv;
      if (isTv && audioProvider.pendingRandomShowRequest == null) {
        logger.i(
          'ShowListScreen: Resetting dice for TV (Delayed Selection Complete)',
        );
        _resetDiceAnimation();
      }
    }
  }

  void _resetDiceAnimation() {
    if (!mounted) return;
    isResettingRandomShow = true;

    // Minimum 2s roll duration for visual consistency
    final now = DateTime.now();
    final startTime = lastRollStartTime ?? now;
    final elapsed = now.difference(startTime).inMilliseconds;
    final remaining = math.max(0, 2000 - elapsed);

    final showListProvider = context.read<ShowListProvider>();

    if (remaining > 0) {
      Future.delayed(Duration(milliseconds: remaining), () {
        if (mounted) {
          showListProvider.setIsChoosingRandomShow(false);
          setState(() {
            isRandomShowLoading = false;
            isResettingRandomShow = false;
            userInitiatedRoll = false;
          });
        }
      });
    } else {
      showListProvider.setIsChoosingRandomShow(false);
      setState(() {
        isRandomShowLoading = false;
        isResettingRandomShow = false;
        userInitiatedRoll = false;
      });
    }
  }

  void _onPlayerStateChange(PlayerState state) {
    if (!mounted) return;
    final processingState = state.processingState;

    if (isRandomShowLoading && !isResettingRandomShow) {
      // If running a visual test, ignore player state (which might be idle)
      if (isAnimationTest) return;

      if (processingState == ProcessingState.ready ||
          processingState == ProcessingState.completed) {
        _resetDiceAnimation();
      }
    }

    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.loadingShowKey != null &&
        showListProvider.loadingShowKey ==
            (audioProvider.currentShow != null
                ? showListProvider.getShowKey(audioProvider.currentShow!)
                : null)) {
      if (processingState == ProcessingState.ready ||
          processingState == ProcessingState.idle) {
        showListProvider.setLoadingShow(null);
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    showMessage(context, msg);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _showListProvider.removeListener(_syncSearchState);
    _audioProvider.removeListener(_onAudioProviderUpdate);

    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.stop();
    _animationController.dispose();
    _searchPulseController.stop();
    _searchPulseController.dispose();
    _randomPulseController.stop();
    _randomPulseController.dispose();
    _randomShowSubscription?.cancel();
    _playerStateSubscription?.cancel();
    for (var node in _showFocusNodes.values) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> scrollToCurrentShowFromTab() async {
    if (!mounted) return;
    final settings = context.read<SettingsProvider>();
    final showListProvider = context.read<ShowListProvider>();
    final currentShow = context.read<AudioProvider>().currentShow;
    if (currentShow == null) return;

    // Wait for the list to mount/attach after tab transition.
    for (int i = 0; i < 20 && !_itemScrollController.isAttached; i++) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
    }

    if (!_itemScrollController.isAttached) return;

    final targetIndex = showListProvider.filteredShows.indexOf(currentShow);
    if (targetIndex == -1) return;

    if (!mounted) return;
    if (settings.performanceMode) {
      _itemScrollController.jumpTo(index: targetIndex, alignment: 0.3);
      return;
    }

    await reliablyScrollToShow(
      currentShow,
      duration: const Duration(milliseconds: 700),
    );
  }

  void _syncSearchState() {
    if (!mounted) return;
    final phase = SchedulerBinding.instance.schedulerPhase;
    if (phase == SchedulerPhase.persistentCallbacks ||
        phase == SchedulerPhase.midFrameMicrotasks) {
      _scheduleSearchSync();
      return;
    }
    _syncSearchStateNow();
  }

  void _scheduleSearchSync() {
    if (_pendingSearchSync) return;
    _pendingSearchSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _pendingSearchSync = false;
      if (!mounted) return;
      _syncSearchStateNow();
    });
  }

  void _syncSearchStateNow() {
    final showListProvider = context.read<ShowListProvider>();
    final isVisible = showListProvider.isSearchVisible;

    if (isVisible) {
      if (!_searchFocusNode.hasFocus) _searchFocusNode.requestFocus();
      if (!_searchPulseController.isAnimating) {
        _searchPulseController.repeat(reverse: true);
      }
    } else {
      if (_searchFocusNode.hasFocus) _searchFocusNode.unfocus();
      if (_searchPulseController.isAnimating) {
        _searchPulseController.stop();
        _searchPulseController.reset();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    Color? backgroundColor;
    // Only apply custom background color if NOT in "True Black" mode.
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (!isFruit &&
        !isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        audioProvider.currentShow != null) {
      String seed = audioProvider.currentShow!.name;
      if (audioProvider.currentShow!.sources.length > 1 &&
          audioProvider.currentSource != null) {
        seed = audioProvider.currentSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(
        seed,
        brightness: Theme.of(context).brightness,
      );
    }

    return ShowListShell(
      isPane: widget.isPane,
      backgroundColor: widget.isPane
          ? Colors.transparent
          : (backgroundColor ?? Theme.of(context).scaffoldBackgroundColor),
      randomPulseAnimation: _randomPulseAnimation,
      searchPulseAnimation: _searchPulseAnimation,
      isRandomShowLoading: isRandomShowLoading,
      enableDiceHaptics: userInitiatedRoll,
      onRandomPlay: handlePlayRandomShow,
      onToggleSearch: toggleSearch,
      searchController: _searchController,
      searchFocusNode: _searchFocusNode,
      onSearchSubmitted: onSearchSubmitted,
      animationDuration: _animationDuration,
      onOpenPlaybackScreen:
          widget.onOpenPlaybackRequested ?? openPlaybackScreen,
      showPasteFeedback: showPasteFeedback,
      onTitleTap:
          widget.onSettingsRequested ??
          () => navigateTo(const SettingsScreen()),
      scrollbarFocusNode: widget.scrollbarFocusNode,
      showFruitTabBar: widget.showFruitTabBar,
      body: ShowListBody(
        showListProvider: showListProvider,
        audioProvider: audioProvider,
        settingsProvider: settingsProvider,
        itemScrollController: _itemScrollController,
        itemPositionsListener: _itemPositionsListener,
        animation: _animation,
        onShowTapped: onShowTapped,
        scrollbarFocusNode: widget.scrollbarFocusNode,
        onFocusLeft: widget.onFocusLeft,
        onFocusRight: widget.onFocusPlayback,
        onCardLongPressed: onCardLongPressed,
        onSourceTapped: onSourceTapped,
        onSourceLongPressed: onSourceLongPressed,
        showFocusNodes: _showFocusNodes,
        onFocusShow: focusShow,
        onShowFocused: _onShowFocused,
        topPadding: isFruit ? (MediaQuery.paddingOf(context).top + 80) : 0,
      ),
    );
  }
}
