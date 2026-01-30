import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/styles/font_config.dart';

/// Common helper widgets used across onboarding screens.
class OnboardingComponents {
  static Widget buildBulletPoint(
      BuildContext context, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: colorScheme.primary,
              fontSize: AppTypography.responsiveFontSize(context, 18.0),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    height: 1.3,
                    fontSize: AppTypography.responsiveFontSize(
                        context,
                        (settings.uiScale && settings.appFont == 'caveat')
                            ? 12.5
                            : 14.0),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget buildTipRow(
      BuildContext context, Widget leading, String text, double scaleFactor) {
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();

    return Row(
      children: [
        leading,
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.2,
                  fontSize: AppTypography.responsiveFontSize(
                      context,
                      (settings.uiScale && settings.appFont == 'caveat')
                          ? 12.5
                          : 14.0),
                ),
          ),
        ),
      ],
    );
  }

  static Widget buildIconBubble(BuildContext context, IconData icon) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      child: Icon(icon,
          size: AppTypography.responsiveFontSize(context, 20.0),
          color: colorScheme.primary),
    );
  }

  static Widget buildSectionHeader(
      BuildContext context, String title, double scaleFactor) {
    final settings = context.read<SettingsProvider>();
    final fontConfig = FontConfig.get(settings.appFont);
    final mediaQuery = MediaQuery.of(context);

    // Base size 21px, divided by font's scaleFactor to normalize visual size
    final normalizedFontSize = (21.0 / fontConfig.scaleFactor) *
        scaleFactor *
        mediaQuery.textScaler.scale(1.0);

    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
            fontSize: normalizedFontSize,
          ),
    );
  }
}
