import 'package:flutter/material.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/section_card.dart';

class DataSection extends StatelessWidget {
  final double scaleFactor;

  const DataSection({
    super.key,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      scaleFactor: scaleFactor,
      title: 'Manage Rated Shows Library',
      icon: Icons.star_rounded,
      lucideIcon: Icons.star,
      initiallyExpanded: false,
      children: [
        const SizedBox(
          height: 600,
          child: RatedShowsBody(),
        ),
      ],
    );
  }
}
