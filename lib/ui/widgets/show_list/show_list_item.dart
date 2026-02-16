import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/catalog_service.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_card.dart';
import 'package:shakedown/ui/widgets/show_list_item_details.dart';
import 'package:shakedown/ui/widgets/swipe_action_background.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class ShowListItem extends StatelessWidget {
  final Show show;
  final bool isExpanded;
  final Animation<double> animation;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final Function(Source) onSourceTap;
  final Function(Source) onSourceLongPress;
  final VoidCallback? onFocusLeft;
  final ValueChanged<int>? onFocusChange;
  final void Function(int, {bool shouldScroll})? onWrapAround;
  final FocusNode? focusNode;
  final int index;

  const ShowListItem({
    super.key,
    required this.show,
    required this.isExpanded,
    required this.animation,
    required this.onTap,
    required this.onLongPress,
    required this.onSourceTap,
    required this.onSourceLongPress,
    this.onFocusLeft,
    this.onFocusChange,
    this.onWrapAround,
    this.focusNode,
    required this.index,
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

    final deviceService = context.watch<DeviceService>();
    final isTv = deviceService.isTv;

    Widget card = ShowListCard(
      show: show,
      isExpanded: isExpanded,
      isPlaying: isPlaying,
      playingSource: playingSource,
      isLoading: isLoading,
      onTap: onTap,
      onLongPress: onLongPress,
    );

    if (isTv) {
      card = TvFocusWrapper(
        focusNode: focusNode,
        onTap: onTap,
        onLongPress: onLongPress,
        scaleOnFocus: 1.0, // Disable scaling
        focusBackgroundColor: Colors.transparent, // Transparent background
        focusColor: Theme.of(context).colorScheme.primary, // Primary border
        borderRadius: BorderRadius.circular(12),
        onFocusChange: (focused) {
          if (focused) onFocusChange?.call(index);
        },
        onKeyEvent: (node, event) {
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (event is KeyDownEvent) onFocusLeft?.call();
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            final shows = context.read<ShowListProvider>().filteredShows;
            if (index == shows.length - 1) {
              if (event is KeyDownEvent) {
                onWrapAround?.call(0);
              }
              return KeyEventResult.handled; // Anchor
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            if (index == 0) {
              if (event is KeyDownEvent) {
                final shows = context.read<ShowListProvider>().filteredShows;
                onWrapAround?.call(shows.length - 1);
              }
              return KeyEventResult.handled; // Anchor
            }
          }
          return KeyEventResult.ignored;
        },
        child: card,
      );
    }

    return Column(
      key: ValueKey('${show.name}_${show.date}'),
      children: [
        if (isTv)
          card
        else
          Dismissible(
            key: ValueKey('${show.name}_${show.date}'),
            direction: DismissDirection.endToStart,
            dismissThresholds: const {
              DismissDirection.endToStart: 0.6,
            },
            background: const SwipeActionBackground(
              borderRadius: 12.0,
            ),
            confirmDismiss: (direction) async {
              return await _showBlockConfirmation(
                  context, show, audioProvider, settingsProvider);
            },
            onDismissed: (direction) {
              context.read<ShowListProvider>().dismissShow(show);
            },
            child: card,
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

  Future<bool> _showBlockConfirmation(BuildContext context, Show show,
      AudioProvider audioProvider, SettingsProvider settingsProvider) async {
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

    // Capture playback state for resume if UNDO is pressed
    final isCurrentlyPlaying = audioProvider.currentShow == show;
    final resumeSource =
        isCurrentlyPlaying ? audioProvider.currentSource : null;
    final resumeIndex =
        isCurrentlyPlaying ? audioProvider.audioPlayer.currentIndex : 0;
    final resumePosition =
        isCurrentlyPlaying ? audioProvider.audioPlayer.position : Duration.zero;

    if (isCurrentlyPlaying) {
      audioProvider.stopAndClear();
    }

    // Mark ONLY the representative source as Blocked (Red Star / -1)
    // The user requested that swiping the main card should only block
    // "that source" even if multiple sources exist.
    context.read<CatalogService>().setRating(show.sources.first.id, -1);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.block,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                show.sources.length > 1
                    ? 'Blocked source "${show.sources.first.id}"'
                    : 'Blocked',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold),
              ),
            ),
            // Block & Roll Button - Only if this was the playing show
            if (audioProvider.currentShow == show)
              TextButton(
                onPressed: () {
                  audioProvider.playRandomShow();
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 0),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  children: [
                    Icon(
                        settingsProvider.nonRandom
                            ? Icons.playlist_play_rounded
                            : Icons.casino_rounded,
                        size: 16,
                        color:
                            Theme.of(context).colorScheme.onPrimaryContainer),
                    const SizedBox(width: 4),
                    Text(
                      settingsProvider.nonRandom ? 'NEXT' : 'ROLL',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
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
            // Restore rating for the specifically blocked source
            context.read<CatalogService>().setRating(show.sources.first.id, 0);

            // Resume playback if it was currently playing
            if (isCurrentlyPlaying && resumeSource != null) {
              audioProvider.playSource(
                show,
                resumeSource,
                initialIndex: resumeIndex ?? 0,
                initialPosition: resumePosition,
              );
            }
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
