import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/settings/color_picker_dialog.dart';
import 'package:shakedown/ui/widgets/settings/font_selection_dialog.dart';
import 'package:shakedown/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/settings/rainbow_color_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
                  HapticFeedback.lightImpact();
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
                    TvFocusWrapper(
                      borderRadius: BorderRadius.circular(24),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: SegmentedButton<ThemeMode>(
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.system,
                              label: const Text('System'),
                              icon: Icon(
                                  themeProvider.themeStyle == ThemeStyle.fruit
                                      ? LucideIcons.monitor
                                      : Icons.brightness_auto_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              label: const Text('Light'),
                              icon: Icon(
                                  themeProvider.themeStyle == ThemeStyle.fruit
                                      ? LucideIcons.sun
                                      : Icons.light_mode_rounded),
                            ),
                            ButtonSegment(
                              value: ThemeMode.dark,
                              label: const Text('Dark'),
                              icon: Icon(
                                  themeProvider.themeStyle == ThemeStyle.fruit
                                      ? LucideIcons.moon
                                      : Icons.dark_mode_rounded),
                            ),
                          ],
                          selected: {themeProvider.selectedThemeMode},
                          onSelectionChanged: (Set<ThemeMode> newSelection) {
                            HapticFeedback.lightImpact();
                            context
                                .read<ThemeProvider>()
                                .setThemeMode(newSelection.first);
                          },
                          showSelectedIcon: false,
                          style: ButtonStyle(
                            shape: WidgetStateProperty.all(
                              RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24)),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
        if (kIsWeb && !context.watch<DeviceService>().isTv) ...[
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
                TvFocusWrapper(
                  borderRadius: BorderRadius.circular(24),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<ThemeStyle>(
                      segments: [
                        ButtonSegment(
                          value: ThemeStyle.android,
                          label: const Text('Android'),
                          icon: Icon(
                              themeProvider.themeStyle == ThemeStyle.fruit
                                  ? LucideIcons.smartphone
                                  : Icons.android_rounded),
                        ),
                        ButtonSegment(
                          value: ThemeStyle.fruit,
                          label: const Text('Fruit'),
                          icon: Icon(
                              themeProvider.themeStyle == ThemeStyle.fruit
                                  ? LucideIcons.apple
                                  : Icons.apple_rounded),
                        ),
                      ],
                      selected: {themeProvider.themeStyle},
                      onSelectionChanged: (Set<ThemeStyle> newSelection) {
                        final style = newSelection.first;
                        HapticFeedback.lightImpact();
                        context.read<ThemeProvider>().setThemeStyle(style);

                        // Theme-specific constraints
                        final sp = context.read<SettingsProvider>();
                        if (style == ThemeStyle.fruit) {
                          // Fruit requires non-black for Glass/Neumorphic effects
                          sp.setUseNeumorphism(true);
                          if (sp.useTrueBlack) sp.toggleUseTrueBlack();
                          if (sp.useDynamicColor) sp.toggleUseDynamicColor();
                        } else {
                          // Default back to True Black when Fruit is off
                          if (!sp.useTrueBlack) sp.toggleUseTrueBlack();
                        }
                      },
                      showSelectedIcon: false,
                      style: ButtonStyle(
                        shape: WidgetStateProperty.all(
                          RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24)),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (themeProvider.themeStyle == ThemeStyle.fruit) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fruit Color',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 16.0 * widget.scaleFactor),
                  ),
                  const SizedBox(height: 8),
                  TvFocusWrapper(
                    borderRadius: BorderRadius.circular(24),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<FruitColorOption>(
                        segments: [
                          const ButtonSegment(
                            value: FruitColorOption.sophisticate,
                            label: Text('Sophisticate'),
                            icon: Icon(LucideIcons.moon),
                          ),
                          const ButtonSegment(
                            value: FruitColorOption.minimalist,
                            label: Text('Minimalist'),
                            icon: Icon(LucideIcons.sun),
                          ),
                          const ButtonSegment(
                            value: FruitColorOption.creative,
                            label: Text('Creative'),
                            icon: Icon(LucideIcons.palette),
                          ),
                        ],
                        selected: {themeProvider.fruitColorOption},
                        onSelectionChanged:
                            (Set<FruitColorOption> newSelection) {
                          HapticFeedback.lightImpact();
                          themeProvider.setFruitColorOption(newSelection.first);
                        },
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Glass, Hover, and Neumorphism are mandatory features of the Fruit theme
            // and are managed automatically, so they are hidden from settings to reduce clutter.
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
                      'Optimizes Fruit theme for older phones (removes blurs)',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12 * widget.scaleFactor))),
              value: settingsProvider.performanceMode,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<SettingsProvider>().togglePerformanceMode();
              },
              secondary: const Icon(LucideIcons.zap),
            ),
          ],
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
              HapticFeedback.lightImpact();
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
              HapticFeedback.lightImpact();
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
        if (kIsWeb && !context.read<DeviceService>().isTv)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Glow Border',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            value: settingsProvider.glowMode > 0,
            onChanged: (value) {
              context
                  .read<SettingsProvider>()
                  .setGlowMode(value ? 65 : 0); // 65% or Off
            },
            secondary: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                ? LucideIcons.sparkles
                : Icons.blur_on_rounded),
          ),
        if (kIsWeb &&
            !context.read<DeviceService>().isTv &&
            settingsProvider.glowMode > 0)
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
                                  HapticFeedback.selectionClick();
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
                                  HapticFeedback.selectionClick();
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
                            onChangeStart: (_) => HapticFeedback.lightImpact(),
                            value: settingsProvider.glowMode.toDouble(),
                            min: 10,
                            max: 100,
                            divisions: 18, // 5% steps
                            label: '${settingsProvider.glowMode}%',
                            onChanged: (value) {
                              if (value.round() != settingsProvider.glowMode) {
                                HapticFeedback.selectionClick();
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
                                  color: Theme.of(context).colorScheme.primary),
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
        if (kIsWeb || context.read<DeviceService>().isTv)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Highlight Playing with RGB',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Animate border with RGB colors',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            value: settingsProvider.highlightPlayingWithRgb,
            onChanged: (value) {
              final provider = context.read<SettingsProvider>();
              provider.toggleHighlightPlayingWithRgb();
              // If turning RGB OFF and True Black is ON, turn off Glow too
              if (!value && provider.useTrueBlack) {
                provider.setGlowMode(0);
              }
            },
            secondary: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                ? LucideIcons.zap
                : Icons.animation_rounded),
          ),
        if (settingsProvider.highlightPlayingWithRgb)
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
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<double>(
                        segments: [
                          ButtonSegment(
                            value: 1.0,
                            label: const Text('1x'),
                            icon: Icon(
                                themeProvider.themeStyle == ThemeStyle.fruit
                                    ? LucideIcons.gauge
                                    : Icons.speed),
                          ),
                          const ButtonSegment(
                            value: 0.5,
                            label: Text('0.5x'),
                          ),
                          const ButtonSegment(
                            value: 0.25,
                            label: Text('0.25x'),
                          ),
                          const ButtonSegment(
                            value: 0.1,
                            label: Text('0.1x'),
                          ),
                        ],
                        selected: {settingsProvider.rgbAnimationSpeed},
                        onSelectionChanged: (Set<double> newSelection) {
                          HapticFeedback.lightImpact();
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
                          // Using a 0-width transparent side is more robust on web than "none".
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
                                // Ensure high contrast for the selected state text
                                return Theme.of(context).colorScheme.onSurface;
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
                              // Rock Salt doesn't support bold well, and we rely on color for highlight.
                              // Returning null allows it to inherit the Theme's labelLarge (which has the correct font).
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
        if (!context.read<DeviceService>().isTv)
          Opacity(
            opacity: themeProvider.themeStyle == ThemeStyle.fruit ? 0.5 : 1.0,
            child: AbsorbPointer(
              absorbing: themeProvider.themeStyle == ThemeStyle.fruit,
              child: TvListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: Icon(themeProvider.themeStyle == ThemeStyle.fruit
                    ? LucideIcons.type
                    : Icons.text_format_rounded),
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
                    child: Text(
                        themeProvider.themeStyle == ThemeStyle.fruit
                            ? 'Inter (Forced by Fruit Theme)'
                            : _getFontDisplayName(settingsProvider.appFont),
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(fontSize: 12 * widget.scaleFactor))),
                onTap: () {
                  HapticFeedback.lightImpact();
                  FontSelectionDialog.show(context);
                },
              ),
            ),
          ),
      ],
    );
  }
}

// Helper widget for Color Picker
