import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';

class RandomProbabilityCard extends StatelessWidget {
  final double scaleFactor;

  const RandomProbabilityCard({super.key, required this.scaleFactor});

  Widget _buildWeightRow(
      BuildContext context, String label, String weight, double scaleFactor,
      {required bool isActive, bool isBest = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodyMedium;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                label,
                style: textStyle?.copyWith(
                  fontSize: 12.0 * scaleFactor,
                  color: isActive
                      ? (isBest ? colorScheme.primary : colorScheme.onSurface)
                      : colorScheme.outline,
                  decoration: isActive ? null : TextDecoration.lineThrough,
                  fontWeight:
                      isBest && isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ),
          Text(
            isActive ? weight : 'Excluded',
            style: textStyle?.copyWith(
              fontSize: 12.0 * scaleFactor,
              color: isActive
                  ? (isBest
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant)
                  : colorScheme.outline,
              fontWeight:
                  isBest && isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();

    if (settingsProvider.nonRandom) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selection Probability',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontSize: 12.0 * scaleFactor,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            _buildWeightRow(context, 'Unplayed', '50x', scaleFactor,
                isActive: true, // Always active
                isBest: true),
            _buildWeightRow(context, '3 Stars', '30x', scaleFactor,
                isActive: !settingsProvider.randomOnlyUnplayed),
            _buildWeightRow(context, '2 Stars', '20x', scaleFactor,
                isActive: !settingsProvider.randomOnlyUnplayed),
            _buildWeightRow(context, '1 Star', '10x', scaleFactor,
                isActive: !settingsProvider.randomOnlyUnplayed &&
                    !settingsProvider.randomOnlyHighRated),
            _buildWeightRow(context, 'Played', '5x', scaleFactor,
                isActive: !settingsProvider.randomOnlyUnplayed &&
                    !settingsProvider.randomExcludePlayed),
          ],
        ),
      ),
    );
  }
}
