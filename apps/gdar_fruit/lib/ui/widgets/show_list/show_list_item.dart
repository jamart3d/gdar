import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/catalog_service.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:gdar_fruit/ui/widgets/show_list/show_list_card.dart';
import 'package:gdar_fruit/ui/widgets/show_list_item_details.dart';
import 'package:shakedown_core/ui/widgets/swipe_action_background.dart';

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
    final settingsProvider = context.watch<SettingsProvider>();

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
      alwaysShowRatingInteraction: isTv,
      focusNode: isTv ? focusNode : null,
      onFocusChange: isTv
          ? (focused) {
              if (focused) onFocusChange?.call(index);
            }
          : null,
      onKeyEvent: isTv
          ? (node, event) {
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
                    final shows =
                        context.read<ShowListProvider>().filteredShows;
                    onWrapAround?.call(shows.length - 1);
                  }
                  return KeyEventResult.handled; // Anchor
                }
              }
              return KeyEventResult.ignored;
            }
          : null,
    );

    return Column(
      key: ValueKey('${show.name}_${show.date}'),
      children: [
        if (isTv)
          card
        else
          Dismissible(
            key: ValueKey('${show.name}_${show.date}'),
            direction: settingsProvider.enableSwipeToBlock
                ? DismissDirection.endToStart
                : DismissDirection.none,
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
    unawaited(AppHaptics.selectionClick(context.read<DeviceService>()));

    final isCurrentlyPlaying = audioProvider.currentShow == show;

    if (isCurrentlyPlaying) {
      unawaited(audioProvider.stopAndClear());
    }

    // Mark ONLY the representative source as Blocked (Red Star / -1)
    unawaited(
        context.read<CatalogService>().setRating(show.sources.first.id, -1));

    showMessage(
      context,
      show.sources.length > 1
          ? 'Blocked source "${show.sources.first.id}"'
          : 'Blocked',
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
