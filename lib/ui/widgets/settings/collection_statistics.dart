import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:provider/provider.dart';

class CollectionStatistics extends StatelessWidget {
  final bool initiallyExpanded;

  const CollectionStatistics({
    super.key,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
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
      scaleFactor: scaleFactor,
      title: 'Collection Statistics',
      initiallyExpanded: initiallyExpanded,
      icon: Icons.bar_chart,
      children: [
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Text('Total Collection',
              style: TextStyle(fontSize: 10 * scaleFactor)),
          trailing: Text('$totalShows Shows / $totalSources Sources',
              style: TextStyle(
                  fontSize: 10 * scaleFactor, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title:
              Text('Total Songs', style: TextStyle(fontSize: 10 * scaleFactor)),
          trailing: Text('$totalSongs',
              style: TextStyle(
                  fontSize: 10 * scaleFactor, fontWeight: FontWeight.bold)),
        ),
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Text('Total Runtime',
              style: TextStyle(fontSize: 10 * scaleFactor)),
          trailing: Text('${days}d ${hours}h ${minutes}m',
              style: TextStyle(
                  fontSize: 10 * scaleFactor, fontWeight: FontWeight.bold)),
        ),
        ExpansionTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: Text('Source Categories',
              style: TextStyle(fontSize: 10 * scaleFactor)),
          shape: const Border(),
          children: [
            if (catBettySources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('Betty Boards',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catBettyShows.length} Shows / $catBettySources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catUltraSources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('Ultra Matrix',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catUltraShows.length} Shows / $catUltraSources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catMatrixSources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('Matrix',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catMatrixShows.length} Shows / $catMatrixSources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catDsbdSources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('Digital SBD',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catDsbdShows.length} Shows / $catDsbdSources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catFmSources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('FM Broadcast',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catFmShows.length} Shows / $catFmSources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catSbdSources > 0)
              ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: Text('Soundboard',
                      style: TextStyle(fontSize: 10 * scaleFactor)),
                  trailing: Text(
                      '${catSbdShows.length} Shows / $catSbdSources Sources',
                      style: TextStyle(fontSize: 8.5 * scaleFactor))),
            if (catUnkSources > 0)
              ListTile(
                dense: true,
                visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
                title: Text('Unknown Shows',
                    style: TextStyle(fontSize: 10 * scaleFactor)),
                trailing: Text(
                    '${catUnkShows.length} Shows / $catUnkSources Sources',
                    style: TextStyle(fontSize: 8.5 * scaleFactor)),
              ),
          ],
        ),
      ],
    );
  }
}
