import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/settings/appearance_theme_controls.dart';
import 'package:shakedown_core/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_segmented_control.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

class GlowBorderTile extends StatelessWidget {
  final double scaleFactor;

  const GlowBorderTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    final colorScheme = Theme.of(context).colorScheme;
    final isGated = settingsProvider.performanceMode;
    const reason = 'Disabled in Simple Theme';

    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Glow Border',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontSize: 16 * scaleFactor,
            color: isGated
                ? colorScheme.onSurface.withValues(alpha: 0.5)
                : null,
          ),
        ),
      ),
      subtitle: isGated
          ? Text(
              reason,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12 * scaleFactor,
                color: colorScheme.secondary.withValues(alpha: 0.7),
              ),
            )
          : null,
      value: !isGated && settingsProvider.glowMode > 0,
      onChanged: isGated
          ? null
          : (value) {
              context.read<SettingsProvider>().setGlowMode(value ? 65 : 0);
            },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.sparkles
            : Icons.blur_on_rounded,
        color: isGated ? colorScheme.onSurface.withValues(alpha: 0.3) : null,
      ),
    );
  }
}

class GlowIntensityControl extends StatelessWidget {
  final double scaleFactor;

  const GlowIntensityControl({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              children: [
                Text(
                  'Intensity',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 12.0 * scaleFactor),
                ),
                Expanded(
                  child: TvFocusWrapper(
                    onKeyEvent: (node, event) {
                      if (event is KeyDownEvent) {
                        if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                          final newValue = (settingsProvider.glowMode - 5)
                              .clamp(10, 100);
                          if (newValue != settingsProvider.glowMode) {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            context.read<SettingsProvider>().setGlowMode(
                              newValue,
                            );
                          }
                          return KeyEventResult.handled;
                        }
                        if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                          final newValue = (settingsProvider.glowMode + 5)
                              .clamp(10, 100);
                          if (newValue != settingsProvider.glowMode) {
                            AppHaptics.selectionClick(
                              context.read<DeviceService>(),
                            );
                            context.read<SettingsProvider>().setGlowMode(
                              newValue,
                            );
                          }
                          return KeyEventResult.handled;
                        }
                      }
                      return KeyEventResult.ignored;
                    },
                    borderRadius: BorderRadius.circular(12),
                    focusDecoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    showGlow: false,
                    useRgbBorder: true,
                    tightDecorativeBorder: true,
                    decorativeBorderGap: 1.0,
                    overridePremiumHighlight: false,
                    child: Slider(
                      onChangeStart: (_) =>
                          AppHaptics.lightImpact(context.read<DeviceService>()),
                      value: settingsProvider.glowMode.toDouble(),
                      min: 10,
                      max: 100,
                      divisions: 18,
                      label: '${settingsProvider.glowMode}%',
                      onChanged: (value) {
                        if (value.round() != settingsProvider.glowMode) {
                          AppHaptics.selectionClick(
                            context.read<DeviceService>(),
                          );
                        }
                        context.read<SettingsProvider>().setGlowMode(
                          value.round(),
                        );
                      },
                    ),
                  ),
                ),
                SizedBox(
                  width: 40 * scaleFactor,
                  child: Text(
                    '${settingsProvider.glowMode}%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 12.0 * scaleFactor,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    textAlign: TextAlign.end,
                  ),
                ),
                const SizedBox(width: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HighlightPlayingTile extends StatelessWidget {
  final double scaleFactor;

  const HighlightPlayingTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: Text(
          'Highlight Playing with RGB',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor),
        ),
      ),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Animate active border with RGB colors, including in Simple Theme',
      ),
      value: settingsProvider.highlightPlayingWithRgb,
      onChanged: (value) {
        final provider = context.read<SettingsProvider>();
        provider.toggleHighlightPlayingWithRgb();
        if (!value && provider.useTrueBlack) {
          provider.setGlowMode(0);
        }
      },
      secondary: Icon(
        themeProvider.themeStyle == ThemeStyle.fruit
            ? LucideIcons.zap
            : Icons.animation_rounded,
      ),
    );
  }
}

class RgbAnimationSpeedControl extends StatelessWidget {
  final double scaleFactor;

  const RgbAnimationSpeedControl({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'RGB Animation Speed',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontSize: 12.0 * scaleFactor),
          ),
          const SizedBox(height: 8),
          AnimatedGradientBorder(
            borderRadius: 24,
            borderWidth: 3,
            allowInPerformanceMode: true,
            colors: const [
              Colors.red,
              Colors.yellow,
              Colors.green,
              Colors.cyan,
              Colors.blue,
              Colors.purple,
              Colors.red,
            ],
            enabled: true,
            showShadow: true,
            glowOpacity: 0.5 * (settingsProvider.glowMode / 100.0),
            animationSpeed: settingsProvider.rgbAnimationSpeed,
            ignoreGlobalClock: true,
            backgroundColor: Colors.transparent,
            child: TvFocusWrapper(
              borderRadius: BorderRadius.circular(21),
              focusDecoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(21),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              showGlow: false,
              useRgbBorder: false,
              tightDecorativeBorder: true,
              decorativeBorderGap: 1.0,
              overridePremiumHighlight: false,
              child: SingleChildScrollView(
                key: const PageStorageKey('rgb_speed_scroll'),
                controller: ScrollController(keepScrollOffset: false),
                scrollDirection: Axis.horizontal,
                child: themeProvider.themeStyle == ThemeStyle.fruit
                    ? FruitSegmentedControl<double>(
                        values: const [1.0, 0.5, 0.25, 0.1],
                        selectedValue: settingsProvider.rgbAnimationSpeed,
                        onSelectionChanged: (value) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          context.read<SettingsProvider>().setRgbAnimationSpeed(
                            value,
                          );
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
                                  style: TextStyle(fontSize: 12 * scaleFactor),
                                ),
                              ],
                            );
                          }
                          if (value == 0.5) {
                            return Text(
                              'Med',
                              style: TextStyle(fontSize: 12 * scaleFactor),
                            );
                          }
                          if (value == 0.25) {
                            return Text(
                              'Slow',
                              style: TextStyle(fontSize: 12 * scaleFactor),
                            );
                          }
                          return Text(
                            'Off',
                            style: TextStyle(fontSize: 12 * scaleFactor),
                          );
                        },
                        borderRadius: BorderRadius.circular(21),
                      )
                    : SegmentedButton<double>(
                        segments: [
                          ButtonSegment(
                            value: 1.0,
                            label: const Text('Fast'),
                            icon: Icon(
                              themeProvider.themeStyle == ThemeStyle.fruit
                                  ? LucideIcons.zap
                                  : Icons.speed,
                            ),
                          ),
                          const ButtonSegment(value: 0.5, label: Text('Med')),
                          const ButtonSegment(value: 0.25, label: Text('Slow')),
                          const ButtonSegment(value: 0.1, label: Text('Off')),
                        ],
                        selected: {settingsProvider.rgbAnimationSpeed},
                        onSelectionChanged: (Set<double> newSelection) {
                          AppHaptics.lightImpact(context.read<DeviceService>());
                          context.read<SettingsProvider>().setRgbAnimationSpeed(
                            newSelection.first,
                          );
                        },
                        showSelectedIcon: false,
                        style: ButtonStyle(
                          shape: WidgetStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(21),
                            ),
                          ),
                          side: WidgetStateProperty.all(
                            const BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                          backgroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(context).colorScheme.onSurface
                                      .withValues(alpha: 0.12);
                                }
                                return Colors.transparent;
                              }),
                          foregroundColor:
                              WidgetStateProperty.resolveWith<Color>((states) {
                                if (states.contains(WidgetState.selected)) {
                                  return Theme.of(
                                    context,
                                  ).colorScheme.onSurface;
                                }
                                return Theme.of(
                                  context,
                                ).colorScheme.onSurface.withValues(alpha: 0.7);
                              }),
                          textStyle:
                              WidgetStateProperty.resolveWith<TextStyle?>(
                                (states) => null,
                              ),
                        ),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class BeatAutocorrSecondPassTile extends StatelessWidget {
  final double scaleFactor;

  const BeatAutocorrSecondPassTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: buildTileTitle(context, scaleFactor, 'Beat Precision Refinement'),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Improves BPM accuracy when no beat grid is locked',
      ),
      value: settingsProvider.beatAutocorrSecondPass,
      onChanged: (_) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleBeatAutocorrSecondPass();
      },
      secondary: const Icon(LucideIcons.activity),
    );
  }
}

class BeatAutocorrSecondPassHqTile extends StatelessWidget {
  final double scaleFactor;

  const BeatAutocorrSecondPassHqTile({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: buildTileTitle(context, scaleFactor, 'High-Quality Refinement'),
      subtitle: buildTileSubtitle(
        context,
        scaleFactor,
        'Higher accuracy, more compute. Not available on all devices.',
      ),
      value: settingsProvider.beatAutocorrSecondPassHq,
      onChanged: (_) {
        AppHaptics.lightImpact(context.read<DeviceService>());
        context.read<SettingsProvider>().toggleBeatAutocorrSecondPassHq();
      },
      secondary: const Icon(LucideIcons.cpu),
    );
  }
}
