part of 'playback_section.dart';

extension _PlaybackSectionBuild on PlaybackSection {
  Widget _buildPlaybackSection(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final isTv = context.read<DeviceService>().isTv;

    return SectionCard(
      key: ValueKey(
        'playback_${initiallyExpanded || isHighlightSettingMatching}',
      ),
      scaleFactor: scaleFactor,
      title: 'Playback',
      icon: Icons.play_circle_outline_rounded,
      lucideIcon: LucideIcons.playCircle,
      initiallyExpanded: initiallyExpanded,
      children: [
        if (kIsWeb) ...[
          ..._buildWebGaplessSection(
            context,
            settingsProvider,
            scaleFactor,
            isFruit,
          ),
          _buildHighlightableToggle(
            context,
            keyName: 'play_pause_fade',
            title: 'Play/Pause Fade Transition',
            subtitle: 'Quickly fades audio in and out to prevent pops (Web)',
            value: settingsProvider.usePlayPauseFade,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().togglePlayPauseFade();
            },
            secondary: Icon(isFruit ? LucideIcons.sliders : Icons.tune_rounded),
          ),
        ],
        _buildHighlightableToggle(
          context,
          keyName: 'play_on_tap',
          title: 'Play on Tap',
          subtitle: 'Tap track in inactive source to play',
          value: settingsProvider.playOnTap,
          onChanged: (value) {
            AppHaptics.lightImpact(context.read<DeviceService>());
            context.read<SettingsProvider>().togglePlayOnTap();
          },
          secondary: Icon(
            isFruit ? LucideIcons.pointer : Icons.touch_app_rounded,
          ),
        ),
        _buildHighlightableToggle(
          context,
          keyName: 'playback_messages',
          title: 'Show Playback Messages',
          subtitle: 'Display detailed status, buffered time, and errors',
          value: settingsProvider.showPlaybackMessages,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleShowPlaybackMessages();
          },
          secondary: Icon(
            isFruit ? LucideIcons.messageSquare : Icons.message_rounded,
          ),
        ),
        if (kIsWeb)
          TvSwitchListTile(
            dense: true,
            visualDensity: VisualDensity.compact,
            title: _buildTileTitle(context, 'Show Dev Audio HUD'),
            subtitle: _buildTileSubtitle(
              context,
              'Persistent engine + playback keychart (dev)',
            ),
            value: settingsProvider.showDevAudioHud,
            onChanged: (value) {
              context.read<SettingsProvider>().toggleShowDevAudioHud();
            },
            secondary: Icon(
              isFruit ? LucideIcons.badgeInfo : Icons.developer_mode,
            ),
          ),
        if (!isTv && !kIsWeb)
          _buildHighlightableToggle(
            context,
            keyName: 'offline_buffering',
            title: 'Advanced Cache',
            subtitleBuilder: (context) => Consumer<AudioProvider>(
              builder: (context, audioProvider, _) => _buildTileSubtitle(
                context,
                settingsProvider.offlineBuffering
                    ? 'Cached ${audioProvider.cachedTrackCount} of (${audioProvider.currentSource?.tracks.length ?? 0} + 5) tracks'
                    : 'Cache current show tracks to disk',
              ),
            ),
            value: settingsProvider.offlineBuffering,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleOfflineBuffering();
            },
            secondary: Icon(
              isFruit
                  ? LucideIcons.download
                  : Icons.download_for_offline_rounded,
            ),
          ),
        if (!kIsWeb)
          _buildHighlightableToggle(
            context,
            keyName: 'enable_buffer_agent',
            title: 'Buffer Agent',
            subtitle: 'Auto-fix network and buffer issues',
            value: settingsProvider.enableBufferAgent,
            onChanged: (value) {
              AppHaptics.lightImpact(context.read<DeviceService>());
              context.read<SettingsProvider>().toggleEnableBufferAgent();
            },
            secondary: Icon(
              isFruit ? LucideIcons.activity : Icons.healing_rounded,
            ),
          ),
        TvSwitchListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'Random',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 16 * scaleFactor,
                color: !settingsProvider.nonRandom
                    ? null
                    : Theme.of(
                        context,
                      ).colorScheme.onSurface.withValues(alpha: 0.5),
              ),
            ),
          ),
          value: !settingsProvider.nonRandom,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleNonRandom();
          },
          secondary: Icon(
            isFruit ? LucideIcons.shuffle : Icons.shuffle_rounded,
            color: !settingsProvider.nonRandom
                ? null
                : Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.5),
          ),
        ),
        _buildToggleTile(
          context,
          title: settingsProvider.nonRandom
              ? 'Play Next Show on Completion'
              : 'Play Random Show on Completion',
          subtitle: settingsProvider.nonRandom
              ? 'When a show ends, play the next show in the list'
              : 'When a show ends, play another one randomly',
          value: settingsProvider.playRandomOnCompletion,
          onChanged: (value) {
            context.read<SettingsProvider>().togglePlayRandomOnCompletion();
            if (!kIsWeb && value && !settingsProvider.offlineBuffering) {
              showMessage(context, 'Consider enabling Advanced Cache.');
            }
          },
          secondary: Icon(isFruit ? LucideIcons.repeat : Icons.repeat_rounded),
        ),
        _buildToggleTile(
          context,
          title: settingsProvider.nonRandom
              ? 'Play Next Show on Startup'
              : 'Play Random Show on Startup',
          subtitle: settingsProvider.nonRandom
              ? 'Start playing the next show when the app opens'
              : 'Start playing a random show when the app opens',
          value: settingsProvider.playRandomOnStartup,
          onChanged: (value) {
            context.read<SettingsProvider>().togglePlayRandomOnStartup();
          },
          secondary: Icon(isFruit ? LucideIcons.play : Icons.start_rounded),
        ),
        _buildToggleTile(
          context,
          title: 'Only Select Unplayed Shows',
          subtitle: 'Random playback will prefer unplayed shows',
          value: settingsProvider.randomOnlyUnplayed,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomOnlyUnplayed();
          },
          secondary: Icon(
            isFruit ? LucideIcons.star : Icons.new_releases_rounded,
          ),
        ),
        _buildToggleTile(
          context,
          title: 'Only Select High Rated Shows',
          subtitle: 'Random playback will prefer shows rated 2+ stars',
          value: settingsProvider.randomOnlyHighRated,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomOnlyHighRated();
          },
          secondary: Icon(isFruit ? LucideIcons.star : Icons.star_rate_rounded),
        ),
        _buildToggleTile(
          context,
          title: 'Exclude Already Played Shows',
          subtitle: 'Random playback will never select shows you have played',
          value: settingsProvider.randomExcludePlayed,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleRandomExcludePlayed();
          },
          secondary: Icon(
            isFruit ? LucideIcons.history : Icons.history_toggle_off_rounded,
          ),
        ),
        RandomProbabilityCard(scaleFactor: scaleFactor),
        _buildToggleTile(
          context,
          title: 'Mark Played on Start',
          subtitle: 'Mark a show as played when playback begins',
          value: settingsProvider.markPlayedOnStart,
          onChanged: (value) {
            context.read<SettingsProvider>().toggleMarkPlayedOnStart();
          },
          secondary: Icon(
            isFruit
                ? LucideIcons.checkCircle
                : Icons.check_circle_outline_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightableToggle(
    BuildContext context, {
    required String keyName,
    required String title,
    String? subtitle,
    Widget Function(BuildContext context)? subtitleBuilder,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget secondary,
  }) {
    return HighlightableSetting(
      key: ValueKey(
        '${keyName}_${highlightTriggerCount}_${activeHighlightKey == keyName}',
      ),
      startWithHighlight: activeHighlightKey == keyName,
      settingKey: settingKeys[keyName],
      child: TvSwitchListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        title: _buildTileTitle(context, title),
        subtitle: subtitleBuilder != null
            ? subtitleBuilder(context)
            : _buildTileSubtitle(context, subtitle ?? ''),
        value: value,
        onChanged: onChanged,
        secondary: secondary,
      ),
    );
  }

  Widget _buildToggleTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Widget secondary,
  }) {
    return TvSwitchListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: _buildTileTitle(context, title),
      subtitle: _buildTileSubtitle(context, subtitle),
      value: value,
      onChanged: onChanged,
      secondary: secondary,
    );
  }

  Widget _buildTileTitle(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontSize: 16 * scaleFactor),
      ),
    );
  }

  Widget _buildTileSubtitle(BuildContext context, String text) {
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(fontSize: 12 * scaleFactor),
      ),
    );
  }
}
