import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/show_list_provider.dart';
import 'package:shakedown/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'package:shakedown/ui/screens/settings_screen.dart';

class TvHeader extends StatelessWidget {
  final VoidCallback onRandomPlay;
  final Animation<double>? randomPulseAnimation;
  final bool enableDiceHaptics;
  final bool autofocusDice;
  final FocusNode? diceFocusNode;
  final FocusNode? gearsFocusNode;
  final VoidCallback? onLeft;

  const TvHeader({
    super.key,
    required this.onRandomPlay,
    this.randomPulseAnimation,
    this.enableDiceHaptics = false,
    this.autofocusDice = false,
    this.diceFocusNode,
    this.gearsFocusNode,
    this.onLeft,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showListProvider = context.watch<ShowListProvider>();
    final isChoosingRandomShow = showListProvider.isChoosingRandomShow;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
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
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 56, // Reduced from 72
              height: 56, // Reduced from 72
              child: AnimatedDiceIcon(
                onPressed: onRandomPlay,
                isLoading: isChoosingRandomShow,
                enableHaptics: enableDiceHaptics,
                tooltip: 'Play Random Show',
              ),
            ),
          ),
          const SizedBox(width: 16),
          // 2. Title Text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'SHAKEDOWN',
                  style: TextStyle(
                    fontFamily: 'Rock Salt', // Or similar authoritative font
                    fontSize: 22, // Reduced from 32
                    height: 1.0,
                    fontWeight: FontWeight.bold,
                    color: colorScheme.onSurface,
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
                  transitionDuration: Duration.zero,
                ),
              );
            },
            focusNode: gearsFocusNode,
            onKeyEvent: (node, event) {
              if (event is KeyDownEvent &&
                  event.logicalKey == LogicalKeyboardKey.arrowLeft) {
                diceFocusNode?.requestFocus();
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            borderRadius: BorderRadius.circular(50),
            child: Container(
              padding: const EdgeInsets.all(10), // Reduced from 12
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color:
                    colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              ),
              child: Icon(
                Icons.settings_rounded,
                size: 24, // Reduced from 28
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
