import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/theme/fruit_ui.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/ui/widgets/show_list/show_list_search_bar.dart';

class ShowListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Animation<double> randomPulseAnimation;
  final Animation<double> searchPulseAnimation;
  final bool isRandomShowLoading;
  final VoidCallback onRandomPlay;
  final VoidCallback onToggleSearch;
  final VoidCallback onTitleTap;
  final Color? backgroundColor;
  final bool enableDiceHaptics;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final Function(String)? onSearchSubmitted;

  const ShowListAppBar({
    super.key,
    required this.randomPulseAnimation,
    required this.searchPulseAnimation,
    required this.isRandomShowLoading,
    required this.onRandomPlay,
    required this.onToggleSearch,
    required this.onTitleTap,
    this.backgroundColor,
    this.enableDiceHaptics = false,
    this.searchController,
    this.searchFocusNode,
    this.onSearchSubmitted,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.isFruit;
    final settingsProvider = context.watch<SettingsProvider>();
    final isLiquidGlassOff =
        isFruit && !settingsProvider.fruitEnableLiquidGlass;
    final isDarkMode =
        isFruit && Theme.of(context).brightness == Brightness.dark;

    final Color? appBarBg = isLiquidGlassOff
        ? (isDarkMode
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).scaffoldBackgroundColor)
        : backgroundColor;

    if (isFruit) {
      return _buildFruitFloatingHeader(context);
    }

    return AppBar(
      backgroundColor: appBarBg,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      shape: isFruit ? const Border(bottom: BorderSide.none) : null,
      title: const ShakedownTitle(
        fontSize: 16,
        animateOnStart: true,
        shakeDelay: Duration(milliseconds: 1700),
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    final isTv = context.watch<DeviceService>().isTv;

    Widget wrap(Widget child,
        {VoidCallback? onTap, BorderRadius? radius, bool isCircle = false}) {
      final Widget wrapped = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8.0),
        child: isTv
            ? TvFocusWrapper(
                onTap: onTap,
                borderRadius:
                    radius ?? BorderRadius.circular(isCircle ? 28 : 12),
                child: child,
              )
            : child,
      );

      return wrapped;
    }

    return [
      if (settingsProvider.nonRandom)
        if (isRandomShowLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          wrap(
            IconButton(
              icon: const Icon(Icons.playlist_play_rounded),
              onPressed: onRandomPlay,
              tooltip: 'Play Next Show',
            ),
            onTap: onRandomPlay,
          )
      else if (settingsProvider.simpleRandomIcon)
        if (isRandomShowLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          )
        else
          wrap(
            ScaleTransition(
              scale: randomPulseAnimation,
              child: IconButton(
                icon: const Icon(Icons.question_mark_rounded),
                onPressed: onRandomPlay,
                tooltip: 'Play Random Show',
              ),
            ),
            onTap: onRandomPlay,
          )
      else
        // Expressive Animated Dice (M3)
        // Handles its own loading state (spinning)
        wrap(
          AnimatedDiceIcon(
            onPressed: onRandomPlay,
            isLoading: isRandomShowLoading,
            enableHaptics: enableDiceHaptics,
            tooltip: 'Play Random Show',
            useLucide: false,
          ),
          onTap: onRandomPlay,
          radius: BorderRadius.circular(12),
        ),
      // Gap removed to match spacing between Search and Settings (standard AppBar spacing)
      wrap(
        ScaleTransition(
          scale: searchPulseAnimation,
          child: IconButton(
            icon: const Icon(Icons.search_rounded),
            isSelected: showListProvider.isSearchVisible,
            style: showListProvider.isSearchVisible
                ? IconButton.styleFrom(
                    backgroundColor: colorScheme.surfaceContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                      side: BorderSide(color: colorScheme.outline),
                    ),
                  )
                : null,
            onPressed: onToggleSearch,
          ),
        ),
        onTap: onToggleSearch,
      ),
      wrap(
        IconButton(
          icon: const Icon(Icons.settings_rounded),
          iconSize: 24.0,
          onPressed: () async {
            // Pause global clock before navigating to generic pages (Settings)
            // to prevent "visual jumps" when returning.
            try {
              context.read<AnimationController>().stop();
            } catch (_) {}

            unawaited(Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SettingsScreen(),
                transitionDuration: Duration.zero,
              ),
            ));

            // Resume clock on return
            if (context.mounted) {
              try {
                final controller = context.read<AnimationController>();
                if (!controller.isAnimating) {
                  unawaited(controller.repeat());
                }
              } catch (_) {}
            }
          },
          tooltip: 'Settings',
        ),
        onTap: () async {
          // Trigger the same logic as icon button handler
          try {
            context.read<AnimationController>().stop();
          } catch (_) {}

          unawaited(Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SettingsScreen(),
              transitionDuration: Duration.zero,
            ),
          ));

          if (context.mounted) {
            try {
              final controller = context.read<AnimationController>();
              if (!controller.isAnimating) unawaited(controller.repeat());
            } catch (_) {}
          }
        },
      ),
    ];
  }

  Widget _buildFruitFloatingHeader(BuildContext context) {
    final showListProvider = context.watch<ShowListProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Center(
        child: Row(
          children: [
            // Left/Center Area: Title or Search
            Expanded(
              child: showListProvider.isSearchVisible &&
                      searchController != null &&
                      searchFocusNode != null
                  ? Row(
                      children: [
                        Expanded(
                          child: ShowListSearchBar(
                            controller: searchController!,
                            focusNode: searchFocusNode!,
                            onSubmitted: onSearchSubmitted ?? (_) {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        FruitTextAction(
                          label: 'Cancel',
                          onPressed: () {
                            showListProvider.setSearchVisible(false);
                            searchController!.clear();
                          },
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const ShakedownTitle(
                          fontSize: 20,
                          animateOnStart: true,
                          shakeDelay: Duration(milliseconds: 1700),
                        ),
                        _buildFruitHeaderButton(
                          context,
                          icon: LucideIcons.search,
                          onPressed: onToggleSearch,
                        ),
                      ],
                    ),
            ),
            const SizedBox(width: 12),
            // Right Area: Fixed Theme Toggle (Never Moves)
            _buildFruitHeaderButton(
              context,
              icon: Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              onPressed: () {
                context.read<ThemeProvider>().toggleTheme();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFruitHeaderButton(BuildContext context,
      {required IconData icon, required VoidCallback onPressed}) {
    return FruitActionButton(
      icon: icon,
      onPressed: onPressed,
    );
  }
}
