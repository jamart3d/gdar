import 'package:flutter/material.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/services/device_service.dart';

class CollectionStatistics extends StatelessWidget {
  final bool initiallyExpanded;

  const CollectionStatistics({
    super.key,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final allShows = showListProvider.allShows;
    final isTv = context.watch<DeviceService>().isTv;
    final scaleFactor = isTv ? 1.0 : 1.0; // Keep it simple for now

    int totalShows = allShows.length;
    int totalSources = 0;
    int totalSongs = 0;
    int totalDurationSeconds = 0;

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

    final duration = Duration(seconds: totalDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Collection Statistics',
      initiallyExpanded: initiallyExpanded,
      icon: Icons.bar_chart,
      children: [
        ListTile(
          dense: true,
          title: Text('$totalShows Total Shows'),
          subtitle: Text('$totalSources Sources / $totalSongs Songs'),
        ),
        ListTile(
          dense: true,
          title: Text('${days}d ${hours}h Total Runtime'),
        ),
        ExpansionTile(
          dense: true,
          title: const Text('Source Categories Details'),
          leading: const Icon(Icons.list_alt_rounded),
          children: categories.map((cat) {
            return ListTile(
              dense: true,
              title: Text(cat['name']),
              trailing: Text('${cat['shows']} Shows / ${cat['sources']} Src'),
            );
          }).toList(),
        ),
      ],
    );
  }
}
