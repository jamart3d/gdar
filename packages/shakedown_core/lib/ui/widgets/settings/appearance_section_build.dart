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
        _buildThemeModeSection(context, themeProvider),
        if (themeProvider.isFruitAllowed) ...[
          _buildThemeStyleSection(context, themeProvider),
          _buildFruitOptionsSwitcher(context, themeProvider, settingsProvider),
          if (themeProvider.themeStyle != ThemeStyle.fruit)
            _buildPerformanceModeTile(context, settingsProvider),
        ],
        if (themeProvider.themeStyle != ThemeStyle.fruit)
          _buildDynamicColorTile(context, settingsProvider, themeProvider),
        if (isDarkMode && themeProvider.themeStyle != ThemeStyle.fruit)
          _buildTrueBlackTile(context, settingsProvider, themeProvider),
        if (themeProvider.themeStyle != ThemeStyle.fruit &&
            !settingsProvider.useDynamicColor)
          _buildCustomThemeColorControl(
            context,
            settingsProvider,
            themeProvider,
          ),
        if (showExpressiveAccents && !context.read<DeviceService>().isTv) ...[
          _buildGlowBorderTile(context, settingsProvider, themeProvider),
          if (settingsProvider.glowMode > 0 &&
              !settingsProvider.performanceMode)
            _buildGlowIntensityControl(context, settingsProvider),
        ],
        if (showExpressiveAccents)
          _buildHighlightPlayingTile(context, settingsProvider, themeProvider),
        if (settingsProvider.highlightPlayingWithRgb)
          _buildRgbAnimationSpeedControl(
            context,
            settingsProvider,
            themeProvider,
          ),
        if (!context.read<DeviceService>().isTv &&
            themeProvider.themeStyle != ThemeStyle.fruit)
          _buildFontSelectionTile(context, settingsProvider),
      ],
    );
  }
}
