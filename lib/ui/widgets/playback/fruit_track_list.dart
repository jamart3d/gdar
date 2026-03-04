import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/widgets/playback/fruit_now_playing_card.dart';

class FruitTrackList extends StatelessWidget {
  final Show trackShow;
  final double scaleFactor;

  const FruitTrackList({
    super.key,
    required this.trackShow,
    required this.scaleFactor,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final currentTrackIndex = audioProvider.audioPlayer.currentIndex ?? 0;
    final tracks = audioProvider.currentSource?.tracks ?? [];

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(
        24.0 * scaleFactor, // px-6
        0,
        24.0 * scaleFactor,
        140.0 * scaleFactor, // pb-tabbar
      ),
      itemCount: tracks.length,
      itemBuilder: (context, i) {
        if (i == currentTrackIndex && audioProvider.currentTrack != null) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: 20 * scaleFactor),
            child: FruitNowPlayingCard(
              trackShow: trackShow,
              track: audioProvider.currentTrack!,
              index: i + 1,
              scaleFactor: scaleFactor,
            ),
          );
        }

        return _buildTrackItem(
          context: context,
          track: tracks[i],
          index: i,
          isActive: false, // Card handles active state
          audioProvider: audioProvider,
        );
      },
    );
  }

  Widget _buildTrackItem({
    required BuildContext context,
    required Track track,
    required int index,
    required bool isActive,
    required AudioProvider audioProvider,
  }) {
    // Standard track row for inactive items
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          audioProvider.audioPlayer.seek(Duration.zero, index: index);
        },
        borderRadius: BorderRadius.circular(16 * scaleFactor),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 16.0 * scaleFactor, // px-4
            vertical: 18.0 * scaleFactor, // py-4.5
          ),
          child: Row(
            children: [
              SizedBox(
                width: 24 * scaleFactor, // w-6
                child: Text(
                  (index + 1).toString().padLeft(2, '0'),
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12 * scaleFactor, // text-xs
                    fontWeight: FontWeight.w800, // font-extrabold
                    color: colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.4), // Light blue-grey
                  ),
                ),
              ),
              SizedBox(width: 12 * scaleFactor), // gap-3
              Expanded(
                child: Text(
                  track.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 15 * scaleFactor, // text-base-ish
                    fontWeight: FontWeight.w600, // font-semibold
                    color: colorScheme.onSurface
                        .withValues(alpha: 0.8), // Slightly soft black
                  ),
                ),
              ),
              Text(
                _formatDuration(track.duration),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 11 * scaleFactor, // text-xs
                  fontWeight: FontWeight.w800, // font-extrabold
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDuration(int totalSeconds) {
    if (totalSeconds <= 0) return '0:00';
    final duration = Duration(seconds: totalSeconds);
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
