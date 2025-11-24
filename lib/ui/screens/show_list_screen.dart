import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'package:animations/animations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/screens/track_list_screen.dart';
import 'package:gdar/ui/widgets/mini_player.dart';
import 'package:gdar/ui/widgets/show_list_card.dart';
import 'package:gdar/ui/widgets/show_list_item_details.dart';
import 'package:gdar/utils/logger.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class ShowListScreen extends StatefulWidget {
  const ShowListScreen({super.key});

  @override
  State<ShowListScreen> createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _isSearchVisible = false;
  bool _isRandomShowLoading = false;
  bool _randomShowPlayed = false;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Height constants for calculation
  static const double _baseSourceHeaderHeight = 59.0;
  static const double _listVerticalPadding = 16.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: _animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutCubicEmphasized,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _checkArchiveStatus());

    // Play random show on startup if enabled
    final settingsProvider = context.read<SettingsProvider>();
    if (settingsProvider.playRandomOnStartup) {
      final showListProvider = context.read<ShowListProvider>();
      final audioProvider = context.read<AudioProvider>();

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
        playRandomShowAndRemoveListener();
      } else {
        showListProvider.addListener(playRandomShowAndRemoveListener);
      }
    }

    _searchController.addListener(() {
      context.read<ShowListProvider>().setSearchQuery(_searchController.text);
    });

    // Listen to player state to manage loading indicators
    final audioProvider = context.read<AudioProvider>();
    audioProvider.addListener(() {
      if (audioProvider.error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(audioProvider.error!),
            action: SnackBarAction(
              label: 'Dismiss',
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
      if (showListProvider.loadingShowName != null &&
          showListProvider.loadingShowName == audioProvider.currentShow?.name) {
        if (processingState == ProcessingState.ready ||
            processingState == ProcessingState.idle) {
          showListProvider.setLoadingShow(null);
        }
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    _playerStateSubscription?.cancel();
    super.dispose();
  }

  void _toggleSearch() => setState(() => _isSearchVisible = !_isSearchVisible);

  double _calculateExpandedHeight(Show show) {
    if (show.sources.length <= 1) return 0.0;
    final settingsProvider = context.read<SettingsProvider>();
    final sourceHeaderHeight = _baseSourceHeaderHeight *
        (settingsProvider.scaleTrackList ? 1.25 : 1.0);
    return (show.sources.length * sourceHeaderHeight) + _listVerticalPadding;
  }

  /// Scrolls a show into view, centering it in the viewport.
  Future<void> _reliablyScrollToShow(Show show) async {
    final showListProvider = context.read<ShowListProvider>();
    final targetIndex = showListProvider.filteredShows.indexOf(show);
    logger.i('Attempting to scroll to "${show.name}" at index $targetIndex.');

    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list for scrolling.');
      return;
    }

    // Align to (0.4) if collapsed.
    // If expanded, adjust alignment based on number of sources to show more context.
    final isExpanded = showListProvider.expandedShowName == show.name;
    double alignment = 0.4;

    if (isExpanded) {
      if (show.sources.length > 4) {
        alignment = 0.02; // Top (approx 3 cards above center)
      } else if (show.sources.length > 2) {
        alignment = 0.20; // Upper third (approx 2 cards above center)
      } else if (show.sources.length > 1) {
        alignment = 0.35; // Slightly above center (approx 1 card above center)
      }
    }

    try {
      await _itemScrollController.scrollTo(
        index: targetIndex,
        duration: _animationDuration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: alignment,
      );
      logger.i('Scroll animation initiated for item at index $targetIndex.');
    } catch (e) {
      logger.e('Error during scroll to show: $e');
    }
  }

  /// Handles tapping on a show card based on the current playback state and show structure.
  Future<void> _onShowTapped(Show show) async {
    final audioProvider = context.read<AudioProvider>();
    final showListProvider = context.read<ShowListProvider>();
    final isPlayingThisShow = audioProvider.currentShow?.name == show.name;
    final isExpanded = showListProvider.expandedShowName == show.name;

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
            builder: (_) => TrackListScreen(show: show),
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
    final previouslyExpanded = showListProvider.expandedShowName;
    final isCollapsingCurrent = previouslyExpanded == show.name;

    // If tapping an already expanded show, collapse it.
    if (isCollapsingCurrent) {
      showListProvider.collapseCurrentShow();
      _animationController.reverse();
      return;
    }

    // If tapping a new or collapsed show, expand it.
    final wasSomethingExpanded = previouslyExpanded != null;
    showListProvider.onShowTap(show);

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
        year: show.year,
        venue: show.venue,
        sources: [source],
        hasFeaturedTrack: show.hasFeaturedTrack,
      );
      final shouldOpenPlayer = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackListScreen(show: singleSourceShow),
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

    showListProvider.setLoadingShow(show.name);
    // Expand the parent show if it's not already.
    if (showListProvider.expandedShowName != show.name) {
      showListProvider.expandShow(show);
      _animationController.forward(from: 0.0);
    }
    audioProvider.playSource(show, source);
  }

  Future<void> _openPlaybackScreen() async {
    final settingsProvider = context.read<SettingsProvider>();
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          const PlaybackScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        if (settingsProvider.useSharedAxisTransition) {
          return SharedAxisTransition(
            animation: animation,
            secondaryAnimation: secondaryAnimation,
            transitionType: SharedAxisTransitionType.vertical,
            child: child,
          );
        }
        // Default to the fade transition
        return FadeTransition(opacity: animation, child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));

    // This code runs *after* the PlaybackScreen is popped.
    if (!mounted) return;
    _collapseAndScrollOnReturn();
  }

  /// Collapses/Expands show and scrolls to the current show on return.
  void _collapseAndScrollOnReturn() {
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();
    final currentShow = audioProvider.currentShow;

    if (currentShow == null) return;

    // If multi-source, ensure it's expanded.
    if (currentShow.sources.length > 1) {
      if (showListProvider.expandedShowName != currentShow.name) {
        showListProvider.expandShow(currentShow);
        _animationController.forward(from: 0.0);
      }
    } else {
      // If single source (or no sources), collapse any expanded show.
      if (showListProvider.expandedShowName != null) {
        showListProvider.collapseCurrentShow();
        _animationController.reverse();
      }
    }

    // After a short delay to allow the animation to start,
    // scroll to the currently playing show.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _reliablyScrollToShow(currentShow);
      }
    });
  }

  Future<void> _handlePlayRandomShow() async {
    final showListProvider = context.read<ShowListProvider>();

    // Check if a show is currently expanded and collapse it first.
    if (showListProvider.expandedShowName != null) {
      showListProvider.collapseCurrentShow();
      _animationController.reverse();
    }

    setState(() => _isRandomShowLoading = true);

    final show = await context.read<AudioProvider>().playRandomShow();
    if (show != null) {
      // If the random show has multiple sources, expand it.
      if (show.sources.length > 1) {
        showListProvider.expandShow(show);
        _animationController.forward(from: 0.0);
      }

      // Use addPostFrameCallback to ensure collapse animation has started
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _reliablyScrollToShow(show);
        }
      });
    } else {
      setState(() => _isRandomShowLoading = false);
    }
  }

  static const int _maxRetries = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const Duration _timeout = Duration(seconds: 5);

  Future<void> _checkArchiveStatus() async {
    bool isArchiveDown = false;
    for (int i = 0; i < _maxRetries; i++) {
      try {
        logger.i(
            'Checking archive.org status (Attempt ${i + 1}/$_maxRetries)...');
        final response =
            await http.head(Uri.parse('https://archive.org')).timeout(_timeout);
        if (response.statusCode >= 200 && response.statusCode < 400) {
          logger.i('archive.org is reachable.');
          isArchiveDown = false;
          break; // Exit loop on success
        } else {
          logger.w(
              'archive.org returned status code: ${response.statusCode} (Attempt ${i + 1}/$_maxRetries)');
          isArchiveDown = true;
        }
      } on TimeoutException {
        logger.w('archive.org check timed out (Attempt ${i + 1}/$_maxRetries)');
        isArchiveDown = true;
      } on SocketException catch (e) {
        logger.e(
            'Failed to connect to archive.org: $e (Attempt ${i + 1}/$_maxRetries)');
        isArchiveDown = true;
      } catch (e) {
        logger.e(
            'An unexpected error occurred while checking archive.org: $e (Attempt ${i + 1}/$_maxRetries)');
        isArchiveDown = true;
      }

      if (isArchiveDown && i < _maxRetries - 1) {
        await Future.delayed(_retryDelay);
      }
    }

    if (isArchiveDown && mounted) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Connection Issue'),
            content: const Text(
                'gdar could not connect to archive.org after multiple attempts. The service may be temporarily unavailable. You may experience issues with playback.'),
            actions: <Widget>[
              TextButton(
                child: const Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
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
          tooltip: 'Play Random Show',
          onPressed: _handlePlayRandomShow,
        ),
      IconButton(
        icon: const Icon(Icons.search_rounded),
        tooltip: 'Search',
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
      IconButton(
        icon: const Icon(Icons.settings_rounded),
        tooltip: 'Settings',
        onPressed: () => Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (context, animation, secondaryAnimation) =>
                const SettingsScreen(),
            transitionDuration: Duration.zero,
          ),
        ),
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
              scale: settingsProvider.scaleShowList ? 1.1 : 1.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search by venue or date',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                          IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchController.clear())
                        ]
                      : null,
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('gdar'),
        actions: _buildAppBarActions(),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              _buildSearchBar(),
              Expanded(child: _buildBody(showListProvider, audioProvider)),
            ],
          ),
          if (audioProvider.currentShow != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Hero(
                tag: 'player',
                child: MiniPlayer(
                  onTap: _openPlaybackScreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSliverLayout() {
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    return Scaffold(
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
                SliverAppBar(
                  title: const Text('gdar'),
                  actions: _buildAppBarActions(),
                  floating: true,
                  snap: true,
                  forceElevated: innerBoxIsScrolled,
                ),
                SliverToBoxAdapter(child: _buildSearchBar()),
              ];
            },
            body: _buildBody(showListProvider, audioProvider),
          ),
          if (audioProvider.currentShow != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Hero(
                tag: 'player',
                child: MiniPlayer(
                  onTap: _openPlaybackScreen,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(
      ShowListProvider showListProvider, AudioProvider audioProvider) {
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
        return _buildShowListItem(showListProvider, audioProvider, index);
      },
    );
  }

  Widget _buildShowListItem(ShowListProvider showListProvider,
      AudioProvider audioProvider, int index) {
    final show = showListProvider.filteredShows[index];
    final isExpanded = showListProvider.expandedShowName == show.name;

    return Column(
      key: ValueKey(show.name),
      children: [
        ShowListCard(
          show: show,
          isExpanded: isExpanded,
          isPlaying: audioProvider.currentShow?.name == show.name,
          isLoading: showListProvider.loadingShowName == show.name,
          onTap: () => _onShowTapped(show),
          onLongPress: () => _onCardLongPressed(show),
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
  }
}
