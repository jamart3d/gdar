import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';

/// A reusable widget for the app title "Shakedown" that handles
/// consistent styling, Hero animations, and flight transitions.
class ShakedownTitle extends StatelessWidget {
  final double fontSize;
  final bool enableHero;

  const ShakedownTitle({
    super.key,
    required this.fontSize,
    this.enableHero = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settingsProvider = context.watch<SettingsProvider>();
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final textStyle = theme.textTheme.displayLarge?.copyWith(
      fontSize: fontSize * scaleFactor,
      fontFamily: settingsProvider.appFont == 'default'
          ? 'Roboto'
          : (settingsProvider.appFont == 'rock_salt'
              ? 'RockSalt'
              : (settingsProvider.appFont == 'permanent_marker'
                  ? 'Permanent Marker'
                  : 'Caveat')),
      fontWeight: FontWeight.bold,
      color: theme.colorScheme.primary,
      letterSpacing: 1.2,
      height: 1.4,
    );

    // If using 'titleLarge' base (like in AppBar), we might want to map displayLarge props
    // or just use the style we constructed above. The key is CONSISTENCY across screens.
    // The previous implementations used slightly different bases, but manual overrides
    // made them look similar. We'll enforce the manual overrides here.

    final widget = Text(
      'Shakedown',
      style: textStyle,
      textAlign: TextAlign.center,
    );

    if (!enableHero || !settingsProvider.enableShakedownTween) {
      return widget;
    }

    return Hero(
      tag: 'app_title',
      // Custom flight shuttle to smooth out text style interpolation
      flightShuttleBuilder: (
        BuildContext flightContext,
        Animation<double> animation,
        HeroFlightDirection flightDirection,
        BuildContext fromHeroContext,
        BuildContext toHeroContext,
      ) {
        return DefaultTextStyle(
          style: DefaultTextStyle.of(toHeroContext).style,
          child: toHeroContext.widget,
        );
      },
      child: Material(
        type: MaterialType.transparency,
        child: widget,
      ),
    );
  }
}
