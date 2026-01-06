import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/screens/playback_screen.dart';
import 'package:gdar/ui/screens/settings_screen.dart';
import 'package:gdar/ui/widgets/mini_player.dart';
import 'package:gdar/ui/widgets/src_badge.dart';
import 'package:gdar/ui/widgets/rating_control.dart';
import 'package:gdar/utils/utils.dart';
import 'package:provider/provider.dart';

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
      _showContextualOverlay(itemContext);
      return;
    }

    audioProvider.playSource(widget.show, source, initialIndex: trackIndex);
  }

  void _showContextualOverlay(BuildContext itemContext) {
    _overlayEntry?.remove();
    _overlayEntry = null;

    final renderBox = itemContext.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final size = renderBox.size;
    final offset = renderBox.localToGlobal(Offset.zero);

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: offset.dx,
        top: offset.dy,
        width: size.width,
        height: size.height,
        child: Material(
          color: Colors.transparent,
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.inverseSurface,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Play on Tap disabled',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onInverseSurface,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    _overlayEntry?.remove();
                    _overlayEntry = null;
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                  child: Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
    Future.delayed(const Duration(seconds: 3), () {
      _overlayEntry?.remove();
      _overlayEntry = null;
    });
  }

  void _openPlaybackScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PlaybackScreen()),
    );
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    final String ratingKey = widget.source.id;
                    final isPlayed = settings.isPlayed(ratingKey);

                    return RatingControl(
                      key: ValueKey(
                          '${ratingKey}_${settings.getRating(ratingKey)}_$isPlayed'),
                      rating: settings.getRating(ratingKey),
                      size: 16 * (settings.uiScale ? 1.25 : 1.0),
                      isPlayed: isPlayed,
                      onTap: () async {
                        final currentRating = settings.getRating(ratingKey);
                        await showDialog(
                          context: context,
                          builder: (context) => RatingDialog(
                            initialRating: currentRating,
                            sourceId: widget.source.id,
                            sourceUrl: widget.source.tracks.isNotEmpty
                                ? widget.source.tracks.first.url
                                : null,
                            isPlayed: settings.isPlayed(ratingKey),
                            onRatingChanged: (newRating) {
                              settings.setRating(ratingKey, newRating);
                            },
                            onPlayedChanged: (bool newIsPlayed) {
                              if (newIsPlayed != settings.isPlayed(ratingKey)) {
                                settings.togglePlayed(ratingKey);
                              }
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.source.src != null) ...[
                      SrcBadge(src: widget.source.src!),
                      const SizedBox(width: 4),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .secondaryContainer
                            .withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.source.id,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSecondaryContainer,
                              fontSize:
                                  10 * (settingsProvider.uiScale ? 1.25 : 1.0),
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_rounded),
            iconSize: 24 * (settingsProvider.uiScale ? 1.25 : 1.0),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
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
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0, top: 8.0),
      child: Card(
        elevation: 0,
        color: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
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
                      height: 1.1,
                      letterSpacing: -0.5,
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
        ),
      ),
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

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
    final textTheme = Theme.of(context).textTheme;

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final titleStyle = baseTitleStyle
        .copyWith(fontWeight: FontWeight.w400, letterSpacing: 0.25)
        .apply(fontSizeFactor: scaleFactor);

    final baseDurationStyle =
        textTheme.labelMedium ?? const TextStyle(fontSize: 12.0);
    final durationStyle = baseDurationStyle.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w500,
      fontFeatures: [const FontFeature.tabularFigures()],
    ).apply(fontSizeFactor: scaleFactor);

    final titleText = settingsProvider.showTrackNumbers
        ? '${track.trackNumber}. ${track.title}'
        : track.title;

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
