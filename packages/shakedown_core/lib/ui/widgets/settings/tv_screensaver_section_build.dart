part of 'tv_screensaver_section.dart';

extension _TvScreensaverSectionBuild on _TvScreensaverSectionState {
  List<Widget> _buildSectionChildren({
    required BuildContext context,
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
    required bool isRingMode,
    required bool autoSpacing,
  }) {
    return [
      const SizedBox(height: 16),
      ..._buildSystemSection(
        context: context,
        settings: settings,
        colorScheme: colorScheme,
        textTheme: textTheme,
        isFruit: isFruit,
      ),
      if (settings.useOilScreensaver) ...[
        ..._buildVisualSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
          isFruit: isFruit,
        ),
        ..._buildTrackInfoSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
          isFruit: isFruit,
          isRingMode: isRingMode,
          autoSpacing: autoSpacing,
        ),
        ..._buildAudioReactivitySection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
          isFruit: isFruit,
        ),
        ..._buildFrequencyIsolationSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
          isFruit: isFruit,
        ),
        ..._buildPerformanceSection(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
      ],
    ];
  }

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

  List<Widget> _buildVisualSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
  }) {
    return [
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
        valueFormatter: (v) => v == 0.0 ? 'None' : '-${(v * 100).round()}%',
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
    ];
  }

  List<Widget> _buildTrackInfoSection({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
    required bool isFruit,
    required bool isRingMode,
    required bool autoSpacing,
  }) {
    return [
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
        _buildDisplayStyleSelector(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        const SizedBox(height: 16),
        _buildBannerFontSelector(
          settings: settings,
          colorScheme: colorScheme,
          textTheme: textTheme,
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
        _ToggleRow(
          label: isRingMode ? 'Auto Arc Spacing' : 'Auto Spacing',
          subtitle: isRingMode
              ? 'Auto-fit text to circular arcs'
              : 'Auto-fit letter, word, and line spacing',
          value: autoSpacing,
          onChanged: (value) => isRingMode
              ? settings.setOilAutoRingSpacing(value)
              : settings.setOilAutoTextSpacing(value),
          colorScheme: colorScheme,
          textTheme: textTheme,
        ),
        if (!autoSpacing) ...[
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
        ],
        const SizedBox(height: 16),
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
            valueFormatter: (v) => v == 0.0 ? 'Off' : '${(v * 100).round()}%',
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
            label: 'Track Ring Font Size',
            value: settings.oilMiddleRingFontScale,
            min: 0.3,
            max: 1.0,
            step: 0.05,
            leftLabel: 'Small',
            rightLabel: 'Full',
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (v) => settings.setOilMiddleRingFontScale(v),
          ),
          const SizedBox(height: 16),
          TvStepperRow(
            label: 'Venue Ring Font Size',
            value: settings.oilOuterRingFontScale,
            min: 0.3,
            max: 1.0,
            step: 0.05,
            leftLabel: 'Small',
            rightLabel: 'Full',
            valueFormatter: (v) => '${(v * 100).round()}%',
            onChanged: (v) => settings.setOilOuterRingFontScale(v),
          ),
          if (!autoSpacing) ...[
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Inner Ring Spacing',
              value: settings.oilInnerRingSpacingMultiplier,
              min: 0.3,
              max: 3.0,
              step: 0.05,
              leftLabel: 'Tight',
              rightLabel: 'Airy',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilInnerRingSpacingMultiplier(v),
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Track Ring Spacing',
              value: settings.oilMiddleRingSpacingMultiplier,
              min: 0.3,
              max: 3.0,
              step: 0.05,
              leftLabel: 'Tight',
              rightLabel: 'Airy',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilMiddleRingSpacingMultiplier(v),
            ),
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Venue Ring Spacing',
              value: settings.oilOuterRingSpacingMultiplier,
              min: 0.3,
              max: 3.0,
              step: 0.05,
              leftLabel: 'Tight',
              rightLabel: 'Airy',
              valueFormatter: (v) => '${(v * 100).round()}%',
              onChanged: (v) => settings.setOilOuterRingSpacingMultiplier(v),
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
          ],
        ],
        if (!isRingMode) ...[
          const SizedBox(height: 16),
          _buildFlatPlacementSelector(
            settings: settings,
            colorScheme: colorScheme,
            textTheme: textTheme,
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
          if (!autoSpacing) ...[
            const SizedBox(height: 16),
            TvStepperRow(
              label: 'Line Spacing',
              value: settings.oilFlatLineSpacing,
              min: 0.5,
              max: 2.5,
              step: 0.1,
              leftLabel: 'Tight',
              rightLabel: 'Spaced',
              valueFormatter: (v) => v.toStringAsFixed(1),
              onChanged: (v) => settings.setOilFlatLineSpacing(v),
            ),
          ],
        ],
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
    ];
  }

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

  Widget _buildDisplayStyleSelector({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TvFocusWrapper(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
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
                onSelectionChanged: (Set<String> selection) =>
                    settings.setOilBannerDisplayMode(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBannerFontSelector({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: TvFocusWrapper(
              onKeyEvent: (node, event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
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
                  ButtonSegment(value: 'RockSalt', label: Text('Rock Salt')),
                  ButtonSegment(value: 'Roboto', label: Text('Roboto')),
                ],
                selected: {settings.oilBannerFont},
                onSelectionChanged: (Set<String> selection) =>
                    settings.setOilBannerFont(selection.first),
                showSelectedIcon: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlatPlacementSelector({
    required SettingsProvider settings,
    required ColorScheme colorScheme,
    required TextTheme textTheme,
  }) {
    return Padding(
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
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  settings.setOilFlatTextPlacement('below');
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  settings.setOilFlatTextPlacement('above');
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'below', label: Text('Below')),
                ButtonSegment(value: 'above', label: Text('Above')),
              ],
              selected: {settings.oilFlatTextPlacement},
              onSelectionChanged: (Set<String> selection) =>
                  settings.setOilFlatTextPlacement(selection.first),
              showSelectedIcon: false,
            ),
          ),
        ],
      ),
    );
  }
}
