import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/track_list_screen.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shakedown/models/rating.dart';

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

  int _getShowCount(int rating, ShowListProvider showListProvider) {
    if (showListProvider.allShows.isEmpty) return 0;
    final catalog = CatalogService(); // Use service directly

    int count = 0;

    for (var show in showListProvider.allShows) {
      final showRating = catalog.getRating(show.name);

      // Played (-2) - Match deduplication logic
      if (rating == -2) {
        int explicitCount = 0;
        for (var source in show.sources) {
          if (catalog.isPlayed(source.id)) {
            explicitCount++;
          }
        }
        count += explicitCount;
      }
      // Other Ratings
      else {
        for (var source in show.sources) {
          final sourceRating = catalog.getRating(source.id);
          int effectiveRating;
          if (sourceRating != 0) {
            effectiveRating = sourceRating;
          } else {
            if (showRating == -1) {
              effectiveRating = -1;
            } else if (show.sources.length == 1) {
              effectiveRating = showRating;
            } else {
              effectiveRating = 0;
            }
          }

          // Match check
          bool match = false;
          if (rating == -1) {
            if (effectiveRating == -1) match = true;
          } else {
            if (effectiveRating == rating) match = true;
          }

          if (match) {
            count++;
          }
        }
      }
    }
    return count;
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
    // Only watch ShowListProvider, not SettingsProvider (at least for data)
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider =
        context.watch<SettingsProvider>(); // Still needed for uiScale? Yes.
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: ValueListenableBuilder<Box<bool>>(
            valueListenable: CatalogService().historyListenable,
            builder: (context, historyBox, _) {
              return ValueListenableBuilder<Box<Rating>>(
                  valueListenable: CatalogService().ratingsListenable,
                  builder: (context, ratingsBox, _) {
                    return TabBar(
                      controller: _tabController,
                      isScrollable: true,
                      labelStyle: tabLabelStyle,
                      unselectedLabelStyle: tabLabelStyle,
                      tabs: _tabs.map((r) {
                        final count = _getShowCount(r, showListProvider);
                        return Tab(text: _getTabLabel(r, count));
                      }).toList(),
                    );
                  });
            },
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<bool>>(
        valueListenable: CatalogService().historyListenable,
        builder: (context, historyBox, _) {
          return ValueListenableBuilder<Box<Rating>>(
              valueListenable: CatalogService().ratingsListenable,
              builder: (context, ratingsBox, _) {
                return TabBarView(
                  controller: _tabController,
                  children: _tabs
                      .map((rating) => _RatedShowList(rating: rating))
                      .toList(),
                );
              });
        },
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
  @override
  Widget build(BuildContext context) {
    final showListProvider = context.read<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final catalog = CatalogService();

    // 1. Get all shows
    final allShows = showListProvider.allShows;

    // 2. Flatten relevant sources into a single list
    final List<({Show show, Source source})> flatSources = [];

    for (var show in allShows) {
      final showRating = catalog.getRating(show.name);

      // Special handling for "Played" tab to avoid duplicates
      if (widget.rating == -2) {
        // 1. Find sources explicitly marked as played
        final explicitlyPlayedSources =
            show.sources.where((s) => catalog.isPlayed(s.id)).toList();

        for (var source in explicitlyPlayedSources) {
          flatSources.add((show: show, source: source));
        }
        continue; // Done with this show for Played tab
      }

      // Logic for Ratings (-1, 1, 2, 3)
      for (var source in show.sources) {
        final sourceRating = catalog.getRating(source.id);

        // Calculate Effective Rating
        int effectiveRating;
        if (sourceRating != 0) {
          effectiveRating = sourceRating;
        } else {
          // Fallback Logic
          if (showRating == -1) {
            // Always inherit blocking
            effectiveRating = -1;
          } else if (show.sources.length == 1) {
            // Inherit positive rating ONLY for single-source
            effectiveRating = showRating;
          } else {
            effectiveRating = 0;
          }
        }

        bool match = false;

        // Blocked (-1)
        if (widget.rating == -1) {
          // Strict check: Is this specific source effectively blocked?
          if (effectiveRating == -1) match = true;
        }
        // Stars (1, 2, 3)
        else {
          if (effectiveRating == widget.rating) match = true;
        }

        if (match) {
          flatSources.add((show: show, source: source));
        }
      }
    }

    if (flatSources.isEmpty) {
      return Center(
        child:
            Text('No shows found with rating: ${_getTabLabel(widget.rating)}'),
      );
    }

    return ListView.builder(
      itemCount: flatSources.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final item = flatSources[index];
        final show = item.show;
        final source = item.source;

        final isPlaying = audioProvider.currentSource?.id == source.id;
        final rating = catalog.getRating(source.id);

        // Customize the item presentation
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: _buildRatedSourceItem(
            context,
            show,
            source,
            isPlaying,
            rating,
            settingsProvider,
            audioProvider,
          ),
        );
      },
    );
  }

  Widget _buildRatedSourceItem(
      BuildContext context,
      Show show,
      Source source,
      bool isPlaying,
      int rating,
      SettingsProvider settingsProvider,
      AudioProvider audioProvider) {
    final catalog = CatalogService();
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
    final colorScheme = Theme.of(context).colorScheme;

    // Use SourceListItem logic but wrapped with Show info
    return Material(
      color: isPlaying
          ? colorScheme.tertiaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isPlaying) {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const PlaybackScreen()),
            );
          } else {
            final singleSourceShow = show.copyWith(sources: [source]);
            Navigator.of(context).push(
              MaterialPageRoute(
                  builder: (_) => TrackListScreen(
                      show: singleSourceShow,
                      source: singleSourceShow.sources.first)),
            );
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          audioProvider.playSource(show, source);
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            children: [
              // Rating
              RatingControl(
                rating: catalog.getRating(source.id),
                size: 18 * scaleFactor,
                isPlayed: catalog.isPlayed(source.id),
                onTap: () async {
                  final currentRating = catalog.getRating(source.id);
                  await showDialog(
                    context: context,
                    builder: (context) => RatingDialog(
                      initialRating: currentRating,
                      sourceId: source.id,
                      sourceUrl: source.tracks.isNotEmpty
                          ? source.tracks.first.url
                          : null,
                      isPlayed: catalog.isPlayed(source.id),
                      onRatingChanged: (newRating) {
                        catalog.setRating(source.id, newRating);
                      },
                      onPlayedChanged: (bool isPlayed) {
                        if (isPlayed != catalog.isPlayed(source.id)) {
                          catalog.togglePlayed(source.id);
                        }
                      },
                    ),
                  );
                },
              ),
              const SizedBox(width: 12),
              // Content: Just the Date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      show.formattedDateYearFirst,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isPlaying
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSurface,
                          )
                          .apply(fontSizeFactor: scaleFactor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    ValueListenableBuilder(
                      valueListenable: CatalogService().playCountsListenable,
                      builder: (context, box, _) {
                        final count = box.get(source.id) ?? 0;
                        if (count > 0) {
                          return Text(
                            'Played $count time${count == 1 ? '' : 's'}',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: isPlaying
                                      ? colorScheme.onTertiaryContainer
                                          .withValues(alpha: 0.8)
                                      : colorScheme.onSurfaceVariant,
                                )
                                .apply(fontSizeFactor: scaleFactor),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ],
                ),
              ),
              // Badge
              if (source.src != null) ...[
                const SizedBox(width: 8),
                SrcBadge(src: source.src!, isPlaying: isPlaying),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _getTabLabel(int rating) {
    if (rating == -1) return 'Blocked';
    if (rating == -2) return 'Played';
    return '$rating Star${rating > 1 ? 's' : ''}';
  }
}
