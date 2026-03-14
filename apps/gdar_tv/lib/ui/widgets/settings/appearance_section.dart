import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:gdar_tv/ui/widgets/animated_gradient_border.dart';
import 'package:gdar_tv/ui/widgets/section_card.dart';
import 'package:gdar_tv/ui/widgets/settings/color_picker_dialog.dart';
import 'package:gdar_tv/ui/widgets/settings/font_selection_dialog.dart';
import 'package:gdar_tv/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:gdar_tv/ui/widgets/tv/tv_list_tile.dart';
import 'package:gdar_tv/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:gdar_tv/ui/widgets/settings/rainbow_color_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';

class AppearanceSection extends StatefulWidget {
  final double scaleFactor;
  final bool initiallyExpanded;
  final bool showFontSelection;

  const AppearanceSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
    this.showFontSelection = false,
  });

  @override
  State<AppearanceSection> createState() => _AppearanceSectionState();
}

class _AppearanceSectionState extends State<AppearanceSection> {
  @override
  void initState() {
    super.initState();
    // Trigger Font Selection Dialog if requested
    if (widget.showFontSelection) {
      // Delay slightly to allow screen transition to complete/start smoothly
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) FontSelectionDialog.show(context);
      });
    }
  }

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
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final colorScheme = Theme.of(context).colorScheme;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SectionCard(
      scaleFactor: widget.scaleFactor,
      title: 'Appearance',
      icon: Icons.palette_outlined,
      lucideIcon: LucideIcons.palette,
      initiallyExpanded: widget.initiallyExpanded,
      children: [
        context.watch<DeviceService>().isTv
            ? TvSwitchListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                title: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text('Dark',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 16 * widget.scaleFactor))),
                value: themeProvider.isDarkMode,
                onChanged: (value) {
                  AppHaptics.lightImpact(context.read<DeviceService>());
                  context
                      .read<ThemeProvider>()
                      .setThemeMode(value ? ThemeMode.dark : ThemeMode.light);
                },
                secondary: Icon(
                  themeProvider.themeStyle == ThemeStyle.fruit
                      ? (themeProvider.isDarkMode
                          ? LucideIcons.moon
                          : LucideIcons.sun)
                      : (themeProvider.isDarkMode
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded),
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontSize: 16.0 * widget.scaleFactor),
                    ),
                    const SizedBox(height: 8),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        return TvFocusWrapper(
                          borderRadius:
                              BorderRadius.circular(isFruit ? 28 : 24),
                          child: SingleChildScrollView(
                            key:
                                const PageStorageKey('appearance_theme_scroll'),
                            controller:
                                ScrollController(keepScrollOffset: false),
                            scrollDirection: Axis.horizontal,
                            child: themeProvider.themeStyle == ThemeStyle.fruit
                                ? FruitSegmentedControl<ThemeMode>(
                                    values: ThemeMode.values,
                                    selectedValue:
                                        themeProvider.selectedThemeMode,
                                    onSelectionChanged: (newMode) {
                                      AppHaptics.lightImpact(
                                          context.read<DeviceService>());
                                      context
                                          .read<ThemeProvider>()
                                          .setThemeMode(newMode);
                                      final sp =
                                          context.read<SettingsProvider>();
                                      final isLightMode = newMode ==
                                              ThemeMode.light ||
                                          (newMode == ThemeMode.system &&
                                              MediaQuery.platformBrightnessOf(
                                                      context) ==
                                                  Brightness.light);
                                      if (isLightMode && sp.useTrueBlack) {
                                        sp.toggleUseTrueBlack();
                                      }
                                    },
                                    labelBuilder: (mode) {
                                      IconData icon;
                                      switch (mode) {
                                        case ThemeMode.system:
                                          icon = LucideIcons.monitor;
                                          break;
                                        case ThemeMode.light:
                                          icon = LucideIcons.sun;
                                          break;
                                        case ThemeMode.dark:
                                          icon = LucideIcons.moon;
                                          break;
                                      }
                                      return Icon(icon, size: 20);
                                    },
                                  )
                                : SegmentedButton<ThemeMode>(
                                    segments: [
                                      ButtonSegment(
                                        value: ThemeMode.system,
                                        icon: Icon(themeProvider.themeStyle ==
                                                ThemeStyle.fruit
                                            ? LucideIcons.monitor
                                            : Icons.brightness_auto_rounded),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.light,
                                        icon: Icon(themeProvider.themeStyle ==
                                                ThemeStyle.fruit
                                            ? LucideIcons.sun
                                            : Icons.light_mode_rounded),
                                      ),
                                      ButtonSegment(
                                        value: ThemeMode.dark,
                                        icon: Icon(themeProvider.themeStyle ==
                                                ThemeStyle.fruit
                                            ? LucideIcons.moon
                                            : Icons.dark_mode_rounded),
                                      ),
                                    ],
                                    selected: {themeProvider.selectedThemeMode},
                                    onSelectionChanged:
                                        (Set<ThemeMode> newSelection) {
                                      AppHaptics.lightImpact(
                                          context.read<DeviceService>());
                                      final newMode = newSelection.first;
                                      context
                                          .read<ThemeProvider>()
                                          .setThemeMode(newMode);
                                      // Auto-disable True Black in light mode
                                      // so Glow Border toggle becomes available.
                                      final sp =
                                          context.read<SettingsProvider>();
                                      final isLightMode = newMode ==
                                              ThemeMode.light ||
                                          (newMode == ThemeMode.system &&
                                              MediaQuery.platformBrightnessOf(
                                                      context) ==
                                                  Brightness.light);
                                      if (isLightMode && sp.useTrueBlack) {
                                        sp.toggleUseTrueBlack();
                                      }
                                    },
                                    showSelectedIcon: false,
                                    style: ButtonStyle(
                                      shape: WidgetStateProperty.all(
                                        RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                                isFruit ? 28 : 24)),
                                      ),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
        if (themeProvider.isFruitAllowed) ...[
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Style',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 16.0 * widget.scaleFactor),
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
                                  AppHaptics.lightImpact(
                                      context.read<DeviceService>());
                                  context
                                      .read<ThemeProvider>()
                                      .setThemeStyle(style);

                                  // Theme-specific constraints
                                  final sp = context.read<SettingsProvider>();
                                  if (style == ThemeStyle.fruit) {
                                    sp.setUseNeumorphism(true);
                                    if (sp.useTrueBlack) {
                                      sp.toggleUseTrueBlack();
                                    }
                                    if (sp.useDynamicColor) {
                                      sp.toggleUseDynamicColor();
                                    }
                                    if (sp.glowMode == 0 &&
                                        !sp.performanceMode) {
                                      sp.setGlowMode(65);
                                    }
                                  } else {
                                    sp.setUseNeumorphism(false);
                                    if (!sp.useTrueBlack) {
                                      sp.toggleUseTrueBlack();
                                    }
                                    if (!sp.useDynamicColor) {
                                      sp.toggleUseDynamicColor();
                                    }
                                  }
                                },
                                labelBuilder: (style) {
                                  IconData icon;
                                  switch (style) {
                                    case ThemeStyle.android:
                                      icon = themeProvider.themeStyle ==
                                              ThemeStyle.fruit
                                          ? LucideIcons.bot
                                          : Icons.smart_toy_rounded;
                                      break;
                                    case ThemeStyle.fruit:
                                      icon = themeProvider.themeStyle ==
                                              ThemeStyle.fruit
                                          ? LucideIcons.apple
                                          : Icons.apple_rounded;
                                      break;
                                  }
                                  return Icon(icon, size: 20);
                                },
                              )
                            : SegmentedButton<ThemeStyle>(
                                segments: [
                                  ButtonSegment(
                                    value: ThemeStyle.android,
                                    icon: Icon(themeProvider.themeStyle ==
                                            ThemeStyle.fruit
                                        ? LucideIcons.bot
                                        : Icons.smart_toy_rounded),
                                  ),
                                  ButtonSegment(
                                    value: ThemeStyle.fruit,
                                    icon: Icon(themeProvider.themeStyle ==
                                            ThemeStyle.fruit
                                        ? LucideIcons.apple
                                        : Icons.apple_rounded),
                                  ),
                                ],
                                selected: {themeProvider.themeStyle},
                                onSelectionChanged:
                                    (Set<ThemeStyle> newSelection) {
                                  final style = newSelection.first;
                                  AppHaptics.lightImpact(
                                      context.read<DeviceService>());
                                  context
                                      .read<ThemeProvider>()
                                      .setThemeStyle(style);

                                  // Theme-specific constraints
                                  final sp = context.read<SettingsProvider>();
                                  if (style == ThemeStyle.fruit) {
                                    // Fruit requires non-black for Glass/Neumorphic effects
                                    sp.setUseNeumorphism(true);
                                    if (sp.useTrueBlack) {
                                      sp.toggleUseTrueBlack();
                                    }
                                    if (sp.useDynamicColor) {
                                      sp.toggleUseDynamicColor();
                                    }
                                    if (sp.glowMode == 0 &&
                                        !sp.performanceMode) {
                                      sp.setGlowMode(65);
                                    }
                                  } else {
                                    // Default back to True Black when Fruit is off
                                    sp.setUseNeumorphism(false);
                                    if (!sp.useTrueBlack) {
                                      sp.toggleUseTrueBlack();
                                    }
                                    // Enable dynamic color when switching back to Android
                                    if (!sp.useDynamicColor) {
                                      sp.toggleUseDynamicColor();
                                    }
                                  }
                                },
                                showSelectedIcon: false,
                                style: ButtonStyle(
                                  shape: WidgetStateProperty.all(
                                    RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            isFruit ? 28 : 24)),
                                  ),
                                ),
                              ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          AnimatedSwitcher(
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
                            horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Accent Color',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                      fontSize: 16.0 * widget.scaleFactor),
                            ),
                            const SizedBox(height: 8),
                            FruitSegmentedControl<FruitColorOption>(
                              values: FruitColorOption.values,
                              selectedValue: themeProvider.fruitColorOption,
                              onSelectionChanged: (option) {
                                AppHaptics.lightImpact(
                                    context.read<DeviceService>());
                                themeProvider.setFruitColorOption(option);
                              },
                              labelBuilder: (option) {
                                IconData icon;
                                switch (option) {
                                  case FruitColorOption.sophisticate:
                                    icon = LucideIcons.moon;
                                    break;
                                  case FruitColorOption.minimalist:
                                    icon = LucideIcons.sun;
                                    break;
                                  case FruitColorOption.creative:
                                    icon = LucideIcons.palette;
                                    break;
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
                        title: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text('Dense Show List',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(
                                        fontSize: 16 * widget.scaleFactor))),
                        subtitle: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                                'Shows more items on screen with tighter spacing',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                        fontSize: 12 * widget.scaleFactor))),
                        value: settingsProvider.fruitDenseList,
                        onChanged: (value) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          context
                              .read<SettingsProvider>()
                              .toggleFruitDenseList();
                        },
                        secondary: const Icon(LucideIcons.listFilter),
                      ),
                      (() {
                        final isGated = settingsProvider.performanceMode;
                        const reason = 'Disabled in Simple Theme';

                        return TvSwitchListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text('Enable Liquid Glass',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                          fontSize: 16 * widget.scaleFactor,
                                          color: isGated
                                              ? colorScheme.onSurface
                                                  .withValues(alpha: 0.5)
                                              : null))),
                          subtitle: isGated
                              ? Text(reason,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                          fontSize: 12 * widget.scaleFactor,
                                          color: colorScheme.secondary
                                              .withValues(alpha: 0.7)))
                              : FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                      'Apply translucent blur over background elements',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                              fontSize:
                                                  12 * widget.scaleFactor))),
                          value: !isGated &&
                              settingsProvider.fruitEnableLiquidGlass,
                          onChanged: isGated
                              ? null
                              : (value) {
                                  AppHaptics.lightImpact(
                                      context.read<DeviceService>());
                                  context
                                      .read<SettingsProvider>()
                                      .toggleFruitEnableLiquidGlass();
                                },
                          secondary: Icon(
                            LucideIcons.droplet,
                            color: isGated
                                ? colorScheme.onSurface.withValues(alpha: 0.3)
                                : null,
                          ),
                        );
                      })(),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Performance Mode (Simple Theme)',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                    'Optimizes UI for older phones (removes blurs, shadows, and complex animations)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            value: settingsProvider.performanceMode,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().togglePerformanceMode();
            },
            secondary: const Icon(LucideIcons.zap),
          ),
        ],
        if (themeProvider.themeStyle != ThemeStyle.fruit)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Dynamic Color',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Theme from wallpaper',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            value: settingsProvider.useDynamicColor,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleUseDynamicColor();
            },
            secondary: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                ? LucideIcons.palette
                : Icons.color_lens_rounded),
          ),
        // True Black Mode (only in Dark Mode)
        if (isDarkMode && themeProvider.themeStyle != ThemeStyle.fruit)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('True Black',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Shadows and blur disabled',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            value: settingsProvider.useTrueBlack,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleUseTrueBlack();
            },
            secondary: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                ? LucideIcons.circle
                : Icons.brightness_1_rounded),
          ),
        if (themeProvider.themeStyle != ThemeStyle.fruit &&
            !settingsProvider.useDynamicColor)
          context.watch<DeviceService>().isTv
              ? RainbowColorPicker(scaleFactor: widget.scaleFactor)
              : TvListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                      ? LucideIcons.palette
                      : Icons.palette_rounded),
                  title: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Custom Theme Color',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontSize: 16 * widget.scaleFactor))),
                  subtitle: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Overrides the default theme color',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 12 * widget.scaleFactor))),
                  onTap: () => ColorPickerDialog.show(context),
                  trailing: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: settingsProvider.seedColor ?? Colors.purple,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: colorScheme.outline,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
        if (!context.read<DeviceService>().isTv) ...[
          (() {
            final isGated = settingsProvider.performanceMode;
            const reason = 'Disabled in Simple Theme';

            return TvSwitchListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Glow Border',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16 * widget.scaleFactor,
                          color: isGated
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : null))),
              subtitle: isGated
                  ? Text(reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12 * widget.scaleFactor,
                          color: colorScheme.secondary.withValues(alpha: 0.7)))
                  : null,
              value: !isGated && settingsProvider.glowMode > 0,
              onChanged: isGated
                  ? null
                  : (value) {
                      context
                          .read<SettingsProvider>()
                          .setGlowMode(value ? 65 : 0); // 65% or Off
                    },
              secondary: Icon(
                themeProvider.themeStyle == ThemeStyle.fruit
                    ? LucideIcons.sparkles
                    : Icons.blur_on_rounded,
                color: isGated
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : null,
              ),
            );
          })(),
          if (settingsProvider.glowMode > 0 &&
              !settingsProvider.performanceMode)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  const SizedBox(width: 16),
                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'Intensity',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 12.0 * widget.scaleFactor),
                        ),
                        Expanded(
                          child: TvFocusWrapper(
                            onKeyEvent: (node, event) {
                              if (event is KeyDownEvent) {
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowLeft) {
                                  final newVal = (settingsProvider.glowMode - 5)
                                      .clamp(10, 100);
                                  if (newVal != settingsProvider.glowMode) {
                                    AppHaptics.selectionClick(
                                        context.read<DeviceService>());
                                    context
                                        .read<SettingsProvider>()
                                        .setGlowMode(newVal);
                                  }
                                  return KeyEventResult.handled;
                                } else if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowRight) {
                                  final newVal = (settingsProvider.glowMode + 5)
                                      .clamp(10, 100);
                                  if (newVal != settingsProvider.glowMode) {
                                    AppHaptics.selectionClick(
                                        context.read<DeviceService>());
                                    context
                                        .read<SettingsProvider>()
                                        .setGlowMode(newVal);
                                  }
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: Slider(
                              onChangeStart: (_) => AppHaptics.lightImpact(
                                  context.read<DeviceService>()),
                              value: settingsProvider.glowMode.toDouble(),
                              min: 10,
                              max: 100,
                              divisions: 18, // 5% steps
                              label: '${settingsProvider.glowMode}%',
                              onChanged: (value) {
                                if (value.round() !=
                                    settingsProvider.glowMode) {
                                  AppHaptics.selectionClick(
                                      context.read<DeviceService>());
                                }
                                context
                                    .read<SettingsProvider>()
                                    .setGlowMode(value.round());
                              },
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 40 * widget.scaleFactor,
                          child: Text(
                            '${settingsProvider.glowMode}%',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                    fontSize: 12.0 * widget.scaleFactor,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Theme.of(context).colorScheme.primary),
                            textAlign: TextAlign.end,
                          ),
                        ),
                        const SizedBox(width: 16), // Balance spacing
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
        if (true) // Enable RGB for all platforms
          (() {
            final isGated = settingsProvider.performanceMode;
            const reason = 'Disabled in Simple Theme';

            return TvSwitchListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Highlight Playing with RGB',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontSize: 16 * widget.scaleFactor,
                          color: isGated
                              ? colorScheme.onSurface.withValues(alpha: 0.5)
                              : null))),
              subtitle: isGated
                  ? Text(reason,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 12 * widget.scaleFactor,
                          color: colorScheme.secondary.withValues(alpha: 0.7)))
                  : FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text('Animate border with RGB colors',
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(fontSize: 12 * widget.scaleFactor))),
              value: !isGated && settingsProvider.highlightPlayingWithRgb,
              onChanged: isGated
                  ? null
                  : (value) {
                      final provider = context.read<SettingsProvider>();
                      provider.toggleHighlightPlayingWithRgb();
                      // If turning RGB OFF and True Black is ON, turn off Glow too
                      if (!value && provider.useTrueBlack) {
                        provider.setGlowMode(0);
                      }
                    },
              secondary: Icon(
                themeProvider.themeStyle == ThemeStyle.fruit
                    ? LucideIcons.zap
                    : Icons.animation_rounded,
                color: isGated
                    ? colorScheme.onSurface.withValues(alpha: 0.3)
                    : null,
              ),
            );
          })(),
        if (!settingsProvider.performanceMode &&
            settingsProvider.highlightPlayingWithRgb)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RGB Animation Speed',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(fontSize: 12.0 * widget.scaleFactor),
                ),
                const SizedBox(height: 8),
                AnimatedGradientBorder(
                  borderRadius: 24, // Matches standard SegmentedButton radius
                  borderWidth: 3,
                  colors: const [
                    Colors.red,
                    Colors.yellow,
                    Colors.green,
                    Colors.cyan,
                    Colors.blue,
                    Colors.purple,
                    Colors.red,
                  ],
                  showGlow: true,
                  // Glow mirrors the global logic:
                  // If "Glow Border" is ON (1) or HALF (2), we show shadow.
                  showShadow: settingsProvider.glowMode > 0,
                  // Use percentage-based glow intensity
                  glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
                  animationSpeed: settingsProvider.rgbAnimationSpeed,
                  // Ignore global clock locally so the preview animates even if the
                  // global clock is paused by the ShowListScreen behind us.
                  ignoreGlobalClock: true,
                  // Default background color (cardColor) masks the center of the RGB effect
                  backgroundColor: null,
                  child: TvFocusWrapper(
                    showGlow: true,
                    borderRadius:
                        BorderRadius.circular(21), // MATCH INNER RADIUS (24-3)
                    child: SingleChildScrollView(
                      key: const PageStorageKey('rgb_speed_scroll'),
                      controller: ScrollController(keepScrollOffset: false),
                      scrollDirection: Axis.horizontal,
                      child: themeProvider.themeStyle == ThemeStyle.fruit
                          ? FruitSegmentedControl<double>(
                              values: const [1.0, 0.5, 0.25, 0.1],
                              selectedValue: settingsProvider.rgbAnimationSpeed,
                              onSelectionChanged: (value) {
                                AppHaptics.lightImpact(
                                    context.read<DeviceService>());
                                context
                                    .read<SettingsProvider>()
                                    .setRgbAnimationSpeed(value);
                              },
                              labelBuilder: (value) {
                                if (value == 1.0) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(LucideIcons.zap, size: 14),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Fast',
                                        style: TextStyle(
                                            fontSize: 12 * widget.scaleFactor),
                                      ),
                                    ],
                                  );
                                }
                                if (value == 0.5) {
                                  return Text(
                                    'Med',
                                    style: TextStyle(
                                        fontSize: 12 * widget.scaleFactor),
                                  );
                                }
                                if (value == 0.25) {
                                  return Text(
                                    'Slow',
                                    style: TextStyle(
                                        fontSize: 12 * widget.scaleFactor),
                                  );
                                }
                                return Text(
                                  'Off',
                                  style: TextStyle(
                                      fontSize: 12 * widget.scaleFactor),
                                );
                              },
                              borderRadius: BorderRadius.circular(21),
                            )
                          : SegmentedButton<double>(
                              segments: [
                                ButtonSegment(
                                  value: 1.0,
                                  label: const Text('Fast'),
                                  icon: Icon(themeProvider.themeStyle ==
                                          ThemeStyle.fruit
                                      ? LucideIcons.zap
                                      : Icons.speed),
                                ),
                                const ButtonSegment(
                                  value: 0.5,
                                  label: Text('Med'),
                                ),
                                const ButtonSegment(
                                  value: 0.25,
                                  label: Text('Slow'),
                                ),
                                const ButtonSegment(
                                  value: 0.1,
                                  label: Text('Off'),
                                ),
                              ],
                              selected: {settingsProvider.rgbAnimationSpeed},
                              onSelectionChanged: (Set<double> newSelection) {
                                AppHaptics.lightImpact(
                                    context.read<DeviceService>());
                                context
                                    .read<SettingsProvider>()
                                    .setRgbAnimationSpeed(newSelection.first);
                              },
                              showSelectedIcon: false,
                              style: ButtonStyle(
                                // Match proper inner radius (24 - 3 = 21)
                                shape: WidgetStateProperty.all(
                                  RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(21)),
                                ),
                                // Make border transparent to let gradient show.
                                side: WidgetStateProperty.all(const BorderSide(
                                    color: Colors.transparent, width: 0)),
                                backgroundColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.12);
                                    }
                                    return Colors.transparent;
                                  },
                                ),
                                foregroundColor:
                                    WidgetStateProperty.resolveWith<Color>(
                                  (states) {
                                    if (states.contains(WidgetState.selected)) {
                                      return Theme.of(context)
                                          .colorScheme
                                          .onSurface;
                                    }
                                    return Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.7);
                                  },
                                ),
                                textStyle:
                                    WidgetStateProperty.resolveWith<TextStyle?>(
                                  (states) {
                                    return null;
                                  },
                                ),
                              ),
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (!context.read<DeviceService>().isTv &&
            themeProvider.themeStyle != ThemeStyle.fruit)
          TvListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.text_format_rounded),
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('App Font',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(_getFontDisplayName(settingsProvider.appFont),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            onTap: () {
              AppHaptics.lightImpact(context.read<DeviceService>());
              FontSelectionDialog.show(context);
            },
          ),
      ],
    );
  }
}

// Helper widget for Color Picker
