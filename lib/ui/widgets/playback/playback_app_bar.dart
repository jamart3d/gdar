import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';

class PlaybackAppBar extends StatelessWidget {
  final Show currentShow;
  final Source currentSource;
  final Color backgroundColor;
  final double panelPosition;

  const PlaybackAppBar({
    super.key,
    required this.currentShow,
    required this.currentSource,
    required this.backgroundColor,
    required this.panelPosition,
  });

  @override
  Widget build(BuildContext context) {
    final double opacity = (1.0 - (panelPosition * 5.0)).clamp(0.0, 1.0);
    final settingsProvider = context.watch<SettingsProvider>();

    // Date Formatting Logic
    String dateFormatPattern = '';
    if (settingsProvider.showDayOfWeek) {
      dateFormatPattern +=
          settingsProvider.abbreviateDayOfWeek ? 'E, ' : 'EEEE, ';
    }
    dateFormatPattern += settingsProvider.abbreviateMonth ? 'MMM' : 'MMMM';
    dateFormatPattern += ' d, y';

    final String formattedDate = () {
      try {
        final date = DateTime.parse(currentShow.date);
        return DateFormat(dateFormatPattern).format(date);
      } catch (e) {
        return currentShow.date;
      }
    }();

    return Opacity(
      opacity: opacity,
      child: Container(
        height: kToolbarHeight,
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: AppTypography.responsiveFontSize(context, 11),
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Right side items
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                children: [
                  ValueListenableBuilder<Box<bool>>(
                    valueListenable: CatalogService().historyListenable,
                    builder: (context, historyBox, _) {
                      return ValueListenableBuilder<Box<Rating>>(
                        valueListenable: CatalogService().ratingsListenable,
                        builder: (context, ratingsBox, _) {
                          final String ratingKey = currentSource.id;
                          final isPlayed = historyBox.get(ratingKey) ?? false;
                          final ratingObj = ratingsBox.get(ratingKey);
                          final int rating = ratingObj?.rating ?? 0;

                          return RatingControl(
                            key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                            rating: rating,
                            size: 16.0,
                            isPlayed: isPlayed,
                            onTap: () async {
                              final currentRating =
                                  ratingsBox.get(ratingKey)?.rating ?? 0;
                              await showDialog(
                                context: context,
                                builder: (context) => RatingDialog(
                                  initialRating: currentRating,
                                  sourceId: currentSource.id,
                                  sourceUrl: currentSource.tracks.isNotEmpty
                                      ? currentSource.tracks.first.url
                                      : null,
                                  isPlayed: historyBox.get(ratingKey) ?? false,
                                  onRatingChanged: (newRating) {
                                    CatalogService()
                                        .setRating(ratingKey, newRating);
                                  },
                                  onPlayedChanged: (bool newIsPlayed) {
                                    if (newIsPlayed !=
                                        (historyBox.get(ratingKey) ?? false)) {
                                      CatalogService().togglePlayed(ratingKey);
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (currentSource.src != null)
                        SrcBadge(
                          src: currentSource.src!,
                          matchShnidLook: true,
                        ),
                      const SizedBox(height: 2),
                      ShnidBadge(text: currentSource.id),
                    ],
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.settings_rounded),
                    iconSize: AppTypography.responsiveFontSize(context, 24.0),
                    onPressed: () async {
                      try {
                        context.read<AnimationController>().stop();
                      } catch (_) {}

                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SettingsScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );

                      if (context.mounted) {
                        try {
                          final controller =
                              context.read<AnimationController>();
                          if (!controller.isAnimating) controller.repeat();
                        } catch (_) {}
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
