import 'package:flutter/material.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:provider/provider.dart';

import 'package:shakedown/utils/font_layout_config.dart';

class SrcBadge extends StatelessWidget {
  final String src;
  final bool isPlaying;
  final double fontSize;
  final bool matchShnidLook;
  final EdgeInsetsGeometry? padding;

  const SrcBadge({
    super.key,
    required this.src,
    this.isPlaying = false,
    this.fontSize = 7.0,
    this.matchShnidLook = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (src.isEmpty) return const SizedBox.shrink();

    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final double effectiveScale =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    // When playing, the parent card uses tertiaryContainer background.
    // To ensure visibility and an "expressive" look, we invert the badge colors.
    // Normal: tertiaryContainer bg / onTertiaryContainer text
    // Playing: onTertiaryContainer bg / tertiaryContainer text (High Contrast)
    final backgroundColor = isPlaying
        ? colorScheme.onTertiaryContainer
        : colorScheme.tertiaryContainer;

    final textColor = isPlaying
        ? colorScheme.tertiaryContainer
        : colorScheme.onTertiaryContainer;

    final borderColor = isPlaying
        ? Colors.transparent // No border needed for high contrast pill
        : colorScheme.onTertiaryContainer.withValues(alpha: 0.1);

    return Container(
      padding: padding ??
          const EdgeInsets.symmetric(
            horizontal: 6,
            vertical: 1.0,
          ),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(matchShnidLook ? 8 : 12),
        border: matchShnidLook
            ? null
            : Border.all(
                color: borderColor,
                width: 0.5,
              ),
        boxShadow: matchShnidLook
            ? [
                BoxShadow(
                    color: colorScheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 2,
                    offset: const Offset(0, 1))
              ]
            : null,
      ),
      child: Text(
        src.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              height: matchShnidLook ? 1.5 : 1.0,
              fontSize: matchShnidLook
                  ? (settingsProvider.appFont == 'rock_salt'
                      ? 7.5 * effectiveScale
                      : 9.0 * effectiveScale)
                  : fontSize *
                      (settingsProvider.appFont == 'rock_salt' ? 0.7 : 1.0) *
                      effectiveScale,
              letterSpacing:
                  settingsProvider.appFont == 'rock_salt' ? 0.0 : 0.5,
            ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
