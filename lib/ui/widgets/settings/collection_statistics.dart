import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:provider/provider.dart';

class CollectionStatistics extends StatelessWidget {
  const CollectionStatistics({super.key});

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final allShows = showListProvider.allShows;

    int totalShows = allShows.length;
    int totalSources = 0;
    int totalSongs = 0;
    int totalDurationSeconds = 0;

    // Category IDs
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

        // Count Categories
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
        // Check for 'unk' (featured tracks)
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

    final duration = Duration(seconds: totalDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    return SectionCard(
      title: 'Collection Statistics',
      icon: Icons.bar_chart,
      children: [
        ListTile(
          title: const Text('Total Collection'),
          trailing: Text('$totalShows Shows / $totalSources Sources',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ListTile(
          title: const Text('Total Songs'),
          trailing: Text('$totalSongs',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ListTile(
          title: const Text('Total Runtime'),
          trailing: Text('${days}d ${hours}h ${minutes}m',
              style: Theme.of(context).textTheme.titleMedium),
        ),
        ExpansionTile(
          title: const Text('Source Categories'),
          shape: const Border(),
          children: [
            if (catBettySources > 0)
              ListTile(
                  title: const Text('Betty Boards'),
                  trailing: Text(
                      '${catBettyShows.length} Shows / $catBettySources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catUltraSources > 0)
              ListTile(
                  title: const Text('Ultra Matrix'),
                  trailing: Text(
                      '${catUltraShows.length} Shows / $catUltraSources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catMatrixSources > 0)
              ListTile(
                  title: const Text('Matrix'),
                  trailing: Text(
                      '${catMatrixShows.length} Shows / $catMatrixSources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catDsbdSources > 0)
              ListTile(
                  title: const Text('Digital SBD'),
                  trailing: Text(
                      '${catDsbdShows.length} Shows / $catDsbdSources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catFmSources > 0)
              ListTile(
                  title: const Text('FM Broadcast'),
                  trailing: Text(
                      '${catFmShows.length} Shows / $catFmSources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catSbdSources > 0)
              ListTile(
                  title: const Text('Soundboard'),
                  trailing: Text(
                      '${catSbdShows.length} Shows / $catSbdSources Sources',
                      style: Theme.of(context).textTheme.bodyMedium)),
            if (catUnkSources > 0)
              ListTile(
                title: const Text('Unknown Shows'),
                trailing: Text(
                    '${catUnkShows.length} Shows / $catUnkSources Sources',
                    style: Theme.of(context).textTheme.bodyLarge),
              ),
          ],
        ),
      ],
    );
  }
}
