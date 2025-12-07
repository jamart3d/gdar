import 'dart:math';

import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/ui/widgets/show_list_card.dart';
import 'package:gdar/ui/widgets/source_list_item.dart';
import 'package:provider/provider.dart';

class RatedShowsScreen extends StatefulWidget {
  const RatedShowsScreen({super.key});

  @override
  State<RatedShowsScreen> createState() => _RatedShowsScreenState();
}

class _RatedShowsScreenState extends State<RatedShowsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<int> _tabs = [
    -2,
    3,
    2,
    1,
    -1
  ]; // Played, 3 Stars, 2 Stars, 1 Star, Blocked

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _getShowCount(int rating, SettingsProvider settingsProvider,
      ShowListProvider showListProvider) {
    if (showListProvider.allShows.isEmpty) return 0;

    return showListProvider.allShows.where((show) {
      final showRating = settingsProvider.getRating(show.name);

      // Blocked (-1)
      if (rating == -1) {
        if (showRating == -1) return true;
        for (var source in show.sources) {
          if (settingsProvider.getRating(source.id) == -1) return true;
        }
        return false;
      }

      // Played (-2)
      if (rating == -2) {
        if (settingsProvider.isPlayed(show.name)) return true;
        for (var source in show.sources) {
          if (settingsProvider.isPlayed(source.id)) return true;
        }
        return false;
      }

      // Stars
      if (showRating == rating) return true;
      for (var source in show.sources) {
        if (settingsProvider.getRating(source.id) == rating) return true;
      }
      return false;
    }).length;
  }

  String _getTabLabel(int rating, int count) {
    String baseLabel;
    if (rating == -1) {
      baseLabel = 'Blocked';
    } else if (rating == -2) {
      baseLabel = 'Played';
    } else {
      baseLabel = '$rating Star${rating > 1 ? 's' : ''}';
    }
    return '$baseLabel ($count)';
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();
    final scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;
    final textTheme = Theme.of(context).textTheme;

    final appBarTitleStyle = textTheme.titleLarge?.copyWith(
      fontSize: (textTheme.titleLarge?.fontSize ?? 22.0) * scaleFactor,
    );
    final tabLabelStyle = textTheme.labelLarge?.copyWith(
      fontSize: (textTheme.labelLarge?.fontSize ?? 14.0) * scaleFactor,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Rated Shows Library',
          style: appBarTitleStyle,
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelStyle: tabLabelStyle,
          unselectedLabelStyle: tabLabelStyle,
          tabs: _tabs.map((r) {
            final count = _getShowCount(r, settingsProvider, showListProvider);
            return Tab(text: _getTabLabel(r, count));
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children:
            _tabs.map((rating) => _RatedShowList(rating: rating)).toList(),
      ),
    );
  }
}

class _RatedShowList extends StatefulWidget {
  final int rating;

  const _RatedShowList({required this.rating});

  @override
  State<_RatedShowList> createState() => _RatedShowListState();
}

class _RatedShowListState extends State<_RatedShowList> {
  String? _expandedShowName;

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.read<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();

    // 1. Get all shows
    final allShows = showListProvider.allShows;

    // 2. Filter by rating
    final filteredShows = allShows.where((show) {
      final showRating = settingsProvider.getRating(show.name);

      // If filtering for Blocked (-1), include shows that are blocked
      // OR shows that have any blocked source.
      if (widget.rating == -1) {
        if (showRating == -1) return true;
        for (var source in show.sources) {
          if (settingsProvider.getRating(source.id) == -1) return true;
        }
        return false;
      }

      // If filtering for Played (-2), include shows that are marked played
      // OR shows that have any played source.
      if (widget.rating == -2) {
        if (settingsProvider.isPlayed(show.name)) return true;
        for (var source in show.sources) {
          if (settingsProvider.isPlayed(source.id)) return true;
        }
        return false;
      }

      // for positive ratings, check show OR any source
      if (showRating == widget.rating) return true;
      for (var source in show.sources) {
        if (settingsProvider.getRating(source.id) == widget.rating) return true;
      }
      return false;
    }).toList();

    if (filteredShows.isEmpty) {
      return Center(
        child:
            Text('No shows found with rating: ${_getTabLabel(widget.rating)}'),
      );
    }

    return ListView.builder(
      itemCount: filteredShows.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final show = filteredShows[index];
        final isExpanded = _expandedShowName == show.name;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Column(
            children: [
              ShowListCard(
                show: show,
                isExpanded: isExpanded,
                isPlaying: audioProvider.currentShow?.name == show.name,
                playingSourceId: audioProvider.currentSource?.id,
                isLoading: false,
                alwaysShowRatingInteraction: true,
                onTap: () {
                  if (show.sources.length <= 1) return;
                  setState(() {
                    if (_expandedShowName == show.name) {
                      _expandedShowName = null;
                    } else {
                      _expandedShowName = show.name;
                    }
                  });
                },
                onLongPress: () {
                  final showRating = settingsProvider.getRating(show.name);
                  if (showRating == -1) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Cannot play blocked show')),
                    );
                    return;
                  }

                  // Filter out blocked sources
                  final validSources = show.sources.where((s) {
                    return settingsProvider.getRating(s.id) != -1;
                  }).toList();

                  if (validSources.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('No unblocked sources available')),
                    );
                    return;
                  }

                  // Pick random source
                  final source =
                      validSources[Random().nextInt(validSources.length)];
                  HapticFeedback.mediumImpact();
                  audioProvider.playSource(show, source);
                },
              ),
              if (isExpanded)
                _buildSourceList(
                    context, show, audioProvider, settingsProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSourceList(BuildContext context, Show show,
      AudioProvider audioProvider, SettingsProvider settingsProvider) {
    // Determine scale factor for SourceListItem, matching ShowListItemDetails logic
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return Container(
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.3),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: show.sources.map((source) {
          final isPlaying = audioProvider.currentSource?.id == source.id;
          final sourceRating = settingsProvider.getRating(source.id);
          final isBlocked = sourceRating == -1;

          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: SourceListItem(
              source: source,
              isSourcePlaying: isPlaying,
              scaleFactor: scaleFactor,
              borderRadius: 20, // Match ShowListItemDetails default
              alwaysShowRatingInteraction: true,
              onTap: () {
                // User requested single tap should not play.
                // Playback is handled via long-press only for this screen.
              },
              onLongPress: () {
                if (isBlocked) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cannot play blocked source')),
                  );
                  return;
                }
                HapticFeedback.mediumImpact();
                audioProvider.playSource(show, source);
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _getTabLabel(int rating) {
    if (rating == -1) return 'Blocked';
    if (rating == -2) return 'Played';
    return '$rating Star${rating > 1 ? 's' : ''}';
  }
}
