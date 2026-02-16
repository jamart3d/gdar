import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvReloadDialog extends StatelessWidget {
  final VoidCallback onReload;

  const TvReloadDialog({
    super.key,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: 480,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.refresh_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Connection Issue?',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'The track seems to be taking longer than usual to load. Would you like to try reloading the show?',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                _DialogButton(
                  label: 'Reload Show',
                  icon: Icons.replay_rounded,
                  description: 'Re-establish connection and try again',
                  onTap: () {
                    Navigator.of(context).pop();
                    onReload();
                  },
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                _DialogButton(
                  label: 'Cancel',
                  icon: Icons.close_rounded,
                  description: 'Continue waiting',
                  onTap: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> show(
    BuildContext context, {
    required VoidCallback onReload,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => TvReloadDialog(
        onReload: onReload,
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  final String label;
  final String description;
  final IconData icon;
  final VoidCallback onTap;
  final bool autofocus;

  const _DialogButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusWrapper(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(16),
      focusColor: colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
