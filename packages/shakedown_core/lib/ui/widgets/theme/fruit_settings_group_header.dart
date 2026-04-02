import 'package:flutter/material.dart';

class FruitSettingsGroupHeader extends StatelessWidget {
  final String label;
  final bool addTopSpacing;

  const FruitSettingsGroupHeader({
    super.key,
    required this.label,
    this.addTopSpacing = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = theme.colorScheme.onSurface;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: addTopSpacing ? 18 : 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(
              color: onSurface.withValues(alpha: 0.62),
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          child: Divider(
            height: 1,
            thickness: 1,
            color: onSurface.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.14 : 0.08,
            ),
          ),
        ),
      ],
    );
  }
}
