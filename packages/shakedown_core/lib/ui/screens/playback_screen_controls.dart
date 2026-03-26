part of 'playback_screen.dart';

class _RatingStars extends StatelessWidget {
  final int rating;
  final Color color;

  const _RatingStars({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    const int total = 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: List.generate(total, (i) {
        final bool filled = i < rating;
        return Icon(
          filled ? LucideIcons.star : LucideIcons.star,
          size: 16,
          color: filled ? color : color.withValues(alpha: 0.3),
        );
      }),
    );
  }
}
