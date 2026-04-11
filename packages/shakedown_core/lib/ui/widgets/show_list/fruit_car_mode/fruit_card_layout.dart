import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/rating_dialog.dart';
import 'package:shakedown_core/ui/widgets/show_list/card_style_utils.dart';
import 'package:shakedown_core/ui/widgets/show_list/fruit_car_mode/fruit_track_progress.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:shakedown_core/utils/app_haptics.dart';

Widget buildFruitCarModeCardContent({
  required BuildContext context,
  required Show show,
  required Source? playingSource,
  required bool isPlaying,
  required bool alwaysShowRatingInteraction,
  required VoidCallback onTap,
  required VoidCallback onLongPress,
  required Widget Function(
    BuildContext context,
    Show show,
    double effectiveScale,
    bool isTv, {
    bool tappable,
  })
  buildBadge,
  required double borderRadius,
  required Color backgroundColor,
  required CardStyle style,
  required SettingsProvider settingsProvider,
  required ColorScheme colorScheme,
}) {
  final String currentTrackTitle =
      context.select<AudioProvider, String?>(
        (audioProvider) => audioProvider.currentTrack?.title.trim(),
      ) ??
      '';
  final Source? targetSource =
      (isPlaying ? playingSource : null) ??
      (show.sources.length == 1 ? show.sources.firstOrNull : null);
  final String? ratingKey = targetSource?.id;
  final String locationText = (playingSource?.location ?? show.location).trim();
  final String? badgeSrc = targetSource?.src;
  final bool shouldShowSrcBadge = badgeSrc != null && badgeSrc.isNotEmpty;
  final bool dateFirst = settingsProvider.dateFirstInShowCard;
  final String primaryHeadline = dateFirst ? style.formattedDate : show.venue;
  final bool isCurrentCard = isPlaying;
  // Temporary web workaround: hide inline now-playing block in Fruit show list.
  final bool showTrackTitle =
      isCurrentCard && currentTrackTitle.isNotEmpty && !kIsWeb;
  final bool shnidInColumn =
      settingsProvider.showSingleShnid && style.shouldShowBadge;
  final bool badgeInFooter = style.shouldShowBadge && !shnidInColumn;
  final bool compactIdleHeight = !isCurrentCard;
  final bool forceBadgeIntoDateRowOnCompactIdle =
      compactIdleHeight &&
      !dateFirst &&
      style.shouldShowBadge &&
      !shouldShowSrcBadge;
  final bool starsOnPrimaryRow = dateFirst && ratingKey != null;
  final bool badgeOnDateRow =
      !dateFirst &&
      (shouldShowSrcBadge ||
          style.shouldShowBadge ||
          forceBadgeIntoDateRowOnCompactIdle);
  final bool controlsOnLocationRow =
      locationText.isNotEmpty &&
      (dateFirst ? (badgeInFooter || shouldShowSrcBadge) : ratingKey != null);
  final bool controlsOnPrimaryRow =
      !controlsOnLocationRow && dateFirst && badgeInFooter;
  final bool badgeOnLocationRow =
      controlsOnLocationRow && badgeInFooter && !badgeOnDateRow;
  final bool showFooterRow =
      !compactIdleHeight &&
      (showTrackTitle ||
          (badgeInFooter &&
              !badgeOnLocationRow &&
              !controlsOnPrimaryRow &&
              !badgeOnDateRow));
  final bool useCompactTextLayout = isCurrentCard && showFooterRow;
  final double currentCardBaseHeight = showFooterRow
      ? (dateFirst ? 222.0 : 232.0)
      : (dateFirst ? 168.0 : 178.0);
  final double cardHeight =
      (isPlaying ? currentCardBaseHeight : 146.0) * style.effectiveScale;
  final double horizontalPadding =
      (isCurrentCard ? 24.0 : 22.0) * style.effectiveScale;
  final double leadingPadding = isCurrentCard && dateFirst
      ? 12.0 * style.effectiveScale
      : horizontalPadding;
  final double trailingPadding = horizontalPadding;
  final double verticalPadding =
      (isCurrentCard
          ? (showFooterRow ? 20.0 : 14.0)
          : (compactIdleHeight ? (dateFirst ? 6.0 : 8.0) : 11.0)) *
      style.effectiveScale;
  final double headlineFontSize =
      (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
  final double supportingFontSize =
      (isCurrentCard ? 28.0 : 26.0) * style.effectiveScale;
  final double locationFontSize =
      (isCurrentCard ? 22.0 : 20.0) * style.effectiveScale;
  final double ratingSize =
      (isCurrentCard ? 38.0 : 36.0) * style.effectiveScale;
  final double footerRowHeight =
      (showTrackTitle ? 58.0 : 32.0) * style.effectiveScale;
  final double progressIndicatorScale = style.effectiveScale * 0.82;
  final double trackTitleFontSize =
      (isCurrentCard ? 27.0 : 25.0) * style.effectiveScale;
  final double trackBlockGap =
      (showTrackTitle ? 6.0 : 8.0) * style.effectiveScale;
  final bool shouldAllowWrappedPrimaryHeadline = !dateFirst;
  final int primaryHeadlineMaxLines = shouldAllowWrappedPrimaryHeadline
      ? 2
      : ((useCompactTextLayout || compactIdleHeight) ? 1 : 2);
  final int secondaryVenueMaxLines = isCurrentCard && dateFirst
      ? 2
      : (useCompactTextLayout ? 1 : 2);
  final double contentGap =
      (compactIdleHeight ? 5.0 : 8.0) * style.effectiveScale;
  final double metadataGap =
      (useCompactTextLayout ? 4.0 : 5.0) * style.effectiveScale;
  final double compactSupportingFontSize =
      supportingFontSize * (useCompactTextLayout ? 0.94 : 1.0);
  final double compactLocationFontSize =
      locationFontSize * (useCompactTextLayout ? 0.95 : 1.0);

  return ValueListenableBuilder(
    valueListenable: CatalogService().ratingsListenable,
    builder: (context, _, _) {
      final int rating = ratingKey != null
          ? CatalogService().getRating(ratingKey)
          : 0;
      final bool isPlayed = ratingKey != null
          ? CatalogService().isPlayed(ratingKey)
          : false;

      return LayoutBuilder(
        builder: (context, constraints) {
          final double cardWidth = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : MediaQuery.sizeOf(context).width;
          final bool constrainedIdleHeight =
              !isCurrentCard &&
              constraints.maxHeight.isFinite &&
              constraints.maxHeight <= 124.5;
          final double effectiveVerticalPadding = constrainedIdleHeight
              ? (3.0 * style.effectiveScale)
              : verticalPadding;
          final bool shiftIdleVenueFirstDown =
              !constrainedIdleHeight && !isCurrentCard && !dateFirst;
          final double effectiveTopPadding =
              effectiveVerticalPadding +
              (shiftIdleVenueFirstDown ? 3.0 * style.effectiveScale : 0.0);
          final double effectiveBottomPadding =
              (effectiveVerticalPadding -
                      (shiftIdleVenueFirstDown
                          ? 2.0 * style.effectiveScale
                          : 0.0))
                  .clamp(0.0, double.infinity);
          final double effectiveContentGap = constrainedIdleHeight
              ? (2.0 * style.effectiveScale)
              : contentGap;
          final double effectiveMetadataGap = constrainedIdleHeight
              ? (1.0 * style.effectiveScale)
              : metadataGap;
          final int effectivePrimaryHeadlineMaxLines = constrainedIdleHeight
              ? 1
              : primaryHeadlineMaxLines;
          final int effectiveSecondaryVenueMaxLines = constrainedIdleHeight
              ? 1
              : secondaryVenueMaxLines;
          final double effectiveSupportingFontSize = constrainedIdleHeight
              ? (compactSupportingFontSize * 0.9)
              : compactSupportingFontSize;
          final double effectiveLocationFontSize = constrainedIdleHeight
              ? (compactLocationFontSize * 0.9)
              : compactLocationFontSize;
          final bool abbreviateWeekday =
              settingsProvider.showDayOfWeek &&
              !settingsProvider.abbreviateDayOfWeek &&
              cardWidth < 480 &&
              cardWidth >= 420;
          final bool omitWeekday =
              settingsProvider.showDayOfWeek && cardWidth < 420;
          final String displayDate = abbreviateWeekday || omitWeekday
              ? AppDateUtils.formatDate(
                  show.date,
                  settings: settingsProvider,
                  showDayOfWeek: !omitWeekday,
                  abbreviateDayOfWeek:
                      abbreviateWeekday || settingsProvider.abbreviateDayOfWeek,
                )
              : style.formattedDate;
          final venueTextStyle = TextStyle(
            fontFamily: 'Inter',
            fontSize: effectiveSupportingFontSize,
            fontWeight: FontWeight.w800,
            height: 1.05,
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.9),
          );
          final double trailingMetaWidth = starsOnPrimaryRow
              ? (ratingSize + 12.0) * style.effectiveScale
              : (controlsOnPrimaryRow || controlsOnLocationRow)
              ? 0.0
              : (ratingKey != null || shouldShowSrcBadge)
              ? ((ratingSize + 16.0 + 72.0) * style.effectiveScale)
              : 0.0;

          Widget buildTrailingControls({required bool inline}) {
            final List<Widget> children = [
              if (ratingKey != null && !starsOnPrimaryRow)
                RatingControl(
                  rating: rating,
                  isPlayed: isPlayed,
                  size: ratingSize,
                  compact: true,
                  enforceMinTapTarget: true,
                  onTap:
                      (isPlaying ||
                          alwaysShowRatingInteraction ||
                          show.sources.length == 1)
                      ? () async {
                          await showDialog(
                            context: context,
                            builder: (context) => RatingDialog(
                              initialRating: rating,
                              sourceId: ratingKey,
                              sourceUrl: targetSource?.tracks.firstOrNull?.url,
                              isPlayed: isPlayed,
                              onRatingChanged: (newRating) {
                                CatalogService().setRating(
                                  ratingKey,
                                  newRating,
                                );
                              },
                              onPlayedChanged: (newIsPlayed) {
                                if (newIsPlayed !=
                                    CatalogService().isPlayed(ratingKey)) {
                                  CatalogService().togglePlayed(ratingKey);
                                }
                              },
                            ),
                          );
                        }
                      : null,
                ),
              if (ratingKey != null &&
                  !starsOnPrimaryRow &&
                  shouldShowSrcBadge &&
                  !badgeOnDateRow)
                inline
                    ? SizedBox(width: 8 * style.effectiveScale)
                    : SizedBox(height: 8 * style.effectiveScale),
              if (shouldShowSrcBadge && !badgeOnDateRow)
                SrcBadge(
                  src: badgeSrc,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  padding: EdgeInsets.symmetric(
                    horizontal: 10 * style.effectiveScale,
                    vertical: 4 * style.effectiveScale,
                  ),
                  scaleFactor: style.effectiveScale,
                ),
              if (shnidInColumn && !badgeOnDateRow) ...[
                inline
                    ? SizedBox(width: 6 * style.effectiveScale)
                    : SizedBox(height: 6 * style.effectiveScale),
                buildBadge(context, show, style.effectiveScale * 1.1, false),
              ],
              if (badgeInFooter && !shnidInColumn && !badgeOnDateRow) ...[
                inline
                    ? SizedBox(width: 8 * style.effectiveScale)
                    : SizedBox(height: 8 * style.effectiveScale),
                buildBadge(context, show, style.effectiveScale * 1.1, false),
              ],
            ];

            return inline
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: children,
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: children,
                  );
          }

          final double primaryHeadlineWrapExtraHeight =
              shouldAllowWrappedPrimaryHeadline
              ? _measureWrappedTextExtraHeight(
                  text: primaryHeadline,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: headlineFontSize,
                    fontWeight: FontWeight.w900,
                    height: 0.95,
                    letterSpacing: -0.8,
                  ),
                  maxWidth:
                      cardWidth -
                      leadingPadding -
                      trailingPadding -
                      trailingMetaWidth,
                  maxLines: effectivePrimaryHeadlineMaxLines,
                  scaleFactor: style.effectiveScale,
                )
              : 0.0;
          final double venueWrapExtraHeight = isCurrentCard && dateFirst
              ? _measureWrappedTextExtraHeight(
                  text: show.venue,
                  style: venueTextStyle,
                  maxWidth: cardWidth - leadingPadding - trailingPadding,
                  maxLines: effectiveSecondaryVenueMaxLines,
                  scaleFactor: style.effectiveScale,
                )
              : 0.0;
          final double resolvedCardHeight =
              cardHeight +
              (constrainedIdleHeight ? 0.0 : primaryHeadlineWrapExtraHeight) +
              (isCurrentCard ? venueWrapExtraHeight : 0.0);

          return Container(
            key: const ValueKey('fruit_show_list_car_mode_card'),
            height: resolvedCardHeight,
            constraints: BoxConstraints(minHeight: cardHeight),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              color: backgroundColor,
            ),
            child: Material(
              color: const Color(0x00000000),
              child: InkWell(
                canRequestFocus: true,
                borderRadius: BorderRadius.circular(borderRadius),
                onTap: () {
                  AppHaptics.selectionClick(context.read<DeviceService>());
                  onTap();
                },
                onLongPress: onLongPress,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    leadingPadding,
                    effectiveTopPadding,
                    trailingPadding,
                    effectiveBottomPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              dateFirst ? displayDate : primaryHeadline,
                              maxLines: effectivePrimaryHeadlineMaxLines,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Inter',
                                fontSize: headlineFontSize,
                                fontWeight: FontWeight.w900,
                                height: 0.95,
                                letterSpacing: -0.8,
                                color: colorScheme.onSurface,
                              ),
                            ),
                          ),
                          if (starsOnPrimaryRow) ...[
                            SizedBox(width: 12 * style.effectiveScale),
                            RatingControl(
                              rating: rating,
                              isPlayed: isPlayed,
                              size: ratingSize,
                              compact: true,
                              enforceMinTapTarget: true,
                              onTap:
                                  (isPlaying ||
                                      alwaysShowRatingInteraction ||
                                      show.sources.length == 1)
                                  ? () async {
                                      await showDialog(
                                        context: context,
                                        builder: (context) => RatingDialog(
                                          initialRating: rating,
                                          sourceId: ratingKey,
                                          sourceUrl: targetSource
                                              ?.tracks
                                              .firstOrNull
                                              ?.url,
                                          isPlayed: isPlayed,
                                          onRatingChanged: (newRating) {
                                            CatalogService().setRating(
                                              ratingKey,
                                              newRating,
                                            );
                                          },
                                          onPlayedChanged: (newIsPlayed) {
                                            if (newIsPlayed !=
                                                CatalogService().isPlayed(
                                                  ratingKey,
                                                )) {
                                              CatalogService().togglePlayed(
                                                ratingKey,
                                              );
                                            }
                                          },
                                        ),
                                      );
                                    }
                                  : null,
                            ),
                          ],
                          if (controlsOnPrimaryRow) ...[
                            SizedBox(width: 12 * style.effectiveScale),
                            buildTrailingControls(inline: true),
                          ],
                          if (!controlsOnLocationRow &&
                              !controlsOnPrimaryRow &&
                              !starsOnPrimaryRow &&
                              (ratingKey != null ||
                                  shouldShowSrcBadge ||
                                  shnidInColumn)) ...[
                            SizedBox(width: 16 * style.effectiveScale),
                            buildTrailingControls(inline: false),
                          ],
                        ],
                      ),
                      SizedBox(height: effectiveContentGap),
                      if (dateFirst) ...[
                        Text(
                          show.venue,
                          maxLines: effectiveSecondaryVenueMaxLines,
                          overflow: TextOverflow.ellipsis,
                          style: venueTextStyle,
                        ),
                        SizedBox(height: effectiveMetadataGap),
                      ],
                      if (locationText.isNotEmpty) ...[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: effectiveLocationFontSize,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.88),
                                ),
                              ),
                            ),
                            if (controlsOnLocationRow) ...[
                              SizedBox(width: 12 * style.effectiveScale),
                              buildTrailingControls(inline: true),
                            ],
                          ],
                        ),
                        SizedBox(height: effectiveMetadataGap),
                      ],
                      if (!dateFirst)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Text(
                                displayDate,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: effectiveSupportingFontSize,
                                  fontWeight: FontWeight.w800,
                                  height: 1.1,
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.74),
                                ),
                              ),
                            ),
                            if (badgeOnDateRow) ...[
                              SizedBox(width: 8 * style.effectiveScale),
                              if (shouldShowSrcBadge)
                                SrcBadge(
                                  src: badgeSrc,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 10 * style.effectiveScale,
                                    vertical: 4 * style.effectiveScale,
                                  ),
                                  scaleFactor: style.effectiveScale,
                                )
                              else if (style.shouldShowBadge)
                                buildBadge(
                                  context,
                                  show,
                                  style.effectiveScale * 1.1,
                                  false,
                                ),
                              if (shouldShowSrcBadge &&
                                  shnidInColumn &&
                                  style.shouldShowBadge) ...[
                                SizedBox(width: 8 * style.effectiveScale),
                                buildBadge(
                                  context,
                                  show,
                                  style.effectiveScale * 1.1,
                                  false,
                                ),
                              ],
                            ],
                          ],
                        ),
                      if (showFooterRow) ...[
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (badgeInFooter && !badgeOnLocationRow)
                              buildBadge(
                                context,
                                show,
                                style.effectiveScale * 1.1,
                                false,
                              ),
                            SizedBox(
                              width: badgeInFooter
                                  ? 12 * style.effectiveScale
                                  : 0,
                            ),
                            if (showTrackTitle)
                              Expanded(
                                child: SizedBox(
                                  height: footerRowHeight,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 32 * style.effectiveScale,
                                        child: Align(
                                          alignment: Alignment.centerLeft,
                                          child: ConditionalMarquee(
                                            key: ValueKey(currentTrackTitle),
                                            text: currentTrackTitle,
                                            enableAnimation:
                                                settingsProvider.marqueeEnabled,
                                            velocity: 44.0,
                                            blankSpace: 56.0,
                                            pauseAfterRound: const Duration(
                                              milliseconds: 1000,
                                            ),
                                            fadingEdgeStartFraction: 0.02,
                                            fadingEdgeEndFraction: 0.08,
                                            style: TextStyle(
                                              fontFamily: 'Inter',
                                              fontSize: trackTitleFontSize,
                                              fontWeight: FontWeight.w900,
                                              height: 0.96,
                                              letterSpacing: -0.8,
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      ),
                                      SizedBox(height: trackBlockGap),
                                      FruitCarModeTrackProgress(
                                        colorScheme: colorScheme,
                                        scaleFactor: progressIndicatorScale,
                                        glassEnabled: settingsProvider
                                            .fruitEnableLiquidGlass,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      );
    },
  );
}

double _measureWrappedTextExtraHeight({
  required String text,
  required TextStyle style,
  required double maxWidth,
  required int maxLines,
  required double scaleFactor,
}) {
  if (text.isEmpty || maxLines <= 1 || maxWidth <= 0) {
    return 0;
  }

  final painter = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    maxLines: maxLines,
  )..layout(maxWidth: maxWidth);

  final int lineCount = painter.computeLineMetrics().length;
  if (lineCount <= 1) {
    return 0;
  }

  final double lineHeight = (style.fontSize ?? 0) * (style.height ?? 1.0);
  return ((lineCount - 1) * lineHeight) + (2 * scaleFactor);
}
