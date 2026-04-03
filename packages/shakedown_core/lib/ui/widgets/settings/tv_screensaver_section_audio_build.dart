part of 'tv_screensaver_section.dart';

extension _TvScreensaverSectionAudioBuild on _TvScreensaverSectionState {
  List<Widget> _buildAudioReactivitySection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
  }) {
    return [
      _SectionHeader(title: 'Audio Reactivity', colorScheme: colorScheme),
      const SizedBox(height: 8),
      _ToggleRow(
        label: 'Enable Audio Reactivity',
        subtitle:
            'Sync visuals to the music being played (requires audio permission)',
        value: settings.oilEnableAudioReactivity,
        onChanged: (_) => _handleAudioReactivityToggle(settings),
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
        const SizedBox(height: 16),
        _buildBeatDetectorSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
          isFruit: isFruit,
        ),
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
        _buildAudioGraphSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
      const SizedBox(height: 24),
    ];
  }

  List<Widget> _buildFrequencyIsolationSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
  }) {
    return [
      _SectionHeader(title: 'Frequency Isolation', colorScheme: colorScheme),
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
          onSelect: (value) => settings.setOilScaleSource(value),
          colorScheme: colorScheme,
        ),
      ),
      const SizedBox(height: 8),
      _ReactiveHint(
        message:
            'Default follows the usual logo motion driver. None disables '
            'audio-driven logo scaling so only the base size and beat bump '
            'remain.',
        colorScheme: colorScheme,
        textTheme: textTheme,
        isFruit: isFruit,
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
          onSelect: (value) => settings.setOilColorSource(value),
          colorScheme: colorScheme,
        ),
      ),
      const SizedBox(height: 8),
      _ReactiveHint(
        message:
            'Default uses the normal color-reactive driver. None disables '
            'audio color pulsing and leaves the palette steady.',
        colorScheme: colorScheme,
        textTheme: textTheme,
        isFruit: isFruit,
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
    ];
  }

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
          const SizedBox(height: 16),

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
          if (settings.oilAudioGraphMode != 'off') ...[
            const SizedBox(height: 16),
            _ToggleRow(
              label: 'Preview: Audio Graph',
              subtitle: 'Show scaled audio graph in preview instead of logo',
              value: settings.oilPreviewShowGraph,
              onChanged: (_) => settings.toggleOilPreviewShowGraph(),
              colorScheme: colorScheme,
              textTheme: textTheme,
            ),
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
