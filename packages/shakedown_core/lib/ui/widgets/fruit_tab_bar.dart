import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shakedown_core/utils/web_runtime.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shakedown_core/providers/audio_provider.dart';
import 'package:shakedown_core/utils/utils.dart';
import 'package:shakedown_core/utils/font_layout_config.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/show_list_provider.dart';
import 'package:shakedown_core/ui/widgets/show_list/animated_dice_icon.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/services/device_service.dart';
import 'package:shakedown_core/utils/app_haptics.dart';
import 'package:shakedown_core/ui/styles/font_config.dart';

class FruitTabBar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTabSelected;

  const FruitTabBar({
    super.key,
    this.selectedIndex = 1, // Default to LIBRARY
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final audioProvider = context.watch<AudioProvider>();
    final themeProvider = context.watch<ThemeProvider>();
    final showListProvider = context.watch<ShowListProvider>();

    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final isDarkMode = theme.brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final isFruitColor = themeProvider.themeStyle == ThemeStyle.fruit;
    final bool isLiquidGlassEnabled =
        isFruitColor && settingsProvider.fruitEnableLiquidGlass;
    final bool isLiquidGlassOff = isFruitColor && !isLiquidGlassEnabled;

    final backgroundColor = isTrueBlackMode
        ? Colors.black.withValues(alpha: 0.85)
        : isLiquidGlassEnabled
        ? Colors.transparent
        : isLiquidGlassOff
        ? (isDarkMode ? colorScheme.surface : theme.scaffoldBackgroundColor)
        : Colors.white.withValues(alpha: 0.4); // Matches liquid glass

    final content = Container(
      padding: EdgeInsets.fromLTRB(
        32.0 * scaleFactor, // px-8
        16.0 * scaleFactor, // pt-4
        32.0 * scaleFactor, // px-8
        16.0 * scaleFactor + MediaQuery.paddingOf(context).bottom, // pb-8
      ),
      decoration: BoxDecoration(color: backgroundColor),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: _FruitTabItem(
              icon: LucideIcons.playCircle,
              label: 'PLAY',
              isActive: selectedIndex == 0,
              scaleFactor: scaleFactor,
              onTap: () {
                if (audioProvider.currentTrack != null) {
                  onTabSelected(0);
                } else {
                  showMessage(context, 'No track playing');
                }
              },
            ),
          ),
          Expanded(
            child: _FruitTabItem(
              icon: LucideIcons.library,
              label: 'LIBRARY',
              isActive: selectedIndex == 1,
              scaleFactor: scaleFactor,
              onTap: () {
                onTabSelected(1);
              },
            ),
          ),
          Expanded(
            child: _FruitTabItem(
              icon: settingsProvider.nonRandom
                  ? LucideIcons.skipForward
                  : LucideIcons.dice5,
              label: settingsProvider.nonRandom ? 'NEXT' : 'RANDOM',
              isActive: selectedIndex == 2,
              isLoading: showListProvider.isChoosingRandomShow,
              enableHaptics: settingsProvider.enableHaptics,
              useAnimatedRandomIcon:
                  !settingsProvider.nonRandom &&
                  !settingsProvider.simpleRandomIcon,
              scaleFactor: scaleFactor,
              onTap: () {
                AppHaptics.selectionClick(
                  context.read<DeviceService>(),
                  enabled: settingsProvider.enableHaptics,
                );
                onTabSelected(2);
              },
            ),
          ),
          Expanded(
            child: _FruitTabItem(
              icon: LucideIcons.settings,
              label: 'SETTINGS',
              isActive: selectedIndex == 3,
              scaleFactor: scaleFactor,
              onTap: () {
                onTabSelected(3);
              },
            ),
          ),
        ],
      ),
    );

    if (isTrueBlackMode || isLiquidGlassOff || !kIsWeb) {
      return content;
    }

    return _FruitTabBarShell(child: content);
  }
}

class _FruitTabBarShell extends StatelessWidget {
  final Widget child;

  const _FruitTabBarShell({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Conservative blur budget matching LiquidGlassWrapper web pattern.
    // Skip blur entirely on WASM (no compositor support).
    final bool skipBlur = isWasmSafeMode();
    final double sigma = MediaQuery.sizeOf(context).shortestSide < 700
        ? 8.0
        : 12.0;
    final baseColor = isDark ? Colors.black : Colors.white;
    final baseAlpha = isDark ? 0.55 : 0.65;

    final decoration = BoxDecoration(
      color: baseColor.withValues(alpha: baseAlpha),
      border: Border(
        top: BorderSide(
          color: isDark
              ? Colors.white.withValues(alpha: 0.14)
              : Colors.black.withValues(alpha: 0.08),
          width: 0.7,
        ),
      ),
    );

    final stack = Stack(
      children: [
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 1.2,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: isDark ? 0.22 : 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.white.withValues(alpha: isDark ? 0.05 : 0.08),
                    Colors.white.withValues(alpha: 0.02),
                    Colors.transparent,
                  ],
                  stops: const [0.0, 0.12, 0.5],
                ),
              ),
            ),
          ),
        ),
        child,
      ],
    );

    if (skipBlur) {
      return ClipRect(
        child: DecoratedBox(
          decoration: decoration,
          child: stack,
        ),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(
          decoration: decoration,
          child: stack,
        ),
      ),
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
  final bool enableHaptics;
  final bool useAnimatedRandomIcon;

  const _FruitTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.scaleFactor,
    required this.onTap,
    this.isLoading = false,
    this.enableHaptics = false,
    this.useAnimatedRandomIcon = true,
  });

  @override
  State<_FruitTabItem> createState() => _FruitTabItemState();
}

class _FruitTabItemState extends State<_FruitTabItem> {
  bool _isPressed = false;
  bool _isFocused = false;

  void _activate() {
    if (_isPressed) {
      setState(() => _isPressed = false);
    }
    widget.onTap();
  }

  @override
  void didUpdateWidget(covariant _FruitTabItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) {
      if (_isPressed || _isFocused) {
        setState(() {
          _isPressed = false;
          _isFocused = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final color = widget.isActive
        ? colorScheme.primary
        : colorScheme.onSurfaceVariant.withValues(alpha: 0.6); // text-slate-400

    final semanticsLabel = '${widget.label.toLowerCase()} tab';
    final isSimple = context.watch<SettingsProvider>().performanceMode;

    return Semantics(
      button: true,
      selected: widget.isActive,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: FocusableActionDetector(
          enabled: true,
          mouseCursor: SystemMouseCursors.click,
          onShowFocusHighlight: (value) {
            setState(() => _isFocused = value);
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _activate();
                return null;
              },
            ),
          },
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: _activate,
            child: isSimple
                ? Opacity(
                    opacity: _isPressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
                    child: Transform.scale(
                      scale: _isPressed ? 0.94 : 1.0,
                      child: Container(
                        width: double.infinity,
                        color: Colors.transparent,
                        child: _buildTabContent(color),
                      ),
                    ),
                  )
                : AnimatedScale(
                    scale: _isPressed ? 0.94 : 1.0,
                    duration: const Duration(milliseconds: 100),
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 100),
                      opacity: _isPressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
                      child: Container(
                        width: double.infinity,
                        color: Colors.transparent,
                        child: _buildTabContent(color),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label == 'RANDOM' && widget.useAnimatedRandomIcon)
          AnimatedDiceIcon(
            onPressed: widget.onTap,
            isLoading: widget.isLoading,
            enableHaptics: widget.enableHaptics,
            naked: true,
            disableSquash: true,
            useLucide: true,
            iconColor: color,
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
            fontFamily: FontConfig.resolve('Inter'),
            fontSize: 9 * widget.scaleFactor, // text-[9px]
            fontWeight: FontWeight.w700, // font-bold
            letterSpacing: 2.0, // tracking-widest
            color: color,
          ),
        ),
      ],
    );
  }
}
