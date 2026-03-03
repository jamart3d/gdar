import 'package:flutter/material.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class TvInteractionModal extends StatelessWidget {
  final String title;
  final String? subtitle;
  final VoidCallback onPlay;
  final VoidCallback onRate;

  const TvInteractionModal({
    super.key,
    required this.title,
    this.subtitle,
    required this.onPlay,
    required this.onRate,
  });

  static Future<void> show(
    BuildContext context, {
    required String title,
    String? subtitle,
    required VoidCallback onPlay,
    required VoidCallback onRate,
  }) {
    return showDialog(
      context: context,
      builder: (context) => TvInteractionModal(
        title: title,
        subtitle: subtitle,
        onPlay: onPlay,
        onRate: onRate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: double.infinity,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            SizedBox(
              width: double.infinity,
              child: Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(8, 24, 8, 24),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TvFocusWrapper(
              autofocus: true,
              useRgbBorder: true,
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(context);
                onPlay();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_circle_filled_rounded,
                        color: colorScheme.primary, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Play Now',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            TvFocusWrapper(
              useRgbBorder: true,
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                Navigator.pop(context);
                onRate();
              },
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.star_rounded,
                        color: colorScheme.secondary, size: 28),
                    const SizedBox(width: 16),
                    Text(
                      'Rate / Details',
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
