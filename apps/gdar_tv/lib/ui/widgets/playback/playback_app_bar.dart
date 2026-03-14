import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:gdar_tv/ui/screens/settings_screen.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_icon_button.dart';
import 'package:gdar_tv/ui/styles/app_typography.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'package:shakedown_core/models/rating.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:gdar_tv/ui/widgets/rating_control.dart';
import 'package:gdar_tv/ui/widgets/shnid_badge.dart';
import 'package:gdar_tv/ui/widgets/src_badge.dart';
import 'package:gdar_tv/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';

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
    final isTv = context.watch<DeviceService>().isTv;
    final isFruit = themeProvider.isFruit;
    final useNeumorphic = settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    final String formattedDate =
        AppDateUtils.formatDate(currentShow.date, settings: settingsProvider);

    final double actionPadding = kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0;

    return AppBar(
      backgroundColor: backgroundColor.withValues(alpha: opacity),
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: kIsWeb
          ? Builder(builder: (context) {
              final Widget menuBtn = isFruit
                  ? FruitIconButton(
                      icon: const Icon(LucideIcons.chevronLeft),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to Show List',
                      padding: 0,
                    )
                  : IconButton(
                      icon: const Icon(Icons.chevron_left_rounded),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to Show List',
                    );

              if (useNeumorphic && !isTv) {
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: NeumorphicWrapper(
                    isCircle: false,
                    borderRadius: 12.0,
                    intensity: 1.2,
                    color: Colors.transparent,
                    child: LiquidGlassWrapper(
                      enabled: !isTv,
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
          : null, // Let Flutter provide the back button on mobile.
      titleSpacing: kIsWeb ? 0 : 4,
      title: Opacity(
        opacity: opacity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              formattedDate,
              style: TextStyle(
                fontSize: AppTypography.responsiveFontSize(context, 14),
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                height: 1.1,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
      actions: [
        Opacity(
          opacity: opacity,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: actionPadding),
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
                                      sourceUrl: currentSource.tracks.isNotEmpty
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
                    ShnidBadge(
                      text: currentSource.id,
                      onTap: () {
                        if (currentSource.tracks.isNotEmpty) {
                          launchArchivePage(
                              currentSource.tracks.first.url, context);
                        } else {
                          launchArchiveDetails(currentSource.id, context);
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Builder(builder: (context) {
          Future<void> onSettingsPressed() async {
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
          }

          final Widget btn = isFruit
              ? FruitIconButton(
                  icon: const Icon(LucideIcons.settings),
                  size: 24.0,
                  padding: 0,
                  onPressed: onSettingsPressed,
                  tooltip: 'Settings',
                )
              : IconButton(
                  icon: const Icon(Icons.settings_rounded),
                  iconSize: 24.0,
                  onPressed: onSettingsPressed,
                  tooltip: 'Settings',
                );

          return Padding(
            padding: EdgeInsets.symmetric(horizontal: actionPadding),
            child: (useNeumorphic && !isTv)
                ? NeumorphicWrapper(
                    isCircle: false,
                    borderRadius: 12.0,
                    intensity: 1.2,
                    color: Colors.transparent,
                    child: LiquidGlassWrapper(
                      enabled: !isTv,
                      borderRadius: BorderRadius.circular(12.0),
                      opacity: 0.08,
                      blur: 5.0,
                      child: btn,
                    ),
                  )
                : btn,
          );
        }),
      ],
    );
  }
}
