import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';

class ShnidBadge extends StatelessWidget {
  final String text;
  final bool showUnderline;

  const ShnidBadge({
    super.key,
    required this.text,
    this.showUnderline = false,
  });

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

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

    final textColor = colorScheme.onSecondaryContainer;

    Widget content = Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: (settingsProvider.appFont == 'rock_salt')
              ? 7.5 * effectiveScale
              : 9.0 * effectiveScale,
          height: (settingsProvider.appFont == 'rock_salt') ? 2.0 : 1.5,
          letterSpacing: (settingsProvider.appFont == 'rock_salt' ||
                  settingsProvider.appFont == 'permanent_marker')
              ? 1.5
              : 0.0),
      overflow: TextOverflow.ellipsis,
      maxLines: 1,
      textAlign: TextAlign.center,
    );

    if (showUnderline) {
      content = Container(
        padding: EdgeInsets.only(
          bottom: (settingsProvider.appFont == 'rock_salt') ? 3.0 : 1.0,
        ),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: textColor.withValues(alpha: 0.5),
              width: 1.5,
            ),
          ),
        ),
        child: content,
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.0),
      constraints: const BoxConstraints(maxWidth: 100),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: colorScheme.shadow.withValues(alpha: 0.05),
              blurRadius: 2,
              offset: const Offset(0, 1))
        ],
      ),
      child: content,
    );
  }
}
