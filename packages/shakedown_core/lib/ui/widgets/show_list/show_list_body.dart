import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown_core/models/show.dart';
import 'package:shakedown_core/models/source.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/ui/widgets/show_list/fast_scrollbar.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_item.dart';
import 'package:shakedown_core/ui/widgets/tv/tv_scrollbar.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_activity_indicator.dart';
import 'package:shakedown_core/providers/theme_provider.dart';

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
  final VoidCallback? onFocusRight;
  final double topPadding;

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
    this.onFocusRight,
    this.topPadding = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    if (showListProvider.isLoading) {
      return const Center(child: FruitActivityIndicator());
    }
    if (showListProvider.error != null) {
      return Center(child: Text(showListProvider.error!));
    }
    if (showListProvider.filteredShows.isEmpty) {
      return const Center(
        child: Text('No shows match your search or filters.'),
      );
    }

    final isTv = context.watch<DeviceService>().isTv;
    final bool isFruit =
        context.read<ThemeProvider>().themeStyle == ThemeStyle.fruit;

    final list = ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: EdgeInsets.only(
        top: topPadding,
        left: isTv ? 6.0 : 0.0,
        bottom: isTv ? 28 : (isFruit ? 180 : 160),
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
                  onFocusRight: () {
                    if (settingsProvider.hideTvScrollbars) {
                      onFocusRight?.call();
                    } else if (scrollbarFocusNode != null) {
                      scrollbarFocusNode!.requestFocus();
                    }
                  },
          onFocusChange: onShowFocused,
          onWrapAround: onFocusShow,
          focusNode: showFocusNodes?[index],
          index: index,
        );
      },
    );

    // Phone: measure mini player height accurately from its layout constants
    // rather than hardcoding, so it works across all device safe area sizes.
    final bottomSafeArea = MediaQuery.of(context).padding.bottom;

    // MiniPlayer content breakdown at scaleFactor=1.0:
    //   progress bar:    4px
    //   top padding:    20px
    //   title:          19px * 2.2 lineHeight ≈ 42px
    //   bottom padding: 20px
    //   ─────────────────────
    // content total:  86px  + device bottom safe area
    final miniPlayerHeight =
        (audioProvider.currentTrack != null && !isFruit && !isTv)
        ? 86.0 + bottomSafeArea
        : 0.0;

    return Stack(
      children: [
        if (isTv)
          Row(
            children: [
              Expanded(child: list),
                if (context.read<DeviceService>().isTv && !settingsProvider.hideTvScrollbars)
                  TvScrollbar(
                    itemPositionsListener: itemPositionsListener,
                    itemScrollController: itemScrollController,
                    itemCount: showListProvider.filteredShows.length,
                    focusNode: scrollbarFocusNode,
                    onLeft: () {
                      final positions = itemPositionsListener.itemPositions.value;
                      if (positions.isNotEmpty) {
                        final firstVisible = positions
                            .where((p) => p.itemTrailingEdge > 0)
                            .reduce((min, p) => p.index < min.index ? p : min)
                            .index;
                        onFocusShow?.call(firstVisible, shouldScroll: false);
                      }
                    },
                    onRight: onFocusRight,
                  ),
            ],
          )
        else ...[
          list,
          FastScrollbar(
            shows: showListProvider.filteredShows,
            itemScrollController: itemScrollController,
            itemPositionsListener: itemPositionsListener,
            bottomPadding: miniPlayerHeight,
          ),
        ],
      ],
    );
  }
}
