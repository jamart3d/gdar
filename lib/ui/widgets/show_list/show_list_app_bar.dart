import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/widgets/theme/neumorphic_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:lucide_icons/lucide_icons.dart';

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
    final themeStyle = context.watch<ThemeProvider>().themeStyle;
    final isFruit = themeStyle == ThemeStyle.fruit && kIsWeb;
    final useNeumorphic = settingsProvider.useNeumorphism &&
        isFruit &&
        !settingsProvider.useTrueBlack;

    Widget wrap(Widget child,
        {VoidCallback? onTap,
        BorderRadius? radius,
        bool isCircle = false, // Standardize to rounded square for Fruit
        double intensity = 1.2}) {
      Widget interactive = child;
      if (useNeumorphic) {
        interactive = NeumorphicWrapper(
          isCircle: isCircle,
          borderRadius: radius?.topLeft.x ?? 12,
          intensity: intensity,
          // Background color for the glass effect
          color: Colors.transparent,
          child: LiquidGlassWrapper(
            enabled: true,
            borderRadius: radius ?? BorderRadius.circular(isCircle ? 28 : 12),
            opacity: 0.08, // Slightly more subtle glass
            blur: 5, // Sharper subtle blur
            child: child,
          ),
        );
      }

      final Widget wrapped = Padding(
        padding: EdgeInsets.symmetric(
            horizontal: kIsWeb ? (isFruit ? 16.0 : 8.0) : 8.0),
        child: isTv
            ? TvFocusWrapper(
                onTap: onTap,
                borderRadius:
                    radius ?? BorderRadius.circular(isCircle ? 28 : 12),
                child: interactive,
              )
            : interactive,
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
                child: CircularProgressIndicator(strokeWidth: 2.5)),
          )
        else
          wrap(
            IconButton(
              icon: Icon(isFruit
                  ? LucideIcons.playCircle
                  : Icons.playlist_play_rounded),
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
            settingsProvider.useNeumorphism
                ? IconButton(
                    icon: Icon(isFruit
                        ? LucideIcons.helpCircle
                        : Icons.question_mark_rounded),
                    onPressed: onRandomPlay,
                    tooltip: 'Play Random Show',
                  )
                : ScaleTransition(
                    scale: randomPulseAnimation,
                    child: IconButton(
                      icon: Icon(isFruit
                          ? LucideIcons.helpCircle
                          : Icons.question_mark_rounded),
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
            useLucide: isFruit,
          ),
          onTap: onRandomPlay,
          radius: BorderRadius.circular(12),
        ),
      // Gap removed to match spacing between Search and Settings (standard AppBar spacing)
      wrap(
        settingsProvider.useNeumorphism
            ? IconButton(
                icon: Icon(isFruit ? LucideIcons.search : Icons.search_rounded),
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
              )
            : ScaleTransition(
                scale: searchPulseAnimation,
                child: IconButton(
                  icon:
                      Icon(isFruit ? LucideIcons.search : Icons.search_rounded),
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
          icon: Icon(isFruit ? LucideIcons.settings : Icons.settings_rounded),
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
                if (!controller.isAnimating) unawaited(controller.repeat());
              } catch (_) {}
            }
          },
        ),
        onTap: () async {
          // Trigger the same logic as IconButton's onPressed
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
}
