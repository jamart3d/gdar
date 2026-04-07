import 'package:flutter/material.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';

class TrackListSetHeader extends StatelessWidget {
  const TrackListSetHeader({super.key, required this.setName});

  final String setName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontSize: AppTypography.responsiveFontSize(context, 14.0),
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
