import 'package:flutter/material.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:provider/provider.dart';

class SrcBadge extends StatelessWidget {
  final String src;
  final bool isPlaying;
  final double fontSize;

  const SrcBadge({
    super.key,
    required this.src,
    this.isPlaying = false,
    this.fontSize = 9.0,
  });

  @override
  Widget build(BuildContext context) {
    if (src.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();

    // Check for True Black mode
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final List<Color> gradientColors;
    if (isTrueBlackMode) {
      gradientColors = [
        Colors.black,
        Colors.black,
      ];
    } else {
      gradientColors = [
        colorScheme.secondaryContainer.withValues(alpha: 0.7),
        colorScheme.secondaryContainer.withValues(alpha: 0.5),
      ];
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(10),
        border: isTrueBlackMode
            ? Border.all(color: colorScheme.outlineVariant, width: 0.5)
            : null,
        boxShadow: isTrueBlackMode
            ? []
            : [
                BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1))
              ],
      ),
      child: Text(
        src.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: fontSize *
                  (settingsProvider.uiScale ? 1.25 : 1.0) *
                  (settingsProvider.appFont == 'rock_salt' ? 0.7 : 1.0),
              letterSpacing:
                  settingsProvider.appFont == 'rock_salt' ? 0.0 : 0.5,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
