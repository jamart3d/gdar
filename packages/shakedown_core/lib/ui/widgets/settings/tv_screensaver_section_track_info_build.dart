part of 'tv_screensaver_section.dart';

extension _TvScreensaverSectionTrackInfoBuild on _TvScreensaverSectionState {
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
