import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/track.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/providers/audio_provider.dart';

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

    // Based on the Stitch HTML structure, the list consists of Sets.
    // We'll iterate through the sequence and find Set breaks.

    // For simplicity, we just render the raw list of tracks.
    // In a full implementation, we group them by Set I, Set II, Encore.
    return Column(
      children: [
        for (int i = 0; i < tracks.length; i++)
          _buildTrackItem(
            context: context,
            track: tracks[i],
            index: i,
            isActive: i == currentTrackIndex,
            audioProvider: audioProvider,
          ),
      ],
    );
  }

  Widget _buildTrackItem({
    required BuildContext context,
    required Track track,
    required int index,
    required bool isActive,
    required AudioProvider audioProvider,
  }) {
    // If it's active, the HTML design doesn't show it in the list (it's up in the Now Playing card)
    // However, if we want to show it, the active state background is `bg-white/10`.
    // The Stitch mock removes the active track from this list block entirely,
    // but standard UX usually keeps it highlighted. We'll follow standard UX and highlight it.

    if (isActive) {
      return const SizedBox
          .shrink(); // Hide the playing track from the lower list to exactly match Stitch!
    }

    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          audioProvider.audioPlayer.seek(Duration.zero, index: index);
        },
        borderRadius: BorderRadius.circular(16 * scaleFactor), // rounded-2xl
        highlightColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        splashColor: isDark
            ? Colors.white.withValues(alpha: 0.1)
            : Colors.black.withValues(alpha: 0.05),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: 24.0 * scaleFactor, // px-6
            vertical: 16.0 * scaleFactor, // py-4
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    SizedBox(
                      width: 20 * scaleFactor, // w-5
                      child: Text(
                        (index + 1).toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 12 * scaleFactor, // text-xs
                          fontWeight: FontWeight.bold, // font-bold
                          color: colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6), // text-slate-400
                        ),
                      ),
                    ),
                    SizedBox(width: 16 * scaleFactor), // gap-4
                    Expanded(
                      child: Text(
                        track.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14 * scaleFactor, // text-sm
                          fontWeight: FontWeight.w600, // font-semibold
                          color: colorScheme.onSurface, // text-slate-700
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatDuration(track.duration),
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 10 * scaleFactor, // text-[10px]
                  fontWeight: FontWeight.bold, // font-bold
                  color: colorScheme.onSurfaceVariant
                      .withValues(alpha: 0.6), // text-slate-400
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
