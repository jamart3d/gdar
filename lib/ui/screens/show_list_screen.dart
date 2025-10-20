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

  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;

  String? _expandedShowName;
  String? _expandedShnid;
  bool _isSearchVisible = false;

  late final AnimationController _animationController;
  late final Animation<double> _animation;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  // Height constants for calculation - adjusted for Material 3 expressive styling
  static const double _sourceHeaderHeight = 72.0;
  static const double _trackItemHeight = 75.0;
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

    _fetchShows();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
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

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _playSource(Show show, Source source) {
    Provider.of<AudioProvider>(context, listen: false).playSource(show, source);
  }

  void _collapseCurrentShow() {
    if (_expandedShowName == null) return;

    setState(() {
      _expandedShowName = null;
      _expandedShnid = null;
    });
    _animationController.reverse();
  }

  void _expandShow(Show show) {
    setState(() {
      _expandedShowName = show.name;
      _expandedShnid = show.sources.length == 1 ? show.sources.first.id : null;
    });
    _animationController.forward();
  }

  double _calculateExpandedHeight(Show show) {
    double totalHeight = 0.0;

    final hasMultipleSources = show.sources.length > 1;

    if (hasMultipleSources) {
      totalHeight += _shnidLabelHeight;
      totalHeight += show.sources.length * _sourceHeaderHeight;

      if (_expandedShnid != null) {
        final expandedSource = show.sources.firstWhere(
              (s) => s.id == _expandedShnid,
          orElse: () => show.sources.first,
        );
        totalHeight += expandedSource.tracks.length * _trackItemHeight;
        totalHeight += _sourcePadding;

        final cappedHeight = totalHeight > _maxTrackListHeight
            ? _maxTrackListHeight
            : totalHeight;

        logger.d('Height for "${show.name}" with shnid expanded: ${totalHeight.toStringAsFixed(1)}px (capped: ${cappedHeight.toStringAsFixed(1)}px)');
        return cappedHeight;
      } else {
        totalHeight += _sourcePadding;

        final cappedHeight = totalHeight > _maxShnidListHeight
            ? _maxShnidListHeight
            : totalHeight;

        logger.d('Height for "${show.name}" with just shnid list: ${totalHeight.toStringAsFixed(1)}px (capped: ${cappedHeight.toStringAsFixed(1)}px)');
        return cappedHeight;
      }
    } else {
      final source = show.sources.first;
      totalHeight += source.tracks.length * _trackItemHeight;

      final cappedHeight = totalHeight > _maxTrackListHeight
          ? _maxTrackListHeight
          : totalHeight;

      logger.d('Height for "${show.name}" (single source): ${totalHeight.toStringAsFixed(1)}px (capped: ${cappedHeight.toStringAsFixed(1)}px)');
      return cappedHeight;
    }
  }

  Future<void> _scrollToShowTop(Show show, List<Show> currentlyVisibleShows) async {
    final targetIndex = currentlyVisibleShows.indexOf(show);
    if (targetIndex == -1) {
      logger.w('Show "${show.name}" not found in filtered list');
      return;
    }

    // Always scroll without checking position - let the controller handle optimization
    logger.i('Scrolling item at index $targetIndex to top');

    try {
      await _itemScrollController.scrollTo(
        index: targetIndex,
        duration: _animationDuration,
        curve: Curves.easeInOutCubicEmphasized,
        alignment: 0.0, // Explicitly set alignment to top
      );

      // Add small delay to ensure scroll completes before state changes
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      logger.e('Error scrolling to show: $e');
    }
  }

  Future<void> _onShowTapped(Show show, List<Show> currentlyVisibleShows) async {
    final isAlreadyExpanded = _expandedShowName == show.name;

    if (isAlreadyExpanded) {
      logger.i('Collapsing the same show: "${show.name}"');
      _collapseCurrentShow();
      return;
    }

    // IMPROVED FLOW:
    // 1. Collapse any expanded show first (so height calculations are accurate)
    final isAnotherShowExpanded = _expandedShowName != null;
    if (isAnotherShowExpanded) {
      logger.i('Collapsing previous show before expanding new one');
      _collapseCurrentShow();
      // Wait for collapse animation to complete
      await Future.delayed(_animationDuration + const Duration(milliseconds: 50));
    }

    // 2. Scroll tapped show to top with clean state
    await _scrollToShowTop(show, currentlyVisibleShows);

    // 3. Expand the tapped show
    logger.i('Expanding show: "${show.name}"');
    _expandShow(show);
  }

  void _onShnidTapped(String shnid) {
    setState(() {
      if (_expandedShnid == shnid) {
        _expandedShnid = null;
      } else {
        _expandedShnid = shnid;
      }
    });
  }

  void _openPlaybackScreen() {
    Navigator.of(context).push(PageRouteBuilder(
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
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    context.watch<SettingsProvider>();
    final hasCurrentShow = audioProvider.currentShow != null;

    const bool hideGdShowsInternally = true;

    final filteredShows = _allShows.where((show) {
      if (hideGdShowsInternally && show.hasFeaturedTrack) {
        return false;
      }

      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) {
        return true;
      }
      final venueMatches = show.venue.toLowerCase().contains(query);
      final dateMatches = show.formattedDate.toLowerCase().contains(query);
      return venueMatches || dateMatches;
    }).toList();

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
            onPressed: () {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Column(
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
                      shape: WidgetStatePropertyAll(
                          RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                            side: BorderSide(
                                color:
                                Theme.of(context).colorScheme.outline),
                          )),
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
                Expanded(child: _buildBody(filteredShows)),
              ],
            ),
          ),
          if (hasCurrentShow)
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
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (filteredShows.isEmpty) {
      return const Center(
          child: Text('No shows match your search or filters.'));
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: filteredShows.length,
      itemBuilder: (context, index) {
        final show = filteredShows[index];
        final isExpanded = _expandedShowName == show.name;
        final audioProvider = context.watch<AudioProvider>();
        final currentShow = audioProvider.currentShow;
        final currentSource = audioProvider.currentSource;
        final isPlaying = currentShow?.name == show.name;
        final playingSourceId = isPlaying ? currentSource?.id : null;

        return Column(
          key: ValueKey(show.name),
          children: [
            _buildShowHeader(
                context, show, isExpanded, isPlaying, filteredShows),
            SizeTransition(
              sizeFactor: _animation,
              axisAlignment: -1.0,
              child: isExpanded
                  ? _buildExpandedContent(context, show, playingSourceId)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShowHeader(BuildContext context, Show show, bool isExpanded,
      bool isPlaying, List<Show> filteredShows) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMultipleSources = show.sources.length > 1;

    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;

    final containerColor = isExpanded
        ? colorScheme.primaryContainer.withOpacity(0.3)
        : colorScheme.surface;

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
            width: (isPlaying || show.hasFeaturedTrack) ? 2 : 1,
          ),
        ),
        child: AnimatedContainer(
          duration: _animationDuration,
          curve: Curves.easeInOutCubicEmphasized,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            color: containerColor,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: () => _onShowTapped(show, filteredShows),
              onLongPress: () {
                HapticFeedback.mediumImpact();
                context.read<AudioProvider>().playShow(show);
              },
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    AnimatedRotation(
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
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: isExpanded
                              ? colorScheme.onPrimaryContainer
                              : colorScheme.onSurfaceVariant,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
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
                    if (hasMultipleSources) _buildBadge(context, show),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colorScheme.secondaryContainer,
              colorScheme.secondaryContainer.withOpacity(0.8),
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
            ),
          ]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.library_music_rounded,
            size: 16,
            color: colorScheme.onSecondaryContainer,
          ),
          const SizedBox(width: 6),
          Text('${show.sources.length}',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.1)),
        ],
      ),
    );
  }

  Widget _buildExpandedContent(
      BuildContext context, Show show, String? playingSourceId) {
    if (show.sources.isEmpty) {
      return const SizedBox(
        height: 100,
        child: Center(
          child: Text('No tracks available for this show.'),
        ),
      );
    }

    final hasMultipleSources = show.sources.length > 1;
    final expandedHeight = _calculateExpandedHeight(show);

    bool needsScroll;
    if (hasMultipleSources) {
      if (_expandedShnid != null) {
        needsScroll = expandedHeight >= _maxTrackListHeight;
      } else {
        needsScroll = expandedHeight >= _maxShnidListHeight;
      }
    } else {
      needsScroll = expandedHeight >= _maxTrackListHeight;
    }

    return SizedBox(
      height: expandedHeight,
      child: needsScroll
          ? SingleChildScrollView(
        child: Column(
          children: [
            if (hasMultipleSources)
              _buildSourceSelection(context, show, playingSourceId)
            else
              _buildTrackList(context, show, show.sources.first),
          ],
        ),
      )
          : Column(
        children: [
          if (hasMultipleSources)
            _buildSourceSelection(context, show, playingSourceId)
          else
            _buildTrackList(context, show, show.sources.first),
        ],
      ),
    );
  }

  Widget _buildSourceSelection(
      BuildContext context, Show show, String? playingSourceId) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        ...show.sources.map((source) {
          final isSourceExpanded = _expandedShnid == source.id;
          final isSourcePlaying = playingSourceId == source.id;
          return Column(
            key: ValueKey(source.id),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Material(
                  color: isSourcePlaying
                      ? colorScheme.tertiaryContainer.withOpacity(0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () => _onShnidTapped(source.id),
                    onLongPress: () {
                      HapticFeedback.lightImpact();
                      _playSource(show, source);
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Row(
                        children: [
                          AnimatedRotation(
                            turns: isSourceExpanded ? 0.5 : 0,
                            duration: _animationDuration,
                            curve: Curves.easeInOutCubicEmphasized,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: isSourceExpanded
                                    ? colorScheme.primaryContainer
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                size: 18,
                                color: isSourceExpanded
                                    ? colorScheme.onPrimaryContainer
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(source.id,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(
                                    color: isSourcePlaying
                                        ? colorScheme.tertiary
                                        : colorScheme.onSurface,
                                    fontWeight: isSourcePlaying
                                        ? FontWeight.w700
                                        : FontWeight.w600,
                                    letterSpacing: 0.1)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${source.tracks.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
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
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTrackList(BuildContext context, Show show, Source source,
      {bool isNested = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isNested
            ? Theme.of(context).colorScheme.surfaceContainerLowest
            : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: source.tracks
            .map((track) => _buildTrackItem(context, show, track, source))
            .toList(),
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Show show, Track track, Source source) {
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
            final isPlayingTrack = isCurrentlyPlayingSource &&
                indexSnapshot.data == track.trackNumber - 1;

            final titleText = settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                gradient: isPlayingTrack
                    ? LinearGradient(
                  colors: [
                    colorScheme.primaryContainer.withOpacity(0.6),
                    colorScheme.primaryContainer.withOpacity(0.3),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                )
                    : null,
                color: isPlayingTrack ? null : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: isPlayingTrack
                    ? Border.all(
                  color: colorScheme.primary.withOpacity(0.3),
                  width: 1.5,
                )
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    if (isCurrentlyPlayingSource) {
                      audioProvider.seekToTrack(track.trackNumber - 1);
                    } else {
                      _playSource(show, source);
                    }
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        if (isPlayingTrack)
                          Container(
                            margin: const EdgeInsets.only(right: 12),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.play_arrow_rounded,
                              size: 16,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                        Expanded(
                          child: Text(titleText,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isPlayingTrack
                                ? colorScheme.primary.withOpacity(0.2)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                              formatDuration(Duration(seconds: track.duration)),
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
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