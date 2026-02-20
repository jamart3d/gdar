import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/tv/tv_stepper_row.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';

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
        // ── System ─────────────────────────────────────────────────────
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

        // Everything below is hidden when screensaver is off
        if (settings.useOilScreensaver) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
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
                    onSelectionChanged: (Set<int> s) =>
                        settings.setOilScreensaverInactivityMinutes(s.first),
                    showSelectedIcon: false,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          TvListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            leading: const Icon(Icons.play_circle_outline_rounded),
            title: Text(
              'Start Screen Saver',
              style:
                  textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
            ),
            subtitle: Text(
              'Test the Steal Your Face visual effect now',
              style: textTheme.bodySmall
                  ?.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            onTap: () => ScreensaverScreen.show(context),
          ),

          const SizedBox(height: 32),

          // ── Visual Settings ──────────────────────────────────────────
          _SectionHeader(title: 'Visual', colorScheme: colorScheme),
          const SizedBox(height: 8),

          Text(
            'Color Palette',
            style: textTheme.bodySmall
                ?.copyWith(color: colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          _PaletteSegmentedButton(
            selected: settings.oilPalette,
            onSelect: (key) => settings.setOilPalette(key),
            colorScheme: colorScheme,
          ),

          const SizedBox(height: 24),

          _ToggleRow(
            label: 'Flat Color Mode',
            subtitle: 'Use a single static palette color instead of animation',
            value: settings.oilFlatColor,
            onChanged: (_) => settings.toggleOilFlatColor(),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: 16),

          _ToggleRow(
            label: 'Auto Palette Cycle',
            subtitle: 'Automatically rotate through palettes over time',
            value: settings.oilPaletteCycle,
            onChanged: (_) => settings.toggleOilPaletteCycle(),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          const SizedBox(height: 24),

          TvStepperRow(
            label: 'Logo Scale',
            value: settings.oilLogoScale,
            min: 0.1,
            max: 1.0,
            step: 0.05,
            leftLabel: 'Small',
            rightLabel: 'Full',
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (v) => settings.setOilLogoScale(v),
          ),

          const SizedBox(height: 16),

          TvStepperRow(
            label: 'Logo Blur',
            value: settings.oilBlurAmount,
            min: 0.0,
            max: 1.0,
            step: 0.05,
            leftLabel: 'Sharp',
            rightLabel: 'Soft',
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (v) => settings.setOilBlurAmount(v),
          ),

          const SizedBox(height: 16),

          TvStepperRow(
            label: 'Motion Smoothing',
            value: settings.oilTranslationSmoothing,
            min: 0.0,
            max: 1.0,
            step: 0.05,
            leftLabel: 'Crisp',
            rightLabel: 'Smooth',
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (v) => settings.setOilTranslationSmoothing(v),
          ),

          const SizedBox(height: 24),

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

          // ── Track Info Rings ─────────────────────────────────────────
          _ToggleRow(
            label: 'Show Track Info',
            subtitle:
                'Three rings: venue (outer), title (middle), date (inner)',
            value: settings.oilShowInfoBanner,
            onChanged: (_) => settings.toggleOilShowInfoBanner(),
            colorScheme: colorScheme,
            textTheme: textTheme,
          ),

          if (settings.oilShowInfoBanner) ...[
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Inner Ring Size',
              value: settings.oilInnerRingScale,
              min: 0.5,
              max: 2.0,
              step: 0.05,
              leftLabel: 'Small',
              rightLabel: 'Large',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilInnerRingScale(v),
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Title Ring Gap',
              value: settings.oilInnerToMiddleGap,
              min: 0.0,
              max: 1.0,
              step: 0.05,
              leftLabel: 'Tight',
              rightLabel: 'Spaced',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilInnerToMiddleGap(v),
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Venue Ring Gap',
              value: settings.oilMiddleToOuterGap,
              min: 0.0,
              max: 1.0,
              step: 0.05,
              leftLabel: 'Tight',
              rightLabel: 'Spaced',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilMiddleToOuterGap(v),
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Orbit Drift',
              value: settings.oilOrbitDrift,
              min: 0.0,
              max: 2.0,
              step: 0.1,
              leftLabel: 'Centered',
              rightLabel: 'Wide',
              valueFormatter: (v) => v == 0.0 ? 'Off' : '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilOrbitDrift(v),
            ),
            const SizedBox(height: 16),
            _ToggleRow(
              label: 'Ring Neon Glow',
              subtitle: 'Triple-layer neon glow effect on text rings',
              value: settings.oilBannerGlow,
              onChanged: (_) => settings.toggleOilBannerGlow(),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Ring Flicker',
              value: settings.oilBannerFlicker,
              min: 0.0,
              max: 1.0,
              step: 0.05,
              leftLabel: 'Steady',
              rightLabel: 'Buzzing',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilBannerFlicker(v),
            ),
          ],

          const SizedBox(height: 32),

          // ── Audio Reactivity ─────────────────────────────────────────
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
                'Peak Decay controls how quickly the visualizer adapts to changes '
                'in volume. Slow adapt keeps loud moments pumping longer; Fast '
                'adapt stays fresh with quiet passages.',
                style: textTheme.bodySmall
                    ?.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ),
          ],

          const SizedBox(height: 32),

          // ── Performance ──────────────────────────────────────────────
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
        // End of useOilScreensaver block
      ],
    );
  }
}

// ── Palette Segmented Button ───────────────────────────────────────────────

class _PaletteSegmentedButton extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final ColorScheme colorScheme;

  const _PaletteSegmentedButton({
    required this.selected,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final keys = StealConfig.palettes.keys.toList();

    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final idx = keys.indexOf(selected);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && idx > 0) {
            onSelect(keys[idx - 1]);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              idx < keys.length - 1) {
            onSelect(keys[idx + 1]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SegmentedButton<String>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.transparent),
          iconColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(BorderSide.none),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        segments: keys.map((key) {
          final isSelected = key == selected;
          return ButtonSegment<String>(
            value: key,
            label: _AnimatedPaletteSegment(
              paletteKey: key,
              isSelected: isSelected,
              colorScheme: colorScheme,
            ),
          );
        }).toList(),
        selected: {selected},
        onSelectionChanged: (Set<String> s) => onSelect(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _AnimatedPaletteSegment extends StatefulWidget {
  final String paletteKey;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _AnimatedPaletteSegment({
    required this.paletteKey,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  State<_AnimatedPaletteSegment> createState() =>
      _AnimatedPaletteSegmentState();
}

class _AnimatedPaletteSegmentState extends State<_AnimatedPaletteSegment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;

  static const Duration _stepDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _colors = StealConfig.palettes[widget.paletteKey]!;
    _controller = AnimationController(
      vsync: this,
      duration: _stepDuration * _colors.length,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _currentColor {
    final t = _controller.value * _colors.length;
    final idx = t.floor() % _colors.length;
    final next = (idx + 1) % _colors.length;
    final frac = t - t.floor();
    return Color.lerp(_colors[idx], _colors[next], frac)!;
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = _currentColor;
        final isSelected = widget.isSelected;
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.85 : 0.28),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.0),
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(Icons.check_rounded,
                  color: Colors.white.withValues(alpha: 0.9), size: 18)
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

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
