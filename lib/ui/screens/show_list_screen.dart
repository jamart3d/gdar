// lib/ui/screens/show_list_screen.dart

import 'package:flutter/material.dart';
import 'package:gdar/api/show_service.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
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

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_filteredShows.isEmpty) {
      return const Center(child: Text('No shows found.'));
    }

    return ListView.builder(
      itemCount: _filteredShows.length,
      itemBuilder: (context, index) {
        final show = _filteredShows[index];
        return ShowListItem(
          show: show,
          onTap: () {
            // Use the AudioProvider to play the selected show
            Provider.of<AudioProvider>(context, listen: false).playShow(show);

            // Navigate to the playback screen
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaybackScreen()),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('gdar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search by venue or date',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () => _searchController.clear(),
                )
                    : null,
              ),
            ),
          ),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}