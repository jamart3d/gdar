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
import 'package:shakedown/ui/screens/screensaver_screen.dart';

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
      initiallyExpanded: widget.initiallyExpanded,
      children: [
        TvSwitchListTile(
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
            context.read<ThemeProvider>().toggleTheme();
          },
          secondary: Icon(
            themeProvider.isDarkMode
                ? Icons.dark_mode_rounded
                : Icons.light_mode_rounded,
          ),
        ),
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
          secondary: const Icon(Icons.color_lens_rounded),
        ),
        // True Black Mode (only in Dark Mode)
        if (isDarkMode)
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
            secondary: const Icon(Icons.brightness_1_rounded),
          ),
        if (!settingsProvider.useDynamicColor)
          context.watch<DeviceService>().isTv
              ? RainbowColorPicker(scaleFactor: widget.scaleFactor)
              : TvListTile(
                  dense: true,
                  visualDensity: VisualDensity.compact,
                  leading: const Icon(Icons.palette_rounded),
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
        if (!context.read<DeviceService>().isTv)
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
            secondary: const Icon(Icons.blur_on_rounded),
          ),
        if (settingsProvider.glowMode > 0)
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
        if (!context.read<DeviceService>().isTv)
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
            secondary: const Icon(Icons.animation_rounded),
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
                  // Transparent background to blend with SectionCard
                  backgroundColor: Colors.transparent,
                  child: TvFocusWrapper(
                    showGlow: true,
                    borderRadius: BorderRadius.circular(24),
                    child: SegmentedButton<double>(
                      segments: const [
                        ButtonSegment(
                          value: 1.0,
                          label: Text('1x'),
                          icon: Icon(Icons.speed),
                        ),
                        ButtonSegment(
                          value: 0.5,
                          label: Text('0.5x'),
                        ),
                        ButtonSegment(
                          value: 0.25,
                          label: Text('0.25x'),
                        ),
                        ButtonSegment(
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
                        // Make border transparent to let gradient show
                        side: WidgetStateProperty.all(BorderSide.none),
                        backgroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            // Always use transparent background for a cleaner look
                            // Rely on text color to show selection
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor:
                            WidgetStateProperty.resolveWith<Color?>(
                          (states) {
                            if (states.contains(WidgetState.selected)) {
                              return Theme.of(context).colorScheme.primary;
                            }
                            // Unselected: Use white70 in dark mode for contrast, or default grey
                            final isDark =
                                Theme.of(context).brightness == Brightness.dark;
                            return isDark ? Colors.white70 : null;
                          },
                        ),
                        textStyle: WidgetStateProperty.resolveWith<TextStyle?>(
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
              ],
            ),
          ),
        if (!Provider.of<DeviceService>(context, listen: false).isTv)
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
              HapticFeedback.lightImpact();
              FontSelectionDialog.show(context);
            },
          ),
        // Screensaver (oil_slide) - Show on TV OR in Debug/Profile mode for testing
        if (Provider.of<DeviceService>(context, listen: false).isTv ||
            !kReleaseMode) ...[
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Screen Saver',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Psychedelic oil lamp visualizer',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            value: settingsProvider.useOilScreensaver,
            onChanged: (value) {
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().toggleUseOilScreensaver();
            },
            secondary: const Icon(Icons.blur_circular_rounded),
          ),
          // Manual Start Button
          TvListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Start Screen Saver',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * widget.scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Test the psychedelic oil lamp effect now',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * widget.scaleFactor))),
            onTap: () {
              HapticFeedback.lightImpact();
              ScreensaverScreen.show(context);
            },
          ),
          if (settingsProvider.useOilScreensaver) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  const SizedBox(height: 8),
                  // Visual Style Selection
                  Text(
                    'Visual Style',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12.0 * widget.scaleFactor),
                  ),
                  const SizedBox(height: 8),
                  TvFocusWrapper(
                    showGlow: true,
                    borderRadius: BorderRadius.circular(24),
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final modes = [
                          'psychedelic',
                          'lava_lamp',
                          'silk',
                          'steal'
                        ];
                        final currentIndex =
                            modes.indexOf(settingsProvider.oilVisualMode);

                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          if (currentIndex > 0) {
                            HapticFeedback.selectionClick();
                            context
                                .read<SettingsProvider>()
                                .setOilVisualMode(modes[currentIndex - 1]);
                            return KeyEventResult.handled;
                          }
                        } else if (event.logicalKey ==
                            LogicalKeyboardKey.arrowRight) {
                          if (currentIndex < modes.length - 1) {
                            HapticFeedback.selectionClick();
                            context
                                .read<SettingsProvider>()
                                .setOilVisualMode(modes[currentIndex + 1]);
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'psychedelic',
                          label: Text('Standard'),
                          icon: Icon(Icons.auto_awesome_rounded),
                        ),
                        ButtonSegment(
                          value: 'lava_lamp',
                          label: Text('Lava Lamp'),
                          icon: Icon(Icons.waves_rounded),
                        ),
                        ButtonSegment(
                          value: 'silk',
                          label: Text('Silk'),
                          icon: Icon(Icons.texture_rounded),
                        ),
                        ButtonSegment(
                          value: 'steal',
                          label: Text('Steal'),
                          icon: Icon(Icons.bolt_rounded),
                        ),
                      ],
                      selected: {settingsProvider.oilVisualMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        HapticFeedback.lightImpact();
                        context
                            .read<SettingsProvider>()
                            .setOilVisualMode(newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // App Mode Selection (Standard vs Kiosk)
                  Text(
                    'App Mode',
                    style: Theme.of(context)
                        .textTheme
                        .bodyMedium
                        ?.copyWith(fontSize: 12.0 * widget.scaleFactor),
                  ),
                  const SizedBox(height: 8),
                  TvFocusWrapper(
                    showGlow: true,
                    borderRadius: BorderRadius.circular(24),
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        final modes = ['standard', 'kiosk'];
                        final currentIndex =
                            modes.indexOf(settingsProvider.oilScreensaverMode);

                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          if (currentIndex > 0) {
                            HapticFeedback.selectionClick();
                            context
                                .read<SettingsProvider>()
                                .setOilScreensaverMode(modes[currentIndex - 1]);
                            return KeyEventResult.handled;
                          }
                        } else if (event.logicalKey ==
                            LogicalKeyboardKey.arrowRight) {
                          if (currentIndex < modes.length - 1) {
                            HapticFeedback.selectionClick();
                            context
                                .read<SettingsProvider>()
                                .setOilScreensaverMode(modes[currentIndex + 1]);
                            return KeyEventResult.handled;
                          }
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'standard',
                          label: Text('Standard'),
                          icon: Icon(Icons.tv_rounded),
                        ),
                        ButtonSegment(
                          value: 'kiosk',
                          label: Text('Kiosk'),
                          icon: Icon(Icons.settings_remote_rounded),
                        ),
                      ],
                      selected: {settingsProvider.oilScreensaverMode},
                      onSelectionChanged: (Set<String> newSelection) {
                        HapticFeedback.lightImpact();
                        context
                            .read<SettingsProvider>()
                            .setOilScreensaverMode(newSelection.first);
                      },
                      showSelectedIcon: false,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Inactivity Timeout
                  Row(
                    children: [
                      Text(
                        'Inactivity Timeout',
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
                                final newVal = (settingsProvider
                                            .oilScreensaverInactivityMinutes -
                                        1)
                                    .clamp(1, 30);
                                if (newVal !=
                                    settingsProvider
                                        .oilScreensaverInactivityMinutes) {
                                  HapticFeedback.selectionClick();
                                  context
                                      .read<SettingsProvider>()
                                      .setOilScreensaverInactivityMinutes(
                                          newVal);
                                }
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                final newVal = (settingsProvider
                                            .oilScreensaverInactivityMinutes +
                                        1)
                                    .clamp(1, 30);
                                if (newVal !=
                                    settingsProvider
                                        .oilScreensaverInactivityMinutes) {
                                  HapticFeedback.selectionClick();
                                  context
                                      .read<SettingsProvider>()
                                      .setOilScreensaverInactivityMinutes(
                                          newVal);
                                }
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: Slider(
                            onChangeStart: (_) => HapticFeedback.lightImpact(),
                            value: settingsProvider
                                .oilScreensaverInactivityMinutes
                                .toDouble(),
                            min: 1,
                            max: 30,
                            divisions: 29,
                            label:
                                '${settingsProvider.oilScreensaverInactivityMinutes} min',
                            onChanged: (value) {
                              if (value.round() !=
                                  settingsProvider
                                      .oilScreensaverInactivityMinutes) {
                                HapticFeedback.selectionClick();
                              }
                              context
                                  .read<SettingsProvider>()
                                  .setOilScreensaverInactivityMinutes(
                                      value.round());
                            },
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 60 * widget.scaleFactor,
                        child: Text(
                          '${settingsProvider.oilScreensaverInactivityMinutes} min',
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
                      const SizedBox(width: 16),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Manual Start Button
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

// Helper widget for Color Picker
