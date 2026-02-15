import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/settings/collection_statistics.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/widgets/section_card.dart';

class LibrarySection extends StatelessWidget {
  final double scaleFactor;
  final bool initiallyExpanded;

  const LibrarySection({
    super.key,
    required this.scaleFactor,
    this.initiallyExpanded = false,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Library',
      icon: Icons.local_library_rounded,
      scaleFactor: scaleFactor,
      initiallyExpanded: initiallyExpanded,
      children: [
        // Collection Statistics (Stats content)
        CollectionStatistics(
          asBody: true,
          scaleFactor: scaleFactor,
        ),

        const Divider(height: 1, indent: 16, endIndent: 16),

        // Manage Rated Shows Link
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, bottom: 4.0),
                child: Text(
                  'INTERACTION',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                ),
              ),
              TvListTile(
                dense: true,
                visualDensity: VisualDensity.compact,
                leading: const Icon(Icons.stars_rounded),
                title: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Manage Rated Shows',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 16 * scaleFactor,
                        ),
                  ),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
                onTap: () async {
                  HapticFeedback.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (context) => const RatedShowsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
