import 'package:flutter/material.dart';
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
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:gdar/utils/utils.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'dart:ui';

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
  final ItemScrollController _itemScrollController = ItemScrollController();
  final ItemPositionsListener _itemPositionsListener =
      ItemPositionsListener.create();
  String? _lastTrackTitle;

  @override
  void initState() {
    super.initState();
    final audioProvider = context.read<AudioProvider>();
    _lastTrackTitle = audioProvider.currentTrack?.title;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToCurrentTrack(animate: false);
    });
  }

  void _scrollToCurrentTrack({bool animate = true}) {
    if (!mounted) return;
    final audioProvider = context.read<AudioProvider>();

    final isCurrentShow = audioProvider.currentShow?.name == widget.show.name;
    if (!isCurrentShow) return;

    final currentTrack = audioProvider.currentTrack;
    if (currentTrack == null) return;

    // Build the list structure to find the index
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in widget.source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    final List<dynamic> listItems = [];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      listItems.addAll(tracks);
    });

    int targetIndex = -1;
    for (int i = 0; i < listItems.length; i++) {
      final item = listItems[i];
      if (item is Track &&
          item.title == currentTrack.title &&
          item.trackNumber == currentTrack.trackNumber) {
        targetIndex = i;
        break;
      }
    }

    if (targetIndex != -1 && _itemScrollController.isAttached) {
      if (animate) {
        _itemScrollController.scrollTo(
          index: targetIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.3,
        );
      } else {
        _itemScrollController.jumpTo(
          index: targetIndex,
          alignment: 0.3,
        );
      }
    }
  }

  void _onTrackTapped(Source source, int trackIndex) {
    final audioProvider = context.read<AudioProvider>();
    audioProvider.playSource(widget.show, source, initialIndex: trackIndex);
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

    // Auto-scroll when track changes while viewing this show
    if (audioProvider.currentShow?.name == widget.show.name &&
        audioProvider.currentTrack?.title != _lastTrackTitle) {
      _lastTrackTitle = audioProvider.currentTrack?.title;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentTrack();
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.show.formattedDate,
              style: Theme.of(context).textTheme.titleLarge?.apply(
                  fontSizeFactor: settingsProvider.uiScale ? 1.25 : 1.0),
            ),
            Text(
              widget.show.venue,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 12 * (settingsProvider.uiScale ? 1.25 : 1.0),
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
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
                            .withOpacity(0.5),
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
    final bottomPadding = isDifferentShowPlaying ? 140.0 : 16.0;

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
    final Map<int, int> listItemToTrackIndex = {};
    int currentTrackIndex = 0;

    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName);
      for (var track in tracks) {
        listItemToTrackIndex[listItems.length] = currentTrackIndex++;
        listItems.add(track);
      }
    });

    return ScrollablePositionedList.builder(
      itemScrollController: _itemScrollController,
      itemPositionsListener: _itemPositionsListener,
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          final trackIndex = listItemToTrackIndex[index] ?? 0;
          return _buildTrackItem(context, item, source, trackIndex);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    final settingsProvider = context.watch<SettingsProvider>();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            )
            .apply(fontSizeFactor: settingsProvider.uiScale ? 1.25 : 1.0),
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Track track, Source source, int index) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      initialData: audioProvider.audioPlayer.currentIndex,
      builder: (context, snapshot) {
        final currentIndex = snapshot.data;
        final isCurrentTrack =
            audioProvider.currentShow?.name == widget.show.name &&
                currentIndex == index;

        final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

        final baseTitleStyle =
            textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
        final titleStyle = baseTitleStyle
            .copyWith(
                color: isCurrentTrack
                    ? colorScheme.primary
                    : colorScheme.onSurface,
                fontWeight: isCurrentTrack ? FontWeight.bold : FontWeight.w500,
                letterSpacing: 0.1)
            .apply(fontSizeFactor: scaleFactor);

        final baseDurationStyle =
            textTheme.labelMedium ?? const TextStyle(fontSize: 12.0);
        final durationStyle = baseDurationStyle.copyWith(
          color: isCurrentTrack
              ? colorScheme.primary.withOpacity(0.8)
              : colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
          fontFeatures: [const FontFeature.tabularFigures()],
        ).apply(fontSizeFactor: scaleFactor);

        final titleText = settingsProvider.showTrackNumbers
            ? '${track.trackNumber}. ${track.title}'
            : track.title;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          child: Material(
            color: isCurrentTrack
                ? colorScheme.primaryContainer.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onTrackTapped(source, index),
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 8 * scaleFactor),
                child: Row(
                  children: [
                    if (isCurrentTrack) ...[
                      Icon(Icons.play_arrow_rounded,
                          color: colorScheme.primary, size: 20 * scaleFactor),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: SizedBox(
                        height: titleStyle.fontSize! * 1.5,
                        child: ConditionalMarquee(
                          text: titleText,
                          style: titleStyle,
                          textAlign: settingsProvider.hideTrackDuration
                              ? TextAlign.center
                              : TextAlign.left,
                        ),
                      ),
                    ),
                    if (!settingsProvider.hideTrackDuration) ...[
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 52 * scaleFactor,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCurrentTrack
                                ? colorScheme.primaryContainer.withOpacity(0.5)
                                : colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            formatDuration(Duration(seconds: track.duration)),
                            style: durationStyle,
                            textAlign: TextAlign.center,
                          ),
                        ),
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
  }
}
