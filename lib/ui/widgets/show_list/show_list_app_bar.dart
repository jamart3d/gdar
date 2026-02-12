import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';

class ShowListAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Animation<double> randomPulseAnimation;
  final Animation<double> searchPulseAnimation;
  final bool isRandomShowLoading;
  final VoidCallback onRandomPlay;
  final VoidCallback onToggleSearch;
  final VoidCallback onTitleTap;
  final Color? backgroundColor;
  final bool enableDiceHaptics;

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
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: backgroundColor,
      title: GestureDetector(
        onTap: onTitleTap,
        child: const ShakedownTitle(
          fontSize: 16,
          animateOnStart: true,
          shakeDelay: Duration(milliseconds: 1700),
        ),
      ),
      actions: _buildActions(context),
    );
  }

  List<Widget> _buildActions(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    final isTv = context.watch<DeviceService>().isTv;

    Widget wrap(Widget child, {VoidCallback? onTap, BorderRadius? radius}) {
      if (isTv) {
        return TvFocusWrapper(
          onTap: onTap,
          borderRadius: radius ?? BorderRadius.circular(28),
          child: child,
        );
      }
      return child;
    }

    return [
      if (settingsProvider.nonRandom)
        if (isRandomShowLoading)
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
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
                child: CircularProgressIndicator(strokeWidth: 2.5)),
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
                    shape: CircleBorder(
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
          onPressed: () async {
            // Pause global clock before navigating to generic pages (Settings)
            // to prevent "visual jumps" when returning.
            try {
              context.read<AnimationController>().stop();
            } catch (_) {}

            await Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const SettingsScreen(),
                transitionDuration: Duration.zero,
              ),
            );

            // Resume clock on return
            if (context.mounted) {
              try {
                final controller = context.read<AnimationController>();
                if (!controller.isAnimating) controller.repeat();
              } catch (_) {}
            }
          },
        ),
        onTap: () async {
          // Trigger the same logic as IconButton's onPressed
          try {
            context.read<AnimationController>().stop();
          } catch (_) {}

          await Navigator.of(context).push(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SettingsScreen(),
              transitionDuration: Duration.zero,
            ),
          );

          if (context.mounted) {
            try {
              final controller = context.read<AnimationController>();
              if (!controller.isAnimating) controller.repeat();
            } catch (_) {}
          }
        },
      ),
    ];
  }
}
