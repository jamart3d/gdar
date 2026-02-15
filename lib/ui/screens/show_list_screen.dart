import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';

import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/utils/logger.dart';

import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/ui/screens/show_list/show_list_logic_mixin.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_shell.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_body.dart';

class ShowListScreen extends StatefulWidget {
  final bool isPane;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onFocusLeft;

  const ShowListScreen({
    super.key,
    this.isPane = false,
    this.scrollbarFocusNode,
    this.onFocusLeft,
  });

  @override
  State<ShowListScreen> createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen>
    with
        TickerProviderStateMixin,
        WidgetsBindingObserver,
        ShowListLogicMixin<ShowListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
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

  void _focusShow(int index) {
    if (index < 0) return;

    // Ensure the focus node exists
    if (!_showFocusNodes.containsKey(index)) {
      _showFocusNodes[index] = FocusNode();
    }

    // Scroll to the show to ensure it's built and visible
    _itemScrollController.jumpTo(index: index, alignment: 0.3);

    // Wait for a frame to ensure the Focus widget is mounted
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFocusNodes[index]?.requestFocus();
    });
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
      CurvedAnimation(
        parent: _searchPulseController,
        curve: Curves.easeInOut,
      ),
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
    _randomShowSubscription =
        _audioProvider.randomShowRequestStream.listen((selection) {
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
    if (settingsProvider.playRandomOnStartup) {
      _handleStartupRandomPlay(_showListProvider, _audioProvider);
    }

    _searchController.addListener(() {
      final text = _searchController.text;
      final isPastePattern =
          RegExp(r'(19[6-9]\d|20[0-2]\d).*?-\s*\d+').hasMatch(text);
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

  // Refactored helper to handling startup play to keep init clean
  void _handleStartupRandomPlay(
      ShowListProvider showListProvider, AudioProvider audioProvider) {
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
    final audioProvider = context.read<AudioProvider>(); // safe?
    if (audioProvider.error != null) {
      if (mounted) _showErrorSnackBar(audioProvider.error!);
      audioProvider.clearError();
    }
  }

  void _onPlayerStateChange(PlayerState state) {
    if (!mounted) return;
    final processingState = state.processingState;

    if (isRandomShowLoading) {
      // If running a visual test, ignore player state (which might be idle)
      if (isAnimationTest) return;

      if (processingState == ProcessingState.ready ||
          processingState == ProcessingState.completed) {
        // Minimum 2s roll duration for visual consistency
        final now = DateTime.now();
        final startTime = lastRollStartTime ?? now;
        final elapsed = now.difference(startTime).inMilliseconds;
        final remaining = math.max(0, 2000 - elapsed);

        final showListProvider = context.read<ShowListProvider>();

        if (remaining > 0) {
          logger.d(
              'ShowListScreen: Player READY fast. Delaying reset by ${remaining}ms.');
          Future.delayed(Duration(milliseconds: remaining), () {
            if (mounted) {
              showListProvider.setIsChoosingRandomShow(false);
              setState(() {
                isRandomShowLoading = false;
                userInitiatedRoll = false;
              });
            }
          });
        } else {
          showListProvider.setIsChoosingRandomShow(false);
          setState(() {
            isRandomShowLoading = false;
            userInitiatedRoll = false;
          });
        }
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
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style:
              TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
      backgroundColor: Theme.of(context).colorScheme.errorContainer,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(12),
      action: SnackBarAction(
          label: 'Dismiss',
          textColor: Theme.of(context).colorScheme.onErrorContainer,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar()),
    ));
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

  void _syncSearchState() {
    if (!mounted) return;
    final isVisible = context.read<ShowListProvider>().isSearchVisible;

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
    // Force rebuild to update UI if needed (though existing build uses provider)
    // Actually _buildSearchBar uses provider now? I need to update build too.
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

    if (!isTrueBlackMode &&
        settingsProvider.highlightCurrentShowCard &&
        audioProvider.currentShow != null) {
      String seed = audioProvider.currentShow!.name;
      if (audioProvider.currentShow!.sources.length > 1 &&
          audioProvider.currentSource != null) {
        seed = audioProvider.currentSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }

    return ShowListShell(
      isPane: widget.isPane,
      backgroundColor: backgroundColor ?? Theme.of(context).colorScheme.surface,
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
      onOpenPlaybackScreen: openPlaybackScreen,
      showPasteFeedback: showPasteFeedback,
      onTitleTap: () => navigateTo(const SettingsScreen()),
      scrollbarFocusNode: widget.scrollbarFocusNode,
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
        onCardLongPressed: onCardLongPressed,
        onSourceTapped: onSourceTapped,
        onSourceLongPressed: onSourceLongPressed,
        showFocusNodes: _showFocusNodes,
        onFocusShow: _focusShow,
      ),
    );
  }
}
