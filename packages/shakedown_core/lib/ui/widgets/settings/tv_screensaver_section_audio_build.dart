part of 'tv_screensaver_section.dart';

extension _TvScreensaverSectionAudioBuild on _TvScreensaverSectionState {
  List<Widget> _buildPerformanceSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return [
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
              onSelect: (level) => settings.setOilPerformanceLevel(level),
              colorScheme: colorScheme,
            ),
            const SizedBox(height: 4),
            Text(
              _performanceDescription(settings.oilPerformanceLevel),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
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
            'Smooth the logo edge using sub-pixel precision. May impact '
            'performance.',
        value: settings.oilLogoAntiAlias,
        onChanged: (_) => settings.toggleOilLogoAntiAlias(),
        colorScheme: colorScheme,
        textTheme: textTheme,
      ),
      const SizedBox(height: 32),
    ];
  }

  Widget _buildBeatDetectorSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Beat Detector',
            style: textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: _BeatDetectorSegmentedButton(
              selected: settings.oilBeatDetectorMode,
              onSelect: (mode) =>
                  _handleBeatDetectorModeSelected(settings, mode),
            ),
          ),
          const SizedBox(height: 8),
          _ReactiveHint(
            message:
                _TvScreensaverSectionState._beatDetectorDescriptions[settings
                    .oilBeatDetectorMode] ??
                'Chooses what kind of hit fires the pulse. This stays reactive '
                    'only and does not BPM-lock the screensaver.',
            colorScheme: colorScheme,
            textTheme: textTheme,
            isFruit: isFruit,
          ),
          const SizedBox(height: 8),
          _ReactiveHint(
            message:
                'This stays reactive only and does not BPM-lock the screensaver.',
            colorScheme: colorScheme,
            textTheme: textTheme,
            isFruit: isFruit,
          ),
          if (settings.oilBeatDetectorMode == 'pcm') ...[
            const SizedBox(height: 8),
            _ReactiveHint(
              message:
                  'Enhanced Audio Capture uses Android system audio capture and '
                  'may show a share-audio permission prompt the first time it '
                  'starts in an app session.',
              colorScheme: colorScheme,
              textTheme: textTheme,
              isFruit: isFruit,
            ),
          ] else if (settings.oilBeatDetectorMode == 'auto') ...[
            const SizedBox(height: 8),
            _ReactiveHint(
              message:
                  'Auto will not start Android capture by itself. Choose '
                  'Enhanced if you want to explicitly turn PCM capture on.',
              colorScheme: colorScheme,
              textTheme: textTheme,
              isFruit: isFruit,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAudioGraphSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    const modes = [
      'off',
      'corner',
      'corner_only',
      'circular',
      'ekg',
      'circular_ekg',
      'vu',
      'scope',
      'beat_debug',
    ];

    return Padding(
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TvFocusWrapper(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  final idx = modes.indexOf(settings.oilAudioGraphMode);
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft &&
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
                  ButtonSegment(value: 'corner', label: Text('Corner')),
                  ButtonSegment(
                    value: 'corner_only',
                    label: Text('Corner Only'),
                  ),
                  ButtonSegment(value: 'circular', label: Text('Circular')),
                  ButtonSegment(value: 'ekg', label: Text('EKG')),
                  ButtonSegment(value: 'circular_ekg', label: Text('Circ EKG')),
                  ButtonSegment(value: 'vu', label: Text('VU')),
                  ButtonSegment(value: 'scope', label: Text('Scope')),
                  ButtonSegment(value: 'beat_debug', label: Text('Beat Debug')),
                ],
                selected: {settings.oilAudioGraphMode},
                onSelectionChanged: (Set<String> selection) =>
                    settings.setOilAudioGraphMode(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          if (settings.oilAudioGraphMode == 'circular' ||
              settings.oilAudioGraphMode == 'ekg' ||
              settings.oilAudioGraphMode == 'circular_ekg') ...[
            const SizedBox(height: 16),
            if (settings.oilAudioGraphMode == 'circular' ||
                settings.oilAudioGraphMode == 'circular_ekg') ...[
              TvStepperRow(
                label: 'Radius',
                value: settings.oilEkgRadius,
                min: 0.1,
                max: 2.0,
                step: 0.1,
                valueFormatter: (v) => v.toStringAsFixed(1),
                onChanged: (v) => settings.setOilEkgRadius(v),
              ),
              const SizedBox(height: 16),
            ],
            if (settings.oilAudioGraphMode != 'circular') ...[
              TvStepperRow(
                label: 'Line Replication',
                value: settings.oilEkgReplication.toDouble(),
                min: 1,
                max: 10,
                step: 1,
                valueFormatter: (v) => v.round().toString(),
                onChanged: (v) => settings.setOilEkgReplication(v.round()),
              ),
              const SizedBox(height: 16),
              TvStepperRow(
                label: 'Line Spread',
                value: settings.oilEkgSpread,
                min: 0.0,
                max: 20.0,
                step: 0.5,
                valueFormatter: (v) => v.toStringAsFixed(1),
                onChanged: (v) => settings.setOilEkgSpread(v),
              ),
            ],
          ],
        ],
      ),
    );
  }

  String _performanceDescription(int level) {
    switch (level) {
      case 0:
        return 'High (Spectral chromatic aberration + ghost blur)';
      case 1:
        return 'Balanced (Standard box blur, smooth movement)';
      default:
        return 'Fast (Sharp edges, 1-sample minimal GPU load)';
    }
  }
}
