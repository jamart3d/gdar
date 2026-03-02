import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shakedown/models/rating.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final useNeumorphic = settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    final String formattedDate =
        AppDateUtils.formatDate(currentShow.date, settings: settingsProvider);

    return AppBar(
      backgroundColor: backgroundColor.withValues(alpha: opacity),
      elevation: 0,
      scrolledUnderElevation: 0,
      automaticallyImplyLeading: false,
      leading: kIsWeb
          ? Builder(builder: (context) {
              final Widget menuBtn = IconButton(
                icon: Icon(isFruit ? LucideIcons.menu : Icons.menu_rounded),
                onPressed: () => Navigator.of(context).pop(),
                tooltip: 'Back to Show List',
              );

              if (useNeumorphic) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NeumorphicWrapper(
                    isCircle: false,
                    borderRadius: 12.0,
                    intensity: 1.2,
                    color: Colors.transparent,
                    child: LiquidGlassWrapper(
                      enabled: true,
                      borderRadius: BorderRadius.circular(12.0),
                      opacity: 0.08,
                      blur: 5.0,
                      child: menuBtn,
                    ),
                  ),
                );
              }

              return menuBtn;
            })
          : null,
      titleSpacing: kIsWeb ? 0 : 16,
      title: Opacity(
        opacity: opacity,
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
      actions: [
        // Right side items
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: opacity,
              child: Row(
                mainAxisSize: MainAxisSize.min,
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
                            onTap: opacity < 0.5
                                ? null
                                : () async {
                                    final currentRating =
                                        ratingsBox.get(ratingKey)?.rating ?? 0;
                                    await showDialog(
                                      context: context,
                                      builder: (context) => RatingDialog(
                                        initialRating: currentRating,
                                        sourceId: currentSource.id,
                                        sourceUrl:
                                            currentSource.tracks.isNotEmpty
                                                ? currentSource.tracks.first.url
                                                : null,
                                        isPlayed:
                                            historyBox.get(ratingKey) ?? false,
                                        onRatingChanged: (newRating) {
                                          CatalogService()
                                              .setRating(ratingKey, newRating);
                                        },
                                        onPlayedChanged: (bool newIsPlayed) {
                                          if (newIsPlayed !=
                                              (historyBox.get(ratingKey) ??
                                                  false)) {
                                            CatalogService()
                                                .togglePlayed(ratingKey);
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
                ],
              ),
            ),
            Builder(builder: (context) {
              final Widget btn = IconButton(
                icon: Icon(
                    isFruit ? LucideIcons.settings : Icons.settings_rounded),
                iconSize: 24.0,
                onPressed: () async {
                  try {
                    context.read<AnimationController>().stop();
                  } catch (_) {}

                  unawaited(Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const SettingsScreen(),
                      transitionDuration: Duration.zero,
                    ),
                  ));

                  if (context.mounted) {
                    try {
                      final controller = context.read<AnimationController>();
                      if (!controller.isAnimating) {
                        unawaited(controller.repeat());
                      }
                    } catch (_) {}
                  }
                },
              );

              if (useNeumorphic) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: NeumorphicWrapper(
                    isCircle: false, // Map to rounded square
                    borderRadius: 12.0,
                    intensity: 1.2,
                    color: Colors.transparent,
                    child: LiquidGlassWrapper(
                      enabled: true,
                      borderRadius: BorderRadius.circular(12.0),
                      opacity: 0.08,
                      blur: 5.0,
                      child: btn,
                    ),
                  ),
                );
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: btn,
              );
            }),
          ],
        ),
      ],
    );
  }
}
