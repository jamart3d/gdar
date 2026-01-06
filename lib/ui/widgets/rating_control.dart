import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/utils/utils.dart';
import 'package:provider/provider.dart';

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
      content = Semantics(
        label: 'Blocked show',
        child: Icon(
          Icons.star,
          size: size,
          color: Colors.red,
        ),
      );
    } else if (rating == 0 && isPlayed) {
      // Played but unrated (1 Grey Star, 2 Empty)
      content = Semantics(
        key: ValueKey('rating_0_played_$isPlayed'),
        label: 'Played, unrated',
        child: RatingBar(
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
        ),
      );
    } else {
      // 0-3 Stars (Amber or Empty)
      content = Semantics(
        key: ValueKey('rating_$rating'),
        label: 'Rated $rating stars',
        child: RatingBar(
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
        ),
      );
    }

    if (onTap == null) {
      return content;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        HapticFeedback.selectionClick();
        onTap!();
      },
      child: content,
    );
  }
}

class RatingDialog extends StatefulWidget {
  final int initialRating;
  final ValueChanged<int> onRatingChanged;
  final String? sourceId;
  final String? sourceUrl;
  final bool isPlayed;
  final ValueChanged<bool>? onPlayedChanged;

  const RatingDialog({
    super.key,
    required this.initialRating,
    required this.onRatingChanged,
    this.sourceId,
    this.sourceUrl,
    this.isPlayed = false,
    this.onPlayedChanged,
  });

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late bool _isPlayed;
  late int _currentRating;

  @override
  void initState() {
    super.initState();
    _isPlayed = widget.isPlayed;
    _currentRating = widget.initialRating;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return SimpleDialog(
      titlePadding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 0.0),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Rate Show'),
          if (widget.sourceId != null && widget.sourceId!.isNotEmpty) ...[
            const SizedBox(width: 16),
            InkWell(
              onTap: () {
                if (widget.sourceUrl != null && widget.sourceUrl!.isNotEmpty) {
                  launchArchivePage(widget.sourceUrl!);
                } else {
                  launchArchiveDetails(widget.sourceId!);
                }
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.tertiaryContainer.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: colorScheme.onTertiaryContainer,
                        width: 1.5,
                      ),
                    ),
                  ),
                  padding: const EdgeInsets.only(bottom: 2.0),
                  child: Text(
                    widget.sourceId!,
                    style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
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
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Center(
            child: IgnorePointer(
              ignoring: _currentRating == -1,
              child: Opacity(
                opacity: _currentRating == -1 ? 0.3 : 1.0,
                child: RatingBar(
                  initialRating: (_currentRating == 0 && _isPlayed)
                      ? 1.0
                      : (_currentRating > 0 ? _currentRating.toDouble() : 0.0),
                  minRating: 1,
                  direction: Axis.horizontal,
                  allowHalfRating: false,
                  itemCount: 3,
                  itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                  ratingWidget: RatingWidget(
                    full: Icon(
                      Icons.star,
                      color: (_currentRating == 0 && _isPlayed)
                          ? Colors.grey
                          : Colors.amber,
                    ),
                    half: Icon(
                      Icons.star_half,
                      color: (_currentRating == 0 && _isPlayed)
                          ? Colors.grey
                          : Colors.amber,
                    ),
                    empty: const Icon(Icons.star_border, color: Colors.grey),
                  ),
                  onRatingUpdate: (rating) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _currentRating = rating.toInt();
                    });
                    widget.onRatingChanged(rating.toInt());
                  },
                ),
              ),
            ),
          ),
        ),
        if (widget.onPlayedChanged != null) ...[
          const Divider(),
          SwitchListTile(
            title: const Text('Mark as Played'),
            secondary: Icon(
              _isPlayed ? Icons.check_circle_rounded : Icons.circle_outlined,
              color: _isPlayed ? colorScheme.primary : colorScheme.outline,
            ),
            value: _isPlayed,
            onChanged: (value) async {
              if (!value && _isPlayed) {
                // Confirm before un-marking
                final confirmed = await _showScaledConfirmationDialog(
                  context,
                  'Mark as Unplayed?',
                  'This will remove the show from your played list.',
                );

                if (confirmed != true) return;
              }

              setState(() {
                _isPlayed = value;
              });
              widget.onPlayedChanged?.call(value);
            },
          ),
        ],
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
      onPressed: () async {
        // Confirmation Logic
        if (rating == -1 && _currentRating > 0) {
          // Confirm before blocking a rated show
          final confirmed = await _showScaledConfirmationDialog(
            context,
            'Block Show?',
            'This show has a rating. Blocking it will remove the rating.',
          );
          if (confirmed != true) return;
        } else if (rating == 0 && _currentRating > 0) {
          // Confirm before clearing a rating
          final confirmed = await _showScaledConfirmationDialog(
            context,
            'Clear Rating?',
            'Are you sure you want to remove the rating for this show?',
          );
          if (confirmed != true) return;
        }

        setState(() {
          _currentRating = rating;
        });
        widget.onRatingChanged(rating);
        if (context.mounted) Navigator.pop(context);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Text(text),
            if (_currentRating == rating) ...[
              const Spacer(),
              const Icon(Icons.check, size: 16),
            ]
          ],
        ),
      ),
    );
  }

  Future<bool?> _showScaledConfirmationDialog(
      BuildContext context, String title, String content) {
    final settingsProvider = context.read<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;

    return showDialog<bool>(
      context: context,
      builder: (context) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(scaleFactor),
        ),
        child: AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }
}
