import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/shakedown_title.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';
import 'package:shakedown/providers/theme_provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/utils/font_layout_config.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TvHeader extends StatelessWidget {
  final VoidCallback onRandomPlay;
  final Animation<double>? randomPulseAnimation;
  final bool enableDiceHaptics;
  final bool autofocusDice;
  final FocusNode? diceFocusNode;
  final FocusNode? gearsFocusNode;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final bool isActive;

  const TvHeader({
    super.key,
    required this.onRandomPlay,
    this.randomPulseAnimation,
    this.enableDiceHaptics = false,
    this.autofocusDice = false,
    this.diceFocusNode,
    this.gearsFocusNode,
    this.onLeft,
    this.onRight,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showListProvider = context.watch<ShowListProvider>();
    final settingsProvider = context.watch<SettingsProvider>();
    final isChoosingRandomShow = showListProvider.isChoosingRandomShow;

    final double scaleFactor =
        FontLayoutConfig.getEffectiveScale(context, settingsProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(16 * scaleFactor, 12 * scaleFactor,
          16 * scaleFactor, 8 * scaleFactor),
      child: Row(
        children: [
          // 1. Dice Icon (Large)
          TvFocusWrapper(
            onTap: onRandomPlay,
            autofocus: autofocusDice,
            focusNode: diceFocusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  onLeft?.call();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  gearsFocusNode?.requestFocus();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            borderRadius: BorderRadius.circular(12 * scaleFactor),
            child: SizedBox(
              width: 56 * scaleFactor,
              height: 56 * scaleFactor,
              child: AnimatedDiceIcon(
                onPressed: onRandomPlay,
                isLoading: isChoosingRandomShow,
                enableHaptics: enableDiceHaptics,
                tooltip: 'Play Random Show',
              ),
            ),
          ),
          SizedBox(width: 16 * scaleFactor),
          // 2. Title Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isActive ? 1.0 : 0.5,
                  child: ShakedownTitle(
                    fontSize: 22 * scaleFactor,
                    animateOnStart: true,
                    shakeDelay: const Duration(milliseconds: 1700),
                  ),
                ),
              ],
            ),
          ),
          // 3. Settings Gear
          TvFocusWrapper(
            onTap: () async {
              await Navigator.of(context).push(
                PageRouteBuilder(
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const SettingsScreen(),
                  transitionDuration: const Duration(milliseconds: 80),
                ),
              );
            },
            focusNode: gearsFocusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent) {
                if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                  diceFocusNode?.requestFocus();
                  return KeyEventResult.handled;
                } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
                  onRight?.call();
                  return KeyEventResult.handled;
                }
              }
              return KeyEventResult.ignored;
            },
            borderRadius: BorderRadius.circular(50 * scaleFactor),
            child: Container(
              padding: EdgeInsets.all(10 * scaleFactor),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Icon(
                context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit
                    ? LucideIcons.settings
                    : Icons.settings_rounded,
                size: 24 * scaleFactor,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
