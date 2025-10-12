import 'package:flutter/material.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/widgets/mini_player.dart';
import 'package:gdar/ui/widgets/show_list_item.dart';
import 'package:provider/provider.dart';

class ShowListScreen extends StatefulWidget {
  const ShowListScreen({super.key});

  @override
  State<ShowListScreen> createState() => _ShowListScreenState();
}

class _ShowListScreenState extends State<ShowListScreen> {
  final TextEditingController _searchController = TextEditingController();

  List<Show> _allShows = [];
  List<Show> _filteredShows = [];
  bool _isLoading = true;
  String? _error;

  String? _expandedShowName;
  String? _expandedShnid;

  @override
  void initState() {
    super.initState();
    _fetchShows();
    _searchController.addListener(_filterShows);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchShows() async {
    try {
      final shows = await ShowService.instance.getShows();
      setState(() {
        _allShows = shows;
        _filteredShows = shows;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = "Failed to load shows. Please restart the app.";
        _isLoading = false;
      });
    }
  }

  void _filterShows() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredShows = _allShows.where((show) {
        final venueMatches = show.venue.toLowerCase().contains(query);
        final dateMatches = show.formattedDate.toLowerCase().contains(query);
        return venueMatches || dateMatches;
      }).toList();
    });
  }

  void _playSource(Show show, Source source) {
    Provider.of<AudioProvider>(context, listen: false).playSource(show, source);
  }

  void _onShowTapped(Show show) {
    setState(() {
      if (_expandedShowName == show.name) {
        _expandedShowName = null;
        _expandedShnid = null;
      } else {
        _expandedShowName = show.name;
        if (show.sources.length == 1) {
          _expandedShnid = show.sources.first.id;
        } else {
          _expandedShnid = null;
        }
      }
    });
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
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
        const PlaybackScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOutCubicEmphasized;
          var tween =
          Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);
          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: 16),
              Text(_error!,
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () {
                  setState(() {
                    _isLoading = true;
                    _error = null;
                  });
                  _fetchShows();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    if (_filteredShows.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                _searchController.text.isEmpty
                    ? Icons.music_off_rounded
                    : Icons.search_off_rounded,
                size: 64,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No shows available.'
                  : 'No shows match your search.',
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }
    final audioProvider = context.watch<AudioProvider>();
    final currentShow = audioProvider.currentShow;
    final currentSource = audioProvider.currentSource;

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100),
      itemCount: _filteredShows.length,
      itemBuilder: (context, index) {
        final show = _filteredShows[index];
        final isCurrentlyPlayingShow = currentShow?.name == show.name;

        return ShowListItem(
          show: show,
          isExpanded: _expandedShowName == show.name,
          expandedSourceId:
          _expandedShowName == show.name ? _expandedShnid : null,
          onToggleExpand: () => _onShowTapped(show),
          onPlaySource: (source) => _playSource(show, source),
          onToggleSourceExpand: _onShnidTapped,
          isPlaying: isCurrentlyPlayingShow,
          playingSourceId:
          isCurrentlyPlayingShow ? currentSource?.id : null,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final hasCurrentShow = audioProvider.currentShow != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('gdar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            tooltip: 'Settings',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: SearchBar(
                  controller: _searchController,
                  hintText: 'Search by venue or date',
                  leading: const Icon(Icons.search_rounded),
                  trailing: _searchController.text.isNotEmpty
                      ? [
                    IconButton(
                      icon: const Icon(Icons.clear_rounded),
                      onPressed: () => _searchController.clear(),
                    ),
                  ]
                      : null,
                  elevation: const WidgetStatePropertyAll(0),
                  shape: WidgetStatePropertyAll(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                      side: BorderSide(
                          color: Theme.of(context).colorScheme.outline),
                    ),
                  ),
                ),
              ),
              Expanded(child: _buildBody()),
            ],
          ),
          if (hasCurrentShow)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                onTap: _openPlaybackScreen,
              ),
            ),
        ],
      ),
    );
  }
}


