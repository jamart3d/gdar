import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/settings/library_section.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';
import 'package:shakedown/ui/widgets/section_card.dart';

class DataSection extends StatelessWidget {
  final double scaleFactor;

  const DataSection({super.key, required this.scaleFactor});

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: 'Data Management',
      icon: Icons.storage_rounded,
      scaleFactor: scaleFactor,
      children: [
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
              MaterialPageRoute(builder: (context) => const RatedShowsScreen()),
            );
          },
        ),
        const Divider(),
        TvListTile(
          dense: true,
          visualDensity: VisualDensity.compact,
          leading: const Icon(Icons.dashboard_customize_rounded),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              'TV Library Dashboard',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontSize: 16 * scaleFactor,
                  ),
            ),
          ),
          subtitle: const Text('Google TV style library view'),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => Scaffold(
                  appBar: AppBar(title: const Text('Library Dashboard')),
                  body: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: LibrarySection(
                      scaleFactor: scaleFactor,
                      initiallyExpanded: true,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
