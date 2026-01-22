import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart'; // Add import
import 'package:shakedown/services/catalog_service.dart';

import 'package:shakedown/ui/widgets/source_list_item.dart';
import 'package:shakedown/ui/widgets/swipe_action_background.dart';
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
    final showListProvider = context.read<ShowListProvider>();
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: widget.show.sources.length,
      itemBuilder: (context, index) {
        final source = widget.show.sources[index];
        final isPlaying = widget.playingSourceId == source.id;

        // Common Dismissible Logic
        Future<bool> handleConfirmDismiss() async {
          // Haptic Feedback for the block action
          HapticFeedback.mediumImpact();

          // Stop playback if this specific source is playing
          if (isPlaying ||
              (context.read<AudioProvider>().currentSource?.id == source.id)) {
            final audioProvider = context.read<AudioProvider>();
            audioProvider.stopAndClear();
          }

          // Mark as Blocked (Red Star / -1)
          CatalogService().setRating(source.id, -1);

          // Calculate position for SnackBar
          double bottomMargin = 80; // Default fallback
          try {
            final RenderBox? box = context.findRenderObject() as RenderBox?;
            if (box != null && box.hasSize) {
              final position = box.localToGlobal(Offset.zero);
              final size = box.size;
              final screenHeight = MediaQuery.of(context).size.height;
              // Position just below the item
              final spaceBelow = screenHeight - (position.dy + size.height);
              // Ensure margin is within screen bounds and reasonable
              bottomMargin = (spaceBelow - 60).clamp(10.0, screenHeight - 100);
            }
          } catch (e) {
            // Fallback
          }

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    Icons.block_flipped,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Blocked Source "${source.id}"',
                      style: TextStyle(
                          color:
                              Theme.of(context).colorScheme.onPrimaryContainer,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              margin:
                  EdgeInsets.only(bottom: bottomMargin, left: 32, right: 32),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(100),
                side: BorderSide(
                  color: Theme.of(context)
                      .colorScheme
                      .onPrimaryContainer
                      .withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              action: SnackBarAction(
                label: 'UNDO',
                textColor: Theme.of(context).colorScheme.primary,
                onPressed: () {
                  CatalogService().setRating(source.id, 0);
                },
              ),
            ),
          );
          // Return true to allow "slide off" animation
          return true;
        }

        void handleOnDismissed() {
          // Optimistically remove from list to prevent "still in tree" crash.
          showListProvider.dismissSource(widget.show, source.id);
        }

        if (isPlaying && settingsProvider.highlightPlayingWithRgb) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Builder(builder: (context) {
              return Dismissible(
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
                confirmDismiss: (direction) => handleConfirmDismiss(),
                onDismissed: (direction) => handleOnDismissed(),
                child: SourceListItem(
                  source: source,
                  isSourcePlaying: isPlaying,
                  scaleFactor: scaleFactor,
                  borderRadius: 20, // Match the Dismissible background radius
                  showBorder: false,
                  onTap: () => widget.onSourceTapped(source),
                  onLongPress: () => widget.onSourceLongPress(source),
                ),
              );
            }),
          );
        }

        // Standard Item
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Builder(builder: (context) {
            return Dismissible(
              key: ValueKey(source.id),
              direction: DismissDirection.endToStart,
              background: const SwipeActionBackground(borderRadius: 20),
              confirmDismiss: (direction) => handleConfirmDismiss(),
              onDismissed: (direction) => handleOnDismissed(),
              child: SourceListItem(
                source: source,
                isSourcePlaying: isPlaying,
                scaleFactor: scaleFactor,
                borderRadius: 20,
                onTap: () => widget.onSourceTapped(source),
                onLongPress: () => widget.onSourceLongPress(source),
              ),
            );
          }),
        );
      },
    );
  }
}
