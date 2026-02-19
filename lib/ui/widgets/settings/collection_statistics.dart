import 'package:flutter/material.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:provider/provider.dart';

class CollectionStatistics extends StatelessWidget {
  final bool initiallyExpanded;

  /// When false (TV) the Source Categories are rendered as plain flat rows —
  /// no ExpansionTile, no expand/collapse chrome.
  /// When true (mobile) the existing collapsible ExpansionTile is shown.
  final bool showCategoryDetails;

  const CollectionStatistics({
    super.key,
    this.initiallyExpanded = false,
    this.showCategoryDetails = true,
  });

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final allShows = showListProvider.allShows;

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

    final duration = Duration(seconds: totalDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    // Flat category rows used on TV (no ExpansionTile)
    Widget _catRow(String label, int showCount, int sourceCount) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 3),
        child: Row(
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 10 * scaleFactor,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
            const Spacer(),
            Text(
              '$showCount Shows / $sourceCount Sources',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8.5 * scaleFactor,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      );
    }

    final flatCategoryRows = [
      if (catBettySources > 0)
        _catRow('Betty Boards', catBettyShows.length, catBettySources),
      if (catUltraSources > 0)
        _catRow('Ultra Matrix', catUltraShows.length, catUltraSources),
      if (catMatrixSources > 0)
        _catRow('Matrix', catMatrixShows.length, catMatrixSources),
      if (catDsbdSources > 0)
        _catRow('Digital SBD', catDsbdShows.length, catDsbdSources),
      if (catFmSources > 0)
        _catRow('FM Broadcast', catFmShows.length, catFmSources),
      if (catSbdSources > 0)
        _catRow('Soundboard', catSbdShows.length, catSbdSources),
      if (catUnkSources > 0)
        _catRow('Unknown Shows', catUnkShows.length, catUnkSources),
    ];

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Collection Statistics',
      initiallyExpanded: initiallyExpanded,
      icon: Icons.bar_chart,
      children: [
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.library_music,
              size: 24 * scaleFactor, color: colorScheme.primary),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '$totalShows Total Shows',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(
                top: settingsProvider.appFont == 'rock_salt'
                    ? 4.0 * scaleFactor
                    : 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$totalSources Sources',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12 * scaleFactor,
                    ),
              ),
            ),
          ),
        ),
        ListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: Icon(Icons.timer,
              size: 24 * scaleFactor, color: colorScheme.primary),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '${days}d ${hours}h Total Runtime',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16 * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          subtitle: Padding(
            padding: EdgeInsets.only(
                top: settingsProvider.appFont == 'rock_salt'
                    ? 4.0 * scaleFactor
                    : 0),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '$totalSongs Songs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12 * scaleFactor,
                    ),
              ),
            ),
          ),
        ),
        // TV: flat rows, no expand/collapse chrome
        if (!showCategoryDetails && flatCategoryRows.isNotEmpty) ...[
          const SizedBox(height: 4),
          ...flatCategoryRows,
          const SizedBox(height: 4),
        ],
        // Mobile: collapsible ExpansionTile
        if (showCategoryDetails)
          ExpansionTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            title: Text(
              'Source Categories Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.w500,
                  ),
            ),
            leading: Icon(Icons.list_alt, size: 20 * scaleFactor),
            shape: const Border(),
            children: [
              if (catBettySources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Betty Boards',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catBettyShows.length} Shows / $catBettySources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catUltraSources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Ultra Matrix',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catUltraShows.length} Shows / $catUltraSources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catMatrixSources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Matrix',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catMatrixShows.length} Shows / $catMatrixSources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catDsbdSources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Digital SBD',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catDsbdShows.length} Shows / $catDsbdSources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catFmSources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('FM Broadcast',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catFmShows.length} Shows / $catFmSources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catSbdSources > 0)
                ListTile(
                    dense: true,
                    visualDensity:
                        const VisualDensity(horizontal: 0, vertical: -4),
                    title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Soundboard',
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 10 * scaleFactor)),
                    ),
                    trailing: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                          '${catSbdShows.length} Shows / $catSbdSources Sources',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 8.5 * scaleFactor)),
                    )),
              if (catUnkSources > 0)
                ListTile(
                  dense: true,
                  visualDensity:
                      const VisualDensity(horizontal: 0, vertical: -4),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Unknown Shows',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(fontSize: 10 * scaleFactor)),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                        '${catUnkShows.length} Shows / $catUnkSources Sources',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 8.5 * scaleFactor)),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}
