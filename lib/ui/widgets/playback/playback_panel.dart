import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:shakedown/ui/widgets/playback/playback_controls.dart';
import 'package:shakedown/ui/widgets/playback/playback_progress_bar.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';

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
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

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

    final deviceService = context.watch<DeviceService>();
    if (deviceService.isTv) {
      return _buildTvLayout(
        context,
        audioProvider,
        settingsProvider,
        scaleFactor,
        formattedDate,
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: isTrueBlackMode
            ? const BorderRadius.only(
                topLeft: Radius.circular(24.0),
                topRight: Radius.circular(24.0),
              )
            : null,
        border: isTrueBlackMode
            ? Border.all(
                color: colorScheme.onSurface.withValues(alpha: 0.2),
                width: 1.0,
              )
            : null,
      ),
      child: Column(
        children: [
          SizedBox(
            height: minHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 32,
                      height: 4,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ],
                ),
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomCenter,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: onVenueTap,
                      child: Padding(
                        padding: EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            bottom: 24.0 + bottomPadding),
                        child: Row(
                          mainAxisAlignment: settingsProvider.hideTrackDuration
                              ? MainAxisAlignment.center
                              : MainAxisAlignment.start,
                          children: [
                            SizedBox(
                              height: AppTypography.responsiveFontSize(
                                      context, 18.0) *
                                  2.0,
                              width: MediaQuery.of(context).size.width -
                                  32, // explicit width for marquee in fitted box
                              child: ConditionalMarquee(
                                text: currentShow.venue,
                                style: textTheme.headlineSmall?.copyWith(
                                  fontSize: AppTypography.responsiveFontSize(
                                      context, 18.0),
                                  color: colorScheme.onSurface,
                                ),
                                blankSpace: 60.0,
                                pauseAfterRound: const Duration(seconds: 3),
                                textAlign: settingsProvider.hideTrackDuration
                                    ? TextAlign.center
                                    : TextAlign.start,
                              ),
                            ),
                            if (!settingsProvider.hideTrackDuration)
                              const SizedBox(width: 8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<double>(
              valueListenable: panelPositionNotifier,
              builder: (context, value, child) {
                // Closed (0.0): +100 (Hidden down)
                // Open (1.0): -40 (Up more to create gap from bottom)
                final double yOffset = (100.0 - 124.0 * value) * scaleFactor;
                return Transform.translate(
                  offset: Offset(0, yOffset),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.topCenter,
                    child: Container(
                      width: MediaQuery.of(context).size.width,
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 16 * scaleFactor),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Align(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        currentSource.location ??
                                            'Location N/A',
                                        style: textTheme.titleSmall?.copyWith(
                                          fontSize:
                                              AppTypography.responsiveFontSize(
                                                  context, 16.0),
                                          color: colorScheme.secondary,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Transform.translate(
                                            offset: const Offset(0, 2),
                                            child: SizedBox(
                                              height: AppTypography
                                                      .responsiveFontSize(
                                                          context, 14.0) *
                                                  2.2,
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 4.0),
                                                child: ConditionalMarquee(
                                                  text: formattedDate,
                                                  style: textTheme.titleMedium
                                                      ?.copyWith(
                                                    fontSize: AppTypography
                                                        .responsiveFontSize(
                                                            context, 14.0),
                                                    color: colorScheme
                                                        .onSurfaceVariant,
                                                    height: 1.2,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        IconButton(
                                          constraints: const BoxConstraints(),
                                          padding:
                                              const EdgeInsets.only(left: 8),
                                          icon: Icon(Icons.copy_rounded,
                                              size: 20 * scaleFactor,
                                              color:
                                                  colorScheme.onSurfaceVariant),
                                          onPressed: () {
                                            final track = currentSource.tracks[
                                                audioProvider.audioPlayer
                                                        .currentIndex ??
                                                    0];
                                            final locationStr = currentSource
                                                        .location !=
                                                    null
                                                ? " - ${currentSource.location}"
                                                : "";
                                            final info =
                                                "${currentShow.venue}$locationStr - $formattedDate - ${currentSource.id}\n${track.title}\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}";
                                            Clipboard.setData(
                                                ClipboardData(text: info));
                                            HapticFeedback.selectionClick();
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              SnackBar(
                                                content: Row(
                                                  children: [
                                                    Icon(
                                                      Icons
                                                          .check_circle_outline_rounded,
                                                      color: colorScheme
                                                          .onPrimaryContainer,
                                                      size: 20 * scaleFactor,
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Text(
                                                        'Details copied to clipboard',
                                                        style: textTheme
                                                            .labelLarge
                                                            ?.copyWith(
                                                          color: colorScheme
                                                              .onPrimaryContainer,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                behavior:
                                                    SnackBarBehavior.floating,
                                                backgroundColor: colorScheme
                                                    .primaryContainer,
                                                elevation: 4,
                                                duration: const Duration(
                                                    milliseconds: 1500),
                                                margin: EdgeInsets.only(
                                                  bottom:
                                                      (MediaQuery.of(context)
                                                                  .size
                                                                  .height *
                                                              (settingsProvider
                                                                      .uiScale
                                                                  ? 0.45
                                                                  : 0.40)) -
                                                          minHeight +
                                                          (75 * scaleFactor),
                                                  left: 48,
                                                  right: 48,
                                                ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          100),
                                                  side: BorderSide(
                                                    color: colorScheme
                                                        .onPrimaryContainer
                                                        .withValues(alpha: 0.1),
                                                    width: 1,
                                                  ),
                                                ),
                                              ),
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Rating Stars
                                  ConstrainedBox(
                                    constraints: const BoxConstraints(
                                        minWidth: 48, minHeight: 48),
                                    child: Center(
                                      child: _buildRatingButton(
                                          context, currentShow, currentSource),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  if (currentSource.src != null)
                                    SrcBadge(
                                      src: currentSource.src!,
                                      matchShnidLook: true,
                                    ),
                                  const SizedBox(height: 4),
                                  InkWell(
                                    onTap: () {
                                      if (currentSource.tracks.isNotEmpty) {
                                        launchArchivePage(
                                            currentSource.tracks.first.url,
                                            context);
                                      }
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: ShnidBadge(
                                      text: currentSource.id,
                                      showUnderline: true,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          const PlaybackProgressBar(),
                          const SizedBox(height: 8),
                          ValueListenableBuilder<double>(
                            valueListenable: panelPositionNotifier,
                            builder: (context, position, _) {
                              return PlaybackControls(panelPosition: position);
                            },
                          ),
                          if (settingsProvider.showPlaybackMessages) ...[
                            SizedBox(height: 12 * scaleFactor),
                            _buildStatusMessages(context, audioProvider),
                          ],
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

  Widget _buildTvLayout(
    BuildContext context,
    AudioProvider audioProvider,
    SettingsProvider settingsProvider,
    double scaleFactor,
    String formattedDate,
  ) {
    final track = audioProvider.currentTrack;
    if (track == null) return const SizedBox.shrink();

    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 1. Current Track Title (Hero)
          SizedBox(
            height: AppTypography.responsiveFontSize(context, 28.0) * 1.5,
            child: ConditionalMarquee(
              text: track.title,
              style: textTheme.headlineMedium?.copyWith(
                fontSize: AppTypography.responsiveFontSize(context, 28.0),
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // 2. Metadata Row: Venue | Location | Date
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.stadium_rounded,
                      size: 20,
                      color: colorScheme.secondary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentShow.venue,
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                Text(
                  "  •  ",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 20,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      currentSource.location ?? 'N/A',
                      style: textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                Text(
                  "  •  ",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  ),
                ),
                Text(
                  formattedDate,
                  style: textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 3. Progress Bar
          const PlaybackProgressBar(),
          const SizedBox(height: 16),
          // 4. Controls
          const PlaybackControls(panelPosition: 1.0),
        ],
      ),
    );
  }

  Widget _buildStatusMessages(
      BuildContext context, AudioProvider audioProvider) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.read<SettingsProvider>();
    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final double labelsFontSize = 12.0 * scaleFactor;

    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      initialData: audioProvider.audioPlayer.playerState,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        String statusText = '';
        if (processingState == ProcessingState.loading) {
          statusText = 'Loading...';
        } else if (processingState == ProcessingState.buffering) {
          statusText = 'Buffering...';
        } else if (processingState == ProcessingState.ready) {
          statusText = playing ? 'Playing' : 'Paused';
        } else if (processingState == ProcessingState.completed) {
          statusText = 'Completed';
        }

        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              statusText,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
                fontSize: labelsFontSize,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '•',
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
                fontSize: labelsFontSize,
              ),
            ),
            const SizedBox(width: 8),
            StreamBuilder<Duration>(
              stream: audioProvider.bufferedPositionStream,
              initialData: audioProvider.audioPlayer.bufferedPosition,
              builder: (context, bufferedSnapshot) {
                final buffered = bufferedSnapshot.data ?? Duration.zero;
                return Text(
                  'Buffered: ${formatDuration(buffered)}',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: labelsFontSize,
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  Widget _buildRatingButton(BuildContext context, Show show, Source source) {
    final String ratingKey = source.id;

    return ValueListenableBuilder(
      valueListenable: CatalogService().ratingsListenable,
      builder: (context, _, __) {
        final catalog = CatalogService();
        final rating = catalog.getRating(ratingKey);
        final isPlayed = catalog.isPlayed(ratingKey);

        return RatingControl(
          rating: rating,
          isPlayed: isPlayed,
          size: 24.0,
          onTap: () async {
            await showDialog(
              context: context,
              builder: (context) => RatingDialog(
                initialRating: rating,
                sourceId: source.id,
                sourceUrl:
                    source.tracks.isNotEmpty ? source.tracks.first.url : null,
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
}
