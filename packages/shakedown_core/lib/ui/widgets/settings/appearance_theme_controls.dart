import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/color_picker_dialog.dart';
import 'package:shakedown_core/ui/widgets/settings/font_selection_dialog.dart';
import 'package:shakedown_core/ui/widgets/settings/rainbow_color_picker.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

Widget buildTileTitle(BuildContext context, double scaleFactor, String text) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor),
    ),
  );
}

Widget buildTileSubtitle(
  BuildContext context,
  double scaleFactor,
  String text,
) {
  return FittedBox(
    fit: BoxFit.scaleDown,
    alignment: Alignment.centerLeft,
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
    ),
  );
}

class ThemeModeSection extends StatelessWidget {
  final double scaleFactor;

  const ThemeModeSection({super.key, required this.scaleFactor});

  void _handleThemeModeChanged(BuildContext context, ThemeMode newMode) {
    AppHaptics.lightImpact(context.read<DeviceService>());
    context.read<ThemeProvider>().setThemeMode(newMode);

    final settingsProvider = context.read<SettingsProvider>();
    final isLightMode =
        newMode == ThemeMode.light ||
        (newMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.light);
    if (isLightMode && settingsProvider.useTrueBlack) {
      settingsProvider.toggleUseTrueBlack();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (context.watch<DeviceService>().isTv) {
      return TvSwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: buildTileTitle(context, scaleFactor, 'Dark'),
        value: themeProvider.isDarkMode,
        onChanged: (value) {
          AppHaptics.lightImpact(context.read<DeviceService>());
          context.read<ThemeProvider>().setThemeMode(
            value ? ThemeMode.dark : ThemeMode.light,
          );
        },
        secondary: Icon(
          themeProvider.themeStyle == ThemeStyle.fruit
              ? (themeProvider.isDarkMode ? LucideIcons.moon : LucideIcons.sun)
              : (themeProvider.isDarkMode
                    ? Icons.dark_mode_rounded
                    : Icons.light_mode_rounded),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Theme',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16.0 * scaleFactor),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return TvFocusWrapper(
                borderRadius: BorderRadius.circular(isFruit ? 28 : 24),
                child: SingleChildScrollView(
                  key: const PageStorageKey('appearance_theme_scroll'),
                  controller: ScrollController(keepScrollOffset: false),
                  scrollDirection: Axis.horizontal,
                  child: themeProvider.themeStyle == ThemeStyle.fruit
                      ? FruitSegmentedControl<ThemeMode>(
                          values: ThemeMode.values,
                          selectedValue: themeProvider.selectedThemeMode,
                          onSelectionChanged: (newMode) {
                            _handleThemeModeChanged(context, newMode);
                          },
                          labelBuilder: (mode) {
                            late final IconData icon;
                            switch (mode) {
                              case ThemeMode.system:
                                icon = LucideIcons.monitor;
                              case ThemeMode.light:
                                icon = LucideIcons.sun;
                              case ThemeMode.dark:
                                icon = LucideIcons.moon;
                            }
                            return Icon(icon, size: 20);
                          },
                        )
                      : SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.monitor
                                    : Icons.brightness_auto_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.sun
                                    : Icons.light_mode_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.moon
                                    : Icons.dark_mode_rounded,
                              ),
                            ),
                          ],
                          selected: {themeProvider.selectedThemeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            _handleThemeModeChanged(
                              context,
                              newSelection.first,
                            );
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isFruit ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class ThemeStyleSection extends StatelessWidget {
  final double scaleFactor;

  const ThemeStyleSection({super.key, required this.scaleFactor});

  void _handleThemeStyleChanged(BuildContext context, ThemeStyle style) {
    AppHaptics.lightImpact(context.read<DeviceService>());
    context.read<ThemeProvider>().setThemeStyle(style);

    final settingsProvider = context.read<SettingsProvider>();
    if (style == ThemeStyle.fruit) {
      settingsProvider.setUseNeumorphism(true);
      if (settingsProvider.useTrueBlack) {
        settingsProvider.toggleUseTrueBlack();
      }
      if (settingsProvider.useDynamicColor) {
        settingsProvider.toggleUseDynamicColor();
      }
      return;
    }

    settingsProvider.setUseNeumorphism(false);
    if (!settingsProvider.useTrueBlack) {
      settingsProvider.toggleUseTrueBlack();
    }
    if (!settingsProvider.useDynamicColor) {
      settingsProvider.toggleUseDynamicColor();
    }
    if (settingsProvider.isFirstRun && settingsProvider.appFont == 'default') {
      settingsProvider.setAppFont('rock_salt');
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Style',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 16.0 * scaleFactor),
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, constraints) {
              return TvFocusWrapper(
                borderRadius: BorderRadius.circular(isFruit ? 28 : 24),
                child: SingleChildScrollView(
                  key: const PageStorageKey('appearance_style_scroll'),
                  controller: ScrollController(keepScrollOffset: false),
                  scrollDirection: Axis.horizontal,
                  child: themeProvider.themeStyle == ThemeStyle.fruit
                      ? FruitSegmentedControl<ThemeStyle>(
                          values: themeProvider.isFruitAllowed
                              ? ThemeStyle.values
                              : [ThemeStyle.android],
                          selectedValue: themeProvider.themeStyle,
                          onSelectionChanged: (style) {
                            _handleThemeStyleChanged(context, style);
                          },
                          labelBuilder: (style) {
                            late final IconData icon;
                            switch (style) {
                              case ThemeStyle.android:
                                icon =
                                    themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.bot
                                    : Icons.smart_toy_rounded;
                              case ThemeStyle.fruit:
                                icon =
                                    themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.apple
                                    : Icons.apple_rounded;
                            }
                            return Icon(icon, size: 20);
                          },
                        )
                      : SegmentedButton<ThemeStyle>(
                          segments: [
                            ButtonSegment(
                              value: ThemeStyle.android,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.bot
                                    : Icons.smart_toy_rounded,
                              ),
                            ),
                            ButtonSegment(
                              value: ThemeStyle.fruit,
                              icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.apple
                                    : Icons.apple_rounded,
                              ),
                            ),
                          ],
                          selected: {themeProvider.themeStyle},
                          onSelectionChanged: (Set<ThemeStyle> newSelection) {
                            _handleThemeStyleChanged(
                              context,
                              newSelection.first,
                            );
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  isFruit ? 28 : 24,
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class DynamicColorTile extends StatelessWidget {
  final double scaleFactor;

  const DynamicColorTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: buildTileTitle(context, scaleFactor, 'Dynamic Color'),
      subtitle: buildTileSubtitle(context, scaleFactor, 'Theme from wallpaper'),
      value: settingsProvider.useDynamicColor,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleUseDynamicColor();
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.palette
            : Icons.color_lens_rounded,
      ),
    );
  }
}

class TrueBlackTile extends StatelessWidget {
  final double scaleFactor;

  const TrueBlackTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: buildTileTitle(context, scaleFactor, 'True Black'),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Shadows and blur disabled',
      ),
      value: settingsProvider.useTrueBlack,
      onChanged: (value) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleUseTrueBlack();
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.circle
            : Icons.brightness_1_rounded,
      ),
    );
  }
}

class CustomThemeColorControl extends StatelessWidget {
  final double scaleFactor;

  const CustomThemeColorControl({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    if (context.watch<DeviceService>().isTv) {
      return RainbowColorPicker(scaleFactor: scaleFactor);
    }

    final colorScheme = Theme.of(context).colorScheme;
    return TvListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.palette
            : Icons.palette_rounded,
      ),
      title: buildTileTitle(context, scaleFactor, 'Custom Theme Color'),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Overrides the default theme color',
      ),
      onTap: () => ColorPickerDialog.show(context),
      trailing: Container(
        width: 18,
        height: 18,
        decoration: BoxDecoration(
          color: settingsProvider.seedColor ?? Colors.purple,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outline, width: 1.5),
        ),
      ),
    );
  }
}

class FontSelectionTile extends StatelessWidget {
  final double scaleFactor;

  const FontSelectionTile({super.key, required this.scaleFactor});

  String _getFontDisplayName(String fontKey) {
    switch (fontKey) {
      case 'caveat':
        return 'Caveat';
      case 'permanent_marker':
        return 'Permanent Marker';
      case 'rock_salt':
        return 'Rock Salt';
      default:
        return 'Default (Roboto)';
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return TvListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      leading: const Icon(Icons.text_format_rounded),
      title: buildTileTitle(context, scaleFactor, 'App Font'),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        _getFontDisplayName(settingsProvider.appFont),
      ),
      onTap: () {
        AppHaptics.lightImpact(context.read<DeviceService>());
        FontSelectionDialog.show(context);
      },
    );
  }
}
