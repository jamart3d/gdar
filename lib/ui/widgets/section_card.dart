import 'package:flutter/material.dart';

class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final bool initiallyExpanded;
  final double scaleFactor;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.children,
    this.initiallyExpanded = false,
    this.scaleFactor = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          dense: true,
          visualDensity: VisualDensity.compact,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          collapsedShape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
          leading:
              Icon(icon, color: colorScheme.primary, size: 24 * scaleFactor),
          title: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize:
                        (Theme.of(context).textTheme.titleLarge?.fontSize ??
                                22.0) *
                            scaleFactor,
                  ),
            ),
          ),
          children: children,
        ),
      ),
    );
  }
}
