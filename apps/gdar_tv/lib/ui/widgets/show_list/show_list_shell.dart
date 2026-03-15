import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/ui/widgets/mini_player.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_app_bar.dart';
import 'package:shakedown_core/ui/widgets/show_list/show_list_search_bar.dart';
import 'package:shakedown_core/ui/widgets/show_list/clipboard_feedback_overlay.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/fruit_tab_bar.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_ui.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

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
  final bool showFruitTabBar;

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
    this.showFruitTabBar = true,
  });

  Widget _buildFruitHeader(BuildContext context) {
    return Container(
      height: MediaQuery.paddingOf(context).top + 80,
      padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
      decoration: const BoxDecoration(border: null),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final settingsProvider = context
        .watch<SettingsProvider>(); // Defined settingsProvider
    final bool isFruit = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool disableShader = kIsWeb && isWasmRuntime();

    // MiniPlayer logic:
    // - Always show in Android style if a track is loaded.
    // - Hide in Fruit style because FruitTabBar provides a dedicated Play tab.
    // - Always hide on TV as it has a dedicated layout.
    final bool shouldShowMiniPlayer =
        !settingsProvider.isTv &&
        !isFruit &&
        audioProvider.currentTrack != null;

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
            child: (settingsProvider.performanceMode || disableShader)
                ? FruitSurface(
                    borderRadius: BorderRadius.zero,
                    showBorder: false,
                    blur: FruitTokens.blurSoft,
                    opacity: 0.9,
                    child: _buildFruitHeader(context),
                  )
                : ShaderMask(
                    shaderCallback: (bounds) {
                      return const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.black, Colors.transparent],
                        stops: [0.7, 1.0],
                      ).createShader(bounds);
                    },
                    blendMode: BlendMode.dstIn,
                    child: FruitSurface(
                      showBorder: false,
                      blur: FruitTokens.blurSoft,
                      opacity: 0.9,
                      borderRadius: BorderRadius.zero,
                      child: _buildFruitHeader(context),
                    ),
                  ),
          ),
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          left: 0,
          right: 0,
          bottom: shouldShowMiniPlayer ? (isFruit ? 80.0 : 0.0) : -120,
          child: AnimatedOpacity(
            duration: const Duration(milliseconds: 400),
            opacity: shouldShowMiniPlayer ? 1.0 : 0.0,
            child: MiniPlayer(onTap: onOpenPlaybackScreen),
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
      bottomNavigationBar: isFruit && !isPane && showFruitTabBar
          ? FruitTabBar(
              selectedIndex: 1,
              onTabSelected: (index) {
                if (index == 0) {
                  onOpenPlaybackScreen();
                } else if (index == 2) {
                  onRandomPlay();
                } else if (index == 3) {
                  onTitleTap();
                }
              },
            )
          : null,
    );
  }
}
