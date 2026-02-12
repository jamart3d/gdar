import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvExitDialog extends StatelessWidget {
  final VoidCallback onBackground;
  final VoidCallback onQuit;

  const TvExitDialog({
    super.key,
    required this.onBackground,
    required this.onQuit,
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
                  Icons.headphones_rounded,
                  color: colorScheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Still Listening?',
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
              'Music is currently playing. Would you like to keep it playing in the background or stop and exit?',
              style: TextStyle(
                fontSize: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            Column(
              children: [
                _DialogButton(
                  label: 'Keep Playing',
                  icon: Icons.unfold_less_rounded,
                  description: 'Minimize app and play in background',
                  onTap: onBackground,
                  autofocus: true,
                ),
                const SizedBox(height: 12),
                _DialogButton(
                  label: 'Stop and Exit',
                  icon: Icons.exit_to_app_rounded,
                  description: 'Stop all audio and close the app',
                  onTap: onQuit,
                  isDestructive: true,
                ),
                const SizedBox(height: 12),
                _DialogButton(
                  label: 'Cancel',
                  icon: Icons.arrow_back_rounded,
                  description: 'Stay in the app',
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
    required VoidCallback onBackground,
    required VoidCallback onQuit,
  }) {
    return showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (context) => TvExitDialog(
        onBackground: onBackground,
        onQuit: onQuit,
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
  final bool isDestructive;

  const _DialogButton({
    required this.label,
    required this.description,
    required this.icon,
    required this.onTap,
    this.autofocus = false,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return TvFocusWrapper(
      onTap: onTap,
      autofocus: autofocus,
      borderRadius: BorderRadius.circular(16),
      focusColor: isDestructive ? colorScheme.error : colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: (isDestructive ? colorScheme.error : colorScheme.primary)
                    .withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isDestructive ? colorScheme.error : colorScheme.primary,
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
                      color: isDestructive
                          ? colorScheme.error
                          : colorScheme.onSurface,
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
