import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

/// A TV-optimized stepper row for adjusting numeric values.
/// Captures DPAD Left/Right keys to increment/decrement the value.
class TvStepperRow extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final double step;
  final String? leftLabel;
  final String? rightLabel;
  final ValueChanged<double> onChanged;
  final String Function(double)? valueFormatter;

  const TvStepperRow({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    this.leftLabel,
    this.rightLabel,
    required this.onChanged,
    this.valueFormatter,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            final newValue = (value - step).clamp(min, max);
            if (newValue != value) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            }
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            final newValue = (value + step).clamp(min, max);
            if (newValue != value) {
              HapticFeedback.selectionClick();
              onChanged(newValue);
            }
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(label,
                    style: textTheme.bodyLarge
                        ?.copyWith(color: colorScheme.onSurface)),
                Text(
                  valueFormatter?.call(value) ?? value.toStringAsFixed(2),
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Stack(
              children: [
                Container(
                  height: 4,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final progress = (value - min) / (max - min);
                    return Container(
                      height: 4,
                      width: constraints.maxWidth * progress.clamp(0.0, 1.0),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    );
                  },
                ),
              ],
            ),
            if (leftLabel != null || rightLabel != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (leftLabel != null)
                    Text(leftLabel!,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                  if (rightLabel != null)
                    Text(rightLabel!,
                        style: textTheme.labelSmall
                            ?.copyWith(color: colorScheme.onSurfaceVariant)),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
