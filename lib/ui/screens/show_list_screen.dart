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
  late final Animation<double> _sizeAnimation;
  Completer<void>? _collapseCompleter;

  static const Duration _animationDuration = Duration(milliseconds: 300);

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: _animationDuration);
    _sizeAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOutCubicEmphasized);

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.dismissed) {
        if (_collapseCompleter != null && !_collapseCompleter!.isCompleted) {
          logger.d('Collapse animation finished, completing the future.');
          _collapseCompleter!.complete();
        }
      }
    });

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

  bool _isItemAtTop(int index) {
    final positions = _itemPositionsListener.itemPositions.value;
    try {
      final targetPosition = positions.firstWhere((pos) => pos.index == index);
      return targetPosition.itemLeadingEdge == 0.0;
    } catch (e) {
      return false;
    }
  }

  Future<void> _collapseCurrentShow() async {
    _collapseCompleter = Completer<void>();
    if (mounted) {
      setState(() {
        _expandedShowName = null;
        _expandedShnid = null;
      });
    }
    _animationController.reverse();
    await _collapseCompleter!.future;
  }

  Future<void> _onShowTapped(Show show, List<Show> currentlyVisibleShows) async {
    logger.i('onShowTapped started for show: "${show.name}"');
    final isAlreadyExpanded = _expandedShowName == show.name;
    final isAnotherItemExpanded = _expandedShowName != null && !isAlreadyExpanded;
    final targetIndex = currentlyVisibleShows.indexOf(show);

    if (isAlreadyExpanded) {
      logger.i('Collapsing the same show: "${show.name}"');
      await _collapseCurrentShow();
      return;
    }

    if (isAnotherItemExpanded) {
      logger.i('Another show is expanded. Starting collapse for "${_expandedShowName}".');
      await _collapseCurrentShow();
    }

    if (!mounted || targetIndex == -1) return;

    if (!_isItemAtTop(targetIndex)) {
      logger.i('Item "${show.name}" is not at the top. Scrolling now.');
      final scrollCompleter = Completer<void>();
      final scrollListener = () {
        if (_isItemAtTop(targetIndex)) {
          if (!scrollCompleter.isCompleted) {
            scrollCompleter.complete();
          }
        }
      };
      _itemPositionsListener.itemPositions.addListener(scrollListener);
      await _itemScrollController.scrollTo(index: targetIndex, duration: _animationDuration, curve: Curves.easeInOut);
      await scrollCompleter.future;
      _itemPositionsListener.itemPositions.removeListener(scrollListener);
      logger.i('Scroll for "${show.name}" is complete.');
    } else {
      logger.i('Item "${show.name}" is already at top. No scroll needed.');
    }

    if (mounted) {
      logger.i('Expanding show: "${show.name}"');
      setState(() {
        _expandedShowName = show.name;
        _expandedShnid = show.sources.length == 1 ? show.sources.first.id : null;
      });
      _animationController.forward();
    }
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
      pageBuilder: (context, animation, secondaryAnimation) => const PlaybackScreen(),
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const begin = Offset(0.0, 1.0);
        const end = Offset.zero;
        const curve = Curves.easeInOutCubicEmphasized;
        var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
        return SlideTransition(position: animation.drive(tween), child: child);
      },
      transitionDuration: const Duration(milliseconds: 500),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    // SettingsProvider is no longer needed for filtering, but might be for track numbers
    context.watch<SettingsProvider>();
    final hasCurrentShow = audioProvider.currentShow != null;

    // ** Internal variable for the setting **
    const bool hideGdShowsInternally = true;

    final filteredShows = _allShows.where((show) {
      // 1. Setting filter using the internal variable
      if (hideGdShowsInternally && show.hasFeaturedTrack) {
        return false;
      }

      // 2. Search query filter
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
          IconButton(icon: const Icon(Icons.search_rounded), tooltip: 'Search', onPressed: _toggleSearch),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
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
                          ? [IconButton(icon: const Icon(Icons.clear_rounded), onPressed: () => _searchController.clear())]
                          : null,
                      elevation: const WidgetStatePropertyAll(0),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                        side: BorderSide(color: Theme.of(context).colorScheme.outline),
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
      return const Center(child: Text('No shows match your search or filters.'));
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
            _buildShowHeader(context, show, isExpanded, isPlaying, filteredShows),
            SizeTransition(
              sizeFactor: _sizeAnimation,
              axisAlignment: -1.0,
              child: isExpanded ? _buildExpandedContent(context, show, playingSourceId) : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildShowHeader(BuildContext context, Show show, bool isExpanded, bool isPlaying, List<Show> filteredShows) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMultipleSources = show.sources.length > 1;

    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cardBorderColor,
            width: (isPlaying || show.hasFeaturedTrack) ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onShowTapped(show, filteredShows),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            context.read<AudioProvider>().playShow(show);
          },
          child: Container(
            color: Colors.transparent,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: _animationDuration,
                    curve: Curves.easeInOutCubicEmphasized,
                    child: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(show.venue,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(show.formattedDate,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant)),
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
    );
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(12)),
      child: Text('${show.sources.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildExpandedContent(BuildContext context, Show show, String? playingSourceId) {
    if (show.sources.isEmpty) {
      return const Padding(
        padding: EdgeInsets.fromLTRB(16.0, 0, 16.0, 16.0),
        child: Text('No tracks available for this show.'),
      );
    }
    final hasMultipleSources = show.sources.length > 1;
    return Column(
      children: [
        if (hasMultipleSources)
          _buildSourceSelection(context, show, playingSourceId)
        else
          _buildTrackList(context, show, show.sources.first),
      ],
    );
  }

  Widget _buildSourceSelection(BuildContext context, Show show, String? playingSourceId) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text('shnid', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
        ),
        ...show.sources.map((source) {
          final isSourceExpanded = _expandedShnid == source.id;
          final isSourcePlaying = playingSourceId == source.id;
          return Column(
            key: ValueKey(source.id),
            children: [
              ListTile(
                leading: AnimatedRotation(
                  turns: isSourceExpanded ? 0.5 : 0,
                  duration: _animationDuration,
                  curve: Curves.easeInOutCubicEmphasized,
                  child: Icon(Icons.keyboard_arrow_down_rounded, color: colorScheme.onSurfaceVariant),
                ),
                title: Text(source.id, style: TextStyle(color: isSourcePlaying ? colorScheme.primary : null, fontWeight: isSourcePlaying ? FontWeight.bold : null)),
                trailing: Text('${source.tracks.length} tracks', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant)),
                onTap: () => _onShnidTapped(source.id),
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  _playSource(show, source);
                },
              ),
              AnimatedSize(
                duration: _animationDuration,
                curve: Curves.easeInOutCubicEmphasized,
                child: isSourceExpanded ? _buildTrackList(context, show, source, isNested: true) : const SizedBox.shrink(),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTrackList(BuildContext context, Show show, Source source, {bool isNested = false}) {
    return Container(
      color: isNested ? Theme.of(context).colorScheme.surfaceContainerLowest : Colors.transparent,
      child: Column(
        children: source.tracks.map((track) => _buildTrackItem(context, show, track, source)).toList(),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, Show show, Track track, Source source) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      builder: (context, indexSnapshot) {
        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          builder: (context, stateSnapshot) {
            final isCurrentlyPlayingSource = audioProvider.currentSource?.id == source.id;
            final isPlayingTrack = isCurrentlyPlayingSource && indexSnapshot.data == track.trackNumber - 1;

            final titleText = settingsProvider.showTrackNumbers ? '${track.trackNumber}. ${track.title}' : track.title;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPlayingTrack ? colorScheme.primaryContainer.withOpacity(0.5) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                title: Text(titleText,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: isPlayingTrack ? colorScheme.primary : colorScheme.onSurface,
                        fontWeight: isPlayingTrack ? FontWeight.w600 : FontWeight.normal)),
                trailing: Text(formatDuration(Duration(seconds: track.duration)),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant, fontWeight: FontWeight.w500)),
                onTap: () {
                  if (isCurrentlyPlayingSource) {
                    audioProvider.seekToTrack(track.trackNumber - 1);
                  } else {
                    // This behavior starts the whole source, not just one track.
                    _playSource(show, source);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }
}

