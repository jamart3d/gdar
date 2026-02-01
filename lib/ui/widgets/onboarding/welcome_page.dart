import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/widgets/onboarding/onboarding_components.dart';
import 'package:shakedown/ui/widgets/onboarding/update_banner.dart';
import 'package:in_app_update/in_app_update.dart';

class WelcomePage extends StatelessWidget {
  final double scaleFactor;
  final bool? archiveReachable;
  final AppUpdateInfo? updateInfo;
  final bool isDownloading;
  final bool isWaitingToDownload;
  final bool isSimulated;
  final VoidCallback onUpdateSelected;

  const WelcomePage({
    super.key,
    required this.scaleFactor,
    required this.archiveReachable,
    required this.updateInfo,
    required this.isDownloading,
    required this.isWaitingToDownload,
    required this.onUpdateSelected,
    this.isSimulated = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = context.watch<SettingsProvider>();

    return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              UpdateBanner(
                updateInfo: updateInfo,
                isDownloading: isDownloading,
                isWaitingToDownload: isWaitingToDownload,
                isSimulated: isSimulated,
                onUpdateSelected: onUpdateSelected,
                scaleFactor: scaleFactor,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome friend! and many thanks for helping with this closed test.\nThis app is a lightweight streaming music player.',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.4,
                  fontWeight: FontWeight.w500,
                  fontSize: AppTypography.responsiveFontSize(
                      context,
                      (settings.uiScale && settings.appFont == 'caveat')
                          ? 14.5
                          : 16.0),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Archive.org Item
              _buildArchiveStatusRow(context, theme, colorScheme, settings),
              OnboardingComponents.buildBulletPoint(
                  context,
                  'Dive into an almost endless list of live Grateful Dead shows',
                  scaleFactor),
              OnboardingComponents.buildBulletPoint(context,
                  'Play a random show or choose a specific date', scaleFactor),
              OnboardingComponents.buildBulletPoint(
                  context,
                  'Filter source types: Matrix, Betty Board, Soundboard, etc.',
                  scaleFactor),
              OnboardingComponents.buildBulletPoint(
                  context, 'Gapless playback', scaleFactor),
              const SizedBox(height: 40),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildArchiveStatusRow(BuildContext context, ThemeData theme,
      ColorScheme colorScheme, SettingsProvider settings) {
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
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  height: 1.3,
                  fontSize: AppTypography.responsiveFontSize(
                      context,
                      (settings.uiScale && settings.appFont == 'caveat')
                          ? 12.5
                          : 14.0),
                ),
                children: [
                  const TextSpan(text: 'All audio is streamed directly from '),
                  TextSpan(
                    text: 'Archive.org',
                    style: TextStyle(
                      color: (archiveReachable == false)
                          ? const Color(0xFFEF4444)
                          : null,
                      fontWeight:
                          (archiveReachable == false) ? FontWeight.bold : null,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
