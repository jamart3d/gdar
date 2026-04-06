import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/appearance_theme_controls.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

class FruitOptionsSwitcher extends StatelessWidget {
  final double scaleFactor;

  const FruitOptionsSwitcher({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 400),
      reverseDuration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SizeTransition(
            sizeFactor: animation,
            axisAlignment: -1.0,
            child: child,
          ),
        );
      },
      child: themeProvider.themeStyle == ThemeStyle.fruit
          ? Column(
              key: const ValueKey('fruit_options_group'),
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accent Color',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 16.0 * scaleFactor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      FruitSegmentedControl<FruitColorOption>(
                        values: FruitColorOption.values,
                        selectedValue: themeProvider.fruitColorOption,
                        onSelectionChanged: (option) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          themeProvider.setFruitColorOption(option);
                        },
                        labelBuilder: (option) {
                          late final IconData icon;
                          switch (option) {
                            case FruitColorOption.sophisticate:
                              icon = LucideIcons.moon;
                            case FruitColorOption.minimalist:
                              icon = LucideIcons.sun;
                            case FruitColorOption.creative:
                              icon = LucideIcons.palette;
                          }
                          return Icon(icon, size: 20);
                        },
                      ),
                    ],
                  ),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: buildTileTitle(
                    context,
                    scaleFactor,
                    'Dense Show List',
                  ),
                  subtitle: buildTileSubtitle(
                    context,
                    scaleFactor,
                    'Shows more items on screen with tighter spacing',
                  ),
                  value: settingsProvider.fruitDenseList,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    context.read<SettingsProvider>().toggleFruitDenseList();
                  },
                  secondary: const Icon(LucideIcons.listFilter),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: buildTileTitle(context, scaleFactor, 'Liquid Glass'),
                  subtitle: buildTileSubtitle(
                    context,
                    scaleFactor,
                    'Off switches Fruit into Simple Theme for lighter rendering',
                  ),
                  value:
                      !settingsProvider.performanceMode &&
                      settingsProvider.fruitEnableLiquidGlass,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    final provider = context.read<SettingsProvider>();
                    if (value) {
                      provider.setPerformanceMode(false);
                      provider.setFruitEnableLiquidGlass(true);
                    } else {
                      provider.setFruitEnableLiquidGlass(false);
                      provider.setPerformanceMode(true);
                    }
                  },
                  secondary: const Icon(LucideIcons.droplet),
                ),
                TvSwitchListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  title: buildTileTitle(
                    context,
                    scaleFactor,
                    'Highlight Playing with RGB',
                  ),
                  subtitle: buildTileSubtitle(
                    context,
                    scaleFactor,
                    'Animate border with RGB colors',
                  ),
                  value: settingsProvider.highlightPlayingWithRgb,
                  onChanged: (value) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    context
                        .read<SettingsProvider>()
                        .toggleHighlightPlayingWithRgb();
                  },
                  secondary: const Icon(LucideIcons.zap),
                ),
              ],
            )
          : const SizedBox.shrink(),
    );
  }
}

class PerformanceModeTile extends StatelessWidget {
  final double scaleFactor;

  const PerformanceModeTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: buildTileTitle(
        context,
        scaleFactor,
        'Performance Mode (Simple Theme)',
      ),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Optimizes UI for older phones (removes blurs, shadows, and complex animations)',
      ),
      value: settingsProvider.performanceMode,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().togglePerformanceMode();
      },
      secondary: const Icon(LucideIcons.zap),
    );
  }
}
