import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/section_card.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';

class CollectionStatistics extends StatelessWidget {
  final bool initiallyExpanded;

  /// When false (TV) the Source Categories are rendered as plain flat rows —
  /// no ExpansionTile, no expand/collapse chrome.
  /// When true (mobile) the existing collapsible ExpansionTile is shown.
  final bool showCategoryDetails;
  final double scaleFactorOverride;

  const CollectionStatistics({
    super.key,
    this.initiallyExpanded = false,
    this.showCategoryDetails = true,
    this.scaleFactorOverride = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final scaleFactor = scaleFactorOverride != 1.0
        ? scaleFactorOverride
        : FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final colorScheme = Theme.of(context).colorScheme;
    final allShows = showListProvider.allShows;
    final hasActiveFilters =
        settingsProvider.filterHighestShnid ||
        settingsProvider.sourceCategoryFilters.values.any((v) => v);

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

    Set<Show> catBettyShows = {};
    Set<Show> catUltraShows = {};
    Set<Show> catMatrixShows = {};
    Set<Show> catDsbdShows = {};
    Set<Show> catFmShows = {};
    Set<Show> catSbdShows = {};

    for (var show in allShows) {
      totalSources += show.sources.length;
      for (var source in show.sources) {
        totalSongs += source.tracks.length;
        for (var track in source.tracks) {
          totalDurationSeconds += track.duration.toInt();
        }

        final cats = showListProvider.getCategoriesForSource(source);

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
      }
    }

    final duration = Duration(seconds: totalDurationSeconds);
    final days = duration.inDays;
    final hours = duration.inHours % 24;

    final numberFormat = NumberFormat('#,##0');
    final formattedShows = numberFormat.format(totalShows);
    final formattedSources = numberFormat.format(totalSources);
    final formattedSongs = numberFormat.format(totalSongs);
    final formattedDays = numberFormat.format(days);

    String showsText = '$formattedShows Total Shows';
    String sourcesText = '$formattedSources Sources';
    String runtimeText = '$formattedDays Days $hours Hours Total Runtime';
    String songsText = '$formattedSongs Songs';

    if (hasActiveFilters) {
      int filteredShowsCount = 0;
      int filteredSourcesCount = 0;
      int filteredSongsCount = 0;
      int filteredDurationSeconds = 0;

      final filteredShows = showListProvider.filteredShows;
      filteredShowsCount = filteredShows.length;
      for (var show in filteredShows) {
        filteredSourcesCount += show.sources.length;
        for (var source in show.sources) {
          filteredSongsCount += source.tracks.length;
          for (var track in source.tracks) {
            filteredDurationSeconds += track.duration.toInt();
          }
        }
      }
      final filteredDuration = Duration(seconds: filteredDurationSeconds);
      final filteredDays = numberFormat.format(filteredDuration.inDays);
      final filteredHours = filteredDuration.inHours % 24;

      showsText =
          '$formattedShows Total Shows (${numberFormat.format(filteredShowsCount)})';
      sourcesText =
          '$formattedSources Sources (${numberFormat.format(filteredSourcesCount)})';
      runtimeText =
          '$formattedDays Days $hours Hours Total Runtime ($filteredDays Days $filteredHours Hours)';
      songsText =
          '$formattedSongs Songs (${numberFormat.format(filteredSongsCount)})';
    }

    // Flat category rows used on TV (no ExpansionTile)
    Widget catRow(String label, int showCount, int sourceCount) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14 * scaleFactor,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(width: 24),
            Text(
              '$showCount Shows / $sourceCount Sources',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12 * scaleFactor,
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.right,
            ),
          ],
        ),
      );
    }

    final flatCategoryRows = [
      if (catBettySources > 0)
        catRow('Betty Boards', catBettyShows.length, catBettySources),
      if (catUltraSources > 0)
        catRow('Ultra Matrix', catUltraShows.length, catUltraSources),
      if (catMatrixSources > 0)
        catRow('Matrix', catMatrixShows.length, catMatrixSources),
      if (catDsbdSources > 0)
        catRow('Digital SBD', catDsbdShows.length, catDsbdSources),
      if (catFmSources > 0)
        catRow('FM Broadcast', catFmShows.length, catFmSources),
      if (catSbdSources > 0)
        catRow('Soundboard', catSbdShows.length, catSbdSources),
    ];

    final isTv = !showCategoryDetails;

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Collection Statistics',
      initiallyExpanded: initiallyExpanded,
      icon: Icons.bar_chart,
      lucideIcon: LucideIcons.barChart2,
      children: [
        if (hasActiveFilters)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Displaying total and (filtered) collection stats.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontStyle: FontStyle.italic,
                color: colorScheme.primary,
              ),
            ),
          ),
        if (isTv)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _TvStatBlock(
                  icon: Icons.library_music,
                  title: showsText,
                  subtitle: sourcesText,
                  scaleFactor: scaleFactor,
                ),
                _TvStatBlock(
                  icon: Icons.timer,
                  title: runtimeText,
                  subtitle: songsText,
                  scaleFactor: scaleFactor,
                ),
              ],
            ),
          )
        else ...[
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              isFruit ? LucideIcons.library : Icons.library_music,
              size: 24 * scaleFactor,
              color: colorScheme.primary,
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                showsText,
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
                    : 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  sourcesText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
                ),
              ),
            ),
          ),
          ListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: Icon(
              isFruit ? LucideIcons.clock : Icons.timer,
              size: 24 * scaleFactor,
              color: colorScheme.primary,
            ),
            title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                runtimeText,
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
                    : 0,
              ),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  songsText,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
                ),
              ),
            ),
          ),
        ],
        // TV: flat rows, no expand/collapse chrome
        if (!showCategoryDetails && flatCategoryRows.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 6),
            child: Text(
              'Source Categories',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14 * scaleFactor,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          ...flatCategoryRows,
          const SizedBox(height: 10),
        ],
        // Mobile: collapsible ExpansionTile
        if (showCategoryDetails)
          ExpansionTile(
            dense: true,
            visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
            title: Text(
              'Source Categories Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: (isFruit ? 16 : 14) * scaleFactor,
                fontWeight: FontWeight.w500,
              ),
            ),
            leading: Icon(
              isFruit ? LucideIcons.list : Icons.list_alt,
              size: 20 * scaleFactor,
            ),
            shape: const Border(),
            children: [
              if (catBettySources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Betty Boards',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catBettyShows.length} Shows / $catBettySources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
              if (catUltraSources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Ultra Matrix',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catUltraShows.length} Shows / $catUltraSources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
              if (catMatrixSources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Matrix',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catMatrixShows.length} Shows / $catMatrixSources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
              if (catDsbdSources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Digital SBD',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catDsbdShows.length} Shows / $catDsbdSources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
              if (catFmSources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'FM Broadcast',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catFmShows.length} Shows / $catFmSources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
              if (catSbdSources > 0)
                ListTile(
                  dense: true,
                  visualDensity: const VisualDensity(
                    horizontal: 0,
                    vertical: -4,
                  ),
                  title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Soundboard',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: (isFruit ? 12 : 10) * scaleFactor,
                      ),
                    ),
                  ),
                  trailing: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: Text(
                      '${catSbdShows.length} Shows / $catSbdSources Sources',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: (isFruit ? 10.5 : 8.5) * scaleFactor,
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class _TvStatBlock extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final double scaleFactor;

  const _TvStatBlock({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 360, maxWidth: 520),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF000000),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.12),
            width: 1,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28 * scaleFactor, color: colorScheme.primary),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 18 * scaleFactor,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 14 * scaleFactor,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
