import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/services/gapless_player/gapless_player.dart';
import 'package:shakedown/ui/widgets/section_card.dart';
import 'package:shakedown/ui/widgets/settings/highlightable_setting.dart';
import 'package:shakedown/ui/widgets/settings/random_probability_card.dart';
import 'package:shakedown/ui/widgets/tv/tv_switch_list_tile.dart';

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
    final audioProvider = context.watch<AudioProvider>();

    return SectionCard(
      key: ValueKey(
          'playback_${initiallyExpanded || isHighlightSettingMatching}'),
      scaleFactor: scaleFactor,
      title: 'Playback',
      icon: Icons.play_circle_outline_rounded,
      initiallyExpanded: initiallyExpanded,
      children: [
        if (kIsWeb)
          ..._buildWebGaplessSection(context, settingsProvider, scaleFactor),
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
              HapticFeedback.lightImpact();
              context.read<SettingsProvider>().togglePlayOnTap();
            },
            secondary: const Icon(Icons.touch_app_rounded),
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
            secondary: const Icon(Icons.message_rounded),
          ),
        ),
        if (!context.read<DeviceService>().isTv && !kIsWeb)
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
              subtitle: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    settingsProvider.offlineBuffering
                        ? 'Cached ${audioProvider.cachedTrackCount} of (${audioProvider.currentSource?.tracks.length ?? 0} + 5) tracks'
                        : 'Cache current show tracks to disk',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(fontSize: 12 * scaleFactor),
                  )),
              value: settingsProvider.offlineBuffering,
              onChanged: (value) {
                HapticFeedback.lightImpact();
                context.read<SettingsProvider>().toggleOfflineBuffering();
              },
              secondary: const Icon(Icons.download_for_offline_rounded),
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
                HapticFeedback.lightImpact();
                context.read<SettingsProvider>().toggleEnableBufferAgent();
              },
              secondary: const Icon(Icons.healing_rounded),
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
            Icons.shuffle_rounded,
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
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  margin: EdgeInsets.only(
                    bottom: MediaQuery.of(context).size.height * 0.45,
                    left: 16,
                    right: 16,
                  ),
                  content: const Text('Consider enabling Advanced Cache.'),
                  action: SnackBarAction(
                    label: 'GO',
                    onPressed: () => onScrollToSetting('offline_buffering'),
                  ),
                  duration: const Duration(seconds: 4),
                ),
              );
            }
          },
          secondary: const Icon(Icons.repeat_rounded),
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
          secondary: const Icon(Icons.start_rounded),
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
          secondary: const Icon(Icons.new_releases_rounded),
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
          secondary: const Icon(Icons.star_rate_rounded),
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
          secondary: const Icon(Icons.history_toggle_off_rounded),
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
  ) {
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
                  Icons.settings_input_component_rounded,
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
            const SizedBox(height: 16),
            Padding(
              padding: EdgeInsets.only(left: 40.0 * scaleFactor),
              child: Align(
                alignment: Alignment.centerLeft,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SegmentedButton<AudioEngineMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                        value: AudioEngineMode.webAudio,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Web Audio',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ),
                        tooltip: '0ms gapless (High Performance)',
                        icon: const Icon(Icons.graphic_eq_rounded),
                      ),
                      ButtonSegment(
                        value: AudioEngineMode.html5,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Relisten',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ),
                        tooltip: 'Gapless HTML5 (Safe Background)',
                        icon: const Icon(Icons.smartphone_rounded),
                      ),
                      ButtonSegment(
                        value: AudioEngineMode.standard,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Standard',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ),
                        tooltip: 'Native just_audio (Conservative)',
                        icon:
                            const Icon(Icons.settings_input_component_rounded),
                      ),
                      ButtonSegment(
                        value: AudioEngineMode.passive,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Passive',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ),
                        tooltip: 'Minimal HTML5 (Single element streaming)',
                        icon: const Icon(Icons.battery_saver_rounded),
                      ),
                      ButtonSegment(
                        value: AudioEngineMode.hybrid,
                        label: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            'Hybrid',
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                            style: TextStyle(fontSize: 14 * scaleFactor),
                          ),
                        ),
                        tooltip: 'Web Audio Foreground, Relisten Background',
                        icon: const Icon(Icons.handshake_rounded),
                      ),
                    ],
                    selected: {
                      sp.audioEngineMode == AudioEngineMode.auto
                          ? context.read<AudioProvider>().audioPlayer.activeMode
                          : sp.audioEngineMode
                    },
                    onSelectionChanged: (Set<AudioEngineMode> selection) {
                      HapticFeedback.lightImpact();
                      final mode = selection.first;
                      sp.setAudioEngineMode(mode);
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          behavior: SnackBarBehavior.floating,
                          content: const Text(
                              'Relaunch required for engine change to take effect.'),
                          action: SnackBarAction(
                            label: 'RELOAD',
                            onPressed: () {
                              context
                                  .read<AudioProvider>()
                                  .audioPlayer
                                  .reload();
                            },
                          ),
                          duration: const Duration(seconds: 8),
                        ),
                      );
                    },
                  ),
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
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SegmentedButton<String>(
                      showSelectedIcon: false,
                      segments: [
                        ButtonSegment(
                          value: 'gap',
                          label: Text('Gap',
                              style: TextStyle(fontSize: 12 * scaleFactor)),
                          icon: const Icon(Icons.pause_presentation_rounded,
                              size: 16),
                        ),
                        ButtonSegment(
                          value: 'gapless',
                          label: Text('Gapless',
                              style: TextStyle(fontSize: 12 * scaleFactor)),
                          icon:
                              const Icon(Icons.linear_scale_rounded, size: 16),
                        ),
                        ButtonSegment(
                          value: 'crossfade',
                          label: Text('Crossfade',
                              style: TextStyle(fontSize: 12 * scaleFactor)),
                          icon: const Icon(Icons.multiline_chart_rounded,
                              size: 16),
                        ),
                      ],
                      selected: {sp.trackTransitionMode},
                      onSelectionChanged: (Set<String> selection) {
                        HapticFeedback.lightImpact();
                        sp.setTrackTransitionMode(selection.first);
                      },
                    ),
                  ),
                ),
              ),
              if (sp.trackTransitionMode == 'crossfade') ...[
                const SizedBox(height: 16),
                Padding(
                  padding: EdgeInsets.only(
                      left: 40.0 * scaleFactor, right: 16.0 * scaleFactor),
                  child: Row(
                    children: [
                      Text(
                        'Crossfade Duration',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontSize: 14 * scaleFactor,
                            ),
                      ),
                      Expanded(
                        child: Slider(
                          value: sp.crossfadeDurationSeconds,
                          min: 1.0,
                          max: 12.0,
                          divisions: 11,
                          label: '${sp.crossfadeDurationSeconds.toInt()}s',
                          onChanged: (value) {
                            sp.setCrossfadeDurationSeconds(value);
                          },
                        ),
                      ),
                      Text(
                        '${sp.crossfadeDurationSeconds.toInt()}s',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 14 * scaleFactor,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<HybridHandoffMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: HybridHandoffMode.immediate,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Immediate',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'Swap as soon as loaded',
                            icon: const Icon(Icons.flash_on_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: HybridHandoffMode.buffered,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('End of Buffer',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip:
                                'Wait until HTML5 buffer is exhausted before swap',
                            icon: const Icon(Icons.download_done_rounded,
                                size: 16),
                          ),
                          ButtonSegment(
                            value: HybridHandoffMode.none,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Disabled',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'Stay on Web Audio (Gapless) always',
                            icon: const Icon(Icons.block_rounded, size: 16),
                          ),
                        ],
                        selected: {sp.hybridHandoffMode},
                        onSelectionChanged: (Set<HybridHandoffMode> selection) {
                          HapticFeedback.lightImpact();
                          sp.setHybridHandoffMode(selection.first);
                        },
                      ),
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
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SegmentedButton<HybridBackgroundMode>(
                        showSelectedIcon: false,
                        segments: [
                          ButtonSegment(
                            value: HybridBackgroundMode.relisten,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Relisten',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'Hand off to HTML5 for background',
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: HybridBackgroundMode.heartbeat,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Heartbeat',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'Silent Audio Clock (Web Audio)',
                            icon: const Icon(Icons.favorite_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: HybridBackgroundMode.video,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('Video Trick',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'Silent Video Hack (Web Audio)',
                            icon: const Icon(Icons.videocam_rounded, size: 16),
                          ),
                          ButtonSegment(
                            value: HybridBackgroundMode.none,
                            label: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text('None',
                                  style: TextStyle(fontSize: 12 * scaleFactor)),
                            ),
                            tooltip: 'No survival tricks (May throttle)',
                            icon: const Icon(Icons.power_off_rounded, size: 16),
                          ),
                        ],
                        selected: {sp.hybridBackgroundMode},
                        onSelectionChanged:
                            (Set<HybridBackgroundMode> selection) {
                          HapticFeedback.lightImpact();
                          sp.setHybridBackgroundMode(selection.first);
                        },
                      ),
                    ),
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
        secondary: const Icon(Icons.sensor_window_rounded),
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
          HapticFeedback.lightImpact();
          sp.togglePreventSleep();
        },
      ),
    ];
  }
}
