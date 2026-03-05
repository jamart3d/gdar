import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown/utils/app_date_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/ui/widgets/conditional_marquee.dart';
import 'package:shakedown/ui/widgets/playback/playback_controls.dart';
import 'package:shakedown/ui/widgets/playback/playback_messages.dart';
import 'package:shakedown/ui/widgets/playback/playback_progress_bar.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/ui/widgets/theme/fruit_icon_button.dart';

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
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final useNeumorphic = settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;

    final String formattedDate =
        AppDateUtils.formatDate(currentShow.date, settings: settingsProvider);

    final deviceService = context.watch<DeviceService>();
    if (deviceService.isTv) {
      return _buildTvLayout(
        context,
        currentShow,
        currentSource,
        audioProvider,
        settingsProvider,
        scaleFactor,
        formattedDate,
        onVenueTap,
      );
    }

    final panelColor = isTrueBlackMode
        ? Colors.black
        : Theme.of(context).colorScheme.surfaceContainer;

    return LiquidGlassWrapper(
        enabled: isFruit && !isTrueBlackMode,
        blur: 32.0,
        opacity: 0.90, // nice opaque frosted glass
        color: panelColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24.0)),
        child: Container(
          decoration: BoxDecoration(
            color:
                (isFruit && !isTrueBlackMode && kIsWeb && !deviceService.isTv)
                    ? Colors.transparent
                    : panelColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(24.0)),
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
                            color: colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.4),
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
                              mainAxisAlignment:
                                  settingsProvider.hideTrackDuration
                                      ? MainAxisAlignment.center
                                      : MainAxisAlignment.start,
                              children: [
                                NeumorphicWrapper(
                                  enabled: isFruit &&
                                      settingsProvider.useNeumorphism &&
                                      !settingsProvider.useTrueBlack,
                                  borderRadius: 12,
                                  intensity: 0.8,
                                  color: Colors.transparent,
                                  child: LiquidGlassWrapper(
                                    enabled: isFruit,
                                    borderRadius: BorderRadius.circular(12),
                                    opacity: 0.05,
                                    blur: 5,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 6),
                                      child: SizedBox(
                                        height:
                                            AppTypography.responsiveFontSize(
                                                    context, 18.0) *
                                                2.0,
                                        width:
                                            MediaQuery.of(context).size.width -
                                                64, // adjusted for padding
                                        child: ConditionalMarquee(
                                          text: currentShow.venue,
                                          style:
                                              textTheme.headlineSmall?.copyWith(
                                            fontSize: AppTypography
                                                .responsiveFontSize(
                                                    context, 18.0),
                                            color: colorScheme.onSurface,
                                          ),
                                          blankSpace: 60.0,
                                          pauseAfterRound:
                                              const Duration(seconds: 3),
                                          textAlign:
                                              settingsProvider.hideTrackDuration
                                                  ? TextAlign.center
                                                  : TextAlign.start,
                                        ),
                                      ),
                                    ),
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
                    // Open (1.0): -20 (Up slightly to create gap from bottom)
                    final double yOffset =
                        (100.0 - 120.0 * value) * scaleFactor;
                    return Transform.translate(
                      offset: Offset(0, yOffset),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.topCenter,
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          padding:
                              EdgeInsets.fromLTRB(16, 0, 16, 16 * scaleFactor),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Expanded(
                                    child: NeumorphicWrapper(
                                      enabled: isFruit &&
                                          settingsProvider.useNeumorphism &&
                                          !settingsProvider.useTrueBlack,
                                      borderRadius: 12,
                                      intensity: 0.8,
                                      color: Colors.transparent,
                                      child: LiquidGlassWrapper(
                                        enabled: isFruit,
                                        borderRadius: BorderRadius.circular(12),
                                        opacity: 0.05,
                                        blur: 5,
                                        child: Container(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    left: 8.0),
                                                child: Text(
                                                  currentSource.location ??
                                                      'Location N/A',
                                                  style: textTheme.titleSmall
                                                      ?.copyWith(
                                                    fontSize: AppTypography
                                                        .responsiveFontSize(
                                                            context, 16.0),
                                                    color:
                                                        colorScheme.secondary,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Row(
                                                children: [
                                                  Flexible(
                                                    child: Transform.translate(
                                                      offset:
                                                          const Offset(0, 2),
                                                      child: SizedBox(
                                                        height: AppTypography
                                                                .responsiveFontSize(
                                                                    context,
                                                                    14.0) *
                                                            2.2,
                                                        child: Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  left: 8.0,
                                                                  right: 4.0),
                                                          child:
                                                              ConditionalMarquee(
                                                            text: formattedDate,
                                                            style: textTheme
                                                                .titleMedium
                                                                ?.copyWith(
                                                              fontSize: AppTypography
                                                                  .responsiveFontSize(
                                                                      context,
                                                                      14.0),
                                                              color: colorScheme
                                                                  .onSurfaceVariant,
                                                              height: 1.2,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Builder(builder: (context) {
                                                    final Widget iconBtn =
                                                        FruitIconButton(
                                                      icon: Icon(
                                                          isFruit
                                                              ? LucideIcons.copy
                                                              : Icons
                                                                  .copy_rounded,
                                                          size: (isFruit
                                                                  ? 28
                                                                  : 20) *
                                                              scaleFactor,
                                                          color: colorScheme
                                                              .onSurfaceVariant),
                                                      padding: 0,
                                                      onPressed: () {
                                                        final track =
                                                            audioProvider
                                                                .currentTrack;
                                                        if (track == null) {
                                                          return;
                                                        }
                                                        final locationStr =
                                                            currentSource
                                                                        .location !=
                                                                    null
                                                                ? ' - ${currentSource.location}'
                                                                : '';
                                                        final urlStr = settingsProvider
                                                                .omitHttpPathInCopy
                                                            ? ''
                                                            : '\n${track.url.replaceAll('/download/', '/details/').split('/').sublist(0, 5).join('/')}';
                                                        final info =
                                                            '${currentShow.venue}$locationStr - $formattedDate - ${currentSource.id}\n${track.title}$urlStr';
                                                        Clipboard.setData(
                                                            ClipboardData(
                                                                text: info));
                                                        AppHaptics.selectionClick(
                                                            context.read<
                                                                DeviceService>());
                                                        showMessage(context,
                                                            'Details copied to clipboard');
                                                      },
                                                      tooltip: 'Copy Details',
                                                    );

                                                    if (useNeumorphic) {
                                                      return Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(
                                                                left: 6.0),
                                                        child:
                                                            NeumorphicWrapper(
                                                          isCircle: false,
                                                          borderRadius: 12.0,
                                                          intensity: 1.2,
                                                          color: Colors
                                                              .transparent,
                                                          child:
                                                              LiquidGlassWrapper(
                                                            enabled: true,
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        12.0),
                                                            opacity: 0.08,
                                                            blur: 5.0,
                                                            child: iconBtn,
                                                          ),
                                                        ),
                                                      );
                                                    }

                                                    return Padding(
                                                      padding:
                                                          const EdgeInsets.only(
                                                              left: 8.0,
                                                              bottom: 4.0),
                                                      child: iconBtn,
                                                    );
                                                  }),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
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
                                            context,
                                            currentShow,
                                            currentSource,
                                            isFruit: isFruit,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      if (currentSource.src != null)
                                        SrcBadge(
                                          src: currentSource.src!,
                                          matchShnidLook: true,
                                          scaleFactor: isFruit ? 1.4 : 1.0,
                                        ),
                                      const SizedBox(height: 4),
                                      FruitIconButton(
                                        padding: 0,
                                        onPressed: () {
                                          if (currentSource.tracks.isNotEmpty) {
                                            launchArchivePage(
                                                currentSource.tracks.first.url,
                                                context);
                                          }
                                        },
                                        icon: ShnidBadge(
                                          text: currentSource.id,
                                          showUnderline: true,
                                          scaleFactor: isFruit ? 1.4 : 1.0,
                                        ),
                                        tooltip: 'Open in Archive.org',
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              const PlaybackProgressBar(),
                              const SizedBox(height: 4),
                              ValueListenableBuilder<double>(
                                valueListenable: panelPositionNotifier,
                                builder: (context, position, _) {
                                  return PlaybackControls(
                                      panelPosition: position);
                                },
                              ),
                              if (settingsProvider.showPlaybackMessages) ...[
                                SizedBox(height: 8 * scaleFactor),
                                const PlaybackMessages(),
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
        ));
  }

  Widget _buildTvLayout(
    BuildContext context,
    Show currentShow,
    Source currentSource,
    AudioProvider audioProvider,
    SettingsProvider settingsProvider,
    double scaleFactor,
    String formattedDate,
    VoidCallback onVenueTap,
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
                  '  •  ',
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
                  '  •  ',
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

  Widget _buildRatingButton(BuildContext context, Show show, Source source,
      {bool isFruit = false}) {
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
          size: isFruit ? 32.0 : 24.0,
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
