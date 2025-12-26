import 'package:flutter/material.dart';
import 'package:gdar/models/show.dart';
import 'package:gdar/models/source.dart';
import 'package:gdar/providers/audio_provider.dart';
import 'package:gdar/providers/settings_provider.dart';

import 'package:gdar/ui/widgets/source_list_item.dart';
import 'package:gdar/ui/widgets/swipe_action_background.dart';
import 'package:provider/provider.dart';

/// A widget that displays a list of sources (SHNIDs) for a given show.
/// This is used within an expanded [ShowListCard] on the main screen.
class ShowListItemDetails extends StatefulWidget {
  final Show show;
  final String? playingSourceId;
  final double height;
  final Function(Source) onSourceTapped;
  final Function(Source) onSourceLongPress;

  const ShowListItemDetails({
    super.key,
    required this.show,
    required this.playingSourceId,
    required this.height,
    required this.onSourceTapped,
    required this.onSourceLongPress,
  });

  @override
  State<ShowListItemDetails> createState() => _ShowListItemDetailsState();
}

class _ShowListItemDetailsState extends State<ShowListItemDetails> {
  @override
  Widget build(BuildContext context) {
    // This widget should only be built for shows with multiple sources.
    if (widget.show.sources.length <= 1) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: widget.height,
      child: _buildSourceSelection(context),
    );
  }

  Widget _buildSourceSelection(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.show.sources.length,
      itemBuilder: (context, index) {
        final source = widget.show.sources[index];
        final isPlaying = widget.playingSourceId == source.id;

        if (isPlaying && settingsProvider.highlightPlayingWithRgb) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Dismissible(
              key: ValueKey(source.id),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.block, color: Colors.white, size: 24),
              ),
              confirmDismiss: (direction) async {
                final audioProvider = context.read<AudioProvider>();
                if (audioProvider.currentSource?.id == source.id) {
                  audioProvider.stopAndClear();
                }
                settingsProvider.setRating(source.id, -1);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Blocked Source "${source.id}"',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onInverseSurface),
                    ),
                    backgroundColor:
                        Theme.of(context).colorScheme.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    margin: const EdgeInsets.all(12),
                    action: SnackBarAction(
                      label: 'UNDO',
                      textColor: Theme.of(context).colorScheme.inversePrimary,
                      onPressed: () {
                        settingsProvider.setRating(source.id, 0);
                      },
                    ),
                  ),
                );
                return false; // Don't actually dismiss from tree, provider update will refresh list
              },
              child: SourceListItem(
                source: source,
                isSourcePlaying: isPlaying,
                scaleFactor: scaleFactor,
                borderRadius: 20, // Match the Dismissible background radius
                showBorder: false,
                onTap: () => widget.onSourceTapped(source),
                onLongPress: () => widget.onSourceLongPress(source),
              ),
            ),
          );
        }

        // Wrap the item in Dismissible for swipe-to-block functionality.
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Dismissible(
            key: ValueKey(source.id),
            direction: DismissDirection.endToStart,
            background: const SwipeActionBackground(borderRadius: 20),
            onDismissed: (direction) {
              // Stop playback if this specific source is playing
              if (isPlaying) {
                final audioProvider = context.read<AudioProvider>();
                audioProvider.stopAndClear();
              }

              // Mark as Blocked (Red Star / -1)
              settingsProvider.setRating(source.id, -1);

              // Show Undo Snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Blocked Source "${source.id}"',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.onInverseSurface),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.inverseSurface,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.all(12),
                  action: SnackBarAction(
                    label: 'UNDO',
                    textColor: Theme.of(context).colorScheme.inversePrimary,
                    onPressed: () {
                      settingsProvider.setRating(source.id, 0);
                    },
                  ),
                ),
              );
            },
            child: SourceListItem(
              source: source,
              isSourcePlaying: isPlaying,
              scaleFactor: scaleFactor,
              borderRadius: 20,
              onTap: () => widget.onSourceTapped(source),
              onLongPress: () => widget.onSourceLongPress(source),
            ),
          ),
        );
      },
    );
  }
}
