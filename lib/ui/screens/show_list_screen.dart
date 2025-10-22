import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/widgets/mini_player.dart';
import 'package:gdar/utils/logger.dart';
import 'package:gdar/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:collection'; // Import for Queue

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

  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;

  String? _expandedShowName;
  String? _expandedShnid;
  bool _isSearchVisible = false;
  String? _loadingShowName;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  // Queue to store recent scroll target indices for logging position
  final Queue<int> _scrollTargetQueue = Queue<int>();
  Timer? _positionLogTimer;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Height constants for calculation
  // Use the original source header height
  static const double _sourceHeaderHeight = 72.0;
  static const double _trackItemHeight = 75.0;
  static const double _shnidLabelHeight = 0.0;
  static const double _sourcePadding = 16.0; // Corresponds to vertical: 8 margin * 2
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

    _fetchShows();
    _searchController.addListener(() => setState(() {}));
    _itemPositionsListener.itemPositions.addListener(_logItemPositionAfterScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    for (var controller in _trackScrollControllers.values) {
      controller.dispose();
    }
    _itemPositionsListener.itemPositions.removeListener(_logItemPositionAfterScroll);
    _positionLogTimer?.cancel();
    super.dispose();
  }

  void _logItemPositionAfterScroll() {
    if (_scrollTargetQueue.isNotEmpty) {
      _positionLogTimer?.cancel();
      _positionLogTimer = Timer(const Duration(milliseconds: 500), () {
        if (_scrollTargetQueue.isNotEmpty && mounted) {
          final targetIndex = _scrollTargetQueue.removeFirst();
          final positions = _itemPositionsListener.itemPositions.value;
          final targetPosition = positions.firstWhere(
                (pos) => pos.index == targetIndex,
            orElse: () =>
                ItemPosition(index: -1, itemLeadingEdge: -1, itemTrailingEdge: -1),
          );

          if (targetPosition.index != -1) {
            logger.i(
                'Item at index $targetIndex settled. Leading Edge: ${targetPosition.itemLeadingEdge.toStringAsFixed(2)}');
          } else {
            logger.w(
                'Item at index $targetIndex not found in visible positions after scroll.');
          }
        }
        if (_scrollTargetQueue.isNotEmpty) {
          _scrollTargetQueue.clear();
          logger.d("Cleared scroll target queue due to rapid scrolls.");
        }
      });
    }
  }

  Future<void> _fetchShows() async {
    try {
      final shows = await ShowService.instance.getShows();
      if (mounted) {
        setState(() {
          _allShows = shows;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = "Failed to load shows. Please restart the app.";
          _isLoading = false;
        });
      }
    }
  }

  List<Show> _getFilteredShows() {
    const bool hideGdShowsInternally = true;
    return _allShows.where((show) {
      if (hideGdShowsInternally && show.hasFeaturedTrack) return false;
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return true;
      return show.venue.toLowerCase().contains(query) ||
          show.formattedDate.toLowerCase().contains(query);
    }).toList();
  }

  void _toggleSearch() => setState(() => _isSearchVisible = !_isSearchVisible);

  void _collapseCurrentShow() {
    if (_expandedShowName == null) return;
    setState(() {
      _expandedShowName = null;
      _expandedShnid = null;
    });
    _animationController.reverse();
  }

  void _expandShow(Show show, {String? specificShnid}) {
    setState(() {
      _expandedShowName = show.name;
      if (specificShnid != null) {
        _expandedShnid = specificShnid;
      } else if (show.sources.length > 1) {
        _expandedShnid = null;
      } else {
        _expandedShnid = null;
      }
    });
    _animationController.forward(from: 0.0);
  }


  double _calculateExpandedHeight(Show show) {
    double totalHeight = 0.0;
    final hasMultipleSources = show.sources.length > 1;

    if (hasMultipleSources) {
      totalHeight += _shnidLabelHeight;
      // Use the actual number of sources for height calculation
      totalHeight += show.sources.length * _sourceHeaderHeight;
      // Add padding for the top/bottom of the source list itself
      totalHeight += 16;
      if (_expandedShnid != null) {
        final expandedSource = show.sources.firstWhere(
                (s) => s.id == _expandedShnid,
            orElse: () => show.sources.first);
        totalHeight += expandedSource.tracks.length * _trackItemHeight;
        // Add padding for the top/bottom within the nested track list container
        totalHeight += _sourcePadding;
        // Clamp total height (sources + tracks + paddings)
        // Ensure we don't exceed the max track height *plus* the space already taken by sources
        return totalHeight.clamp(0.0, _maxTrackListHeight + (show.sources.length * _sourceHeaderHeight) + 16.0);
      }
      // Clamp height for just the source list + padding
      return totalHeight.clamp(0, _maxShnidListHeight);
    } else {
      // Single source show
      totalHeight += show.sources.first.tracks.length * _trackItemHeight;
      // Add padding for the top/bottom within the track list container
      totalHeight += _sourcePadding;
      return totalHeight.clamp(0, _maxTrackListHeight);
    }
  }




  Future<void> _scrollToShowTop(
      Show show, List<Show> currentlyVisibleShows) async {
    final targetIndex = currentlyVisibleShows.indexOf(show);
    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list for scrolling.');
      return;
    }

    logger.i('Initiating scroll for item at index $targetIndex to top.');
    _scrollTargetQueue.addLast(targetIndex);
    try {
      await _itemScrollController.scrollTo(
        index: targetIndex,
        duration: _animationDuration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: 0.0,
      );
      logger.i(
          'Scroll animation initiated for item at index $targetIndex likely completed (await returned).');
    } catch (e) {
      logger.e('Error during scroll to show: $e');
      _scrollTargetQueue.remove(targetIndex);
    }
  }


  Future<void> _bringShowIntoView(Show show, {String? specificShnid}) async {
    final isAnotherShowExpanded =
        _expandedShowName != null && _expandedShowName != show.name;

    if (isAnotherShowExpanded) {
      logger.i('Collapsing previous show before expanding new one');
      _collapseCurrentShow();
      await Future.delayed(_animationDuration);
    }

    logger.i('Expanding show: "${show.name}"');
    _expandShow(show, specificShnid: specificShnid);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _scrollToShowTop(show, _getFilteredShows());
      }
    });
  }


  Future<void> _onShowTapped(Show show) async {
    if (_expandedShowName == show.name) {
      logger.i('Collapsing the same show: "${show.name}"');
      _collapseCurrentShow();
    } else {
      await _bringShowIntoView(show);
    }
  }

  void _onShnidTapped(String shnid) {
    setState(() => _expandedShnid = (_expandedShnid == shnid) ? null : shnid);
  }

  Future<void> _openPlaybackScreen() async {
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
      const PlaybackScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));

    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();
    final currentShow = audioProvider.currentShow;
    final currentSource = audioProvider.currentSource;

    if (currentShow != null && currentSource != null) {
      final specificShnidToPass = currentShow.sources.length > 1 ? currentSource.id : null;
      await _bringShowIntoView(currentShow, specificShnid: specificShnidToPass);

      await Future.delayed(_animationDuration);
      if (!mounted) return;

      final trackIndex = audioProvider.audioPlayer.currentIndex ?? 0;
      final controller = _trackScrollControllers[currentSource.id];
      if (controller != null && controller.hasClients) {
        final offset = trackIndex * _trackItemHeight;
        if (offset <= controller.position.maxScrollExtent) {
          controller.animateTo(offset,
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeInOut);
        }
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    // ignore: unused_local_variable
    final settingsProvider = context.watch<SettingsProvider>(); // Needed for watch
    final filteredShows = _getFilteredShows();

    return Scaffold(
      appBar: AppBar(
        title: const Text('gdar'),
        actions: [
          IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Search',
              onPressed: _toggleSearch),
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
                )
                    : const SizedBox.shrink(),
              ),
              Expanded(child: _buildBody(filteredShows)),
            ],
          ),
          if (audioProvider.currentShow != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(onTap: _openPlaybackScreen),
            ),
        ],
      ),
    );
  }

  Widget _buildBody(List<Show> filteredShows) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text(_error!));
    if (filteredShows.isEmpty) {
      return const Center(child: Text('No shows match your search or filters.'));
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: filteredShows.length,
      itemBuilder: (context, index) {
        final show = filteredShows[index];
        final audioProvider = context.watch<AudioProvider>();
        return Column(
          key: ValueKey(show.name),
          children: [
            _buildShowHeader(context, show, _expandedShowName == show.name,
                audioProvider.currentShow?.name == show.name),
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: _expandedShowName == show.name
                  ? _buildExpandedContent(
                  context, show, audioProvider.currentSource?.id)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShowHeader(
      BuildContext context, Show show, bool isExpanded, bool isPlaying) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isLoading = _loadingShowName == show.name;
    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;
    final bool shouldShowBadge = show.sources.length > 1 ||
        (show.sources.length == 1 && settingsProvider.showSingleShnid);


    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isExpanded ? 2 : 0,
        shadowColor: colorScheme.shadow.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
              color: cardBorderColor,
              width: (isPlaying || show.hasFeaturedTrack) ? 2 : 1),
        ),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOutCubicEmphasized,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: isExpanded
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : colorScheme.surface,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _onShowTapped(show),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                setState(() => _loadingShowName = show.name);
                _bringShowIntoView(show);
                context.read<AudioProvider>().playShow(show).whenComplete(() {
                  if (mounted && _loadingShowName == show.name) {
                    setState(() => _loadingShowName = null);
                  }
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  // UPDATED: Align children to the bottom
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Keep icon aligned conceptually with the top line of text
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4.0), // Adjust padding slightly if needed
                      child: AnimatedSwitcher(
                        duration: _animationDuration,
                        child: isLoading
                            ? Container(
                          key: ValueKey('loader_${show.name}'),
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(8),
                          child: const CircularProgressIndicator(strokeWidth: 2.5),
                        )
                            : AnimatedRotation(
                          key: ValueKey('icon_${show.name}'),
                          turns: isExpanded ? 0.5 : 0,
                          duration: _animationDuration,
                          curve: Curves.easeInOutCubicEmphasized,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isExpanded
                                  ? colorScheme.primaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.keyboard_arrow_down_rounded,
                                color: isExpanded
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                                size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end, // Align text towards bottom
                        children: [
                          Text(show.venue,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                  color: colorScheme.onSurface),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 6),
                          Text(show.formattedDate,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.15)),
                        ],
                      ),
                    ),
                    // Badge is already aligned bottom-right implicitly by the Row's CrossAxisAlignment.end
                    if (shouldShowBadge)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0), // Keep padding for spacing
                        child: _buildBadge(context, show),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();

    final String badgeText;
    if (show.sources.length == 1 && settingsProvider.showSingleShnid) {
      badgeText = show.sources.first.id.replaceAll(RegExp(r'[^0-9]'), '');
    } else {
      badgeText = '${show.sources.length}';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      constraints: const BoxConstraints(maxWidth: 80),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.secondaryContainer.withOpacity(0.7),
            colorScheme.secondaryContainer.withOpacity(0.5),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withOpacity(0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: Text(
        badgeText,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2),
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
        textAlign: TextAlign.center,
      ),
    );
  }


  Widget _buildExpandedContent(
      BuildContext context, Show show, String? playingSourceId) {
    // UPDATED: Always show source list if > 1 source, otherwise show tracks directly.
    if (show.sources.isEmpty) {
      return const SizedBox(
          height: 100, child: Center(child: Text('No tracks available.')));
    }

    return SizedBox(
      height: _calculateExpandedHeight(show),
      child: show.sources.length > 1
          ? _buildSourceSelection(context, show, playingSourceId) // Show source list if multiple
          : _buildTrackList(context, show, show.sources.first), // Show tracks if single
    );
  }



  Widget _buildSourceSelection(
      BuildContext context, Show show, String? playingSourceId) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>(); // Need settings here

    return ListView.builder(
      // UPDATED: Removed vertical padding from ListView
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: show.sources.length,
      itemBuilder: (context, index) {
        final source = show.sources[index];
        final isSourceExpanded = _expandedShnid == source.id;
        final isSourcePlaying = playingSourceId == source.id;
        return Column(
          key: ValueKey(source.id),
          children: [
            Padding(
              // Keep vertical padding on individual items
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => _onShnidTapped(source.id),
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    setState(() => _loadingShowName = show.name);
                    _bringShowIntoView(show, specificShnid: source.id);
                    context
                        .read<AudioProvider>()
                        .playSource(show, source)
                        .whenComplete(() {
                      if (mounted && _loadingShowName == show.name) {
                        setState(() => _loadingShowName = null);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isSourcePlaying
                              ? colorScheme.tertiaryContainer.withOpacity(0.7)
                              : colorScheme.secondaryContainer,
                          isSourcePlaying
                              ? colorScheme.tertiaryContainer.withOpacity(0.5)
                              : colorScheme.secondaryContainer.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: isSourceExpanded ? Border.all(color: colorScheme.primary, width: 1.5) : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: isSourceExpanded ? 0.5 : 0,
                          duration: _animationDuration,
                          curve: Curves.easeInOutCubicEmphasized,
                          child: Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isSourceExpanded
                                  ? colorScheme.onPrimaryContainer
                                  : isSourcePlaying
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                              source.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                  color: isSourcePlaying
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSecondaryContainer,
                                  fontWeight: isSourcePlaying
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: 0.1)),
                        ),
                        if (!settingsProvider.hideTrackCountInSourceList)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSourcePlaying
                                  ? colorScheme.tertiary.withOpacity(0.1)
                                  : colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${source.tracks.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                    color: isSourcePlaying
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: _animationDuration,
              curve: Curves.easeInOutCubicEmphasized,
              child: isSourceExpanded
                  ? _buildTrackList(context, show, source, isNested: true)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackList(BuildContext context, Show show, Source source,
      {bool isNested = false}) {
    final controller = _trackScrollControllers.putIfAbsent(
        source.id, () => ScrollController());
    // UPDATED: Calculate height differently based on context
    double listHeight;
    if (isNested) {
      // Calculate height for nested list + padding and clamp
      listHeight = ((source.tracks.length * _trackItemHeight) + _sourcePadding).clamp(0.0, _maxTrackListHeight);
    } else {
      // Use the main calculation for single-source shows (already includes padding and clamping)
      listHeight = _calculateExpandedHeight(show);
    }


    return Container(
      height: listHeight, // Use calculated height
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        // UPDATED: Always transparent background
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        controller: controller,
        // Add padding only if nested to ensure spacing below last item
        padding: isNested ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
        itemCount: source.tracks.length,
        itemBuilder: (context, index) {
          return _buildTrackItem(context, show, source.tracks[index], source, index);
        },
      ),
    );
  }




  Widget _buildTrackItem(
      BuildContext context, Show show, Track track, Source source, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      builder: (context, indexSnapshot) {
        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          builder: (context, stateSnapshot) {
            final isCurrentlyPlayingSource =
                audioProvider.currentSource?.id == source.id;
            final isPlayingTrack =
                isCurrentlyPlayingSource && indexSnapshot.data == index;
            final titleText = settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: isPlayingTrack
                    ? LinearGradient(colors: [
                  colorScheme.primaryContainer.withOpacity(0.6),
                  colorScheme.primaryContainer.withOpacity(0.3)
                ], begin: Alignment.centerLeft, end: Alignment.centerRight)
                    : null,
                color: isPlayingTrack ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isPlayingTrack
                    ? Border.all(
                    color: colorScheme.primary.withOpacity(0.3), width: 1.5)
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    final audioProvider = context.read<AudioProvider>();
                    if (isPlayingTrack) {
                      _openPlaybackScreen();
                    } else if (isCurrentlyPlayingSource) {
                      audioProvider.seekToTrack(index);
                    } else if (context.read<SettingsProvider>().playOnTap) {
                      HapticFeedback.lightImpact();
                      audioProvider.playSource(show, source, initialIndex: index);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        if (isPlayingTrack)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            width: 24,
                            height: 24,
                            child: Center(
                              child: (stateSnapshot.data?.processingState ==
                                  ProcessingState.buffering ||
                                  stateSnapshot.data?.processingState ==
                                      ProcessingState.loading)
                                  ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(strokeWidth: 2.0))
                                  : Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: colorScheme.primary,
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Icon(Icons.play_arrow_rounded,
                                      size: 16, color: colorScheme.onPrimary)),
                            ),
                          ),
                        Expanded(
                          child: Text(titleText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: isPlayingTrack
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                  fontWeight: isPlayingTrack
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  letterSpacing: 0.1)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPlayingTrack
                                ? colorScheme.primary.withOpacity(0.2)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              formatDuration(Duration(seconds: track.duration)),
                              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: isPlayingTrack
                                      ? colorScheme.primary
                                      : colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

