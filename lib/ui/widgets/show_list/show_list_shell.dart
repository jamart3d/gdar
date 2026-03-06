import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/mini_player.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_app_bar.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_search_bar.dart';
import 'package:shakedown/ui/widgets/show_list/clipboard_feedback_overlay.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/fruit_tab_bar.dart';

/// The layout shell for [ShowListScreen], including AppBar, SearchBar, and MiniPlayer.
class ShowListShell extends StatelessWidget {
  final Color backgroundColor;
  final Animation<double> randomPulseAnimation;
  final Animation<double> searchPulseAnimation;
  final bool isRandomShowLoading;
  final bool enableDiceHaptics;
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
  final bool isPane;
  final FocusNode? scrollbarFocusNode;

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
    this.isPane = false,
    this.enableDiceHaptics = false,
    this.scrollbarFocusNode,
  });

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider =
        context.watch<SettingsProvider>(); // Defined settingsProvider
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    final bool isRollActive = showListProvider.isChoosingRandomShow;
    final bool shouldShowMiniPlayer = audioProvider.currentShow != null &&
        !isRollActive &&
        !isPane &&
        !isFruit &&
        !(showListProvider.isSearchVisible && searchFocusNode.hasFocus);

    final bodyContent = Stack(
      children: [
        Column(
          children: [
            if (!isFruit)
              ShowListSearchBar(
                controller: searchController,
                focusNode: searchFocusNode,
                onSubmitted: onSearchSubmitted,
                animationDuration: animationDuration,
              ),
            Expanded(child: body),
          ],
        ),
        if (isFruit)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ShaderMask(
              shaderCallback: (bounds) {
                return const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black, Colors.transparent],
                  stops: [
                    0.7,
                    1.0
                  ], // Fade begins earlier for smoother transition
                ).createShader(bounds);
              },
              blendMode: BlendMode.dstIn,
              child: LiquidGlassWrapper(
                enabled: isFruit && settingsProvider.fruitEnableLiquidGlass,
                showBorder: false, // Remove internal sharp border
                blur: 25,
                opacity: 0.85,
                borderRadius: BorderRadius.zero,
                child: Container(
                  height: MediaQuery.paddingOf(context).top + 80,
                  padding: EdgeInsets.only(
                    top: MediaQuery.paddingOf(context).top,
                  ),
                  decoration: const BoxDecoration(
                    // Removing the border entirely to ensure no sharp line
                    border: null,
                  ),
                  alignment: Alignment.topCenter,
                  child: SizedBox(
                    height: 80,
                    child: ShowListAppBar(
                      backgroundColor: Colors.transparent,
                      randomPulseAnimation: randomPulseAnimation,
                      searchPulseAnimation: searchPulseAnimation,
                      isRandomShowLoading: isRandomShowLoading,
                      enableDiceHaptics: enableDiceHaptics,
                      onRandomPlay: onRandomPlay,
                      onToggleSearch: onToggleSearch,
                      onTitleTap: onTitleTap,
                      searchController: searchController,
                      searchFocusNode: searchFocusNode,
                      onSearchSubmitted: onSearchSubmitted,
                    ),
                  ),
                ),
              ),
            ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: shouldShowMiniPlayer ? 0 : -100,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: shouldShowMiniPlayer ? 1.0 : 0.0,
            child: MiniPlayer(
              onTap: onOpenPlaybackScreen,
            ),
          ),
        ),
        ClipboardFeedbackOverlay(isVisible: showPasteFeedback),
      ],
    );

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: (isPane || isFruit)
          ? null
          : ShowListAppBar(
              backgroundColor: backgroundColor,
              randomPulseAnimation: randomPulseAnimation,
              searchPulseAnimation: searchPulseAnimation,
              isRandomShowLoading: isRandomShowLoading,
              enableDiceHaptics: enableDiceHaptics,
              onRandomPlay: onRandomPlay,
              onToggleSearch: onToggleSearch,
              onTitleTap: onTitleTap,
            ),
      body: bodyContent,
      bottomNavigationBar: isFruit && !isPane
          ? FruitTabBar(onOpenPlaybackScreen: onOpenPlaybackScreen)
          : null,
    );
  }
}
