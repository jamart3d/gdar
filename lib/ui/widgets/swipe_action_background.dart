import 'package:flutter/material.dart';

class SwipeActionBackground extends StatelessWidget {
  final double borderRadius;
  final Alignment alignment;
  final EdgeInsets padding;
  final String label;
  final IconData icon;

  const SwipeActionBackground({
    super.key,
    required this.borderRadius,
    this.alignment = Alignment.centerRight,
    this.padding = const EdgeInsets.only(right: 24.0),
    this.label = 'Block',
    this.icon = Icons.block_outlined,
  });

  @override
  Widget build(BuildContext context) {
    // Use the error color scheme for destructive actions
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      alignment: alignment,
      padding: padding,
      decoration: BoxDecoration(
        color: colorScheme.error,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (alignment == Alignment.centerLeft) ...[
            Icon(icon, color: colorScheme.onError),
            const SizedBox(width: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
          if (alignment == Alignment.centerRight) ...[
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: colorScheme.onError,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(width: 8),
            Icon(icon, color: colorScheme.onError),
          ],
        ],
      ),
    );
  }
}
