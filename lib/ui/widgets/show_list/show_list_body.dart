import 'package:flutter/material.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/models/show.dart';
import 'package:shakedown/models/source.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_item.dart';

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

    return ScrollablePositionedList.builder(
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 160),
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
        );
      },
    );
  }
}
