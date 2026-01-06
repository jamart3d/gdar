import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/ui/widgets/section_card.dart';
import 'package:provider/provider.dart';

class SourceFilterSettings extends StatelessWidget {
  const SourceFilterSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    return SectionCard(
      title: 'Source Filtering',
      icon: Icons.filter_alt_outlined,
      children: [
        SwitchListTile(
          title: const Text('Highest SHNID Only'),
          subtitle: const Text('Only show the latest source for each show'),
          value: settingsProvider.filterHighestShnid,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleFilterHighestShnid();
          },
          secondary: const Icon(Icons.filter_list_rounded),
        ),
        ListTile(
          title: const Text('Source Categories'),
          subtitle: const Text('Tap to toggle, Long press to solo'),
          leading: const Icon(Icons.category_rounded),
          trailing: TextButton(
            onPressed: () {
              context.read<SettingsProvider>().enableAllSourceCategories();
            },
            child: const Text('All'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: [
              if (showListProvider.availableCategories.contains('betty'))
                _buildFilterBadge(
                  context,
                  'Betty Boards',
                  settingsProvider.sourceCategoryFilters['betty'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter(
                      'betty',
                      !(settingsProvider.sourceCategoryFilters['betty'] ??
                          true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('betty'),
                ),
              if (showListProvider.availableCategories.contains('ultra'))
                _buildFilterBadge(
                  context,
                  'Ultra Matrix',
                  settingsProvider.sourceCategoryFilters['ultra'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter(
                      'ultra',
                      !(settingsProvider.sourceCategoryFilters['ultra'] ??
                          true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('ultra'),
                ),
              if (showListProvider.availableCategories.contains('matrix'))
                _buildFilterBadge(
                  context,
                  'Matrix',
                  settingsProvider.sourceCategoryFilters['matrix'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter(
                      'matrix',
                      !(settingsProvider.sourceCategoryFilters['matrix'] ??
                          true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('matrix'),
                ),
              if (showListProvider.availableCategories.contains('dsbd'))
                _buildFilterBadge(
                  context,
                  'Digital SBD',
                  settingsProvider.sourceCategoryFilters['dsbd'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter(
                      'dsbd',
                      !(settingsProvider.sourceCategoryFilters['dsbd'] ??
                          true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('dsbd'),
                ),
              if (showListProvider.availableCategories.contains('fm'))
                _buildFilterBadge(
                  context,
                  'FM Broadcast',
                  settingsProvider.sourceCategoryFilters['fm'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter('fm',
                      !(settingsProvider.sourceCategoryFilters['fm'] ?? true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('fm'),
                ),
              if (showListProvider.availableCategories.contains('sbd'))
                _buildFilterBadge(
                  context,
                  'Soundboard',
                  settingsProvider.sourceCategoryFilters['sbd'] ?? true,
                  () => settingsProvider.setSourceCategoryFilter('sbd',
                      !(settingsProvider.sourceCategoryFilters['sbd'] ?? true)),
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('sbd'),
                ),
              // Special case for 'unk' (Unknown) to ensure it's displayed if present
              if (showListProvider.availableCategories.contains('unk'))
                _buildFilterBadge(
                  context,
                  'Unk',
                  settingsProvider.sourceCategoryFilters['unk'] ??
                      false, // Default to FALSE for Unknown
                  () {
                    settingsProvider.setSourceCategoryFilter(
                      'unk',
                      !(settingsProvider.sourceCategoryFilters['unk'] ?? false),
                    );
                  },
                  onLongPress: () =>
                      settingsProvider.setSoloSourceCategoryFilter('unk'),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBadge(
      BuildContext context, String label, bool isActive, VoidCallback onTap,
      {VoidCallback? onLongPress}) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress != null
          ? () {
              HapticFeedback.mediumImpact();
              onLongPress();
            }
          : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isActive
              ? (isTrueBlackMode
                  ? const LinearGradient(colors: [Colors.black, Colors.black])
                  : LinearGradient(
                      colors: [
                        colorScheme.secondaryContainer.withValues(alpha: 0.9),
                        colorScheme.secondaryContainer.withValues(alpha: 0.7),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ))
              : null,
          color: isActive ? null : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive
                ? (isTrueBlackMode
                    ? colorScheme.outlineVariant
                    : Colors.transparent)
                : colorScheme.outline.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: isActive
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 11 * scaleFactor,
                letterSpacing: 0.5,
              ),
        ),
      ),
    );
  }
}
