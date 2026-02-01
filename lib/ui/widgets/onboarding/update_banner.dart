import 'package:flutter/material.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:shakedown/ui/styles/app_typography.dart';

/// A Material 3 banner that notifies the user of an available update.
class UpdateBanner extends StatelessWidget {
  final AppUpdateInfo? updateInfo;
  final bool isDownloading;
  final bool isWaitingToDownload;
  final bool isSimulated;
  final VoidCallback onUpdateSelected;
  final double scaleFactor;

  const UpdateBanner({
    super.key,
    required this.updateInfo,
    required this.isDownloading,
    required this.isWaitingToDownload,
    required this.onUpdateSelected,
    required this.scaleFactor,
    this.isSimulated = false,
  });

  @override
  Widget build(BuildContext context) {
    bool hasUpdate = isSimulated ||
        (updateInfo != null &&
            updateInfo!.updateAvailability ==
                UpdateAvailability.updateAvailable);

    if (!hasUpdate) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: isDownloading
          ? _buildDownloadingCard(context, colorScheme)
          : _buildUpdateActionCard(context, colorScheme),
    );
  }

  Widget _buildDownloadingCard(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 0,
        color: colorScheme.secondaryContainer.withValues(alpha: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor:
                      AlwaysStoppedAnimation<Color>(colorScheme.primary),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  isWaitingToDownload
                      ? 'Waiting to download...'
                      : 'Downloading update...',
                  style: TextStyle(
                    fontSize: AppTypography.responsiveFontSize(context, 13.0),
                    color: colorScheme.onSecondaryContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUpdateActionCard(BuildContext context, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Card(
        elevation: 0,
        color: colorScheme.primaryContainer,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onTap: onUpdateSelected,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  Icons.system_update_rounded,
                  color: colorScheme.onPrimaryContainer,
                  size: 24 * scaleFactor,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Update Available',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                          fontSize:
                              AppTypography.responsiveFontSize(context, 14.0),
                        ),
                      ),
                      Text(
                        'A new version is ready to install.',
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer
                              .withValues(alpha: 0.8),
                          fontSize:
                              AppTypography.responsiveFontSize(context, 12.0),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: onUpdateSelected,
                  style: TextButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text('UPDATE'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
