import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
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
  final Map<String, ScrollController> _trackScrollControllers = {};

  late final AnimationController _animationController;
  late final Animation<double> _animation;
  StreamSubscription<PlayerState>? _playerStateSubscription;

  bool _isSearchVisible = false;
  bool _isRandomShowLoading = false;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Height constants for calculation
  static const double _sourceHeaderHeight = 72.0;
  static const double _trackItemHeight = 64.0;
  static const double _shnidLabelHeight = 0.0;
  static const double _sourcePadding = 16.0;
  static const double _maxShnidListHeight = 400.0;
  static const double _maxTrackListHeight = 500.0;

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

    _searchController.addListener(() {
      context
          .read<ShowListProvider>()
          .setSearchQuery(_searchController.text);
    });

    // Listen to player state to manage loading indicators
    final audioProvider = context.read<AudioProvider>();
    _playerStateSubscription =
        audioProvider.playerStateStream.listen((state) {
          if (!mounted) return;
          final processingState = state.processingState;

          // Handle AppBar's random play indicator
          if (_isRandomShowLoading) {
            // If the player is ready, has completed, or has stopped (idle),
            // we can consider the loading phase over.
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
            // When player is ready or has failed, remove indicator
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
    for (var controller in _trackScrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _toggleSearch() => setState(() => _isSearchVisible = !_isSearchVisible);

  double _calculateExpandedHeight(Show show, String? expandedShnid) {
    double totalHeight = 0.0;
    final hasMultipleSources = show.sources.length > 1;

    if (hasMultipleSources) {
      totalHeight += _shnidLabelHeight;
      totalHeight += show.sources.length * _sourceHeaderHeight;
      totalHeight += 16;
      if (expandedShnid != null) {
        final expandedSource = show.sources.firstWhere(
                (s) => s.id == expandedShnid,
            orElse: () => show.sources.first);
        totalHeight += expandedSource.tracks.length * _trackItemHeight;
        totalHeight += _sourcePadding;
        return totalHeight.clamp(
            0.0,
            _maxTrackListHeight +
                (show.sources.length * _sourceHeaderHeight) +
                16.0);
      }
      return totalHeight.clamp(0, _maxShnidListHeight);
    } else {
      totalHeight += show.sources.first.tracks.length * _trackItemHeight;
      totalHeight += _sourcePadding;
      return totalHeight.clamp(0, _maxTrackListHeight);
    }
  }

  Future<void> _scrollToShowTop(
      Show show, List<Show> currentlyVisibleShows) async {
    final targetIndex = currentlyVisibleShows.indexOf(show);
    logger.i('Attempting to scroll to "${show.name}" at index $targetIndex.');

    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list for scrolling.');
      return;
    }

    try {
      await _itemScrollController.scrollTo(
        index: targetIndex,
        duration: _animationDuration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: 0.0,
      );
      logger.i('Scroll animation initiated for item at index $targetIndex.');
    } catch (e) {
      logger.e('Error during scroll to show: $e');
    }
  }

  Future<void> _onShowTapped(Show show) async {
    logger.d('Tapped on show: ${show.name}');
    final showListProvider = context.read<ShowListProvider>();
    final previouslyExpanded = showListProvider.expandedShowName;
    final isExpandingNewShow = previouslyExpanded != show.name;

    if (previouslyExpanded != null && isExpandingNewShow) {
      logger.i('Collapsing previous show: $previouslyExpanded');
      await _animationController.reverse();
      if (!mounted) return;
    }

    showListProvider.onShowTapped(show);

    if (isExpandingNewShow) {
      logger.i('Expanding new show: ${show.name}');
      await _animationController.forward(from: 0.0);
      if (!mounted) return;
      await Future.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;

      logger.d('Animation complete: Scrolling to ${show.name}');
      _scrollToShowTop(show, showListProvider.filteredShows);
    } else {
      logger.i('Collapsing show: ${show.name}');
      _animationController.reverse();
    }
  }

  Future<void> _onSourceLongPressed(Show show, Source source) async {
    logger.d('Long pressed on source: ${source.id} for show: ${show.name}');
    final showListProvider = context.read<ShowListProvider>();
    final audioProvider = context.read<AudioProvider>();

    final previouslyExpandedShow = showListProvider.expandedShowName;
    final isDifferentShow = previouslyExpandedShow != show.name;
    final wasAlreadyExpanded = previouslyExpandedShow == show.name;

    showListProvider.setLoadingShow(show.name);

    if (previouslyExpandedShow != null && isDifferentShow) {
      logger.i('Collapsing previous show: $previouslyExpandedShow');
      await _animationController.reverse();
      if (!mounted) return;
    }

    showListProvider.expandShowAndSource(show.name, source.id);

    // This is the function that will be called to scroll.
    Future<void> scrollShow() async {
      await Future.delayed(const Duration(milliseconds: 50));
      if (mounted) {
        logger.d('Animation/Action complete: Scrolling to ${show.name}');
        await _scrollToShowTop(show, showListProvider.filteredShows);
      }
    }

    if (!wasAlreadyExpanded) {
      logger.i('Expanding show container for ${show.name}');
      await _animationController.forward(from: 0.0);
      await scrollShow();
    } else {
      await scrollShow();
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
        const curve = Curves.easeInOutCubicEmphasized;
        var tween =
        Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));

    if (!mounted) return;
    _scrollToPlayingShow(isReturning: true);
  }

  Future<void> _scrollToPlayingShow({bool isReturning = false}) async {
    if (isReturning) {
      logger.i(
          'Returned from PlaybackScreen. Initiating scroll-to-playing sequence...');
    } else {
      logger.i('Miniplayer tapped. Initiating scroll-to-playing sequence...');
    }

    final audioProvider = context.read<AudioProvider>();
    final showListProvider = context.read<ShowListProvider>();
    final currentShow = audioProvider.currentShow;
    final currentSource = audioProvider.currentSource;

    if (currentShow == null || currentSource == null) {
      logger.i('No show is currently playing. Aborting sequence.');
      return;
    }

    final trackIndex = audioProvider.audioPlayer.currentIndex ?? 0;
    final specificShnid =
    currentShow.sources.length > 1 ? currentSource.id : null;
    final isAlreadyExpanded =
        showListProvider.expandedShowName == currentShow.name;

    logger.d(
        'Target: Show="${currentShow.name}", Source="${currentSource.id}", Track=$trackIndex. Show already expanded: $isAlreadyExpanded');

    showListProvider.expandToShow(currentShow, specificShnid: specificShnid);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;

      if (!isAlreadyExpanded) {
        logger.i('Show was not expanded. Animating it open...');
        await _animationController.forward(from: 0.0);
        if (!mounted) return;
      }

      await _scrollToShowTop(currentShow, showListProvider.filteredShows);
      if (!mounted) return;

      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;

      final controller = _trackScrollControllers[currentSource.id];
      if (controller != null && controller.hasClients) {
        final viewportHeight = controller.position.viewportDimension;
        final maxScroll = controller.position.maxScrollExtent;
        final itemTopPosition = _trackItemHeight * trackIndex;

        final targetOffset =
        (itemTopPosition - (viewportHeight / 2) + (_trackItemHeight / 2))
            .clamp(0.0, maxScroll);

        logger.i(
            'Centering inner list on track $trackIndex. Target offset: $targetOffset, Viewport: $viewportHeight, MaxScroll: $maxScroll');

        controller.animateTo(
          targetOffset,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      } else {
        logger.w(
            'Could not scroll track list: Controller for ${currentSource.id} not found or has no clients.');
      }
    });
  }

  void _handlePlayRandomShow() {
    setState(() => _isRandomShowLoading = true);

    final show = context.read<AudioProvider>().playRandomShow();
    if (show != null) {
      // The provider immediately sets the current show, so we can scroll to it
      // while the audio loads in the background.
      _scrollToPlayingShow();
    } else {
      // No show was found/played, so stop loading.
      setState(() => _isRandomShowLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('gdar'),
        actions: [
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
            onPressed: () => Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              AnimatedSize(
                duration: _animationDuration,
                curve: Curves.easeInOutCubicEmphasized,
                child: _isSearchVisible
                    ? Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: SearchBar(
                    controller: _searchController,
                    hintText: 'Search by venue or date',
                    leading: const Icon(Icons.search_rounded),
                    trailing: _searchController.text.isNotEmpty
                        ? [
                      IconButton(
                          icon: const Icon(Icons.clear_rounded),
                          onPressed: () =>
                              _searchController.clear())
                    ]
                        : null,
                    elevation: const WidgetStatePropertyAll(0),
                    shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outline),
                    )),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: _buildBody(showListProvider, audioProvider)),
            ],
          ),
          if (audioProvider.currentShow != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(onTap: _scrollToPlayingShow),
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
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: showListProvider.filteredShows.length,
      itemBuilder: (context, index) {
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
              onLongPress: () {
                HapticFeedback.mediumImpact();
                showListProvider.setLoadingShow(show.name);
                if (showListProvider.expandedShowName != show.name) {
                  _onShowTapped(show);
                }
                audioProvider.playShow(show);
              },
            ),
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: isExpanded
                  ? ShowListItemDetails(
                show: show,
                playingSourceId: audioProvider.currentSource?.id,
                expandedShnid: showListProvider.expandedShnid,
                height: _calculateExpandedHeight(
                    show, showListProvider.expandedShnid),
                trackScrollControllers: _trackScrollControllers,
                onOpenPlayback: _openPlaybackScreen,
                onSourceLongPress: (source) =>
                    _onSourceLongPressed(show, source),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }
}
