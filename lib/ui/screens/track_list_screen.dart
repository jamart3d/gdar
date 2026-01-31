import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/screens/playback_screen.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/mini_player.dart';
import 'package:shakedown/ui/widgets/shnid_badge.dart';
import 'package:shakedown/ui/widgets/src_badge.dart';
import 'package:shakedown/ui/widgets/rating_control.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/ui/styles/app_typography.dart';
import 'package:shakedown/utils/font_layout_config.dart';

class TrackListScreen extends StatefulWidget {
  final Show show;
  final Source source;

  const TrackListScreen({
    super.key,
    required this.show,
    required this.source,
  });

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  OverlayEntry? _overlayEntry;

  // Logic identifying the current source/track is removed as requested.

  void _onTrackTapped(BuildContext itemContext, Source source, int trackIndex) {
    final audioProvider = context.read<AudioProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final isCurrentSource = audioProvider.currentSource?.id == source.id;

    // If Play on Tap is disabled, prevent switching sources by tap
    if (!isCurrentSource && !settingsProvider.playOnTap) {
      HapticFeedback.mediumImpact(); // Distinct "blocked" feedback
      _showContextualOverlay(itemContext);
      return;
    }

    HapticFeedback.selectionClick(); // Success feedback
    audioProvider.playSource(widget.show, source, initialIndex: trackIndex);
  }

  void _showContextualOverlay(BuildContext itemContext) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx + 8,
        top: offset.dy,
        width: size.width - 16,
        height: size.height,
        child: Material(
          color: Colors.transparent,
          child: Center(
            child: Container(
              height: 48, // Standard expressive pill height
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: colorScheme.onPrimaryContainer.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(
                    Icons.touch_app_outlined,
                    color: colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Play on Tap disabled',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      _overlayEntry?.remove();
                      _overlayEntry = null;

                      // Pause global clock
                      try {
                        context.read<AnimationController>().stop();
                      } catch (_) {}

                      await Navigator.of(context).push(
                        PageRouteBuilder(
                          pageBuilder:
                              (context, animation, secondaryAnimation) =>
                                  const SettingsScreen(
                            highlightSetting: 'play_on_tap',
                          ),
                          transitionDuration: Duration.zero,
                        ),
                      );

                      // Resume clock
                      if (context.mounted) {
                        try {
                          final controller =
                              context.read<AnimationController>();
                          if (!controller.isAnimating) controller.repeat();
                        } catch (_) {}
                      }
                    },
                    child: Text(
                      'SETTINGS',
                      style: textTheme.labelLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      if (_overlayEntry != null) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
  }

  Future<void> _openPlaybackScreen() async {
    final localContext = context;
    // Pause global clock
    try {
      localContext.read<AnimationController>().stop();
    } catch (_) {}

    await Navigator.of(localContext).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const PlaybackScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeInOut;
          var tween =
              Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          return SlideTransition(
              position: animation.drive(tween), child: child);
        },
      ),
    );

    // Resume clock
    if (localContext.mounted) {
      try {
        final controller = localContext.read<AnimationController>();
        if (!controller.isAnimating) controller.repeat();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final isDifferentShowPlaying = audioProvider.currentShow != null &&
        audioProvider.currentShow!.name != widget.show.name;
    final settingsProvider = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(
        // Title is empty as requested
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 56),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ValueListenableBuilder(
                      valueListenable: CatalogService().ratingsListenable,
                      builder: (context, _, __) {
                        final String ratingKey = widget.source.id;
                        final catalog = CatalogService();
                        final isPlayed = catalog.isPlayed(ratingKey);
                        final rating = catalog.getRating(ratingKey);

                        return RatingControl(
                          key: ValueKey('${ratingKey}_${rating}_$isPlayed'),
                          rating: rating,
                          size: 12 * (settingsProvider.uiScale ? 1.25 : 1.0),
                          isPlayed: isPlayed,
                          compact: true,
                          onTap: () async {
                            await showDialog(
                              context: context,
                              builder: (context) => RatingDialog(
                                initialRating: catalog.getRating(ratingKey),
                                sourceId: widget.source.id,
                                sourceUrl: widget.source.tracks.isNotEmpty
                                    ? widget.source.tracks.first.url
                                    : null,
                                isPlayed: catalog.isPlayed(ratingKey),
                                onRatingChanged: (newRating) {
                                  catalog.setRating(ratingKey, newRating);
                                },
                                onPlayedChanged: (bool newIsPlayed) {
                                  // Direct toggle since we don't have explicit setPlayed(bool) yet
                                  // or just use togglePlayed if it matches logic
                                  if (newIsPlayed !=
                                      catalog.isPlayed(ratingKey)) {
                                    catalog.togglePlayed(ratingKey);
                                  }
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                  Flexible(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.source.src != null) ...[
                          SrcBadge(
                            src: widget.source.src!,
                            matchShnidLook: true,
                          ),
                          const SizedBox(width: 4),
                        ],
                        ShnidBadge(text: widget.source.id),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            iconSize: 24 * (settingsProvider.uiScale ? 1.25 : 1.0),
            onPressed: () async {
              // Pause global clock
              try {
                context.read<AnimationController>().stop();
              } catch (_) {}

              await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SettingsScreen(),
                  transitionDuration: Duration.zero,
                ),
              );

              // Resume clock
              if (context.mounted) {
                try {
                  final controller = context.read<AnimationController>();
                  if (!controller.isAnimating) controller.repeat();
                } catch (_) {}
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          _buildBody(),
          if (isDifferentShowPlaying)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(onTap: _openPlaybackScreen),
            ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final audioProvider = context.watch<AudioProvider>();
    final isDifferentShowPlaying = audioProvider.currentShow != null &&
        audioProvider.currentShow!.name != widget.show.name;
    final bottomPadding = isDifferentShowPlaying ? 160.0 : 40.0;

    if (widget.show.sources.isEmpty) {
      return const Center(child: Text('No tracks available for this show.'));
    }

    final source = widget.source;
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    // Add Header Key
    listItems.add('SHOW_HEADER');

    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item == 'SHOW_HEADER') {
          return _buildShowHeader(context);
        } else if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          // Pass absolute index of the track in the source for playback
          final trackIndex = source.tracks.indexOf(item);
          return _buildTrackItem(context, item, source, trackIndex);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildShowHeader(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    // USE CENTRALIZED SCALING
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    String dateText = widget.show.formattedDate;
    try {
      final date = DateTime.parse(widget.show.date);
      String pattern = '';

      // Month & Day & Year
      if (settingsProvider.abbreviateMonth) {
        pattern = 'MMM d, y';
      } else {
        pattern = 'MMMM d, y';
      }

      // Day of Week
      if (settingsProvider.showDayOfWeek) {
        if (settingsProvider.abbreviateDayOfWeek) {
          pattern = 'E, $pattern';
        } else {
          pattern = 'EEEE, $pattern';
        }
      }
      dateText = DateFormat(pattern).format(date);
    } catch (_) {}

    // USE CENTRALIZED METRICS
    final metrics = AppTypography.getHeaderMetrics(settingsProvider.appFont);

    final audioProvider = context.watch<AudioProvider>();
    final bool isPlaying = audioProvider.isPlaying;

    final Widget headerContent = Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            dateText,
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: metrics.height,
                  letterSpacing: metrics.letterSpacing,
                )
                .apply(fontSizeFactor: scaleFactor),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.stadium_rounded,
                  size: 20 * scaleFactor, color: colorScheme.primary),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  widget.show.venue,
                  textAlign: TextAlign.center,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.bold,
                        letterSpacing: settingsProvider.appFont == 'rock_salt'
                            ? 1.0
                            : (settingsProvider.appFont == 'permanent_marker'
                                ? 0.5
                                : 0.0),
                      )
                      .apply(fontSizeFactor: scaleFactor),
                ),
              ),
            ],
          ),
          if (widget.show.location.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.place_outlined,
                    size: 20 * scaleFactor,
                    color: colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    widget.show.location,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .bodyLarge
                        ?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        )
                        .apply(fontSizeFactor: scaleFactor),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: isPlaying
            ? headerContent
            : InkWell(
                onLongPress: () async {
                  HapticFeedback.mediumImpact();
                  context
                      .read<AudioProvider>()
                      .playSource(widget.show, widget.source);

                  // Pause global clock
                  try {
                    context.read<AnimationController>().stop();
                  } catch (_) {}

                  await Navigator.of(context).push(
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) =>
                          const PlaybackScreen(),
                      transitionDuration: const Duration(milliseconds: 300),
                      transitionsBuilder:
                          (context, animation, secondaryAnimation, child) {
                        const begin = Offset(0.0, 1.0);
                        const end = Offset.zero;
                        const curve = Curves.easeInOut;
                        var tween = Tween(begin: begin, end: end)
                            .chain(CurveTween(curve: curve));
                        return SlideTransition(
                            position: animation.drive(tween), child: child);
                      },
                    ),
                  );

                  // Resume clock
                  if (context.mounted) {
                    try {
                      final controller = context.read<AnimationController>();
                      if (!controller.isAnimating) controller.repeat();
                    } catch (_) {}
                  }
                },
                child: headerContent,
              ),
      ),
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    // USE CENTRALIZED SCALING
    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: 16 * scaleFactor, vertical: 6 * scaleFactor),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(50),
          ),
          child: Text(
            setName.toUpperCase(),
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(
                  color: colorScheme.onSecondaryContainer,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                )
                .apply(fontSizeFactor: scaleFactor),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Track track, Source source, int index) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    // USE CENTRALIZED STYLES
    final titleStyle = AppTypography.body(context).copyWith(
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      // Color comes from Theme.bodyLarge (colorScheme.onSurface usually),
      // we can explicitly set it if needed but inherited is fine.
    );

    final durationStyle = AppTypography.tiny(context).copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: [const FontFeature.tabularFigures()],
    );

    final titleText = settingsProvider.showTrackNumbers
        ? '${track.trackNumber}. ${track.title}'
        : track.title;

    final scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Builder(builder: (context) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _onTrackTapped(context, source, index),
          child: Padding(
            padding: EdgeInsets.symmetric(
                horizontal: 20, vertical: 12 * scaleFactor),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Expanded(
                  child: Text(
                    titleText,
                    style: titleStyle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: settingsProvider.hideTrackDuration
                        ? TextAlign.center
                        : TextAlign.left,
                  ),
                ),
                if (!settingsProvider.hideTrackDuration) ...[
                  const SizedBox(width: 16),
                  Text(
                    formatDuration(Duration(seconds: track.duration)),
                    style: durationStyle,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    });
  }
}
