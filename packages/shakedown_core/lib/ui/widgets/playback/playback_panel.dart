import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown_core/utils/app_date_utils.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/styles/app_typography.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/widgets/conditional_marquee.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_controls.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_messages.dart';
import 'package:shakedown_core/ui/widgets/playback/playback_progress_bar.dart';
import 'package:shakedown_core/ui/widgets/rating_control.dart';
import 'package:shakedown_core/ui/widgets/shnid_badge.dart';
import 'package:shakedown_core/ui/widgets/src_badge.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/utils/utils.dart';

class PlaybackPanel extends StatelessWidget {
  final Show currentShow;
  final Source currentSource;
  final double minHeight;
  final double bottomPadding;
  final ValueNotifier<double> panelPositionNotifier;
  final VoidCallback onVenueTap;

  const PlaybackPanel({
    super.key,
    required this.currentShow,
    required this.currentSource,
    required this.minHeight,
    required this.bottomPadding,
    required this.panelPositionNotifier,
    required this.onVenueTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    final scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final String formattedDate = AppDateUtils.formatDate(
      currentShow.date,
      settings: settingsProvider,
    );

    final panelColor = isTrueBlackMode
        ? Colors.black
        : colorScheme.surfaceContainer;

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        border: isTrueBlackMode
            ? Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1.0,
              )
            : null,
      ),
      child: Column(
        children: [
          // ── HANDLE & VENUE HEADER ──
          SizedBox(
            height: minHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 6),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color: colorScheme.onSurfaceVariant.withValues(
                          alpha: isTrueBlackMode ? 0.22 : 0.4,
                        ),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                ValueListenableBuilder<double>(
                  valueListenable: panelPositionNotifier,
                  builder: (context, position, _) {
                    // Provide a comfortable gap that scales with the panel state
                    // iPhone/Phone gets a tighter gap (8-12) than Web (12-20)
                    const double baseGap = kIsWeb ? 12.0 : 8.0;
                    const double openExtra = kIsWeb ? 8.0 : 4.0;
                    return SizedBox(height: baseGap + (openExtra * position));
                  },
                ),
                ValueListenableBuilder<double>(
                  valueListenable: panelPositionNotifier,
                  builder: (context, position, _) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onVenueTap,
                      child: Padding(
                        padding: EdgeInsets.only(
                          left: 12.0,
                          right: 12.0,
                          bottom: 4.0 + (bottomPadding * (1.0 - position)),
                        ),
                        child: SizedBox(
                          height:
                              AppTypography.responsiveFontSize(context, 22.0) *
                              2.4,
                          width: double.infinity,
                          child: ConditionalMarquee(
                            text: currentShow.venue,
                            style: textTheme.headlineSmall?.copyWith(
                              fontSize: AppTypography.responsiveFontSize(
                                context,
                                22.0,
                              ),
                              color: colorScheme.onSurface,
                            ),
                            blankSpace: 60.0,
                            pauseAfterRound: const Duration(seconds: 3),
                            textAlign: settingsProvider.hideTrackDuration
                                ? TextAlign.center
                                : TextAlign.start,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // ── EXPANDED CONTENT ──
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: panelPositionNotifier,
              builder: (context, value, child) {
                // Resting position (value=1.0) is tighter on Phone (-24) than Web (-12)
                const double restingOffset = kIsWeb ? -12.0 : -24.0;
                const double startOffset = 80.0;
                final double yOffset =
                    (startOffset + (restingOffset - startOffset) * value) *
                    scaleFactor;

                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: SingleChildScrollView(
                    physics: const ClampingScrollPhysics(),
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 12 * scaleFactor),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ── METADATA BOX (Location, Date, ID) ──
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                              vertical: 4.0,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // 1. LOCATION LINE
                                      () {
                                        final double locScore =
                                            (currentSource.location?.length ??
                                                0) *
                                            18.0;
                                        final double dateScore =
                                            formattedDate.length * 14.0;
                                        final bool isLocShorter =
                                            currentSource.location != null &&
                                            locScore < dateScore;

                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Padding(
                                                padding: const EdgeInsets.only(
                                                  left: 2.0,
                                                  right: 2.0,
                                                ),
                                                child: Text(
                                                  currentSource.location ?? '',
                                                  style: textTheme.titleSmall
                                                      ?.copyWith(
                                                        fontSize:
                                                            AppTypography.responsiveFontSize(
                                                              context,
                                                              18.0,
                                                            ),
                                                        color: colorScheme
                                                            .secondary,
                                                        fontWeight:
                                                            FontWeight.w500,
                                                      ),
                                                  maxLines: 1,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ),
                                            if (isLocShorter) ...[
                                              const SizedBox(
                                                width: kIsWeb ? 13 : 8,
                                              ),
                                              _buildCopyButton(
                                                context,
                                                audioProvider,
                                                settingsProvider,
                                                currentShow,
                                                currentSource,
                                                formattedDate,
                                                scaleFactor,
                                                1.6,
                                              ),
                                            ],
                                          ],
                                        );
                                      }(),
                                      const SizedBox(height: 2),
                                      // 2. DATE LINE
                                      () {
                                        final double locScore =
                                            (currentSource.location?.length ??
                                                0) *
                                            18.0;
                                        final double dateScore =
                                            formattedDate.length * 14.0;
                                        final bool isDateShorter =
                                            currentSource.location == null ||
                                            locScore >= dateScore;

                                        return Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Flexible(
                                              child: Transform.translate(
                                                offset: const Offset(0, 2),
                                                child: SizedBox(
                                                  height:
                                                      AppTypography.responsiveFontSize(
                                                        context,
                                                        14.0,
                                                      ) *
                                                      2.8,
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.only(
                                                          left: 4.0,
                                                          right: 4.0,
                                                        ),
                                                    child: ConditionalMarquee(
                                                      text: formattedDate,
                                                      style: textTheme
                                                          .titleMedium
                                                          ?.copyWith(
                                                            fontSize:
                                                                AppTypography.responsiveFontSize(
                                                                  context,
                                                                  14.0,
                                                                ),
                                                            color: colorScheme
                                                                .onSurfaceVariant,
                                                            height: 1.2,
                                                          ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                            if (isDateShorter) ...[
                                              const SizedBox(width: 10),
                                              _buildCopyButton(
                                                context,
                                                audioProvider,
                                                settingsProvider,
                                                currentShow,
                                                currentSource,
                                                formattedDate,
                                                scaleFactor,
                                                2.0,
                                              ),
                                            ],
                                          ],
                                        );
                                      }(),
                                    ],
                                  ),
                                ),
                                SizedBox(
                                  height: 48,
                                  child: VerticalDivider(
                                    width: 16,
                                    thickness: 1,
                                    color: colorScheme.onSurface.withValues(
                                      alpha: 0.1,
                                    ),
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _buildRatingButton(
                                      context,
                                      currentShow,
                                      currentSource,
                                    ),
                                    const SizedBox(height: 2),
                                    if (currentSource.src != null) ...[
                                      SrcBadge(
                                        src: currentSource.src!,
                                        matchShnidLook: true,
                                        scaleFactor: scaleFactor,
                                      ),
                                      const SizedBox(height: 2),
                                    ],
                                    GestureDetector(
                                      onTap: () {
                                        if (currentSource.tracks.isNotEmpty) {
                                          launchArchivePage(
                                            currentSource.tracks.first.url,
                                            context,
                                          );
                                        }
                                      },
                                      child: ShnidBadge(
                                        text: currentSource.id,
                                        showUnderline: true,
                                        scaleFactor: scaleFactor,
                                        interactive: false,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 4),
                          const PlaybackProgressBar(),
                          if (kIsWeb && settingsProvider.showDevAudioHud) ...[
                            SizedBox(height: 8 * scaleFactor),
                            const PlaybackMessages(
                              textAlign: TextAlign.center,
                              showDivider: false,
                              showStatusLine: false,
                              compactDevHud: true,
                            ),
                          ],
                          const SizedBox(height: 12),
                          ValueListenableBuilder<double>(
                            valueListenable: panelPositionNotifier,
                            builder: (context, position, _) {
                              return PlaybackControls(panelPosition: position);
                            },
                          ),
                          SizedBox(height: 8 * scaleFactor),
                          const Align(
                            alignment: Alignment.center,
                            child: PlaybackMessages(
                              textAlign: TextAlign.center,
                              showDevHudInline: false,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingButton(BuildContext context, Show show, Source source) {
    final String ratingKey = source.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, _) {
        final catalog = CatalogService();
        final rating = catalog.getRating(ratingKey);
        final isPlayed = catalog.isPlayed(ratingKey);

        return RatingControl(
          rating: rating,
          isPlayed: isPlayed,
          size: 26.0,
          compact: true,
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => RatingDialog(
                initialRating: rating,
                sourceId: source.id,
                sourceUrl: source.tracks.isNotEmpty
                    ? source.tracks.first.url
                    : null,
                isPlayed: isPlayed,
                onRatingChanged: (newRating) {
                  catalog.setRating(ratingKey, newRating);
                },
                onPlayedChanged: (bool newIsPlayed) {
                  if (newIsPlayed != catalog.isPlayed(ratingKey)) {
                    catalog.togglePlayed(ratingKey);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCopyButton(
    BuildContext context,
    AudioProvider audioProvider,
    SettingsProvider settingsProvider,
    dynamic currentShow,
    dynamic currentSource,
    String formattedDate,
    double scaleFactor,
    double scale,
  ) {
    return Transform.scale(
      scale: scale,
      child: IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.copy_rounded),
        iconSize: 20 * scaleFactor,
        onPressed: () {
          final track = audioProvider.currentTrack;
          if (track == null) return;
          final locationStr = currentSource.location != null
              ? ' - ${currentSource.location}'
              : '';
          final urlStr = settingsProvider.omitHttpPathInCopy
              ? ''
              : '\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}';
          final info =
              '${currentShow.venue}$locationStr - $formattedDate - ${currentSource.id}\n${track.title}$urlStr';
          Clipboard.setData(ClipboardData(text: info));
          AppHaptics.selectionClick(context.read<DeviceService>());
          showMessage(context, 'Details copied to clipboard');
        },
        tooltip: 'Copy Details',
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
      ),
    );
  }
}
