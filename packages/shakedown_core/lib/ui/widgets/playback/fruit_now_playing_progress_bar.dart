import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/widgets/playback/fruit_now_playing_pending_overlay.dart';

class FruitNowPlayingProgressBar extends StatelessWidget {
  final ColorScheme colorScheme;
  final double scaleFactor;
  final bool isLoading;
  final int bufferedPositionMs;
  final int positionMs;
  final int durationMs;
  final bool glassEnabled;
  final bool showPendingState;

  const FruitNowPlayingProgressBar({
    super.key,
    required this.colorScheme,
    required this.scaleFactor,
    required this.isLoading,
    required this.bufferedPositionMs,
    required this.positionMs,
    required this.durationMs,
    required this.glassEnabled,
    required this.showPendingState,
  });

  @override
  Widget build(BuildContext context) {
    final double progress = (durationMs > 0)
        ? (positionMs / durationMs).clamp(0.0, 1.0)
        : 0.0;
    final double bufferedProgress = (durationMs > 0)
        ? (bufferedPositionMs / durationMs).clamp(0.0, 1.0)
        : 0.0;

    return Stack(
      children: [
        Container(
          height: 3.0 * scaleFactor,
          width: double.infinity,
          decoration: BoxDecoration(
            color: colorScheme.onSurface.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(4 * scaleFactor),
          ),
        ),
        if (bufferedProgress > 0)
          FractionallySizedBox(
            widthFactor: bufferedProgress,
            child: Container(
              height: 3.0 * scaleFactor,
              decoration: BoxDecoration(
                color: colorScheme.tertiary.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(4 * scaleFactor),
              ),
            ),
          ),
        if (showPendingState)
          FruitNowPlayingPendingOverlay(
            key: const Key('fruit_pending_progress_overlay'),
            colorScheme: colorScheme,
            scaleFactor: scaleFactor,
            glassEnabled: glassEnabled,
            isLoading: isLoading,
          ),
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 3.0 * scaleFactor,
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(4 * scaleFactor),
            ),
          ),
        ),
      ],
    );
  }
}
