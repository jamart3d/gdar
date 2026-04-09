import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown_core/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';

class TrackListShowHeaderSection extends StatelessWidget {
  const TrackListShowHeaderSection({
    super.key,
    required this.show,
    required this.onTap,
  });

  final Show show;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final String dateText = AppDateUtils.formatDate(
      show.date,
      settings: settingsProvider,
    );
    final metrics = AppTypography.getHeaderMetrics(settingsProvider.appFont);

    final Widget headerContent = isFruit
        ? const SizedBox.shrink()
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  dateText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium
                      ?.copyWith(
                        fontWeight: FontWeight.w800,
                        height: metrics.height,
                        letterSpacing: metrics.letterSpacing,
                        color: colorScheme.onSurface,
                      )
                      .apply(fontSizeFactor: scaleFactor),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.stadium_rounded,
                      size: 20 * scaleFactor,
                      color: colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        show.venue,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                              letterSpacing:
                                  settingsProvider.appFont == 'rock_salt'
                                  ? 1.0
                                  : (settingsProvider.appFont ==
                                            'permanent_marker'
                                        ? 0.5
                                        : 0.0),
                            )
                            .apply(fontSizeFactor: scaleFactor),
                      ),
                    ),
                  ],
                ),
                if (show.location.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 20 * scaleFactor,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          show.location,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge
                              ?.copyWith(color: colorScheme.onSurfaceVariant)
                              .apply(fontSizeFactor: scaleFactor),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: _TrackListShowHeaderCard(
        show: show,
        onTap: onTap,
        headerContent: headerContent,
      ),
    );
  }
}

class _TrackListShowHeaderCard extends StatelessWidget {
  const _TrackListShowHeaderCard({
    required this.show,
    required this.onTap,
    required this.headerContent,
  });

  final Show show;
  final VoidCallback onTap;
  final Widget headerContent;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final usePremium =
        settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;
    final isTv = context.watch<DeviceService>().isTv;

    Widget card = Card(
      elevation: 0,
      color: usePremium
          ? const Color(0x00000000)
          : Theme.of(context).colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(children: [headerContent]),
    );

    if (usePremium && !isTv) {
      card = NeumorphicWrapper(
        borderRadius: 24,
        intensity: 1.0,
        color: const Color(0x00000000),
        child: LiquidGlassWrapper(
          enabled: !isTv,
          borderRadius: BorderRadius.circular(24),
          opacity: 0.08,
          blur: 15.0,
          child: card,
        ),
      );
    }

    if (isTv) {
      final audioProvider = context.watch<AudioProvider>();
      return TvFocusWrapper(
        autofocus: true,
        onTap: () async {
          audioProvider.captureUndoCheckpoint();
          if (audioProvider.currentShow != null &&
              audioProvider.currentShow!.name != show.name) {
            await audioProvider.stopAndClear();
          }
          onTap();
        },
        borderRadius: BorderRadius.circular(24),
        child: card,
      );
    }

    return card;
  }
}

class TrackListSetHeaderSection extends StatelessWidget {
  const TrackListSetHeaderSection({super.key, required this.setName});

  final String setName;

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    if (isFruit) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.04),
        child: Text(
          setName.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
      );
    }

    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );
    final usePremium =
        settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    final Widget pill = Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16 * scaleFactor,
        vertical: 6 * scaleFactor,
      ),
      decoration: BoxDecoration(
        color: usePremium
            ? colorScheme.secondaryContainer.withValues(alpha: 0.3)
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(50),
      ),
      child: Text(
        setName.toUpperCase(),
        style: Theme.of(context).textTheme.labelLarge
            ?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.0,
            )
            .apply(fontSizeFactor: scaleFactor),
      ),
    );

    if (usePremium && !context.read<DeviceService>().isTv) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
        child: Align(
          alignment: Alignment.centerLeft,
          child: NeumorphicWrapper(
            borderRadius: 50,
            intensity: 0.8,
            isPressed: true,
            color: const Color(0x00000000),
            child: LiquidGlassWrapper(
              enabled: true,
              borderRadius: BorderRadius.circular(50),
              opacity: 0.05,
              blur: 5.0,
              child: pill,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Align(alignment: Alignment.centerLeft, child: pill),
    );
  }
}
