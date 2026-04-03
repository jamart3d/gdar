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
        if (settings.oilEnableAudioReactivity)
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
}
