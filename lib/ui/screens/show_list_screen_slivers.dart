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

class ShowListScreenSlivers extends StatefulWidget {
  const ShowListScreenSlivers({super.key});

  @override
  State<ShowListScreenSlivers> createState() => _ShowListScreenSliversState();
}

class _ShowListScreenSliversState extends State<ShowListScreenSlivers> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Show> _allShows = [];
  bool _isLoading = true;
  String? _error;

  String? _expandedShowName;
  String? _expandedShnid;
  bool _isSearchVisible = false;

  @override
  void initState() {
    super.initState();
    _fetchShows();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
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

  void _collapseExpandedShow() {
    logger.i('Collapsing show: "$_expandedShowName"');
    setState(() {
      _expandedShowName = null;
      _expandedShnid = null;
    });
  }

  void _onShowTapped(Show show) {
    if (_expandedShowName == show.name) {
      _collapseExpandedShow();
      return;
    }
    logger.i('Expanding show: "${show.name}"');
    setState(() {
      _expandedShowName = show.name;
      _expandedShnid =
      show.sources.length == 1 ? show.sources.first.id : null;
    });
  }

  void _onShnidTapped(String shnid) {
    setState(() {
      _expandedShnid = (_expandedShnid == shnid) ? null : shnid;
    });
  }

  void _playSource(Show show, Source source) {
    Provider.of<AudioProvider>(context, listen: false).playSource(show, source);
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

  void _toggleSearch() {
    setState(() {
      _isSearchVisible = !_isSearchVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final hasCurrentShow = audioProvider.currentShow != null;

    final filteredShows = _allShows.where((show) {
      if (show.hasFeaturedTrack) {
        return false;
      }
      final query = _searchController.text.toLowerCase();
      if (query.isEmpty) return true;
      return show.venue.toLowerCase().contains(query) ||
          show.formattedDate.toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
            controller: _scrollController,
            slivers: _buildSlivers(context, filteredShows),
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

  List<Widget> _buildSlivers(BuildContext context, List<Show> filteredShows) {
    final bool isExpandedShowFilteredOut = _expandedShowName != null &&
        !filteredShows.any((s) => s.name == _expandedShowName);

    final expandedShow =
    (_expandedShowName != null && !isExpandedShowFilteredOut)
        ? filteredShows.firstWhere((s) => s.name == _expandedShowName)
        : null;

    if (expandedShow == null) {
      // --- MASTER VIEW ---
      return [
        SliverAppBar(
          title: const Text('gdar (Slivers)'),
          floating: true,
          snap: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.search_rounded),
              tooltip: 'Toggle Search',
              onPressed: _toggleSearch,
            ),
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
        if (_isSearchVisible)
          SliverToBoxAdapter(
            child: Padding(
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
              ),
            ),
          ),
        if (_isLoading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
        if (!_isLoading && _error != null)
          SliverFillRemaining(child: Center(child: Text(_error!))),
        if (!_isLoading && _error == null && filteredShows.isEmpty)
          const SliverFillRemaining(
              child: Center(child: Text('No shows match your search or filters.'))),
        if (!_isLoading && _error == null && filteredShows.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.only(bottom: 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                    _buildShowHeader(context, filteredShows[index], false),
                childCount: filteredShows.length,
              ),
            ),
          ),
      ];
    } else {
      // --- DETAIL VIEW ---
      filteredShows.indexWhere((s) => s.name == expandedShow.name);

      final Source? sourceToShow;
      if (expandedShow.sources.length == 1) {
        sourceToShow = expandedShow.sources.first;
      } else if (_expandedShnid != null) {
        sourceToShow = expandedShow.sources
            .firstWhere((s) => s.id == _expandedShnid, orElse: () => expandedShow.sources.first);
      } else {
        sourceToShow = null;
      }

      return [
        SliverAppBar(
          title: Text(expandedShow.venue, style: const TextStyle(fontSize: 18)),
          pinned: true,
          leading: CloseButton(onPressed: _collapseExpandedShow),
        ),
        if (expandedShow.sources.length > 1)
          SliverToBoxAdapter(child: _buildSourceSelection(context, expandedShow)),

        if (sourceToShow != null)
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildTrackItem(
                  context, expandedShow, sourceToShow!.tracks[index], sourceToShow),
              childCount: sourceToShow.tracks.length,
            ),
          )
        else if (expandedShow.sources.length > 1 && sourceToShow == null)
          const SliverFillRemaining(
              child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Text('Select a source (shnid) to see tracks.',
                        textAlign: TextAlign.center),
                  ))),
        const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
      ];
    }
  }

  Widget _buildShowHeader(BuildContext context, Show show, bool isExpanded) {
    final audioProvider = context.watch<AudioProvider>();
    final isPlaying = audioProvider.currentShow?.name == show.name;
    final colorScheme = Theme.of(context).colorScheme;

    final cardBorderColor = isPlaying
        ? colorScheme.primary
        : show.hasFeaturedTrack
        ? colorScheme.tertiary
        : colorScheme.outlineVariant;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Card(
        margin: EdgeInsets.zero,
        elevation: isExpanded ? 4 : 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: cardBorderColor,
            width: (isPlaying || show.hasFeaturedTrack) ? 1.5 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onShowTapped(show),
          onLongPress: () {
            HapticFeedback.mediumImpact();
            context.read<AudioProvider>().playShow(show);
          },
          child: ListTile(
            title: Text(
              show.venue,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600, color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              show.formattedDate,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            trailing:
            (show.sources.length > 1) ? _buildBadge(context, show) : null,
          ),
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context, Show show) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12)),
      child: Text('${show.sources.length}',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildSourceSelection(BuildContext context, Show show) {
    final audioProvider = context.watch<AudioProvider>();
    final playingSourceId =
    audioProvider.currentShow?.name == show.name ? audioProvider.currentSource?.id : null;
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select a source (shnid)',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...show.sources.map((source) {
            final isSelected = _expandedShnid == source.id;
            final isPlaying = playingSourceId == source.id;
            return Card(
              elevation: 0,
              color: isSelected
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceContainerHighest,
              child: ListTile(
                title: Text(
                  source.id,
                  style: TextStyle(
                    fontWeight: isPlaying || isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isPlaying ? colorScheme.primary : null,
                  ),
                ),
                subtitle: Text('${source.tracks.length} tracks'),
                onTap: () => _onShnidTapped(source.id),
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  _playSource(show, source);
                },
                selected: isSelected,
              ),
            );
          }),
        ],
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

            return ListTile(
              title: Text(titleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isPlayingTrack
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                      fontWeight:
                      isPlayingTrack ? FontWeight.w600 : FontWeight.normal)),
              trailing: Text(formatDuration(Duration(seconds: track.duration)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500)),
              onTap: () {
                if (isCurrentlyPlayingSource) {
                  audioProvider.seekToTrack(track.trackNumber - 1);
                } else {
                  _playSource(show, source);
                }
              },
              selected: isPlayingTrack,
            );
          },
        );
      },
    );
  }
}

