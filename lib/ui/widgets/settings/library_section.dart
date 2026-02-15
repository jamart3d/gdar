import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:provider/provider.dart';

class LibrarySection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const LibrarySection({
    super.key,
    required this.scaleFactor,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final allShows = showListProvider.allShows;
    final isTv = context.watch<DeviceService>().isTv;

    int totalShows = allShows.length;
    int totalSources = 0;
    int totalSongs = 0;
    int totalDurationSeconds = 0;

    // Category calculation logic
    int catBettySources = 0;
    int catUltraSources = 0;
    int catMatrixSources = 0;
    int catDsbdSources = 0;
    int catFmSources = 0;
    int catSbdSources = 0;
    int catUnkSources = 0;

    Set<Show> catBettyShows = {};
    Set<Show> catUltraShows = {};
    Set<Show> catMatrixShows = {};
    Set<Show> catDsbdShows = {};
    Set<Show> catFmShows = {};
    Set<Show> catSbdShows = {};
    Set<Show> catUnkShows = {};

    for (var show in allShows) {
      totalSources += show.sources.length;
      for (var source in show.sources) {
        totalSongs += source.tracks.length;
        for (var track in source.tracks) {
          totalDurationSeconds += track.duration;
        }

        final srcType = source.src?.toLowerCase() ?? '';
        final url = source.tracks.isNotEmpty
            ? source.tracks.first.url.toLowerCase()
            : '';

        Set<String> cats = {};
        if (srcType == 'ultra' ||
            url.contains('ultra') ||
            url.contains('healy')) {
          cats.add('ultra');
        }
        if (url.contains('betty') || url.contains('bbd')) {
          cats.add('betty');
        }
        if (srcType == 'mtx' ||
            srcType == 'matrix' ||
            url.contains('mtx') ||
            url.contains('matrix')) {
          cats.add('matrix');
        }
        if (url.contains('dsbd')) {
          cats.add('dsbd');
        }
        if (url.contains('fm') ||
            url.contains('prefm') ||
            url.contains('pre-fm')) {
          cats.add('fm');
        }
        if (srcType == 'sbd' || url.contains('sbd')) {
          cats.add('sbd');
        }
        bool hasFeatTrack = source.tracks
            .any((track) => track.title.toLowerCase().startsWith('gd'));
        if (hasFeatTrack) {
          cats.add('unk');
        }

        if (cats.contains('betty')) {
          catBettySources++;
          catBettyShows.add(show);
        }
        if (cats.contains('ultra')) {
          catUltraSources++;
          catUltraShows.add(show);
        }
        if (cats.contains('matrix')) {
          catMatrixSources++;
          catMatrixShows.add(show);
        }
        if (cats.contains('dsbd')) {
          catDsbdSources++;
          catDsbdShows.add(show);
        }
        if (cats.contains('fm')) {
          catFmSources++;
          catFmShows.add(show);
        }
        if (cats.contains('sbd')) {
          catSbdSources++;
          catSbdShows.add(show);
        }
        if (cats.contains('unk')) {
          catUnkSources++;
          catUnkShows.add(show);
        }
      }
    }

    final List<Map<String, dynamic>> categories = [];
    if (catBettySources > 0) {
      categories.add({
        'name': 'Betty Boards',
        'shows': catBettyShows.length,
        'sources': catBettySources
      });
    }
    if (catUltraSources > 0) {
      categories.add({
        'name': 'Ultra Matrix',
        'shows': catUltraShows.length,
        'sources': catUltraSources
      });
    }
    if (catMatrixSources > 0) {
      categories.add({
        'name': 'Matrix',
        'shows': catMatrixShows.length,
        'sources': catMatrixSources
      });
    }
    if (catDsbdSources > 0) {
      categories.add({
        'name': 'Digital SBD',
        'shows': catDsbdShows.length,
        'sources': catDsbdSources
      });
    }
    if (catFmSources > 0) {
      categories.add({
        'name': 'FM Broadcast',
        'shows': catFmShows.length,
        'sources': catFmSources
      });
    }
    if (catSbdSources > 0) {
      categories.add({
        'name': 'Soundboard',
        'shows': catSbdShows.length,
        'sources': catSbdSources
      });
    }
    if (catUnkSources > 0) {
      categories.add({
        'name': 'Unknown Shows',
        'shows': catUnkShows.length,
        'sources': catUnkSources
      });
    }

    Widget buildCategoryItem(Map<String, dynamic> cat) {
      return ListTile(
        dense: true,
        visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            cat['name'],
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: (isTv ? 12 : 10) * scaleFactor,
                  fontWeight: isTv ? FontWeight.w500 : FontWeight.normal,
                ),
          ),
        ),
        trailing: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            '${cat['shows']} Shows / ${cat['sources']} Sources',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: (isTv ? 10 : 8.5) * scaleFactor,
                ),
          ),
        ),
      );
    }

    final duration = Duration(seconds: totalDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Library',
      initiallyExpanded: initiallyExpanded,
      icon: Icons.library_music_rounded,
      children: [
        // 1. Rated Shows Library Link
        TvListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.star_rate_rounded,
              size: (isTv ? 28 : 24) * scaleFactor, color: colorScheme.primary),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Rated Shows Library',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: (isTv ? 18 : 16) * scaleFactor,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.primary,
                  ),
            ),
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Manage and play your rated shows',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: (isTv ? 14 : 12) * scaleFactor,
                  ),
            ),
          ),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
          onTap: () async {
            HapticFeedback.lightImpact();
            // Pause global clock
            try {
              context.read<AnimationController>().stop();
            } catch (_) {}

            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const RatedShowsScreen(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = 0.92;
                  const end = 1.0;
                  const curve = Curves.easeOutCubic;
                  var scaleTween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  var fadeTween = Tween(begin: 0.0, end: 1.0)
                      .chain(CurveTween(curve: curve));
                  return FadeTransition(
                    opacity: animation.drive(fadeTween),
                    child: ScaleTransition(
                      scale: animation.drive(scaleTween),
                      child: child,
                    ),
                  );
                },
                transitionDuration: const Duration(milliseconds: 400),
                reverseTransitionDuration: const Duration(milliseconds: 350),
              ),
            );

            // Resume clock
            if (context.mounted) {
              try {
                final controller = context.read<AnimationController>();
                if (!controller.isAnimating) controller.repeat();
              } catch (_) {}
            }
          },
        ),

        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: Divider(),
        ),

        // 2. Collection Stats
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.bar_chart_rounded,
              size: (isTv ? 28 : 24) * scaleFactor,
              color: colorScheme.secondary),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$totalShows Total Shows',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: (isTv ? 18 : 16) * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$totalSources Sources / $totalSongs Songs',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: (isTv ? 14 : 12) * scaleFactor,
                  ),
            ),
          ),
        ),

        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.timer_rounded,
              size: (isTv ? 28 : 24) * scaleFactor,
              color: colorScheme.secondary),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${days}d ${hours}h Total Runtime',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: (isTv ? 18 : 16) * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ),

        ExpansionTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Text(
            'Source Type Breakdown',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: (isTv ? 16 : 14) * scaleFactor,
                  fontWeight: FontWeight.w500,
                ),
          ),
          leading: Icon(Icons.list_alt_rounded,
              size: (isTv ? 24 : 20) * scaleFactor),
          shape: const Border(),
          children: [
            isTv
                ? GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 5,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 0,
                    ),
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      return buildCategoryItem(categories[index]);
                    },
                  )
                : Column(
                    children: categories
                        .map((cat) => buildCategoryItem(cat))
                        .toList(),
                  ),
          ],
        ),
      ],
    );
  }
}
