import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/steal_screensaver/steal_config.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/tv/tv_stepper_row.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/screens/screensaver_screen.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/ui/widgets/section_card.dart';

class TvScreensaverSection extends StatefulWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const TvScreensaverSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
  });

  @override
  State<TvScreensaverSection> createState() => _TvScreensaverSectionState();
}

class _TvScreensaverSectionState extends State<TvScreensaverSection> {
  final FocusNode _firstFocusNode = FocusNode();
  final FocusNode _lastFocusNode = FocusNode();
  int _wrapKey = 0;

  @override
  void dispose() {
    _firstFocusNode.dispose();
    _lastFocusNode.dispose();
    super.dispose();
  }

  KeyEventResult _handleFirstKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowUp) {
      setState(() {
        _wrapKey++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastFocusNode.requestFocus();
        try {
          Scrollable.ensureVisible(
            _lastFocusNode.context!,
            alignment: 1.0,
            duration: const Duration(milliseconds: 150),
          );
        } catch (_) {}
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  KeyEventResult _handleLastKey(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.arrowDown) {
      setState(() {
        _wrapKey++;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _firstFocusNode.requestFocus();
        try {
          Scrollable.of(_firstFocusNode.context!).position.jumpTo(0);
        } catch (_) {}
      });
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final isRingMode = settings.oilBannerDisplayMode == 'ring';

    return SectionCard(
      scaleFactor: widget.scaleFactor,
      title: 'TV Screen Saver',
      icon: Icons.monitor,
      lucideIcon: LucideIcons.monitor,
      initiallyExpanded: widget.initiallyExpanded,
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Column(
            key: ValueKey(_wrapKey),
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              // ── System ─────────────────────────────────────────────────────
              _SectionHeader(title: 'System', colorScheme: colorScheme),
              const SizedBox(height: 8),

              _ToggleRow(
                focusNode: _firstFocusNode,
                onKeyEvent: _handleFirstKey,
                label: 'Prevent Sleep',
                subtitle: 'Prevent system sleep while music is playing',
                value: settings.preventSleep,
                onChanged: (_) => settings.togglePreventSleep(),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),

              const SizedBox(height: 16),

              _ToggleRow(
                focusNode: !settings.useOilScreensaver ? _lastFocusNode : null,
                onKeyEvent: !settings.useOilScreensaver ? _handleLastKey : null,
                label: 'Shakedown Screen Saver',
                subtitle: 'Enable the Steal Your Face visual effect',
                value: settings.useOilScreensaver,
                onChanged: (_) => settings.toggleUseOilScreensaver(),
                colorScheme: colorScheme,
                textTheme: textTheme,
              ),

              if (settings.useOilScreensaver) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Inactivity Timeout',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TvFocusWrapper(
                        onKeyEvent: (node, event) {
                          if (event.runtimeType == KeyDownEvent ||
                              event.runtimeType == KeyRepeatEvent) {
                            final current =
                                settings.oilScreensaverInactivityMinutes;
                            int? newVal;
                            if (event.logicalKey ==
                                LogicalKeyboardKey.arrowLeft) {
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
                              settings.setOilScreensaverInactivityMinutes(
                                newVal,
                              );
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
                          onSelectionChanged: (Set<int> s) => settings
                              .setOilScreensaverInactivityMinutes(s.first),
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
                  leading: Icon(
                    isFruit
                        ? LucideIcons.playCircle
                        : Icons.play_circle_outline_rounded,
                  ),
                  title: Text(
                    'Start Screen Saver',
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  onTap: () => ScreensaverScreen.show(context),
                ),

                const SizedBox(height: 32),

                // ── Visual Settings ──────────────────────────────────────────
                _SectionHeader(title: 'Visual', colorScheme: colorScheme),
                const SizedBox(height: 8),

                Text(
                  'Color Palette',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
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
                  subtitle:
                      'Use a single static palette color instead of animation',
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
                const SizedBox(height: 8),
                _ReactiveHint(
                  message:
                      'Audio reactive: beat pulses are applied on top of this base size.',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  isFruit: isFruit,
                ),

                const SizedBox(height: 16),

                TvStepperRow(
                  label: 'Trail Intensity',
                  value: settings.oilLogoTrailIntensity,
                  min: 0.0,
                  max: 1.0,
                  step: 0.05,
                  leftLabel: 'Off',
                  rightLabel: 'Strong',
                  valueFormatter: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => settings.setOilLogoTrailIntensity(v),
                ),

                const SizedBox(height: 16),

                _ToggleRow(
                  label: 'Dynamic Trails',
                  subtitle: 'Scale trail quality based on movement speed',
                  value: settings.oilLogoTrailDynamic,
                  onChanged: (_) => settings.toggleOilLogoTrailDynamic(),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),

                const SizedBox(height: 16),

                TvStepperRow(
                  label: 'Trail Slices',
                  value: settings.oilLogoTrailSlices.toDouble(),
                  min: 2,
                  max: 16,
                  step: 1,
                  leftLabel: 'Slight',
                  rightLabel: 'Liquid',
                  valueFormatter: (v) => v.round().toString(),
                  onChanged: (v) => settings.setOilLogoTrailSlices(v.round()),
                ),

                const SizedBox(height: 16),

                TvStepperRow(
                  label: 'Trail Spread',
                  value: settings.oilLogoTrailLength,
                  min: 0.0,
                  max: 2.0,
                  step: 0.05,
                  leftLabel: 'Tight',
                  rightLabel: 'Long',
                  valueFormatter: (v) => '${(v * 100).round()}%',
                  onChanged: (v) => settings.setOilLogoTrailLength(v),
                ),

                const SizedBox(height: 16),

                TvStepperRow(
                  label: 'Trail Initial Scale',
                  value: settings.oilLogoTrailInitialScale,
                  min: 0.5,
                  max: 2.0,
                  step: 0.05,
                  leftLabel: '50%',
                  rightLabel: '200%',
                  valueFormatter: (v) =>
                      v == 1.0 ? '100% (Native)' : '${(v * 100).round()}%',
                  onChanged: (v) => settings.setOilLogoTrailInitialScale(v),
                ),

                const SizedBox(height: 16),

                TvStepperRow(
                  label: 'Trail Decay Scale',
                  value: settings.oilLogoTrailScale,
                  min: 0.0,
                  max: 0.5,
                  step: 0.05,
                  leftLabel: '1:1',
                  rightLabel: 'Taper',
                  valueFormatter: (v) =>
                      v == 0.0 ? 'None' : '-${(v * 100).round()}%',
                  onChanged: (v) => settings.setOilLogoTrailScale(v),
                ),

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
                  min: 0.01,
                  max: 1.0,
                  step: 0.01,
                  leftLabel: 'Slow',
                  rightLabel: 'Fast',
                  valueFormatter: (v) => v.toStringAsFixed(2),
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
                const SizedBox(height: 8),
                _ReactiveHint(
                  message:
                      'Audio reactive: higher values amplify bass-driven logo expansion.',
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                  isFruit: isFruit,
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

                // ── Track Info ───────────────────────────────────────────────
                _ToggleRow(
                  label: 'Show Track Info',
                  subtitle: 'Display venue, title, and date',
                  value: settings.oilShowInfoBanner,
                  onChanged: (_) => settings.toggleOilShowInfoBanner(),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),

                if (settings.oilShowInfoBanner) ...[
                  const SizedBox(height: 16),

                  // Ring / Flat toggle
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Display Style',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TvFocusWrapper(
                          onKeyEvent: (node, event) {
                            if (event.runtimeType == KeyDownEvent ||
                                event.runtimeType == KeyRepeatEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                settings.setOilBannerDisplayMode('ring');
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                settings.setOilBannerDisplayMode('flat');
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'ring', label: Text('Ring')),
                              ButtonSegment(value: 'flat', label: Text('Flat')),
                            ],
                            selected: {settings.oilBannerDisplayMode},
                            onSelectionChanged: (Set<String> s) =>
                                settings.setOilBannerDisplayMode(s.first),
                            showSelectedIcon: false,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Banner Font',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TvFocusWrapper(
                          onKeyEvent: (node, event) {
                            if (event.runtimeType == KeyDownEvent ||
                                event.runtimeType == KeyRepeatEvent) {
                              if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowLeft) {
                                settings.setOilBannerFont('RockSalt');
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                  LogicalKeyboardKey.arrowRight) {
                                settings.setOilBannerFont('Roboto');
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'RockSalt',
                                label: Text('Rock Salt'),
                              ),
                              ButtonSegment(
                                value: 'Roboto',
                                label: Text('Roboto'),
                              ),
                            ],
                            selected: {settings.oilBannerFont},
                            onSelectionChanged: (Set<String> s) =>
                                settings.setOilBannerFont(s.first),
                            showSelectedIcon: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Text Resolution',
                    value: settings.oilBannerResolution,
                    min: 1.0,
                    max: 4.0,
                    step: 0.5,
                    leftLabel: 'Native',
                    rightLabel: 'Ultra',
                    valueFormatter: (v) => '${v.toStringAsFixed(1)}x',
                    onChanged: (v) => settings.setOilBannerResolution(v),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Letter Spacing (General)',
                    value: settings.oilBannerLetterSpacing,
                    min: 0.5,
                    max: 1.5,
                    step: 0.01,
                    leftLabel: 'Tight',
                    rightLabel: 'Spaced',
                    valueFormatter: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => settings.setOilBannerLetterSpacing(v),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Word Spacing (General)',
                    value: settings.oilBannerWordSpacing,
                    min: 0.0,
                    max: 2.0,
                    step: 0.05,
                    leftLabel: 'Tight',
                    rightLabel: 'Spaced',
                    valueFormatter: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => settings.setOilBannerWordSpacing(v),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Track Letter Spacing',
                    value: settings.oilTrackLetterSpacing,
                    min: 0.5,
                    max: 1.5,
                    step: 0.01,
                    leftLabel: 'Tight',
                    rightLabel: 'Spaced',
                    valueFormatter: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => settings.setOilTrackLetterSpacing(v),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Track Word Spacing',
                    value: settings.oilTrackWordSpacing,
                    min: 0.0,
                    max: 2.0,
                    step: 0.05,
                    leftLabel: 'Tight',
                    rightLabel: 'Spaced',
                    valueFormatter: (v) => v.toStringAsFixed(2),
                    onChanged: (v) => settings.setOilTrackWordSpacing(v),
                  ),
                  const SizedBox(height: 16),

                  // Ring-only settings
                  if (isRingMode) ...[
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Inner Ring Size',
                      value: settings.oilInnerRingScale,
                      min: 0.1,
                      max: 1.0,
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
                      valueFormatter: (v) =>
                          v == 0.0 ? 'Off' : '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilOrbitDrift(v),
                    ),
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Inner Ring Font Size',
                      value: settings.oilInnerRingFontScale,
                      min: 0.3,
                      max: 1.0,
                      step: 0.05,
                      leftLabel: 'Small',
                      rightLabel: 'Full',
                      valueFormatter: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilInnerRingFontScale(v),
                    ),
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Inner Ring Spacing',
                      value: settings.oilInnerRingSpacingMultiplier,
                      min: 0.3,
                      max: 1.0,
                      step: 0.05,
                      leftLabel: 'Tight',
                      rightLabel: 'Normal',
                      valueFormatter: (v) => '${(v * 100).round()}%',
                      onChanged: (v) =>
                          settings.setOilInnerRingSpacingMultiplier(v),
                    ),
                  ],

                  // Flat-only settings
                  if (!isRingMode) ...[
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Text Placement',
                            style: textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TvFocusWrapper(
                            onKeyEvent: (node, event) {
                              if (event.runtimeType == KeyDownEvent ||
                                  event.runtimeType == KeyRepeatEvent) {
                                if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowLeft) {
                                  settings.setOilFlatTextPlacement('below');
                                  return KeyEventResult.handled;
                                } else if (event.logicalKey ==
                                    LogicalKeyboardKey.arrowRight) {
                                  settings.setOilFlatTextPlacement('above');
                                  return KeyEventResult.handled;
                                }
                              }
                              return KeyEventResult.ignored;
                            },
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'below',
                                  label: Text('Below'),
                                ),
                                ButtonSegment(
                                  value: 'above',
                                  label: Text('Above'),
                                ),
                              ],
                              selected: {settings.oilFlatTextPlacement},
                              onSelectionChanged: (Set<String> s) =>
                                  settings.setOilFlatTextPlacement(s.first),
                              showSelectedIcon: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Text Proximity',
                      value: settings.oilFlatTextProximity,
                      min: 0.0,
                      max: 1.0,
                      step: 0.05,
                      leftLabel: 'Away',
                      rightLabel: 'On Logo',
                      valueFormatter: (v) =>
                          v == 0.0 ? 'Default' : '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilFlatTextProximity(v),
                    ),
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Line Spacing',
                      value: settings.oilFlatLineSpacing,
                      min: 0.5,
                      max: 2.5,
                      step: 0.1,
                      leftLabel: 'Tight',
                      rightLabel: 'Spaced',
                      valueFormatter: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilFlatLineSpacing(v),
                    ),
                  ],

                  // Glow & flicker — available in both modes
                  const SizedBox(height: 16),
                  _ToggleRow(
                    label: 'Neon Glow',
                    subtitle: 'Multi-layer neon glow effect on text',
                    value: settings.oilBannerGlow,
                    onChanged: (_) => settings.toggleOilBannerGlow(),
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                  ),
                  if (settings.oilBannerGlow) ...[
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Flicker',
                      value: settings.oilBannerFlicker,
                      min: 0.0,
                      max: 1.0,
                      step: 0.05,
                      leftLabel: 'Steady',
                      rightLabel: 'Buzzing',
                      valueFormatter: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilBannerFlicker(v),
                    ),
                    const SizedBox(height: 16),
                    TvStepperRow(
                      label: 'Glow Blur',
                      value: settings.oilBannerGlowBlur,
                      min: 0.0,
                      max: 1.0,
                      step: 0.05,
                      leftLabel: 'Tight',
                      rightLabel: 'Wide',
                      valueFormatter: (v) => '${(v * 100).round()}%',
                      onChanged: (v) => settings.setOilBannerGlowBlur(v),
                    ),
                  ],
                ],

                const SizedBox(height: 32),

                // ── Audio Reactivity ─────────────────────────────────────────
                _SectionHeader(
                  title: 'Audio Reactivity',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),

                _ToggleRow(
                  label: 'Enable Audio Reactivity',
                  subtitle:
                      'Sync visuals to the music being played (requires audio permission)',
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
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],

                if (settings.oilEnableAudioReactivity) ...[
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Beat Sensitivity',
                    value: settings.oilBeatSensitivity,
                    min: 0.0,
                    max: 1.0,
                    step: 0.05,
                    leftLabel: 'Gentle',
                    rightLabel: 'Aggressive',
                    valueFormatter: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => settings.setOilBeatSensitivity(v),
                  ),
                  const SizedBox(height: 16),
                  TvStepperRow(
                    label: 'Beat Impact',
                    value: settings.oilBeatImpact,
                    min: 0.0,
                    max: 1.0,
                    step: 0.05,
                    leftLabel: 'Off',
                    rightLabel: 'Strong',
                    valueFormatter: (v) => '${(v * 100).round()}%',
                    onChanged: (v) => settings.setOilBeatImpact(v),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audio Graph',
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TvFocusWrapper(
                          onKeyEvent: (node, event) {
                            if (event.runtimeType == KeyDownEvent ||
                                event.runtimeType == KeyRepeatEvent) {
                              const modes = [
                                'off',
                                'corner',
                                'corner_only',
                                'circular',
                                'ekg',
                                'circular_ekg',
                              ];
                              final idx = modes.indexOf(
                                settings.oilAudioGraphMode,
                              );
                              if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowLeft &&
                                  idx > 0) {
                                settings.setOilAudioGraphMode(modes[idx - 1]);
                                return KeyEventResult.handled;
                              } else if (event.logicalKey ==
                                      LogicalKeyboardKey.arrowRight &&
                                  idx < modes.length - 1) {
                                settings.setOilAudioGraphMode(modes[idx + 1]);
                                return KeyEventResult.handled;
                              }
                            }
                            return KeyEventResult.ignored;
                          },
                          child: SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(value: 'off', label: Text('Off')),
                              ButtonSegment(
                                value: 'corner',
                                label: Text('Corner'),
                              ),
                              ButtonSegment(
                                value: 'corner_only',
                                label: Text('Corner Only'),
                              ),
                              ButtonSegment(
                                value: 'circular',
                                label: Text('Circular'),
                              ),
                              ButtonSegment(value: 'ekg', label: Text('EKG')),
                              ButtonSegment(
                                value: 'circular_ekg',
                                label: Text('Circ EKG'),
                              ),
                            ],
                            selected: {settings.oilAudioGraphMode},
                            onSelectionChanged: (Set<String> s) =>
                                settings.setOilAudioGraphMode(s.first),
                            showSelectedIcon: false,
                          ),
                        ),
                        if (settings.oilAudioGraphMode == 'ekg' ||
                            settings.oilAudioGraphMode == 'circular_ekg') ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (settings.oilAudioGraphMode ==
                                  'circular_ekg') ...[
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'EKG Radius',
                                        style: textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      TvFocusWrapper(
                                        onKeyEvent: (node, event) {
                                          if (event.runtimeType ==
                                                  KeyDownEvent ||
                                              event.runtimeType ==
                                                  KeyRepeatEvent) {
                                            if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowLeft) {
                                              settings.setOilEkgRadius(
                                                (settings.oilEkgRadius - 0.1)
                                                    .clamp(0.1, 2.0),
                                              );
                                              return KeyEventResult.handled;
                                            } else if (event.logicalKey ==
                                                LogicalKeyboardKey.arrowRight) {
                                              settings.setOilEkgRadius(
                                                (settings.oilEkgRadius + 0.1)
                                                    .clamp(0.1, 2.0),
                                              );
                                              return KeyEventResult.handled;
                                            }
                                          }
                                          return KeyEventResult.ignored;
                                        },
                                        child: ExcludeFocus(
                                          child: Slider(
                                            value: settings.oilEkgRadius,
                                            min: 0.1,
                                            max: 2.0,
                                            onChanged: settings.setOilEkgRadius,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 24),
                              ],
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Line Replication',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TvFocusWrapper(
                                      onKeyEvent: (node, event) {
                                        if (event.runtimeType == KeyDownEvent ||
                                            event.runtimeType ==
                                                KeyRepeatEvent) {
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowLeft) {
                                            settings.setOilEkgReplication(
                                              (settings.oilEkgReplication - 1)
                                                  .clamp(1, 10),
                                            );
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowRight) {
                                            settings.setOilEkgReplication(
                                              (settings.oilEkgReplication + 1)
                                                  .clamp(1, 10),
                                            );
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: ExcludeFocus(
                                        child: Slider(
                                          value: settings.oilEkgReplication
                                              .toDouble(),
                                          min: 1,
                                          max: 10,
                                          divisions: 9,
                                          label:
                                              '${settings.oilEkgReplication}',
                                          onChanged: (v) => settings
                                              .setOilEkgReplication(v.toInt()),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 24),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Line Spread',
                                      style: textTheme.bodySmall?.copyWith(
                                        color: colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TvFocusWrapper(
                                      onKeyEvent: (node, event) {
                                        if (event.runtimeType == KeyDownEvent ||
                                            event.runtimeType ==
                                                KeyRepeatEvent) {
                                          if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowLeft) {
                                            settings.setOilEkgSpread(
                                              (settings.oilEkgSpread - 0.5)
                                                  .clamp(0.0, 20.0),
                                            );
                                            return KeyEventResult.handled;
                                          } else if (event.logicalKey ==
                                              LogicalKeyboardKey.arrowRight) {
                                            settings.setOilEkgSpread(
                                              (settings.oilEkgSpread + 0.5)
                                                  .clamp(0.0, 20.0),
                                            );
                                            return KeyEventResult.handled;
                                          }
                                        }
                                        return KeyEventResult.ignored;
                                      },
                                      child: ExcludeFocus(
                                        child: Slider(
                                          value: settings.oilEkgSpread,
                                          min: 0.0,
                                          max: 20.0,
                                          divisions: 40,
                                          label: settings.oilEkgSpread
                                              .toStringAsFixed(1),
                                          onChanged: settings.setOilEkgSpread,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Frequency Isolation ─────────────────────────────────────
                _SectionHeader(
                  title: 'Frequency Isolation',
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),

                Text(
                  'Logo Scale Source',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _BandSegmentedButton(
                    selected: settings.oilScaleSource,
                    onSelect: (val) => settings.setOilScaleSource(val),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(height: 16),
                TvStepperRow(
                  label: 'Scale Multiplier',
                  value: settings.oilScaleMultiplier,
                  min: 0.1,
                  max: 2.0,
                  step: 0.1,
                  leftLabel: '0.1x',
                  rightLabel: '2.0x',
                  valueFormatter: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => settings.setOilScaleMultiplier(v),
                ),

                const SizedBox(height: 24),

                _ToggleRow(
                  label: 'Sine Wave Drive',
                  subtitle: 'Modulate logo scale with a periodic wave',
                  value: settings.oilScaleSineEnabled,
                  onChanged: (_) => settings.toggleOilScaleSineEnabled(),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),
                if (settings.oilScaleSineEnabled) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        TvStepperRow(
                          label: 'Sine Frequency',
                          value: settings.oilScaleSineFreq,
                          min: 0.01,
                          max: 10.0,
                          step: 0.05,
                          onChanged: settings.setOilScaleSineFreq,
                          valueFormatter: (v) => '${v.toStringAsFixed(2)} Hz',
                        ),
                        const SizedBox(height: 12),
                        TvStepperRow(
                          label: 'Sine Amplitude',
                          value: settings.oilScaleSineAmp,
                          min: 0.0,
                          max: 1.0,
                          step: 0.05,
                          onChanged: settings.setOilScaleSineAmp,
                          valueFormatter: (v) => '${(v * 100).round()}%',
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                Text(
                  'Logo Color Source',
                  style: textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: _BandSegmentedButton(
                    selected: settings.oilColorSource,
                    onSelect: (val) => settings.setOilColorSource(val),
                    colorScheme: colorScheme,
                  ),
                ),
                const SizedBox(height: 16),
                TvStepperRow(
                  label: 'Color Pulse Multiplier',
                  value: settings.oilColorMultiplier,
                  min: 0.0,
                  max: 2.0,
                  step: 0.1,
                  leftLabel: '0.0x',
                  rightLabel: '2.0x',
                  valueFormatter: (v) => '${v.toStringAsFixed(1)}x',
                  onChanged: (v) => settings.setOilColorMultiplier(v),
                ),

                const SizedBox(height: 32),

                // ── Performance ──────────────────────────────────────────────
                _SectionHeader(title: 'Performance', colorScheme: colorScheme),
                const SizedBox(height: 8),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rendering Quality',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _QualitySegmentedButton(
                        selectedLevel: settings.oilPerformanceLevel,
                        onSelect: (level) =>
                            settings.setOilPerformanceLevel(level),
                        colorScheme: colorScheme,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settings.oilPerformanceLevel == 0
                            ? 'High (Spectral chromatic aberration + ghost blur)'
                            : settings.oilPerformanceLevel == 1
                            ? 'Balanced (Standard box blur, smooth movement)'
                            : 'Fast (Sharp edges, 1-sample minimal GPU load)',
                        style: textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.7,
                          ),
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                _ToggleRow(
                  focusNode: _lastFocusNode,
                  onKeyEvent: _handleLastKey,
                  label: 'Logo Anti-Aliasing',
                  subtitle:
                      'Smooth the logo edge using sub-pixel precision. May impact performance.',
                  value: settings.oilLogoAntiAlias,
                  onChanged: (_) => settings.toggleOilLogoAntiAlias(),
                  colorScheme: colorScheme,
                  textTheme: textTheme,
                ),

                const SizedBox(height: 32),
              ],
            ],
          ),
        ),
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
        if (event.runtimeType == KeyDownEvent ||
            event.runtimeType == KeyRepeatEvent) {
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
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

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
              ? Icon(
                  isFruit ? LucideIcons.check : Icons.check_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

// ── Shared helpers ─────────────────────────────────────────────────────────

class _ReactiveHint extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isFruit;

  const _ReactiveHint({
    required this.message,
    required this.colorScheme,
    required this.textTheme,
    required this.isFruit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isFruit ? LucideIcons.activity : Icons.graphic_eq,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualitySegmentedButton extends StatelessWidget {
  final int selectedLevel; // 0=High, 1=Balanced, 2=Fast
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;

  const _QualitySegmentedButton({
    required this.selectedLevel,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSegment('HIGH', 0, isFirst: true),
        _buildSegment('BALANCED', 1),
        _buildSegment('FAST', 2, isLast: true),
      ],
    );
  }

  Widget _buildSegment(
    String label,
    int level, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = selectedLevel == level;
    return Expanded(
      child: TvFocusWrapper(
        onTap: () => onSelect(level),
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(8) : Radius.zero,
          right: isLast ? const Radius.circular(8) : Radius.zero,
        ),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

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

  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
    this.focusNode,
    this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
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
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
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

class _BandSegmentedButton extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;

  const _BandSegmentedButton({
    required this.selected,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    // -1 = All, 0-7 = Bands
    final options = [-1, 0, 1, 2, 3, 4, 5, 6, 7];

    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event.runtimeType == KeyDownEvent ||
            event.runtimeType == KeyRepeatEvent) {
          final idx = options.indexOf(selected);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && idx > 0) {
            onSelect(options[idx - 1]);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              idx < options.length - 1) {
            onSelect(options[idx + 1]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SegmentedButton<int>(
        segments: options.map((val) {
          String label;
          if (val == -1) {
            label = 'ALL';
          } else if (val == 0) {
            label = '0:SUB';
          } else if (val == 7) {
            label = '7:AIR';
          } else {
            label = val.toString();
          }

          return ButtonSegment<int>(
            value: val,
            label: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        selected: {selected},
        onSelectionChanged: (Set<int> s) => onSelect(s.first),
        showSelectedIcon: false,
      ),
    );
  }
}
