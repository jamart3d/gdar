import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gdar/utils/utils.dart';

class RatingControl extends StatelessWidget {
  final int rating;
  final VoidCallback? onTap;
  final double size;
  final bool isPlayed;

  const RatingControl({
    super.key,
    required this.rating,
    this.onTap,
    this.size = 24.0,
    this.isPlayed = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (rating == -1) {
      // Blocked (Red Star)
      content = Icon(
        Icons.star,
        size: size,
        color: Colors.red,
      );
    } else if (rating == 0 && isPlayed) {
      // Played but unrated (1 Grey Star, 2 Empty)
      content = RatingBar(
        initialRating: 1,
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 3,
        itemSize: size,
        ignoreGestures: true,
        ratingWidget: RatingWidget(
          full: const Icon(Icons.star, color: Colors.grey),
          half: const Icon(Icons.star_half, color: Colors.grey),
          empty: const Icon(Icons.star_border, color: Colors.grey),
        ),
        onRatingUpdate: (_) {},
      );
    } else {
      // 0-3 Stars (Amber or Empty)
      content = RatingBar(
        initialRating: rating.toDouble(),
        minRating: 1,
        direction: Axis.horizontal,
        allowHalfRating: false,
        itemCount: 3,
        itemSize: size,
        ignoreGestures: true,
        ratingWidget: RatingWidget(
          full: const Icon(Icons.star, color: Colors.amber),
          half: const Icon(Icons.star_half, color: Colors.amber),
          empty: const Icon(Icons.star_border, color: Colors.grey),
        ),
        onRatingUpdate: (_) {},
      );
    }

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: content,
    );
  }
}

class RatingDialog extends StatelessWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final String? sourceId;
  final String? sourceUrl;

  const RatingDialog({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.sourceId,
    this.sourceUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('Rate Show'),
          if (sourceId != null && sourceId!.isNotEmpty) ...[
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                if (sourceUrl != null && sourceUrl!.isNotEmpty) {
                  launchArchivePage(sourceUrl!);
                } else {
                  launchArchiveDetails(sourceId!);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  sourceId!,
                  style: textTheme.titleLarge?.copyWith(
                    color: colorScheme.onTertiaryContainer,
                    fontWeight: FontWeight.bold,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(0.0, 12.0, 0.0, 16.0),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: Center(
            child: RatingBar.builder(
              initialRating: initialRating > 0 ? initialRating.toDouble() : 0.0,
              minRating: 1,
              direction: Axis.horizontal,
              allowHalfRating: false,
              itemCount: 3,
              itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
              itemBuilder: (context, _) => const Icon(
                Icons.star,
                color: Colors.amber,
              ),
              onRatingUpdate: (rating) {
                onRatingChanged(rating.toInt());
              },
            ),
          ),
        ),
        const Divider(),
        _buildActionOption(
          context,
          'Block (Red Star)',
          Icons.star,
          Colors.red,
          -1,
        ),
        const Divider(),
        _buildActionOption(
          context,
          'Clear Rating',
          Icons.star_border,
          Colors.grey,
          0,
        ),
      ],
    );
  }

  Widget _buildActionOption(BuildContext context, String text, IconData icon,
      Color color, int rating) {
    return SimpleDialogOption(
      onPressed: () {
        onRatingChanged(rating);
        Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(text),
            if (initialRating == rating) ...[
              const Spacer(),
              const Icon(Icons.check, size: 16),
            ]
          ],
        ),
      ),
    );
  }
}
