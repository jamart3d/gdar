import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

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
        _SliderRow(
          label: 'Flow Speed',
          value: settings.oilFlowSpeed,
          min: 0.1,
          max: 3.0,
          divisions: 29,
          leftLabel: 'Slow',
          rightLabel: 'Fast',
          onChanged: (v) => settings.setOilFlowSpeed(v),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 16),

        // Pulse Intensity
        _SliderRow(
          label: 'Pulse Intensity',
          value: settings.oilPulseIntensity,
          min: 0.0,
          max: 3.0,
          divisions: 30,
          leftLabel: 'Subtle',
          rightLabel: 'Strong',
          onChanged: (v) => settings.setOilPulseIntensity(v),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 16),

        // Film Grain
        _SliderRow(
          label: 'Film Grain',
          value: settings.oilFilmGrain,
          min: 0.0,
          max: 1.0,
          divisions: 20,
          leftLabel: 'None',
          rightLabel: 'Heavy',
          onChanged: (v) => settings.setOilFilmGrain(v),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 16),

        // Heat Drift
        _SliderRow(
          label: 'Heat Drift',
          value: settings.oilHeatDrift,
          min: 0.0,
          max: 3.0,
          divisions: 30,
          leftLabel: 'Still',
          rightLabel: 'Wavy',
          onChanged: (v) => settings.setOilHeatDrift(v),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),

        const SizedBox(height: 24),

        // Palette Cycle toggle
        _ToggleRow(
          label: 'Auto Palette Cycle',
          subtitle: 'Automatically rotate through palettes over time',
          value: settings.oilPaletteCycle,
          onChanged: (_) => settings.toggleOilPaletteCycle(),
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
          _SliderRow(
            label: 'Reactivity Strength',
            value: settings.oilAudioReactivityStrength,
            min: 0.5,
            max: 2.0,
            divisions: 15,
            leftLabel: 'Subtle',
            rightLabel: 'Wild',
            onChanged: (v) => settings.setOilAudioReactivityStrength(v),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: 16),

          // Bass Boost
          _SliderRow(
            label: 'Bass Boost',
            value: settings.oilAudioBassBoost,
            min: 1.0,
            max: 3.0,
            divisions: 20,
            leftLabel: 'Normal',
            rightLabel: 'Punchy',
            onChanged: (v) => settings.setOilAudioBassBoost(v),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: 16),

          // Peak Decay
          _SliderRow(
            label: 'Peak Decay',
            value: settings.oilAudioPeakDecay,
            min: 0.990,
            max: 0.999,
            divisions: 9,
            leftLabel: 'Fast adapt',
            rightLabel: 'Slow adapt',
            onChanged: (v) => settings.setOilAudioPeakDecay(v),
            colorScheme: colorScheme,
            textTheme: textTheme,
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

class _SliderRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String leftLabel;
  final String rightLabel;
  final ValueChanged<double> onChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;

  const _SliderRow({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.leftLabel,
    required this.rightLabel,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: textTheme.bodyLarge
                    ?.copyWith(color: colorScheme.onSurface)),
            Text(
              value.toStringAsFixed(2),
              style: textTheme.bodyMedium
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: colorScheme.primary,
          inactiveColor: colorScheme.surfaceContainerHighest,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(leftLabel,
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(rightLabel,
                  style: textTheme.labelSmall
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
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
