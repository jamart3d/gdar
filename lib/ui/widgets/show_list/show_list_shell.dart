import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/mini_player.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_app_bar.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_search_bar.dart';
import 'package:shakedown/ui/widgets/show_list/clipboard_feedback_overlay.dart';

/// The layout shell for [ShowListScreen], including AppBar, SearchBar, and MiniPlayer.
class ShowListShell extends StatelessWidget {
  final Color backgroundColor;
  final Animation<double> randomPulseAnimation;
  final Animation<double> searchPulseAnimation;
  final bool isRandomShowLoading;
  final VoidCallback onRandomPlay;
  final VoidCallback onToggleSearch;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final Function(String) onSearchSubmitted;
  final Duration animationDuration;
  final Widget body;
  final VoidCallback onOpenPlaybackScreen;
  final bool showPasteFeedback;
  final VoidCallback onTitleTap;

  const ShowListShell({
    super.key,
    required this.backgroundColor,
    required this.randomPulseAnimation,
    required this.searchPulseAnimation,
    required this.isRandomShowLoading,
    required this.onRandomPlay,
    required this.onToggleSearch,
    required this.searchController,
    required this.searchFocusNode,
    required this.onSearchSubmitted,
    required this.animationDuration,
    required this.body,
    required this.onOpenPlaybackScreen,
    required this.showPasteFeedback,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: ShowListAppBar(
        backgroundColor: backgroundColor,
        randomPulseAnimation: randomPulseAnimation,
        searchPulseAnimation: searchPulseAnimation,
        isRandomShowLoading: isRandomShowLoading,
        onRandomPlay: onRandomPlay,
        onToggleSearch: onToggleSearch,
        onTitleTap: onTitleTap,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              ShowListSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                onSubmitted: onSearchSubmitted,
                animationDuration: animationDuration,
              ),
              Expanded(child: body),
            ],
          ),
          if (audioProvider.currentShow != null &&
              !(showListProvider.isSearchVisible && searchFocusNode.hasFocus))
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: MiniPlayer(
                onTap: onOpenPlaybackScreen,
              ),
            ),
          ClipboardFeedbackOverlay(isVisible: showPasteFeedback),
        ],
      ),
    );
  }
}
