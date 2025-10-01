// lib/ui/screens/playback_screen.dart

import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/track.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class PlaybackScreen extends StatelessWidget {
  const PlaybackScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final Show? currentShow = audioProvider.currentShow;

    if (currentShow == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(
          child: Text('No show selected.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(currentShow.venue),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- METADATA DISPLAY ---
            Text(
              currentShow.formattedDate,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            StreamBuilder<int?>(
              stream: audioProvider.currentIndexStream,
              builder: (context, snapshot) {
                final index = snapshot.data ?? 0;
                // Add a check to prevent range errors during transitions
                if (index >= currentShow.tracks.length) return const SizedBox.shrink();
                final track = currentShow.tracks[index];
                return Text(
                  track.title,
                  style: Theme.of(context).textTheme.headlineSmall,
                  textAlign: TextAlign.center,
                );
              },
            ),
            const SizedBox(height: 40),

            // --- PROGRESS BAR ---
            _buildProgressBar(context, audioProvider), // Pass context here
            const SizedBox(height: 20),

            // --- PLAYBACK CONTROLS ---
            _buildControls(audioProvider),

            // --- TRACKLIST ---
            const SizedBox(height: 40),
            Expanded(child: _buildTracklist(context, audioProvider, currentShow)),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AudioProvider audioProvider) {
    return StreamBuilder<PlayerState>(
      stream: audioProvider.playerStateStream,
      builder: (context, snapshot) {
        final playerState = snapshot.data;
        final processingState = playerState?.processingState;
        final playing = playerState?.playing ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(
              icon: const Icon(Icons.skip_previous),
              iconSize: 50,
              onPressed: audioProvider.seekToPrevious,
            ),
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering)
              const SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(),
              )
            else if (!playing)
              IconButton(
                icon: const Icon(Icons.play_arrow),
                iconSize: 64,
                onPressed: audioProvider.play,
              )
            else
              IconButton(
                icon: const Icon(Icons.pause),
                iconSize: 64,
                onPressed: audioProvider.pause,
              ),
            IconButton(
              icon: const Icon(Icons.skip_next),
              iconSize: 50,
              onPressed: audioProvider.seekToNext,
            ),
          ],
        );
      },
    );
  }

  // A helper widget for the progress bar and time labels.
  Widget _buildProgressBar(BuildContext context, AudioProvider audioProvider) {
    // We need two streams: position and duration
    final audioPlayer = Provider.of<AudioProvider>(context, listen: false).audioPlayer;

    return StreamBuilder<Duration>(
      stream: audioPlayer.positionStream,
      builder: (context, positionSnapshot) {
        final position = positionSnapshot.data ?? Duration.zero;

        // This stream builder gets the total duration
        return StreamBuilder<Duration?>(
            stream: audioPlayer.durationStream,
            builder: (context, durationSnapshot) {
              final totalDuration = durationSnapshot.data ?? Duration.zero;

              return Column(
                children: [
                  Slider(
                    min: 0.0,
                    max: totalDuration.inSeconds.toDouble() + 1.0,
                    value: position.inSeconds.toDouble().clamp(0.0, totalDuration.inSeconds.toDouble()),
                    onChanged: (value) {
                      audioProvider.seek(Duration(seconds: value.round()));
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_formatDuration(position)),
                      Text(_formatDuration(totalDuration)),
                    ],
                  )
                ],
              );
            }
        );
      },
    );
  }

  // A helper widget for displaying the list of tracks.
  Widget _buildTracklist(BuildContext context, AudioProvider audioProvider, Show show) {
    return StreamBuilder<int?>(
        stream: audioProvider.currentIndexStream,
        builder: (context, snapshot) {
          final currentIndex = snapshot.data;
          return ListView.builder(
            itemCount: show.tracks.length,
            itemBuilder: (context, index) {
              final Track track = show.tracks[index];
              final bool isPlaying = currentIndex == index;

              return ListTile(
                leading: isPlaying
                    ? const Icon(Icons.volume_up)
                    : Text('${track.trackNumber}.'),
                title: Text(
                  track.title,
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    color: isPlaying ? Theme.of(context).colorScheme.primary : null,
                  ),
                ),
                trailing: Text(_formatDuration(Duration(seconds: track.duration))),
                onTap: () {
                  // Allow tapping a track to jump to it in the playlist
                  audioProvider.seekToTrack(index);
                },
              );
            },
          );
        }
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(d.inMinutes.remainder(60));
    final seconds = twoDigits(d.inSeconds.remainder(60));
    return '$minutes:$seconds';
  }
}