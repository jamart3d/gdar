import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/utils/font_layout_config.dart';

class SourceFilterSettings extends StatelessWidget {
  const SourceFilterSettings({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Source Filtering',
      icon: Icons.filter_alt_outlined,
      children: [
        TvSwitchListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Highest SHNID Only',
                style: TextStyle(fontSize: 10 * scaleFactor)),
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Only show the latest source for each show',
                style: TextStyle(fontSize: 8.5 * scaleFactor)),
          ),
          value: settingsProvider.filterHighestShnid,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().toggleFilterHighestShnid();
          },
          secondary: const Icon(Icons.filter_list_rounded),
        ),
        ListTile(
          dense: true,
          visualDensity: const VisualDensity(horizontal: 0, vertical: -4),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Source Categories',
                style: TextStyle(fontSize: 10 * scaleFactor)),
          ),
          subtitle: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text('Tap to toggle, Long press to solo',
                style: TextStyle(fontSize: 8.5 * scaleFactor)),
          ),
          leading: const Icon(Icons.category_rounded),
          trailing: TextButton(
            onPressed: () {
              context.read<SettingsProvider>().enableAllSourceCategories();
            },
            child: Text('All', style: TextStyle(fontSize: 10 * scaleFactor)),
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
    final isTv = context.read<DeviceService>().isTv;

    Widget badge = _TactileBadge(
      label: label,
      isActive: isActive,
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (isTv) {
      if (isActive) {
        badge = AnimatedGradientBorder(
          borderRadius: 10,
          borderWidth: 2,
          showGlow: true,
          showShadow: true,
          backgroundColor: Colors.transparent,
          child: badge,
        );
      }
      return TvFocusWrapper(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(20), // Match badge rounding roughly
        focusColor: isActive
            ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
            : Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.2),
        child: IgnorePointer(
          ignoring: true,
          child: badge,
        ),
      );
    }

    return badge;
  }
}

class _TactileBadge extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _TactileBadge({
    required this.label,
    required this.isActive,
    required this.onTap,
    this.onLongPress,
  });

  @override
  State<_TactileBadge> createState() => _TactileBadgeState();
}

class _TactileBadgeState extends State<_TactileBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _controller.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }

  void _handleTapCancel() {
    _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      onLongPress: widget.onLongPress != null
          ? () {
              AppHaptics.mediumImpact(context.read<DeviceService>());
              widget.onLongPress!();
            }
          : null,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isActive
                ? colorScheme.onSurface.withValues(alpha: 0.12)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: widget.isActive
                  ? Colors.transparent
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              widget.label.toUpperCase(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: widget.isActive
                        ? colorScheme.onSurface
                        : colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    fontSize: 9 * scaleFactor,
                    letterSpacing: 0.5,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}
