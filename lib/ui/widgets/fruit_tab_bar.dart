import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown/providers/audio_provider.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/utils/utils.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/ui/widgets/theme/liquid_glass_wrapper.dart';
import 'package:shakedown/providers/theme_provider.dart';

class FruitTabBar extends StatelessWidget {
  final VoidCallback onOpenPlaybackScreen;
  final int selectedIndex;

  const FruitTabBar({
    super.key,
    required this.onOpenPlaybackScreen,
    this.selectedIndex = 1, // Default to LIBRARY
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    final isDarkMode = theme.brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final isFruitColor = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool isLiquidGlassOff =
        isFruitColor && !settingsProvider.fruitEnableLiquidGlass;

    final backgroundColor = isLiquidGlassOff
        ? (isDarkMode ? colorScheme.surface : theme.scaffoldBackgroundColor)
        : (isTrueBlackMode
            ? Colors.black.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.4)); // Matches liquid glass

    final content = Container(
      padding: EdgeInsets.fromLTRB(
        32.0 * scaleFactor, // px-8
        16.0 * scaleFactor, // pt-4
        32.0 * scaleFactor, // px-8
        16.0 * scaleFactor + MediaQuery.paddingOf(context).bottom, // pb-8
      ),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: isLiquidGlassOff
            ? null // No "hard line" in high-contrast mode
            : Border(
                top: BorderSide(
                  color: isTrueBlackMode
                      ? colorScheme.onSurface.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.6), // border-white/60
                  width: 1.0,
                ),
              ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _FruitTabItem(
            icon: LucideIcons.playCircle,
            label: 'NOW',
            isActive: selectedIndex == 0,
            scaleFactor: scaleFactor,
            onTap: () {
              if (audioProvider.currentTrack != null) {
                onOpenPlaybackScreen();
              } else {
                showMessage(context, 'No track playing');
              }
            },
          ),
          _FruitTabItem(
            icon: LucideIcons.library,
            label: 'LIBRARY',
            isActive: selectedIndex == 1,
            scaleFactor: scaleFactor,
            onTap: () {
              if (selectedIndex != 1) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
          ),
          _FruitTabItem(
            icon: LucideIcons.cassetteTape,
            label: 'SOURCE',
            isActive: selectedIndex == 2,
            isLoading: showListProvider.isChoosingRandomShow,
            scaleFactor: scaleFactor,
            onTap: () {
              // Keeping random for now as it was mapped to index 2
              audioProvider.playRandomShow();
            },
          ),
          _FruitTabItem(
            icon: LucideIcons.settings,
            label: 'SETTINGS',
            isActive: selectedIndex == 3,
            scaleFactor: scaleFactor,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
    );

    if (isTrueBlackMode || isLiquidGlassOff) {
      return content;
    }

    return LiquidGlassWrapper(
      enabled: settingsProvider.useNeumorphism, // Always blur when appropriate
      blur: 16.0,
      opacity: 0.4,
      borderRadius: BorderRadius.zero,
      child: content,
    );
  }
}

class _FruitTabItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final double scaleFactor;
  final VoidCallback onTap;

  final bool isLoading;

  const _FruitTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.scaleFactor,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  State<_FruitTabItem> createState() => _FruitTabItemState();
}

class _FruitTabItemState extends State<_FruitTabItem> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = widget.isActive
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6); // text-slate-400

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.6 : 1.0,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.label == 'SOURCE')
              AnimatedDiceIcon(
                onPressed: widget.onTap,
                isLoading: widget.isLoading,
                naked: true,
                disableSquash: true,
                useLucide: true,
              )
            else
              Icon(
                widget.icon,
                color: color,
                size: 24 * widget.scaleFactor, // w-6 h-6
              ),
            SizedBox(height: 6 * widget.scaleFactor), // gap-1.5
            Text(
              widget.label.toUpperCase(),
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 9 * widget.scaleFactor, // text-[9px]
                fontWeight: FontWeight.w700, // font-bold
                letterSpacing: 2.0, // tracking-widest
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
