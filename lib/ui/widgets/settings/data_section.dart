import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/screens/rated_shows_screen.dart';
import 'package:shakedown/ui/widgets/tv/tv_list_tile.dart';

class DataSection extends StatelessWidget {
  final double scaleFactor;

  const DataSection({
    super.key,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      elevation: 0,
      color: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: TvListTile(
        dense: true,
        visualDensity: VisualDensity.compact,
        leading: Icon(Icons.library_books_rounded,
            color: Theme.of(context).colorScheme.primary),
        title: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            'Manage Rated Shows',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 16 * scaleFactor),
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 12),
        onTap: () async {
          HapticFeedback.lightImpact();

          // Pause global clock
          try {
            context.read<AnimationController>().stop();
          } catch (_) {}

          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const RatedShowsScreen(),
              transitionsBuilder:
                  (context, animation, secondaryAnimation, child) {
                const begin = 0.92;
                const end = 1.0;
                const curve = Curves.easeOutCubic;

                var scaleTween = Tween(begin: begin, end: end)
                    .chain(CurveTween(curve: curve));
                var fadeTween =
                    Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: curve));

                return FadeTransition(
                  opacity: animation.drive(fadeTween),
                  child: ScaleTransition(
                    scale: animation.drive(scaleTween),
                    child: child,
                  ),
                );
              },
              transitionDuration: const Duration(milliseconds: 400),
              reverseTransitionDuration: const Duration(milliseconds: 350),
            ),
          );

          // Resume clock
          if (context.mounted) {
            try {
              final controller = context.read<AnimationController>();
              if (!controller.isAnimating) controller.repeat();
            } catch (_) {}
          }
        },
      ),
    );
  }
}
