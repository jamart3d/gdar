import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/show_list/fast_scrollbar.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_item.dart';
import 'package:shakedown/ui/widgets/tv/tv_scrollbar.dart';

/// The scrollable list of shows displayed in [ShowListScreen].
class ShowListBody extends StatelessWidget {
  final ShowListProvider showListProvider;
  final AudioProvider audioProvider;
  final SettingsProvider settingsProvider;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;
  final Animation<double> animation;
  final Function(Show) onShowTapped;
  final Function(Show) onCardLongPressed;
  final Function(Show, Source) onSourceTapped;
  final Function(Show, Source) onSourceLongPressed;
  final FocusNode? scrollbarFocusNode;
  final VoidCallback? onFocusLeft;
  final ValueChanged<int>? onShowFocused;
  final Map<int, FocusNode>? showFocusNodes;
  final void Function(int, {bool shouldScroll})? onFocusShow;

  const ShowListBody({
    super.key,
    required this.showListProvider,
    required this.audioProvider,
    required this.settingsProvider,
    required this.itemScrollController,
    required this.itemPositionsListener,
    required this.animation,
    required this.onShowTapped,
    required this.onCardLongPressed,
    required this.onSourceTapped,
    required this.onSourceLongPressed,
    this.scrollbarFocusNode,
    this.onFocusLeft,
    this.onShowFocused,
    this.showFocusNodes,
    this.onFocusShow,
  });

  @override
  Widget build(BuildContext context) {
    if (showListProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (showListProvider.error != null) {
      return Center(child: Text(showListProvider.error!));
    }
    if (showListProvider.filteredShows.isEmpty) {
      return const Center(
          child: Text('No shows match your search or filters.'));
    }

    final isTv = context.read<DeviceService>().isTv;

    final list = ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: EdgeInsets.only(
        bottom: isTv ? 40 : 160,
        right: isTv ? 0 : 28, // reserve space for fast scrollbar thumb
      ),
      itemCount: showListProvider.filteredShows.length,
      itemBuilder: (context, index) {
        final show = showListProvider.filteredShows[index];
        final key = showListProvider.getShowKey(show);
        final isExpanded = showListProvider.expandedShowKey == key;

        return ShowListItem(
          show: show,
          isExpanded: isExpanded,
          animation: animation,
          onTap: () => onShowTapped(show),
          onLongPress: () => onCardLongPressed(show),
          onSourceTap: (source) => onSourceTapped(show, source),
          onSourceLongPress: (source) => onSourceLongPressed(show, source),
          onFocusLeft: onFocusLeft,
          onFocusChange: onShowFocused,
          onWrapAround: onFocusShow,
          focusNode: showFocusNodes?[index],
          index: index,
        );
      },
    );

    if (isTv) {
      return Row(
        children: [
          Expanded(child: list),
          TvScrollbar(
            itemPositionsListener: itemPositionsListener,
            itemScrollController: itemScrollController,
            itemCount: showListProvider.filteredShows.length,
            focusNode: scrollbarFocusNode,
            onLeft: () {
              final positions = itemPositionsListener.itemPositions.value;
              if (positions.isEmpty) return;

              final visibleIndices = positions.map((p) => p.index).toSet();

              // 1. Prioritize currently expanded show IF it is visible
              if (showListProvider.expandedShowKey != null) {
                final index = showListProvider.filteredShows.indexWhere((s) =>
                    showListProvider.getShowKey(s) ==
                    showListProvider.expandedShowKey);
                if (index != -1 && visibleIndices.contains(index)) {
                  onFocusShow?.call(index, shouldScroll: false);
                  return;
                }
              }

              // 2. Fallback: Find middle visible item
              final sorted = positions.toList()
                ..sort((a, b) => a.index.compareTo(b.index));

              double bestDistance = 999.0;
              int targetIndex = -1;
              for (var pos in sorted) {
                final itemCenter =
                    (pos.itemLeadingEdge + pos.itemTrailingEdge) / 2;
                final distance = (itemCenter - 0.5).abs();
                if (distance < bestDistance) {
                  bestDistance = distance;
                  targetIndex = pos.index;
                }
              }

              if (targetIndex != -1) {
                final show = showListProvider.filteredShows[targetIndex];
                if (showListProvider.expandedShowKey !=
                    showListProvider.getShowKey(show)) {
                  showListProvider
                      .expandShow(showListProvider.getShowKey(show));
                }
                onFocusShow?.call(targetIndex, shouldScroll: false);
              }
            },
            onRight: () {
              FocusScope.of(context).focusInDirection(TraversalDirection.right);
            },
          ),
        ],
      );
    }

    // Phone: measure mini player height accurately from its layout constants
    // rather than hardcoding, so it works across all device safe area sizes.
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    // MiniPlayer content breakdown at scaleFactor=1.0:
    //   progress bar:    4px
    //   top padding:    20px
    //   title:          19px * 2.2 lineHeight ≈ 42px
    //   bottom padding: 20px
    //   ─────────────────────
    //   content total:  86px  + device bottom safe area
    final miniPlayerHeight =
        audioProvider.currentTrack != null ? 86.0 + bottomSafeArea : 0.0;

    return Stack(
      children: [
        list,
        FastScrollbar(
          shows: showListProvider.filteredShows,
          itemScrollController: itemScrollController,
          itemPositionsListener: itemPositionsListener,
          bottomPadding: miniPlayerHeight,
        ),
      ],
    );
  }
}
