import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class ShowListItem extends StatelessWidget {
  final Show show;
  final bool isExpanded;
  final bool isPlaying;
  final String? expandedSourceId;
  final String? playingSourceId;
  final VoidCallback onToggleExpand;
  final Function(String) onToggleSourceExpand;
  final Function(Source) onPlaySource;

  const ShowListItem({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.isPlaying,
    this.expandedSourceId,
    this.playingSourceId,
    required this.onToggleExpand,
    required this.onToggleSourceExpand,
    required this.onPlaySource,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasMultipleSources = show.sources.length > 1;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isPlaying ? colorScheme.primary : colorScheme.outlineVariant,
          width: isPlaying ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onToggleExpand,
        onLongPress: () {
          HapticFeedback.mediumImpact();
          context.read<AudioProvider>().playShow(show);
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  AnimatedRotation(
                    turns: isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubicEmphasized,
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          show.venue,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_rounded,
                              size: 14,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              show.formattedDate,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (hasMultipleSources) _buildBadge(context),
                ],
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOutCubicEmphasized,
              child: isExpanded
                  ? _buildExpandedContent(context)
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${show.sources.length}',
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildExpandedContent(BuildContext context) {
    if (show.sources.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: Text('No tracks available for this show.'),
      );
    }

    final hasMultipleSources = show.sources.length > 1;

    return Column(
      children: [
        Divider(
          height: 1,
          thickness: 1,
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
        if (hasMultipleSources)
          _buildSourceSelection(context)
        else
          _buildTrackList(context, show.sources.first),
      ],
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'shnid',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
        ...show.sources.map((source) {
          final isSourceExpanded = expandedSourceId == source.id;
          final isSourcePlaying = playingSourceId == source.id;
          return Column(
            children: [
              ListTile(
                title: Text(
                  source.id,
                  style: TextStyle(
                    color: isSourcePlaying ? colorScheme.primary : null,
                    fontWeight: isSourcePlaying ? FontWeight.bold : null,
                  ),
                ),
                trailing: Text(
                  '${source.tracks.length} tracks',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () => onToggleSourceExpand(source.id),
                onLongPress: () {
                  HapticFeedback.lightImpact();
                  onPlaySource(source);
                },
              ),
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubicEmphasized,
                child: isSourceExpanded
                    ? _buildTrackList(context, source, isNested: true)
                    : const SizedBox.shrink(),
              ),
            ],
          );
        }),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildTrackList(BuildContext context, Source source,
      {bool isNested = false}) {
    return Container(
      color: isNested
          ? Theme.of(context).colorScheme.surfaceContainerLowest
          : Colors.transparent,
      child: Column(
        children:
        source.tracks.map((track) => _buildTrackItem(context, track, source)).toList(),
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, Track track, Source source) {
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
                isCurrentlyPlayingSource && indexSnapshot.data == track.trackNumber - 1;

            final titleText = settingsProvider.showTrackNumbers
                ? '${track.trackNumber}. ${track.title}'
                : track.title;

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: isPlayingTrack
                    ? colorScheme.primaryContainer.withOpacity(0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                title: Text(
                  titleText,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isPlayingTrack
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                    fontWeight:
                    isPlayingTrack ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                trailing: Text(
                  _formatDuration(Duration(seconds: track.duration)),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () {
                  if (isCurrentlyPlayingSource) {
                    audioProvider.seekToTrack(track.trackNumber - 1);
                  } else {
                    onPlaySource(source);
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = d.inHours;
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));

    if (hours > 0) {
      return '$hours:$minutes:$seconds';
    }
    return '$hours:$minutes:$seconds';
  }
}

