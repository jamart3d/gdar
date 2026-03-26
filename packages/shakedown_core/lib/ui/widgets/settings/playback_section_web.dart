part of 'playback_section.dart';

extension _PlaybackSectionWeb on PlaybackSection {
  List<Widget> _buildWebGaplessSection(
    BuildContext context,
    SettingsProvider settingsProvider,
    double scaleFactor,
    bool isFruit,
  ) {
    final audioProvider = context.watch<AudioProvider>();
    final detectedProfile = detectedWebProfileLabel();
    final resolvedMode =
        settingsProvider.audioEngineMode == AudioEngineMode.auto
        ? audioProvider.audioPlayer.activeMode
        : settingsProvider.audioEngineMode;

    return [
      Padding(
        padding: EdgeInsets.only(
          left: 16.0 * scaleFactor,
          right: 16.0 * scaleFactor,
          top: 16.0 * scaleFactor,
          bottom: 8.0 * scaleFactor,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isFruit
                      ? LucideIcons.settings
                      : Icons.settings_input_component_rounded,
                  size: 24 * scaleFactor,
                  color: Theme.of(context).colorScheme.primary,
                ),
                SizedBox(width: 16 * scaleFactor),
                Expanded(
                  child: Text(
                    'Web Audio Engine',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontSize: 16 * scaleFactor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Select the low-level processing engine for gapless playback.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Engine changes apply after relaunch (or browser refresh).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12 * scaleFactor,
                  color: Theme.of(context).colorScheme.onSurface.withAlpha(160),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SegmentedWrap<AudioEngineMode>(
                  isFruit: isFruit,
                  scaleFactor: scaleFactor,
                  segments: [
                    _Segment(
                      value: AudioEngineMode.webAudio,
                      label: 'Web Audio',
                      tooltip: '0ms gapless (High Performance)',
                      icon: isFruit
                          ? LucideIcons.activity
                          : Icons.graphic_eq_rounded,
                    ),
                    _Segment(
                      value: AudioEngineMode.html5,
                      label: 'HTML5',
                      tooltip: 'Gapless HTML5 (Safe Background)',
                      icon: isFruit
                          ? LucideIcons.smartphone
                          : Icons.smartphone_rounded,
                    ),
                    _Segment(
                      value: AudioEngineMode.hybrid,
                      label: 'Hybrid',
                      tooltip: 'Web Audio Foreground, HTML5 Background',
                      icon: isFruit
                          ? LucideIcons.layers
                          : Icons.handshake_rounded,
                    ),
                  ],
                  selectedValue:
                      settingsProvider.audioEngineMode == AudioEngineMode.auto
                      ? context.read<AudioProvider>().audioPlayer.activeMode
                      : settingsProvider.audioEngineMode,
                  onSelectionChanged: (AudioEngineMode mode) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    settingsProvider.setAudioEngineMode(mode);
                    showRestartMessage(
                      context,
                      'Relaunch required for engine change to take effect.',
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: StreamBuilder<String>(
                stream: audioProvider.audioPlayer.engineContextStateStream,
                initialData: 'unknown',
                builder: (context, snapshot) {
                  final contextState = snapshot.data ?? 'unknown';
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12 * scaleFactor,
                      vertical: 8 * scaleFactor,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(10 * scaleFactor),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Engine: ${audioProvider.audioPlayer.engineName}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 12 * scaleFactor),
                        ),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          'Context: $contextState',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 12 * scaleFactor),
                        ),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          'Detected Profile: $detectedProfile',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(fontSize: 12 * scaleFactor),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Background Mode',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _SegmentedWrap<HiddenSessionPreset>(
                  isFruit: isFruit,
                  scaleFactor: scaleFactor,
                  segments: [
                    _Segment(
                      value: HiddenSessionPreset.stability,
                      label: 'Compatible',
                      tooltip:
                          'Best background longevity - video keepalive, gapless when visible',
                      icon: isFruit ? LucideIcons.shield : Icons.shield_rounded,
                    ),
                    _Segment(
                      value: HiddenSessionPreset.balanced,
                      label: 'Balanced',
                      tooltip:
                          'Good background survival + gapless when visible',
                      icon: isFruit ? LucideIcons.scale : Icons.balance_rounded,
                    ),
                    _Segment(
                      value: HiddenSessionPreset.maxGapless,
                      label: 'Gapless',
                      tooltip: 'Best gapless playback - needs a strong browser',
                      icon: isFruit ? LucideIcons.zap : Icons.flash_on_rounded,
                    ),
                  ],
                  selectedValue: settingsProvider.hiddenSessionPreset,
                  onSelectionChanged: (HiddenSessionPreset preset) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    settingsProvider.setHiddenSessionPreset(preset);
                    showRestartMessage(
                      context,
                      'Preset applied. Relaunch required if engine changed.',
                    );
                  },
                ),
              ),
            ),
            if (resolvedMode == AudioEngineMode.hybrid) ...[
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                child: Text(
                  'Hybrid Handoff Mode',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _SegmentedWrap<HybridHandoffMode>(
                    isFruit: isFruit,
                    scaleFactor: scaleFactor,
                    segments: [
                      _Segment(
                        value: HybridHandoffMode.immediate,
                        label: 'Immediate',
                        tooltip: 'Swap as soon as loaded',
                        icon: isFruit
                            ? LucideIcons.zap
                            : Icons.flash_on_rounded,
                      ),
                      _Segment(
                        value: HybridHandoffMode.buffered,
                        label: 'Mid',
                        tooltip:
                            'Wait until HTML5 buffer is exhausted before swap',
                        icon: isFruit
                            ? LucideIcons.check
                            : Icons.download_done_rounded,
                      ),
                      _Segment(
                        value: HybridHandoffMode.boundary,
                        label: 'End',
                        tooltip: 'Swap at the next track boundary',
                        icon: isFruit
                            ? LucideIcons.skipForward
                            : Icons.skip_next_rounded,
                      ),
                      _Segment(
                        value: HybridHandoffMode.none,
                        label: 'Off',
                        tooltip: 'Stay on HTML5 (no Web Audio handoff)',
                        icon: isFruit ? LucideIcons.ban : Icons.block_rounded,
                      ),
                    ],
                    selectedValue: settingsProvider.hybridHandoffMode,
                    onSelectionChanged: (HybridHandoffMode mode) {
                      AppHaptics.lightImpact(context.read<DeviceService>());
                      settingsProvider.setHybridHandoffMode(mode);
                      showRestartMessage(
                        context,
                        'Handoff mode change requires relaunch.',
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                child: Text(
                  'Background Survival Strategy',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 14 * scaleFactor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _SegmentedWrap<HybridBackgroundMode>(
                    isFruit: isFruit,
                    scaleFactor: scaleFactor,
                    segments: [
                      _Segment(
                        value: HybridBackgroundMode.html5,
                        label: 'HTML5',
                        tooltip: 'Hand off to HTML5 for background',
                        icon: isFruit
                            ? LucideIcons.refreshCw
                            : Icons.refresh_rounded,
                      ),
                      _Segment(
                        value: HybridBackgroundMode.heartbeat,
                        label: 'HBeat',
                        tooltip: 'Silent Audio Clock (Web Audio)',
                        icon: isFruit
                            ? LucideIcons.heart
                            : Icons.favorite_rounded,
                      ),
                      _Segment(
                        value: HybridBackgroundMode.video,
                        label: 'Video',
                        tooltip: 'Silent Video Hack (Web Audio)',
                        icon: isFruit
                            ? LucideIcons.video
                            : Icons.videocam_rounded,
                      ),
                      _Segment(
                        value: HybridBackgroundMode.none,
                        label: 'Off',
                        tooltip: 'No survival tricks (May throttle)',
                        icon: isFruit
                            ? LucideIcons.power
                            : Icons.power_off_rounded,
                      ),
                    ],
                    selectedValue: settingsProvider.hybridBackgroundMode,
                    onSelectionChanged: (HybridBackgroundMode mode) {
                      AppHaptics.lightImpact(context.read<DeviceService>());
                      settingsProvider.setHybridBackgroundMode(mode);
                      showRestartMessage(
                        context,
                        'Survival strategy change requires relaunch.',
                      );
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      TvSwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        secondary: Icon(
          isFruit ? LucideIcons.monitor : Icons.sensor_window_rounded,
        ),
        title: Text(
          'Keep Screen On',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor),
        ),
        subtitle: Text(
          'Prevents the device from sleeping during playback.',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
        ),
        value: settingsProvider.preventSleep,
        onChanged: (_) {
          AppHaptics.lightImpact(context.read<DeviceService>());
          settingsProvider.togglePreventSleep();
        },
      ),
    ];
  }

  Widget _buildDevHudAbbreviationLegend(
    BuildContext context,
    double scaleFactor,
  ) {
    final theme = Theme.of(context);
    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontSize: 13 * scaleFactor,
      fontWeight: FontWeight.w700,
    );
    final bodyStyle = theme.textTheme.bodySmall?.copyWith(
      fontSize: 12 * scaleFactor,
      height: 1.35,
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        56 * scaleFactor,
        0,
        16 * scaleFactor,
        8 * scaleFactor,
      ),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: 12 * scaleFactor,
          vertical: 10 * scaleFactor,
        ),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(
            alpha: 0.35,
          ),
          borderRadius: BorderRadius.circular(12 * scaleFactor),
          border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('HUD Abbreviations', style: titleStyle),
            SizedBox(height: 6 * scaleFactor),
            Text(
              'ENG engine  -  DET profile  -  TX transition  -  HF handoff  -  BG background',
              style: bodyStyle,
            ),
            Text(
              'PF prefetch  -  PS processing  -  ST engine state',
              style: bodyStyle,
            ),
            Text(
              'POS position/duration  -  BUF buffered  -  HD headroom',
              style: bodyStyle,
            ),
            Text(
              'NX next buffered  -  IDX track index  -  SIG signal  -  E error',
              style: bodyStyle,
            ),
          ],
        ),
      ),
    );
  }
}

class _SegmentedWrap<T> extends StatelessWidget {
  final List<_Segment<T>> segments;
  final T selectedValue;
  final ValueChanged<T> onSelectionChanged;
  final double scaleFactor;
  final bool isFruit;

  const _SegmentedWrap({
    required this.segments,
    required this.selectedValue,
    required this.onSelectionChanged,
    required this.scaleFactor,
    required this.isFruit,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.outline.withValues(alpha: 0.35);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: dividerColor, width: 1),
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < segments.length; i++) ...[
              if (i > 0)
                VerticalDivider(width: 1, thickness: 1, color: dividerColor),
              Flexible(child: _buildSegment(context, theme, segments[i])),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSegment(
    BuildContext context,
    ThemeData theme,
    _Segment<T> segment,
  ) {
    final isSelected = segment.value == selectedValue;

    return Tooltip(
      message: segment.tooltip ?? '',
      child: Material(
        color: isSelected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: InkWell(
          onTap: () => onSelectionChanged(segment.value),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 10 * scaleFactor,
              vertical: 8 * scaleFactor,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (segment.icon != null) ...[
                  Icon(
                    segment.icon,
                    size: 15 * scaleFactor,
                    color: isSelected
                        ? theme.colorScheme.onPrimaryContainer
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(width: 4 * scaleFactor),
                ],
                Flexible(
                  child: Text(
                    segment.label,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontSize: 12 * scaleFactor,
                      color: isSelected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurfaceVariant,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Segment<T> {
  final T value;
  final String label;
  final IconData? icon;
  final String? tooltip;

  const _Segment({
    required this.value,
    required this.label,
    this.icon,
    this.tooltip,
  });
}
