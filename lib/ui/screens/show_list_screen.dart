import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/screens/track_list_screen.dart';

import 'package:shakedown/ui/widgets/mini_player.dart';
import 'package:shakedown/ui/widgets/show_list_card.dart';
import 'package:shakedown/ui/widgets/swipe_action_background.dart';
import 'package:shakedown/ui/widgets/show_list_item_details.dart';
import 'package:shakedown/utils/color_generator.dart';
import 'package:shakedown/utils/logger.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ShowListScreen extends StatefulWidget {
  const ShowListScreen({super.key});

  @override
  State<ShowListScreen> createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  late AnimationController _searchPulseController;
  late Animation<double> _searchPulseAnimation;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<({Show show, Source source})>? _randomShowSubscription;

  bool _isSearchVisible = false;
  bool _isRandomShowLoading = false;
  bool _randomShowPlayed = false;

  // Track pending selection for when app resumes from background
  ({Show show, Source source})? _pendingBackgroundSelection;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Height constants for calculation
  static const double _baseSourceHeaderHeight = 59.0;
  static const double _listVerticalPadding = 16.0;

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

    // Subscribe to random show requests from AudioProvider (unified logic)
    final audioProvider = context.read<AudioProvider>();
    _randomShowSubscription =
        audioProvider.randomShowRequestStream.listen((selection) {
      if (mounted) {
        _handleRandomShowSelection(selection);
      }
    });

    // Check for any pending selection that might have happened during boot/restart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final pending = audioProvider.pendingRandomShowRequest;
        if (pending != null) {
          logger.i('ShowListScreen: Found pending random selection on mount.');
          _handleRandomShowSelection(pending);
          audioProvider.clearPendingRandomShowRequest();
        }
      }
    });

    // Play random show on startup if enabled
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.playRandomOnStartup) {
      final showListProvider = context.read<ShowListProvider>();

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
          // If loading is finished but we couldn't play, still remove the listener
          showListProvider.removeListener(playRandomShowAndRemoveListener);
        }
      }

      // If shows are already loaded, play immediately. Otherwise, add a listener.
      if (!showListProvider.isLoading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          playRandomShowAndRemoveListener();
        });
      } else {
        showListProvider.addListener(playRandomShowAndRemoveListener);
      }
    }

    _searchController.addListener(() {
      final text = _searchController.text;

      // Detect share strings: look for year pattern (1960-2030) followed by " - " and digits (SHNID)
      // This matches formats like: "... - Fri, Jun 20, 1980 - 156397[track]..."
      final isPastePattern =
          RegExp(r'(19[6-9]\d|20[0-2]\d).*?-\s*\d+').hasMatch(text);

      // Also check for archive.org URLs
      final hasArchiveUrl = text.contains('archive.org/details/gd');

      if (isPastePattern || hasArchiveUrl) {
        _handleClipboardPlayback(text);
      } else {
        context.read<ShowListProvider>().setSearchQuery(text);
      }
    });

    _searchFocusNode.addListener(() {
      // Rebuild when focus changes to hide/show MiniPlayer
      setState(() {});
    });

    // Listen to player state to manage loading indicators
    audioProvider.addListener(() {
      if (audioProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              audioProvider.error!,
              style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer),
            ),
            backgroundColor: Theme.of(context).colorScheme.errorContainer,
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.all(12),
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Theme.of(context).colorScheme.onErrorContainer,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
        audioProvider.clearError();
      }
    });

    _playerStateSubscription = audioProvider.playerStateStream.listen((state) {
      if (!mounted) return;
      final processingState = state.processingState;

      // Handle AppBar's random play indicator
      if (_isRandomShowLoading) {
        if (processingState == ProcessingState.ready ||
            processingState == ProcessingState.completed ||
            processingState == ProcessingState.idle) {
          setState(() => _isRandomShowLoading = false);
        }
      }

      // Handle ShowListCard's loading indicator
      final showListProvider = context.read<ShowListProvider>();
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
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    _searchPulseController.dispose();
    _randomShowSubscription?.cancel();
    _playerStateSubscription?.cancel();
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
      _handleRandomShowSelection(selection);
    }
  }

  void _toggleSearch() {
    HapticFeedback.lightImpact(); // Subtle UI state change feedback
    setState(() {
      _isSearchVisible = !_isSearchVisible;
      if (_isSearchVisible) {
        _searchFocusNode.requestFocus();
        _searchPulseController.repeat(reverse: true); // Start pulsing
      } else {
        _searchFocusNode.unfocus();
        _searchPulseController.stop();
        _searchPulseController.reset(); // Stop pulsing
      }
    });
  }

  double _calculateExpandedHeight(Show show) {
    if (show.sources.length <= 1) return 0.0;
    final settingsProvider = context.read<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
    final sourceHeaderHeight = _baseSourceHeaderHeight * scaleFactor;
    return (show.sources.length * sourceHeaderHeight) + _listVerticalPadding;
  }

  /// Scrolls a show into view, centering it in the viewport.
  Future<void> _reliablyScrollToShow(Show show,
      {Duration duration = _animationDuration}) async {
    final showListProvider = context.read<ShowListProvider>();
    final targetIndex = showListProvider.filteredShows.indexOf(show);
    logger.i('Attempting to scroll to "${show.name}" at index $targetIndex.');

    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list for scrolling.');
      return;
    }

    // Align to (0.4) if collapsed.
    // If expanded, adjust alignment based on number of sources to show more context.
    final key = showListProvider.getShowKey(show);
    final isExpanded = showListProvider.expandedShowKey == key;
    double alignment = 0.4;

    if (isExpanded) {
      if (show.sources.length > 4) {
        alignment = 0.05; // Was 0.02 - Top but with more breathing room
      } else if (show.sources.length > 2) {
        alignment = 0.15; // Was 0.20 - Upper area
      } else if (show.sources.length > 1) {
        alignment = 0.25; // Was 0.35 - Above center
      }
    }

    try {
      await _itemScrollController.scrollTo(
        index: targetIndex,
        duration: duration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: alignment,
      );
      logger.i(
          'Scroll animation initiated for item at index $targetIndex with duration ${duration.inMilliseconds}ms.');
    } catch (e) {
      logger.e('Error during scroll to show: $e');
    }
  }

  /// Handles tapping on a show card based on the current playback state and show structure.
  Future<void> _onShowTapped(Show show) async {
    final audioProvider = context.read<AudioProvider>();
    final showListProvider = context.read<ShowListProvider>();
    final isPlayingThisShow = audioProvider.currentShow == show;
    final key = showListProvider.getShowKey(show);
    final isExpanded = showListProvider.expandedShowKey == key;

    // Tapping never directly plays a show.
    // It either expands, navigates to track list, or goes to player if already playing.
    if (isPlayingThisShow) {
      if (show.sources.length > 1) {
        if (isExpanded) {
          await _openPlaybackScreen(); // Go to player if already playing and expanded
        } else {
          await _handleShowExpansion(
              show); // Expand if playing and not expanded
        }
      } else {
        await _openPlaybackScreen(); // Go to player if playing single source show
      }
    } else {
      // Not playing this show, so expand or go to track list.
      if (show.sources.length > 1) {
        await _handleShowExpansion(show);
      } else {
        final shouldOpenPlayer = await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                TrackListScreen(show: show, source: show.sources.first),
          ),
        );
        if (shouldOpenPlayer == true && mounted) {
          await _openPlaybackScreen();
        }
      }
    }
  }

  /// Manages the logic for expanding and collapsing a show card.
  Future<void> _handleShowExpansion(Show show) async {
    final showListProvider = context.read<ShowListProvider>();
    final previouslyExpanded = showListProvider.expandedShowKey;
    final key = showListProvider.getShowKey(show);
    final isCollapsingCurrent = previouslyExpanded == key;

    // If tapping an already expanded show, collapse it.
    if (isCollapsingCurrent) {
      HapticFeedback.selectionClick(); // Confirm collapse action
      showListProvider.collapseCurrentShow();
      _animationController.reverse();
      return;
    }

    // If tapping a new or collapsed show, expand it.
    HapticFeedback.selectionClick(); // Confirm expand action
    final wasSomethingExpanded = previouslyExpanded != null;
    showListProvider.toggleShowExpansion(key);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      // Animate it open. If another was open, it closes instantly and this one opens.
      if (wasSomethingExpanded) {
        await _animationController.forward(from: 0.0);
      } else {
        await _animationController.forward();
      }
      if (!mounted) return;
      await _reliablyScrollToShow(show);
    });
  }

  /// Handles tapping a source row inside an expanded show card.
  Future<void> _onSourceTapped(Show show, Source source) async {
    final audioProvider = context.read<AudioProvider>();
    final isPlayingThisSource = audioProvider.currentSource?.id == source.id;

    if (isPlayingThisSource) {
      await _openPlaybackScreen();
    } else {
      // Create a "virtual" show containing only the selected source to pass
      // to the track list screen.
      final singleSourceShow = Show(
        name: show.name,
        artist: show.artist,
        date: show.date,
        venue: show.venue,
        sources: [source],
        hasFeaturedTrack: show.hasFeaturedTrack,
      );
      final shouldOpenPlayer = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackListScreen(
              show: singleSourceShow, source: singleSourceShow.sources.first),
        ),
      );
      if (shouldOpenPlayer == true && mounted) {
        await _openPlaybackScreen();
      }
    }
  }

  /// Plays a random source on long press if the show has multiple sources,
  /// otherwise plays the first source.
  Future<void> _onCardLongPressed(Show show) async {
    logger.d('Long pressed on show card: ${show.name}');
    if (show.sources.isEmpty) return;

    Source sourceToPlay;
    if (show.sources.length > 1) {
      final random = Random();
      final index = random.nextInt(show.sources.length);
      sourceToPlay = show.sources[index];
      logger.i(
          'Multiple sources found. Playing random source: ${sourceToPlay.id}');
    } else {
      sourceToPlay = show.sources.first;
    }
    _playSource(show, sourceToPlay);
  }

  /// Plays a specific source from a show on long press inside an expanded card.
  void _onSourceLongPressed(Show show, Source source) {
    logger.d('Long pressed on source row: ${source.id}');
    _playSource(show, source);
  }

  /// Common logic to play a source and update the UI.
  void _playSource(Show show, Source source) {
    HapticFeedback.mediumImpact();
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final key = showListProvider.getShowKey(show);

    showListProvider.setLoadingShow(key);
    // Expand the parent show if it's not already.
    if (showListProvider.expandedShowKey != key) {
      showListProvider.expandShow(key);
      _animationController.forward(from: 0.0);
    }
    audioProvider.playSource(show, source);
  }

  Future<void> _openPlaybackScreen() async {
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlaybackScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOut;

        var tween =
            Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

        return SlideTransition(
          position: animation.drive(tween),
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 300),
    ));

    // This code runs *after* the PlaybackScreen is popped.
    if (!mounted) return;
    _collapseAndScrollOnReturn();
  }

  /// Collapses/Adds show and scrolls to the current show on return.
  void _collapseAndScrollOnReturn() {
    logger.i(
        'ShowListScreen: Returning from playback, scrolling to current show...');
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final currentShow = audioProvider.currentShow;

    if (currentShow == null) {
      logger.w('ShowListScreen: No current show to scroll to');
      return;
    }

    // If multi-source, ensure it's expanded.
    if (currentShow.sources.length > 1) {
      final key = showListProvider.getShowKey(currentShow);
      if (showListProvider.expandedShowKey != key) {
        showListProvider.expandShow(key);
        _animationController.forward(from: 0.0);
      }
    } else {
      // If single source (or no sources), collapse any expanded show.
      if (showListProvider.expandedShowKey != null) {
        showListProvider.collapseCurrentShow();
        _animationController.reverse();
      }
    }

    // After a short delay to allow the animation to start and layout to settle,
    // scroll to the currently playing show.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        // yield to ensure layout pass is complete
        await Future.delayed(const Duration(milliseconds: 100));
        if (mounted) {
          // Re-fetch the current show to ensure we don't scroll to a stale one
          // if the track changed during the delay.
          final freshCurrentShow = context.read<AudioProvider>().currentShow;
          if (freshCurrentShow != null) {
            _reliablyScrollToShow(freshCurrentShow);
          }
        }
      }
    });
  }

  void _handleRandomShowSelection(({Show show, Source source}) selection) {
    if (!mounted) return;

    // Check lifecycle state. If hidden/paused, defer UI updates.
    final lifecycleState = WidgetsBinding.instance.lifecycleState;
    if (lifecycleState != null && lifecycleState != AppLifecycleState.resumed) {
      logger.i(
          'ShowListScreen: handleRandomShowSelection called in background ($lifecycleState). Deferring UI update.');
      _pendingBackgroundSelection = selection;
      return;
    }

    final showListProvider = context.read<ShowListProvider>();
    final show = selection.show;

    // 1. Expand UI if needed
    if (show.sources.length > 1) {
      showListProvider.expandShow(showListProvider.getShowKey(show));
      _animationController.forward(from: 0.0);
    }

    // 2. Scroll to show
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reliablyScrollToShow(show,
            duration: const Duration(milliseconds: 1000));
      }
    });

    // Ensure loading state is cleared
    setState(() => _isRandomShowLoading = false);
  }

  Future<void> _handlePlayRandomShow() async {
    HapticFeedback.mediumImpact();
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    // Check if a show is currently expanded and collapse it first.
    if (showListProvider.expandedShowKey != null) {
      showListProvider.collapseCurrentShow();
      _animationController.reverse();
    }

    setState(() => _isRandomShowLoading = true);

    // Call unified random playback logic.
    // ShowListScreen will react to the selection via the subscription in initState.
    final show = await audioProvider.playRandomShow(filterBySearch: true);

    if (show == null && mounted) {
      // If we failed, wait a moment before hiding the loading indicator to prevent flicker
      await Future.delayed(const Duration(milliseconds: 300));
      setState(() => _isRandomShowLoading = false);
    }
  }

  bool _showPasteFeedback = false; // Add class member

  Future<bool> _handleClipboardPlayback(String text) async {
    logger.i('ShowListScreen: Attempting clipboard playback for: "$text"');

    // 1. Show Top Notification
    setState(() => _showPasteFeedback = true);

    if (!mounted) return false;

    // 2. Start Processing (Delay is purely data fetching)
    final audioProvider = context.read<AudioProvider>();
    final success = await audioProvider.playFromShareString(text);

    // 3. Handle Result
    if (mounted) {
      if (success) {
        HapticFeedback.mediumImpact();
        _searchController.clear();
        _searchFocusNode.unfocus();
        setState(() {
          _isSearchVisible = false;
          _showPasteFeedback = false; // Hide on success before nav
        });

        // Trigger UI Parity
        final show = audioProvider.currentShow;
        final source = audioProvider.currentSource;
        if (show != null && source != null) {
          _handleRandomShowSelection((show: show, source: source));
        }

        _openPlaybackScreen();
      } else {
        // Hide feedback if failed (maybe show error snackbar here instead?)
        setState(() => _showPasteFeedback = false);
      }
    }
    return success;
  }

  void _onSearchSubmitted(String text) {
    logger.i('ShowListScreen: Search submitted: "$text"');
    if (text.isEmpty) return;

    // 1. Try clipboard playback first
    if (text.contains('https://archive.org/details/gd')) {
      _handleClipboardPlayback(text);
      return;
    }

    // 2. Otherwise, treat like "Play on Tap" for the first result
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    if (showListProvider.filteredShows.isNotEmpty) {
      HapticFeedback.selectionClick(); // Confirm search submit action
      final topShow = showListProvider.filteredShows.first;
      if (topShow.sources.isNotEmpty) {
        final topSource = topShow.sources.first;
        audioProvider.playSource(topShow, topSource);

        // Trigger UI Parity: Scroll to show and update selection state
        _handleRandomShowSelection((show: topShow, source: topSource));

        // Navigate to Playback Screen
        _openPlaybackScreen();

        _searchController.clear();
        _searchFocusNode.unfocus();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    if (settingsProvider.useSliverAppBar) {
      return _buildSliverLayout();
    } else {
      return _buildStandardLayout();
    }
  }

  List<Widget> _buildAppBarActions() {
    final colorScheme = Theme.of(context).colorScheme;
    return [
      if (_isRandomShowLoading)
        const Padding(
          padding: EdgeInsets.all(12.0),
          child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5)),
        )
      else
        IconButton(
          icon: const Icon(Icons.question_mark_rounded),
          onPressed: _handlePlayRandomShow,
        ),
      ScaleTransition(
        scale: _searchPulseAnimation,
        child: IconButton(
          icon: const Icon(Icons.search_rounded),
          isSelected: _isSearchVisible,
          style: _isSearchVisible
              ? IconButton.styleFrom(
                  backgroundColor: colorScheme.surfaceContainer,
                  shape: CircleBorder(
                    side: BorderSide(color: colorScheme.outline),
                  ),
                )
              : null,
          onPressed: _toggleSearch,
        ),
      ),
      IconButton(
        icon: const Icon(Icons.settings_rounded),
        onPressed: () async {
          // Pause global clock before navigating to generic pages (Settings)
          // to prevent "visual jumps" when returning.
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

          // Resume clock on return
          if (mounted) {
            try {
              final controller = context.read<AnimationController>();
              if (!controller.isAnimating) controller.repeat();
            } catch (_) {}
          }
        },
      ),
    ];
  }

  Widget _buildSearchBar() {
    final settingsProvider = context.watch<SettingsProvider>();
    return AnimatedSize(
      duration: _animationDuration,
      curve: Curves.easeInOutCubicEmphasized,
      child: _isSearchVisible
          ? Transform.scale(
              scale: settingsProvider.uiScale ? 1.1 : 1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SearchBar(
                  controller: _searchController,
                  focusNode: _searchFocusNode,
                  hintText: 'Search venue, date, location — or paste to play',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear())
                        ]
                      : [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Icon(
                              Icons.content_paste_rounded,
                              size: 20,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                  onSubmitted: _onSearchSubmitted,
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                    side: BorderSide(
                        color: Theme.of(context).colorScheme.outline),
                  )),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildStandardLayout() {
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    Color? backgroundColor;
    // Only apply custom background color if NOT in "True Black" mode.
    // True Black mode = Dark Mode + Custom Seed + No Dynamic Color.
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

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: GestureDetector(
          onTap: () async {
            // Pause global clock
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

            // Resume global clock
            if (mounted) {
              try {
                final controller = context.read<AnimationController>();
                if (!controller.isAnimating) controller.repeat();
              } catch (_) {}
            }
          },
          child: Text(
            'shakedown',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.apply(fontSizeFactor: settingsProvider.uiScale ? 1.5 : 1.0),
          ),
        ),
        actions: _buildAppBarActions(),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              Expanded(
                  child: _buildBody(
                      showListProvider, audioProvider, settingsProvider)),
            ],
          ),
          // Hide MiniPlayer if search is active AND has focus (keyboard likely open)
          if (audioProvider.currentShow != null &&
              !(_isSearchVisible && _searchFocusNode.hasFocus))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                onTap: _openPlaybackScreen,
              ),
            ),
          // Custom Top Notification
          AnimatedPositioned(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutCubic,
            // Visually "just below the paste" area.
            // If search is visible (approx 80 height), it sits below it.
            // If search is hidden, it slides up and away (-100).
            top: _showPasteFeedback ? (_isSearchVisible ? 70.0 : 0.0) : -100.0,
            left: 24,
            right: 24,
            child: Material(
              elevation: 6,
              shadowColor: Colors.black45,
              borderRadius: BorderRadius.circular(16),
              color: Theme.of(context).colorScheme.inverseSurface,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Theme.of(context).colorScheme.onInverseSurface,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Fetching show...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onInverseSurface,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverLayout() {
    // Reverting to a standard layout as requested ("revert to before messing with appbar").
    // This removes the custom floating/hiding/transparency logic.
    return _buildStandardLayout();
  }

  Widget _buildBody(ShowListProvider showListProvider,
      AudioProvider audioProvider, SettingsProvider settingsProvider) {
    if (showListProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (showListProvider.error != null) {
      return Center(child: Text(showListProvider.error!));
    }
    if (showListProvider.filteredShows.isEmpty) {
      return const Center(
          child: Text('No shows match your search or filters.'));
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 160),
      itemCount: showListProvider.filteredShows.length,
      itemBuilder: (context, index) {
        return _buildShowListItem(
            showListProvider, audioProvider, settingsProvider, index);
      },
    );
  }

  Widget _buildShowListItem(
      ShowListProvider showListProvider,
      AudioProvider audioProvider,
      SettingsProvider settingsProvider,
      int index) {
    final show = showListProvider.filteredShows[index];
    final key = showListProvider.getShowKey(show);
    final isExpanded = showListProvider.expandedShowKey == key;

    return Builder(builder: (context) {
      return Column(
        key: ValueKey('${show.name}_${show.date}'),
        children: [
          Dismissible(
            key: ValueKey('${show.name}_${show.date}'),
            // Disable swipe on the main card if there are multiple sources.
            // Sources must be blocked individually in the expanded view.
            direction: show.sources.length > 1
                ? DismissDirection.none
                : DismissDirection.endToStart,
            background: const SwipeActionBackground(
              borderRadius: 12.0, // Matching Card's border radius
            ),
            confirmDismiss: (direction) async {
              // Haptic Feedback for the block action
              HapticFeedback.mediumImpact();

              // Calculate position for SnackBar
              double bottomMargin = 80; // Default fallback
              try {
                final RenderBox? box = context.findRenderObject() as RenderBox?;
                if (box != null && box.hasSize) {
                  final position = box.localToGlobal(Offset.zero);
                  final size = box.size;
                  final screenHeight = MediaQuery.of(context).size.height;
                  // Position just below the item
                  // Screen Height - (Item Top + Item Height) = Space below item
                  // We want SnackBar to float there.
                  // SnackBar approx height is 60.
                  final spaceBelow = screenHeight - (position.dy + size.height);
                  // Ensure margin is within screen bounds and reasonable
                  bottomMargin =
                      (spaceBelow - 60).clamp(10.0, screenHeight - 100);
                }
              } catch (e) {
                // Fallback to default if render object not found
              }

              // Stop playback if this specific show is playing
              if (audioProvider.currentShow == show) {
                audioProvider.stopAndClear();
              }

              // Mark as Blocked (Red Star / -1)
              CatalogService().setRating(show.sources.first.id, -1);

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(
                        Icons.block_flipped,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        size: 20,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Blocked "${show.venue}"',
                          style: TextStyle(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  backgroundColor:
                      Theme.of(context).colorScheme.primaryContainer,
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 4),
                  margin: EdgeInsets.only(
                      bottom: bottomMargin, left: 24, right: 24),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(100),
                    side: BorderSide(
                      color: Theme.of(context)
                          .colorScheme
                          .onPrimaryContainer
                          .withValues(alpha: 0.1),
                      width: 1,
                    ),
                  ),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Theme.of(context).colorScheme.primary,
                    onPressed: () {
                      // Restore rating
                      CatalogService().setRating(show.sources.first.id, 0);
                    },
                  ),
                ),
              );
              return true;
            },
            onDismissed: (direction) {
              // Optimistically remove from list to prevent "still in tree" crash.
              // setRating was already called in confirmDismiss to handle data persistence.
              showListProvider.dismissShow(show);
            },
            child: ShowListCard(
              show: show,
              isExpanded: isExpanded,
              isPlaying: audioProvider.currentShow == show,
              playingSource: audioProvider.currentSource,
              isLoading: showListProvider.isShowLoading(key),
              onTap: () => _onShowTapped(show),
              onLongPress: () => _onCardLongPressed(show),
            ),
          ),
          SizeTransition(
            sizeFactor: _animation,
            axisAlignment: -1.0,
            child: isExpanded
                ? ShowListItemDetails(
                    show: show,
                    playingSourceId: audioProvider.currentSource?.id,
                    height: _calculateExpandedHeight(show),
                    onSourceTapped: (source) => _onSourceTapped(show, source),
                    onSourceLongPress: (source) =>
                        _onSourceLongPressed(show, source),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      );
    });
  }
}
