import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/ui/widgets/show_list_card.dart';
import 'package:shakedown/ui/widgets/show_list_item_details.dart';
import 'package:shakedown/ui/widgets/swipe_action_background.dart';

class ShowListItem extends StatelessWidget {
  final Show show;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Source) onSourceTap;
  final Function(Source) onSourceLongPress;

  const ShowListItem({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.animation,
    required this.onTap,
    required this.onLongPress,
    required this.onSourceTap,
    required this.onSourceLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // We watch only what we need for the card state
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.read<SettingsProvider>();

    final isPlaying = audioProvider.currentShow == show;
    final playingSource = audioProvider.currentSource;
    final isLoading =
        showListProvider.isShowLoading(showListProvider.getShowKey(show));

    return Column(
      key: ValueKey('${show.name}_${show.date}'),
      children: [
        Dismissible(
          key: ValueKey('${show.name}_${show.date}'),
          // Disable swipe on the main card if there are multiple sources.
          // Sources must be blocked individually in the expanded view.
          direction: show.sources.length > 1
              ? DismissDirection.none
              : DismissDirection.endToStart,
          background: const SwipeActionBackground(
            borderRadius: 12.0,
          ),
          confirmDismiss: (direction) async {
            return await _showBlockConfirmation(context, show, audioProvider);
          },
          onDismissed: (direction) {
            // Optimistically remove from list.
            // setRating was already called in confirmDismiss.
            context.read<ShowListProvider>().dismissShow(show);
          },
          child: ShowListCard(
            show: show,
            isExpanded: isExpanded,
            isPlaying: isPlaying,
            playingSource: playingSource,
            isLoading: isLoading,
            onTap: onTap,
            onLongPress: onLongPress,
          ),
        ),
        SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1.0,
          child: isExpanded
              ? ShowListItemDetails(
                  show: show,
                  playingSourceId: playingSource?.id,
                  height:
                      _calculateExpandedHeight(context, show, settingsProvider),
                  onSourceTapped: onSourceTap,
                  onSourceLongPress: onSourceLongPress,
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  Future<bool> _showBlockConfirmation(
      BuildContext context, Show show, AudioProvider audioProvider) async {
    // Haptic Feedback
    HapticFeedback.mediumImpact();

    // Calculate position for SnackBar
    double bottomMargin = 80;
    try {
      final RenderBox? box = context.findRenderObject() as RenderBox?;
      if (box != null && box.hasSize) {
        final position = box.localToGlobal(Offset.zero);
        final size = box.size;
        final screenHeight = MediaQuery.of(context).size.height;
        final spaceBelow = screenHeight - (position.dy + size.height);
        bottomMargin = (spaceBelow - 60).clamp(10.0, screenHeight - 100);
      }
    } catch (_) {}

    // Stop playback if this specific show is playing
    if (audioProvider.currentShow == show) {
      audioProvider.stopAndClear();
    }

    // Mark as Blocked (Red Star / -1)
    CatalogService().setRating(show.sources.first.id, -1);

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
                'Blocked "${show.venue}"',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
        margin: EdgeInsets.only(bottom: bottomMargin, left: 24, right: 24),
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
            // Restore rating
            CatalogService().setRating(show.sources.first.id, 0);
          },
        ),
      ),
    );
    return true;
  }

  double _calculateExpandedHeight(
      BuildContext context, Show show, SettingsProvider settingsProvider) {
    if (show.sources.length <= 1) return 0.0;
    final double scaleFactor = settingsProvider.uiScale ? 1.25 : 1.0;
    const double baseSourceHeaderHeight = 59.0;
    const double listVerticalPadding = 16.0;
    final sourceHeaderHeight = baseSourceHeaderHeight * scaleFactor;
    return (show.sources.length * sourceHeaderHeight) + listVerticalPadding;
  }
}
