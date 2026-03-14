import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/services/gapless_player/gapless_player.dart';
import 'package:gdar_fruit/ui/widgets/section_card.dart';
import 'package:gdar_fruit/ui/widgets/settings/highlightable_setting.dart';
import 'package:gdar_fruit/ui/widgets/settings/random_probability_card.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_switch_list_tile.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/utils/utils.dart';

class PlaybackSection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;
  final String? activeHighlightKey;
  final int highlightTriggerCount;
  final Map<String, GlobalKey> settingKeys;
  final Function(String) onScrollToSetting;
  final bool isHighlightSettingMatching;

  const PlaybackSection({
    super.key,
    required this.scaleFactor,
    required this.initiallyExpanded,
    required this.activeHighlightKey,
    required this.highlightTriggerCount,
    required this.settingKeys,
    required this.onScrollToSetting,
    required this.isHighlightSettingMatching,
  });

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.read<DeviceService>().isTv;

    return SectionCard(
      key: ValueKey(
          'playback_${initiallyExpanded || isHighlightSettingMatching}'),
      scaleFactor: scaleFactor,
      title: 'Playback',
      icon: Icons.play_circle_outline_rounded,
      lucideIcon: LucideIcons.playCircle,
      initiallyExpanded: initiallyExpanded,
      children: [
        if (kIsWeb)
          ..._buildWebGaplessSection(
              context, settingsProvider, scaleFactor, isFruit),
        // Screensaver settings moved to Screensaver section for Google TV

        HighlightableSetting(
          key: ValueKey(
              'play_on_tap_${highlightTriggerCount}_${activeHighlightKey == 'play_on_tap'}'),
          startWithHighlight: activeHighlightKey == 'play_on_tap',
          settingKey: settingKeys['play_on_tap'],
          child: TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Play on Tap',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Tap track in inactive source to play',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor))),
            value: settingsProvider.playOnTap,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().togglePlayOnTap();
            },
            secondary:
                Icon(isFruit ? LucideIcons.pointer : Icons.touch_app_rounded),
          ),
        ),
        HighlightableSetting(
          key: ValueKey(
              'playback_messages_${highlightTriggerCount}_${activeHighlightKey == 'playback_messages'}'),
          startWithHighlight: activeHighlightKey == 'playback_messages',
          settingKey: settingKeys['playback_messages'],
          child: TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Show Playback Messages',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                    'Display detailed status, buffered time, and errors',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor))),
            value: settingsProvider.showPlaybackMessages,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowPlaybackMessages();
            },
            secondary: Icon(
                isFruit ? LucideIcons.messageSquare : Icons.message_rounded),
          ),
        ),
        if (kIsWeb)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Show Dev Audio HUD',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontSize: 16 * scaleFactor))),
            subtitle: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text('Persistent engine + playback keychart (dev)',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor))),
            value: settingsProvider.showDevAudioHud,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowDevAudioHud();
            },
            secondary:
                Icon(isFruit ? LucideIcons.badgeInfo : Icons.developer_mode),
          ),
        if (kIsWeb && settingsProvider.showDevAudioHud)
          _buildDevHudAbbreviationLegend(context, scaleFactor),
        if (!isTv && !kIsWeb)
          HighlightableSetting(
            key: ValueKey(
                'offline_buffering_${highlightTriggerCount}_${activeHighlightKey == 'offline_buffering'}'),
            startWithHighlight: activeHighlightKey == 'offline_buffering',
            settingKey: settingKeys['offline_buffering'],
            child: TvSwitchListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Advanced Cache',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 16 * scaleFactor))),
              subtitle: Consumer<AudioProvider>(
                builder: (context, ap, _) => FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      settingsProvider.offlineBuffering
                          ? 'Cached ${ap.cachedTrackCount} of (${ap.currentSource?.tracks.length ?? 0} + 5) tracks'
                          : 'Cache current show tracks to disk',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(fontSize: 12 * scaleFactor),
                    )),
              ),
              value: settingsProvider.offlineBuffering,
              onChanged: (value) {
                AppHaptics.lightImpact(context.read<DeviceService>());
                context.read<SettingsProvider>().toggleOfflineBuffering();
              },
              secondary: Icon(isFruit
                  ? LucideIcons.download
                  : Icons.download_for_offline_rounded),
            ),
          ),
        if (!kIsWeb)
          HighlightableSetting(
            key: ValueKey(
                'enable_buffer_agent_${highlightTriggerCount}_${activeHighlightKey == 'enable_buffer_agent'}'),
            startWithHighlight: activeHighlightKey == 'enable_buffer_agent',
            settingKey: settingKeys['enable_buffer_agent'],
            child: TvSwitchListTile(
              dense: true,
              visualDensity: VisualDensity.compact,
              title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text('Buffer Agent',
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 16 * scaleFactor))),
              subtitle: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Auto-fix network and buffer issues',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor),
                  )),
              value: settingsProvider.enableBufferAgent,
              onChanged: (value) {
                AppHaptics.lightImpact(context.read<DeviceService>());
                context.read<SettingsProvider>().toggleEnableBufferAgent();
              },
              secondary:
                  Icon(isFruit ? LucideIcons.activity : Icons.healing_rounded),
            ),
          ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Random',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontSize: 16 * scaleFactor,
                        color: !settingsProvider.nonRandom
                            ? null
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5),
                      ))),
          value: !settingsProvider.nonRandom,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleNonRandom();
          },
          secondary: Icon(
            isFruit ? LucideIcons.shuffle : Icons.shuffle_rounded,
            color: !settingsProvider.nonRandom
                ? null
                : Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.5),
          ),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  settingsProvider.nonRandom
                      ? 'Play Next Show on Completion'
                      : 'Play Random Show on Completion',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                settingsProvider.nonRandom
                    ? 'When a show ends, play the next show in the list'
                    : 'When a show ends, play another one randomly',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(fontSize: 12 * scaleFactor),
              )),
          value: settingsProvider.playRandomOnCompletion,
          onChanged: (value) {
            context.read<SettingsProvider>().togglePlayRandomOnCompletion();
            if (value && !settingsProvider.offlineBuffering) {
              showMessage(context, 'Consider enabling Advanced Cache.');
            }
          },
          secondary: Icon(isFruit ? LucideIcons.repeat : Icons.repeat_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  settingsProvider.nonRandom
                      ? 'Play Next Show on Startup'
                      : 'Play Random Show on Startup',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  settingsProvider.nonRandom
                      ? 'Start playing the next show when the app opens'
                      : 'Start playing a random show when the app opens',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.playRandomOnStartup,
          onChanged: (value) {
            context.read<SettingsProvider>().togglePlayRandomOnStartup();
          },
          secondary: Icon(isFruit ? LucideIcons.play : Icons.start_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Only Select Unplayed Shows',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Random playback will prefer unplayed shows',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.randomOnlyUnplayed,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomOnlyUnplayed();
          },
          secondary:
              Icon(isFruit ? LucideIcons.star : Icons.new_releases_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Only Select High Rated Shows',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Random playback will prefer shows rated 2+ stars',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.randomOnlyHighRated,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomOnlyHighRated();
          },
          secondary: Icon(isFruit ? LucideIcons.star : Icons.star_rate_rounded),
        ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text('Exclude Already Played Shows',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontSize: 16 * scaleFactor))),
          subtitle: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                  'Random playback will never select shows you have played',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.randomExcludePlayed,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomExcludePlayed();
          },
          secondary: Icon(
              isFruit ? LucideIcons.history : Icons.history_toggle_off_rounded),
        ),
        RandomProbabilityCard(scaleFactor: scaleFactor),
      ],
    );
  }

  /// Builds the web-only gapless engine settings block.
  ///
  /// Uses a mobile heuristic (userAgent + touch) to mirror the JS hybrid_init.js
  /// detection and show the appropriate label. Returns a list of widgets:
  /// the engine toggle and (when enabled) a prefetch-ahead slider.
  /// These are only ever inserted when [kIsWeb] is true.
  static List<Widget> _buildWebGaplessSection(
    BuildContext context,
    SettingsProvider sp,
    double scaleFactor,
    bool isFruit,
  ) {
    final audioProvider = context.watch<AudioProvider>();
    return [
      Padding(
        padding: EdgeInsets.only(
          left: 16.0 * scaleFactor, // Align with leading icon of other tiles
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
              padding: EdgeInsets.only(
                  left: 40.0 * scaleFactor), // Align with text below title
              child: Text(
                'Select the low-level processing engine for gapless playback.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12 * scaleFactor,
                    ),
              ),
            ),
            const SizedBox(height: 6),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Text(
                'Engine changes apply after relaunch (or browser refresh).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 12 * scaleFactor,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withAlpha(160),
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
                      value: AudioEngineMode.standard,
                      label: 'Standard',
                      tooltip: 'Native just_audio (Conservative)',
                      icon: isFruit
                          ? LucideIcons.settings
                          : Icons.settings_input_component_rounded,
                    ),
                    _Segment(
                      value: AudioEngineMode.passive,
                      label: 'Passive',
                      tooltip: 'Minimal HTML5 (Single element streaming)',
                      icon: isFruit
                          ? LucideIcons.battery
                          : Icons.battery_saver_rounded,
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
                  selectedValue: sp.audioEngineMode == AudioEngineMode.auto
                      ? context.read<AudioProvider>().audioPlayer.activeMode
                      : sp.audioEngineMode,
                  onSelectionChanged: (AudioEngineMode mode) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    sp.setAudioEngineMode(mode);
                    showRestartMessage(context,
                        'Relaunch required for engine change to take effect.');
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
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.08),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Active Engine: ${audioProvider.audioPlayer.engineName}',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12 * scaleFactor,
                                  ),
                        ),
                        SizedBox(height: 4 * scaleFactor),
                        Text(
                          'Context: $contextState',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontSize: 12 * scaleFactor,
                                  ),
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
                'Hidden Session Preset',
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
                      label: 'Stability',
                      tooltip: 'Hybrid + buffered + video survival',
                      icon: isFruit ? LucideIcons.shield : Icons.shield_rounded,
                    ),
                    _Segment(
                      value: HiddenSessionPreset.balanced,
                      label: 'Balanced',
                      tooltip: 'Hybrid + buffered + heartbeat survival',
                      icon: isFruit ? LucideIcons.scale : Icons.balance_rounded,
                    ),
                    _Segment(
                      value: HiddenSessionPreset.maxGapless,
                      label: 'Max Gapless',
                      tooltip: 'Web Audio first, best continuity when alive',
                      icon: isFruit ? LucideIcons.zap : Icons.flash_on_rounded,
                    ),
                  ],
                  selectedValue: sp.hiddenSessionPreset,
                  onSelectionChanged: (HiddenSessionPreset preset) {
                    AppHaptics.lightImpact(context.read<DeviceService>());
                    sp.setHiddenSessionPreset(preset);
                    showRestartMessage(
                      context,
                      'Preset applied. Relaunch required if engine changed.',
                    );
                  },
                ),
              ),
            ),
            if (sp.audioEngineMode == AudioEngineMode.hybrid ||
                sp.audioEngineMode == AudioEngineMode.webAudio ||
                sp.audioEngineMode == AudioEngineMode.auto ||
                sp.audioEngineMode == AudioEngineMode.standard) ...[
              const SizedBox(height: 16),
              Padding(
                padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                child: Text(
                  'Track Transition Mode',
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
                  child: _SegmentedWrap<String>(
                    isFruit: isFruit,
                    scaleFactor: scaleFactor,
                    segments: [
                      _Segment(
                        value: 'gap',
                        label: 'Gap',
                        icon: isFruit
                            ? LucideIcons.pause
                            : Icons.pause_presentation_rounded,
                      ),
                      _Segment(
                        value: 'gapless',
                        label: 'Gapless',
                        icon: isFruit
                            ? LucideIcons.list
                            : Icons.linear_scale_rounded,
                      ),
                    ],
                    selectedValue: sp.trackTransitionMode,
                    onSelectionChanged: (String mode) {
                      AppHaptics.lightImpact(context.read<DeviceService>());
                      sp.setTrackTransitionMode(mode);
                    },
                  ),
                ),
              ),
              if (sp.audioEngineMode == AudioEngineMode.hybrid) ...[
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
                          label: 'End of Buffer',
                          tooltip:
                              'Wait until HTML5 buffer is exhausted before swap',
                          icon: isFruit
                              ? LucideIcons.check
                              : Icons.download_done_rounded,
                        ),
                        _Segment(
                          value: HybridHandoffMode.none,
                          label: 'Disabled',
                          tooltip: 'Stay on Web Audio (Gapless) always',
                          icon: isFruit ? LucideIcons.ban : Icons.block_rounded,
                        ),
                      ],
                      selectedValue: sp.hybridHandoffMode,
                      onSelectionChanged: (HybridHandoffMode mode) {
                        AppHaptics.lightImpact(context.read<DeviceService>());
                        sp.setHybridHandoffMode(mode);
                        showRestartMessage(
                            context, 'Handoff mode change requires relaunch.');
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
                          label: 'Heartbeat',
                          tooltip: 'Silent Audio Clock (Web Audio)',
                          icon: isFruit
                              ? LucideIcons.heart
                              : Icons.favorite_rounded,
                        ),
                        _Segment(
                          value: HybridBackgroundMode.video,
                          label: 'Video Trick',
                          tooltip: 'Silent Video Hack (Web Audio)',
                          icon: isFruit
                              ? LucideIcons.video
                              : Icons.videocam_rounded,
                        ),
                        _Segment(
                          value: HybridBackgroundMode.none,
                          label: 'None',
                          tooltip: 'No survival tricks (May throttle)',
                          icon: isFruit
                              ? LucideIcons.power
                              : Icons.power_off_rounded,
                        ),
                      ],
                      selectedValue: sp.hybridBackgroundMode,
                      onSelectionChanged: (HybridBackgroundMode mode) {
                        AppHaptics.lightImpact(context.read<DeviceService>());
                        sp.setHybridBackgroundMode(mode);
                        showRestartMessage(context,
                            'Survival strategy change requires relaunch.');
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Allow Web Audio while hidden',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13 * scaleFactor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      'Keeps Web Audio active in background. '
                      'May stop sooner on mobile.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12 * scaleFactor,
                          ),
                    ),
                    value: sp.allowHiddenWebAudio,
                    onChanged: (value) {
                      AppHaptics.lightImpact(context.read<DeviceService>());
                      sp.setAllowHiddenWebAudio(value);
                      showRestartMessage(context,
                          'Relaunch required to apply hidden session logic.');
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                  child: SwitchListTile.adaptive(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'Force HTML5 start',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13 * scaleFactor,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Text(
                      'Always start via HTML5 before handing off.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12 * scaleFactor,
                          ),
                    ),
                    value: sp.hybridForceHtml5Start,
                    onChanged: (value) {
                      AppHaptics.lightImpact(context.read<DeviceService>());
                      sp.setHybridForceHtml5Start(value);
                      showRestartMessage(context,
                          'Relaunch required to apply boot logic changes.');
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: EdgeInsets.only(left: 40.0 * scaleFactor),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Handoff Crossfade',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 13 * scaleFactor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Slider(
                              min: 0,
                              max: 200,
                              divisions: 20,
                              value: sp.handoffCrossfadeMs.toDouble(),
                              onChanged: (value) {
                                sp.setHandoffCrossfadeMs(value.round());
                              },
                            ),
                          ),
                          SizedBox(width: 8 * scaleFactor),
                          Text(
                            '${sp.handoffCrossfadeMs}ms',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(fontSize: 12 * scaleFactor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      TvSwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        secondary:
            Icon(isFruit ? LucideIcons.monitor : Icons.sensor_window_rounded),
        title: Text(
          'Keep Screen On',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontSize: 16 * scaleFactor),
        ),
        subtitle: Text(
          'Prevents the device from sleeping during playback.',
          style: Theme.of(context)
              .textTheme
              .bodySmall
              ?.copyWith(fontSize: 12 * scaleFactor),
        ),
        value: sp.preventSleep,
        onChanged: (_) {
          AppHaptics.lightImpact(context.read<DeviceService>());
          sp.togglePreventSleep();
        },
      ),
    ];
  }

  static Widget _buildDevHudAbbreviationLegend(
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
          color:
              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
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
              'ENG engine  •  TX transition  •  HF handoff  •  BG background',
              style: bodyStyle,
            ),
            Text(
              'PF prefetch  •  PS processing  •  ST engine state',
              style: bodyStyle,
            ),
            Text(
              'POS position/duration  •  BUF buffered  •  HD headroom',
              style: bodyStyle,
            ),
            Text(
              'NX next buffered  •  IDX track index  •  SIG signal  •  E error',
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
    return Wrap(
      spacing: 8.0 * scaleFactor,
      runSpacing: 8.0 * scaleFactor,
      children: segments.map((segment) {
        final isSelected = segment.value == selectedValue;
        final theme = Theme.of(context);

        return Tooltip(
          message: segment.tooltip ?? '',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => onSelectionChanged(segment.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(
                  horizontal: 16 * scaleFactor,
                  vertical: 8 * scaleFactor,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (segment.icon != null) ...[
                      Icon(
                        segment.icon,
                        size: 16 * scaleFactor,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(width: 8 * scaleFactor),
                    ],
                    Text(
                      segment.label,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontSize: 13 * scaleFactor,
                        color: isSelected
                            ? theme.colorScheme.onPrimaryContainer
                            : theme.colorScheme.onSurfaceVariant,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
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
