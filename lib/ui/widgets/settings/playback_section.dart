import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/device_service.dart';
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
        if (!context.read<DeviceService>().isTv)
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
                            ? null // Use default active color
                            : Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.5), // Dimmed when OFF
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
              child: Text('When a show ends, play another one randomly',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontSize: 12 * scaleFactor))),
          value: settingsProvider.playRandomOnCompletion,
          onChanged: (value) {
            context.read<SettingsProvider>().togglePlayRandomOnCompletion();

            // Suggest Advanced Cache if enabling and it's currently OFF
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
                    onPressed: () {
                      onScrollToSetting('offline_buffering');
                    },
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
}
