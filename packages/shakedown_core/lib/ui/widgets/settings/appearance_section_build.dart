part of 'appearance_section.dart';

extension _AppearanceSectionBuild on _AppearanceSectionState {
  Widget _buildAppearanceSection(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final showExpressiveAccents = !isFruit;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return SectionCard(
      scaleFactor: widget.scaleFactor,
      title: 'Appearance',
      icon: Icons.palette_outlined,
      lucideIcon: LucideIcons.palette,
      initiallyExpanded: widget.initiallyExpanded,
      children: [
        ThemeModeSection(scaleFactor: widget.scaleFactor),
        if (themeProvider.isFruitAllowed) ...[
          ThemeStyleSection(scaleFactor: widget.scaleFactor),
          FruitOptionsSwitcher(scaleFactor: widget.scaleFactor),
          if (themeProvider.themeStyle != ThemeStyle.fruit)
            PerformanceModeTile(scaleFactor: widget.scaleFactor),
        ],
        if (themeProvider.themeStyle != ThemeStyle.fruit)
          DynamicColorTile(scaleFactor: widget.scaleFactor),
        if (isDarkMode && themeProvider.themeStyle != ThemeStyle.fruit)
          TrueBlackTile(scaleFactor: widget.scaleFactor),
        if (themeProvider.themeStyle != ThemeStyle.fruit &&
            !settingsProvider.useDynamicColor)
          CustomThemeColorControl(scaleFactor: widget.scaleFactor),
        if (showExpressiveAccents && !context.read<DeviceService>().isTv) ...[
          GlowBorderTile(scaleFactor: widget.scaleFactor),
          if (settingsProvider.glowMode > 0 &&
              !settingsProvider.performanceMode)
            GlowIntensityControl(scaleFactor: widget.scaleFactor),
        ],
        if (showExpressiveAccents)
          HighlightPlayingTile(scaleFactor: widget.scaleFactor),
        if (settingsProvider.highlightPlayingWithRgb)
          RgbAnimationSpeedControl(scaleFactor: widget.scaleFactor),
        if (!context.read<DeviceService>().isTv &&
            themeProvider.themeStyle != ThemeStyle.fruit)
          FontSelectionTile(scaleFactor: widget.scaleFactor),
        if (context.read<DeviceService>().isTv) ...[
          BeatAutocorrSecondPassTile(scaleFactor: widget.scaleFactor),
          if (settingsProvider.beatAutocorrSecondPass)
            BeatAutocorrSecondPassHqTile(scaleFactor: widget.scaleFactor),
        ],
      ],
    );
  }
}
