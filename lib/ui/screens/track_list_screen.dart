import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/ui/widgets/conditional_marquee.dart';
import 'package:gdar/ui/widgets/mini_player.dart';
import 'package:gdar/utils/color_generator.dart';
import 'package:gdar/utils/utils.dart';
import 'package:provider/provider.dart';

class TrackListScreen extends StatefulWidget {
  final Show show;
  const TrackListScreen({super.key, required this.show});

  @override
  State<TrackListScreen> createState() => _TrackListScreenState();
}

class _TrackListScreenState extends State<TrackListScreen> {
  static const double _trackItemHeight = 52.0;

  /// Plays the selected track and pops this screen, returning `true` to
  /// signal the ShowListScreen to open the player.
  void _onTrackTapped(Source source, int initialIndex) {
    final audioProvider = context.read<AudioProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    if (settingsProvider.playOnTap) {
      audioProvider.playSource(widget.show, source, initialIndex: initialIndex);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      // If playOnTap is false, only play if it's the current show.
      if (audioProvider.currentShow?.name == widget.show.name) {
        audioProvider.playSource(widget.show, source,
            initialIndex: initialIndex);
        if (mounted) {
          Navigator.of(context).pop(true);
        }
      }
      // If it's not the current show, do nothing on tap.
    }
  }

  /// Navigates to the appropriate screen when a source is tapped.
  Future<void> _onSourceTapped(Source source) async {
    final audioProvider = context.read<AudioProvider>();
    final isPlayingThisSource = audioProvider.currentSource?.id == source.id;

    if (isPlayingThisSource) {
      // If the tapped source is already playing, pop and signal to open the player.
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } else {
      // If it's a new source, create a "virtual" show with only that source
      // and navigate to a new TrackListScreen for it.
      final singleSourceShow = Show(
        name: widget.show.name,
        artist: widget.show.artist,
        date: widget.show.date,
        year: widget.show.year,
        venue: widget.show.venue,
        sources: [source],
        hasFeaturedTrack: widget.show.hasFeaturedTrack,
      );
      final result = await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackListScreen(show: singleSourceShow),
        ),
      );
      // If the nested screen started playback, propagate the signal up.
      if (result == true && mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  /// Opens the full player screen for the currently playing item.
  Future<void> _openPlaybackScreen() async {
    // This screen should not push a new player, but pop and let the main
    // screen handle it to ensure a clean navigation stack.
    if (mounted) {
      Navigator.of(context).pop(true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    // Show the mini player only if a different show is currently playing.
    final isDifferentShowPlaying = audioProvider.currentShow != null &&
        audioProvider.currentShow!.name != widget.show.name;

    // Logic to match ShowListCard exactly
    final isPlaying = audioProvider.currentShow?.name == widget.show.name;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode &&
        !settingsProvider.useDynamicColor &&
        settingsProvider.seedColor != null;

    // Start with surface color (matches ShowListCard default)
    Color backgroundColor = Theme.of(context).colorScheme.surface;

    if (!isTrueBlackMode &&
        isPlaying &&
        settingsProvider.highlightCurrentShowCard) {
      String seed = widget.show.name;
      // If multi-source and playing, use the playing source ID as seed
      if (widget.show.sources.length > 1 &&
          audioProvider.currentSource?.id != null) {
        seed = audioProvider.currentSource!.id;
      }
      backgroundColor = ColorGenerator.getColor(seed,
          brightness: Theme.of(context).brightness);
    }
    // In True Black mode, surface is already black, so no need for explicit check.

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.show.venue, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(
              widget.show.formattedDate,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ],
        ),
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

    // If the show has only one source, display its track list directly.
    // Otherwise, display the list of sources for the user to choose from.
    if (widget.show.sources.length == 1) {
      return _buildTrackList(context, widget.show.sources.first, bottomPadding);
    } else {
      return _buildSourceSelection(context, bottomPadding);
    }
  }

  Widget _buildSourceSelection(BuildContext context, double bottomPadding) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 8, 16, bottomPadding),
      itemCount: widget.show.sources.length,
      itemBuilder: (context, index) {
        final source = widget.show.sources[index];
        final isPlayingThisSource =
            audioProvider.currentSource?.id == source.id;

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Material(
            color: isPlayingThisSource
                ? colorScheme.tertiaryContainer
                : colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _onSourceTapped(source),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        source.id,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: isPlayingThisSource
                                ? colorScheme.onTertiaryContainer
                                : colorScheme.onSecondaryContainer,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.1),
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: isPlayingThisSource
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSecondaryContainer,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTrackList(
      BuildContext context, Source source, double bottomPadding) {
    // Group tracks by set name
    final Map<String, List<Track>> tracksBySet = {};
    for (var track in source.tracks) {
      if (!tracksBySet.containsKey(track.setName)) {
        tracksBySet[track.setName] = [];
      }
      tracksBySet[track.setName]!.add(track);
    }

    // Flatten the list with headers
    final List<dynamic> listItems = [];
    tracksBySet.forEach((setName, tracks) {
      listItems.add(setName); // Add header
      listItems.addAll(tracks); // Add tracks
    });

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(12, 8, 12, bottomPadding),
      itemCount: listItems.length,
      itemBuilder: (context, index) {
        final item = listItems[index];
        if (item is String) {
          return _buildSetHeader(context, item);
        } else if (item is Track) {
          // Find the original index of this track in the source.tracks list
          // This is needed for playback to work correctly with the full list
          final originalIndex = source.tracks.indexOf(item);
          return _buildTrackItem(context, item, source, originalIndex);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildSetHeader(BuildContext context, String setName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        setName,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Track track, Source source, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final settingsProvider = context.watch<SettingsProvider>();

    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    // Safely create a non-nullable base style with a fallback font size.
    final baseTitleStyle =
        textTheme.bodyLarge ?? const TextStyle(fontSize: 16.0);
    final titleStyle = baseTitleStyle
        .copyWith(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.1)
        .apply(fontSizeFactor: scaleFactor);

    final baseDurationStyle =
        textTheme.labelMedium ?? const TextStyle(fontSize: 12.0);
    final durationStyle = baseDurationStyle.copyWith(
      color: colorScheme.onSurfaceVariant,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      fontFeatures: [const FontFeature.tabularFigures()],
    ).apply(fontSizeFactor: scaleFactor);

    final titleText = settingsProvider.showTrackNumbers
        ? '${track.trackNumber}. ${track.title}'
        : track.title;

    return SizedBox(
      height: _trackItemHeight * scaleFactor,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _onTrackTapped(source, index),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: titleStyle.fontSize! * 1.2,
                      child: ConditionalMarquee(
                        text: titleText,
                        style: titleStyle,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 52 * scaleFactor,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
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
              ),
            ),
          ),
        ),
      ),
    );
  }
}
