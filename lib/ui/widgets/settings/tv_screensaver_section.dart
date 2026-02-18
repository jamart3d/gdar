import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/tv/tv_stepper_row.dart';

/// Screensaver settings section for the Google TV settings screen.
/// Covers both visual settings and audio reactivity tuning.
class TvScreensaverSection extends StatelessWidget {
  const TvScreensaverSection({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── System Settings ────────────────────────────────────────────
        _SectionHeader(title: 'System', colorScheme: colorScheme),
        const SizedBox(height: 8),

        _ToggleRow(
          label: 'Prevent Sleep',
          subtitle: 'Prevent system sleep while music is playing',
          value: settings.preventSleep,
          onChanged: (_) => settings.togglePreventSleep(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 16),

        _ToggleRow(
          label: 'Shakedown Screen Saver',
          subtitle: 'Enable the Steal Your Face visual effect',
          value: settings.useOilScreensaver,
          onChanged: (_) => settings.toggleUseOilScreensaver(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 16),

        if (settings.useOilScreensaver) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Inactivity Timeout',
                  style: textTheme.bodySmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 8),
                TvFocusWrapper(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final current = settings.oilScreensaverInactivityMinutes;
                      int? newVal;
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        if (current == 15) {
                          newVal = 5;
                        } else if (current == 5) {
                          newVal = 1;
                        }
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowRight) {
                        if (current == 1) {
                          newVal = 5;
                        } else if (current == 5) {
                          newVal = 15;
                        }
                      }
                      if (newVal != null && newVal != current) {
                        HapticFeedback.selectionClick();
                        settings.setOilScreensaverInactivityMinutes(newVal);
                        return KeyEventResult.handled;
                      }
                    }
                    return KeyEventResult.ignored;
                  },
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 min')),
                      ButtonSegment(value: 5, label: Text('5 min')),
                      ButtonSegment(value: 15, label: Text('15 min')),
                    ],
                    selected: {settings.oilScreensaverInactivityMinutes},
                    onSelectionChanged: (Set<int> newSelection) {
                      HapticFeedback.lightImpact();
                      settings.setOilScreensaverInactivityMinutes(
                          newSelection.first);
                    },
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],

        TvListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.play_circle_outline_rounded),
          title: Text(
            'Start Screen Saver',
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
          subtitle: Text(
            'Test the Steal Your Face visual effect now',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          onTap: () => ScreensaverScreen.show(context),
        ),

        const SizedBox(height: 32),

        // ── Visual Settings ────────────────────────────────────────────
        _SectionHeader(title: 'Visual', colorScheme: colorScheme),
        const SizedBox(height: 8),

        // Palette
        _LabelRow(
          label: 'Color Palette',
          value: settings.oilPalette,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 8),
        FocusTraversalGroup(
          policy: WidgetOrderTraversalPolicy(),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: StealConfig.palettes.keys.map((palette) {
              final isSelected = settings.oilPalette == palette;
              return TvFocusWrapper(
                autofocus: isSelected,
                onTap: () => settings.setOilPalette(palette),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    palette,
                    style: TextStyle(
                      color: isSelected
                          ? colorScheme.onPrimaryContainer
                          : colorScheme.onSurfaceVariant,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 24),

        // Flow Speed
        TvStepperRow(
          label: 'Flow Speed',
          value: settings.oilFlowSpeed,
          min: 0.1,
          max: 3.0,
          step: 0.1,
          leftLabel: 'Slow',
          rightLabel: 'Fast',
          onChanged: (v) => settings.setOilFlowSpeed(v),
        ),

        const SizedBox(height: 16),

        // Pulse Intensity
        TvStepperRow(
          label: 'Pulse Intensity',
          value: settings.oilPulseIntensity,
          min: 0.0,
          max: 3.0,
          step: 0.1,
          leftLabel: 'Subtle',
          rightLabel: 'Strong',
          onChanged: (v) => settings.setOilPulseIntensity(v),
        ),

        const SizedBox(height: 16),

        // Film Grain
        TvStepperRow(
          label: 'Film Grain',
          value: settings.oilFilmGrain,
          min: 0.0,
          max: 1.0,
          step: 0.05,
          leftLabel: 'None',
          rightLabel: 'Heavy',
          onChanged: (v) => settings.setOilFilmGrain(v),
        ),

        const SizedBox(height: 16),

        // Heat Drift
        TvStepperRow(
          label: 'Heat Drift',
          value: settings.oilHeatDrift,
          min: 0.0,
          max: 3.0,
          step: 0.1,
          leftLabel: 'Still',
          rightLabel: 'Wavy',
          onChanged: (v) => settings.setOilHeatDrift(v),
        ),

        const SizedBox(height: 24),

        // Show Track Info banner toggle
        _ToggleRow(
          label: 'Show Track Info',
          subtitle: 'Display track title, venue and date as circular text',
          value: settings.oilShowInfoBanner,
          onChanged: (_) => settings.toggleOilShowInfoBanner(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 32),

        // ── Audio Reactivity ───────────────────────────────────────────
        _SectionHeader(title: 'Audio Reactivity', colorScheme: colorScheme),
        const SizedBox(height: 8),

        _ToggleRow(
          label: 'Enable Audio Reactivity',
          subtitle: 'Sync visuals to the music being played',
          value: settings.oilEnableAudioReactivity,
          onChanged: (_) => settings.toggleOilEnableAudioReactivity(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        if (settings.oilEnableAudioReactivity) ...[
          const SizedBox(height: 24),

          // Reactivity Strength
          TvStepperRow(
            label: 'Reactivity Strength',
            value: settings.oilAudioReactivityStrength,
            min: 0.5,
            max: 2.0,
            step: 0.1,
            leftLabel: 'Subtle',
            rightLabel: 'Wild',
            onChanged: (v) => settings.setOilAudioReactivityStrength(v),
          ),

          const SizedBox(height: 16),

          // Bass Boost
          TvStepperRow(
            label: 'Bass Boost',
            value: settings.oilAudioBassBoost,
            min: 1.0,
            max: 3.0,
            step: 0.1,
            leftLabel: 'Normal',
            rightLabel: 'Punchy',
            onChanged: (v) => settings.setOilAudioBassBoost(v),
          ),

          const SizedBox(height: 16),

          // Peak Decay
          TvStepperRow(
            label: 'Peak Decay',
            value: settings.oilAudioPeakDecay,
            min: 0.990,
            max: 0.999,
            step: 0.001,
            leftLabel: 'Fast adapt',
            rightLabel: 'Slow adapt',
            valueFormatter: (v) => v.toStringAsFixed(3),
            onChanged: (v) => settings.setOilAudioPeakDecay(v),
          ),

          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Peak Decay controls how quickly the visualizer adapts to changes in volume. '
              'Slow adapt keeps loud moments pumping longer; Fast adapt stays fresh with quiet passages.',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ],

        const SizedBox(height: 32),

        // ── Performance ────────────────────────────────────────────────
        _SectionHeader(title: 'Performance', colorScheme: colorScheme),
        const SizedBox(height: 8),

        _ToggleRow(
          label: 'Performance Mode',
          subtitle: 'Reduce shader complexity for smoother playback on TV',
          value: settings.oilPerformanceMode,
          onChanged: (_) => settings.toggleOilPerformanceMode(),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 32),
      ],
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _LabelRow extends StatelessWidget {
  final String label;
  final String value;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _LabelRow({
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface)),
        Text(value,
            style: textTheme.bodyMedium
                ?.copyWith(color: colorScheme.onSurfaceVariant)),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: textTheme.bodyLarge
                          ?.copyWith(color: colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: textTheme.bodySmall
                          ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}
