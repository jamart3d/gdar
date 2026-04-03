part of 'tv_screensaver_section.dart';

extension _TvScreensaverSectionSystemBuild on _TvScreensaverSectionState {
  List<Widget> _buildSystemSection({
    required BuildContext context,
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
  }) {
    return [
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: TvFocusWrapper(
                  onKeyEvent: (node, event) {
                    if (event is KeyDownEvent) {
                      final current = settings.oilScreensaverInactivityMinutes;
                      int? newValue;
                      if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                        if (current == 15) {
                          newValue = 5;
                        } else if (current == 5) {
                          newValue = 1;
                        }
                      } else if (event.logicalKey ==
                          LogicalKeyboardKey.arrowRight) {
                        if (current == 1) {
                          newValue = 5;
                        } else if (current == 5) {
                          newValue = 15;
                        }
                      }
                      if (newValue != null && newValue != current) {
                        settings.setOilScreensaverInactivityMinutes(newValue);
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
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 1, label: Text('1 min')),
                      ButtonSegment(value: 5, label: Text('5 min')),
                      ButtonSegment(value: 15, label: Text('15 min')),
                    ],
                    selected: {settings.oilScreensaverInactivityMinutes},
                    onSelectionChanged: (Set<int> selection) => settings
                        .setOilScreensaverInactivityMinutes(selection.first),
                    showSelectedIcon: false,
                  ),
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
            style: textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
          ),
          onTap: () async {
            final launchDelegate = context.read<ScreensaverLaunchDelegate?>();
            if (launchDelegate != null) {
              await launchDelegate.launch();
              return;
            }
            await ScreensaverScreen.show(context);
          },
        ),
        const SizedBox(height: 32),
      ],
    ];
  }
}
