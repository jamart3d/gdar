import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:gdar/providers/show_list_provider.dart';
import 'package:gdar/utils/utils.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class ShowListItemDetails extends StatelessWidget {
  final Show show;
  final String? playingSourceId;
  final String? expandedShnid;
  final double height;
  final Map<String, ScrollController> trackScrollControllers;
  final VoidCallback onOpenPlayback;
  final Function(Source) onSourceLongPress;

  const ShowListItemDetails({
    super.key,
    required this.show,
    required this.playingSourceId,
    required this.expandedShnid,
    required this.height,
    required this.trackScrollControllers,
    required this.onOpenPlayback,
    required this.onSourceLongPress,
  });

  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const double _trackItemHeight = 64.0; // Matches the SizedBox height
  static const double _sourcePadding = 16.0;
  static const double _maxTrackListHeight = 500.0;

  @override
  Widget build(BuildContext context) {
    if (show.sources.isEmpty) {
      return const SizedBox(
          height: 100, child: Center(child: Text('No tracks available.')));
    }

    return SizedBox(
      height: height,
      child: show.sources.length > 1
          ? _buildSourceSelection(context)
          : _buildTrackList(context, show.sources.first),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.read<ShowListProvider>();

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: show.sources.length,
      itemBuilder: (context, index) {
        final source = show.sources[index];
        final isSourceExpanded = expandedShnid == source.id;
        final isSourcePlaying = playingSourceId == source.id;
        return Column(
          key: ValueKey(source.id),
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () => showListProvider.onShnidTapped(source.id),
                  onLongPress: () => onSourceLongPress(source),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          isSourcePlaying
                              ? colorScheme.tertiaryContainer.withOpacity(0.7)
                              : colorScheme.secondaryContainer,
                          isSourcePlaying
                              ? colorScheme.tertiaryContainer.withOpacity(0.5)
                              : colorScheme.secondaryContainer.withOpacity(0.8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.shadow.withOpacity(0.1),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        )
                      ],
                      border: isSourceExpanded
                          ? Border.all(color: colorScheme.primary, width: 1.5)
                          : null,
                    ),
                    child: Row(
                      children: [
                        AnimatedRotation(
                          turns: isSourceExpanded ? 0.5 : 0,
                          duration: _animationDuration,
                          curve: Curves.easeInOutCubicEmphasized,
                          child: Icon(Icons.keyboard_arrow_down_rounded,
                              size: 18,
                              color: isSourceExpanded
                                  ? colorScheme.onPrimaryContainer
                                  : isSourcePlaying
                                  ? colorScheme.onTertiaryContainer
                                  : colorScheme.onSecondaryContainer),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(source.id,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(
                                  color: isSourcePlaying
                                      ? colorScheme.onTertiaryContainer
                                      : colorScheme.onSecondaryContainer,
                                  fontWeight: isSourcePlaying
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  letterSpacing: 0.1)),
                        ),
                        if (!settingsProvider.hideTrackCountInSourceList)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: isSourcePlaying
                                  ? colorScheme.tertiary.withOpacity(0.1)
                                  : colorScheme.secondary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text('${source.tracks.length}',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                    color: isSourcePlaying
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSecondaryContainer,
                                    fontWeight: FontWeight.w600)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            AnimatedSize(
              duration: _animationDuration,
              curve: Curves.easeInOutCubicEmphasized,
              child: isSourceExpanded
                  ? _buildTrackList(context, source, isNested: true)
                  : const SizedBox.shrink(),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTrackList(BuildContext context, Source source,
      {bool isNested = false}) {
    final controller =
    trackScrollControllers.putIfAbsent(source.id, () => ScrollController());
    double listHeight;
    if (isNested) {
      listHeight = ((source.tracks.length * _trackItemHeight) + _sourcePadding)
          .clamp(0.0, _maxTrackListHeight);
    } else {
      listHeight = height;
    }

    return Container(
      height: listHeight,
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: ListView.builder(
        controller: controller,
        padding: isNested ? const EdgeInsets.only(bottom: 8.0) : EdgeInsets.zero,
        itemCount: source.tracks.length,
        itemBuilder: (context, index) {
          return _buildTrackItem(
              context, source.tracks[index], source, index);
        },
      ),
    );
  }

  Widget _buildTrackItem(
      BuildContext context, Track track, Source source, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    final audioProvider = context.watch<AudioProvider>();
    final settingsProvider = context.watch<SettingsProvider>();

    return StreamBuilder<int?>(
      stream: audioProvider.currentIndexStream,
      builder: (context, indexSnapshot) {
        return StreamBuilder<PlayerState>(
          stream: audioProvider.playerStateStream,
          builder: (context, stateSnapshot) {
            final isCurrentlyPlayingSource =
                audioProvider.currentSource?.id == source.id;
            final isPlayingTrack =
                isCurrentlyPlayingSource && indexSnapshot.data == index;
            final titleText = settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title;

            return SizedBox(
              height: _trackItemHeight,
              child: Padding(
                padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    gradient: isPlayingTrack
                        ? LinearGradient(
                        colors: [
                          colorScheme.primaryContainer.withOpacity(0.6),
                          colorScheme.primaryContainer.withOpacity(0.3)
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight)
                        : null,
                    color: isPlayingTrack ? null : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                    border: isPlayingTrack
                        ? Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1.5)
                        : null,
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        if (isPlayingTrack) {
                          onOpenPlayback();
                        } else if (isCurrentlyPlayingSource) {
                          audioProvider.seekToTrack(index);
                        } else if (settingsProvider.playOnTap) {
                          audioProvider.playSource(show, source,
                              initialIndex: index);
                        }
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            if (isPlayingTrack)
                              Container(
                                margin: const EdgeInsets.only(right: 12),
                                width: 24,
                                height: 24,
                                child: Center(
                                  child: (stateSnapshot.data?.processingState ==
                                      ProcessingState.buffering ||
                                      stateSnapshot.data?.processingState ==
                                          ProcessingState.loading)
                                      ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2.0))
                                      : Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          borderRadius:
                                          BorderRadius.circular(8)),
                                      child: Icon(Icons.play_arrow_rounded,
                                          size: 16,
                                          color: colorScheme.onPrimary)),
                                ),
                              ),
                            Expanded(
                              child: Text(titleText,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyLarge
                                      ?.copyWith(
                                      color: isPlayingTrack
                                          ? colorScheme.primary
                                          : colorScheme.onSurface,
                                      fontWeight: isPlayingTrack
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      letterSpacing: 0.1)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPlayingTrack
                                    ? colorScheme.primary.withOpacity(0.2)
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                  formatDuration(
                                      Duration(seconds: track.duration)),
                                  style: Theme.of(context)
                                      .textTheme
                                      .labelMedium
                                      ?.copyWith(
                                      color: isPlayingTrack
                                          ? colorScheme.primary
                                          : colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5)),
                            ),
                          ],
                        ),
                      ),
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
}
