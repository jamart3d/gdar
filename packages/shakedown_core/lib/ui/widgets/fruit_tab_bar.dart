import 'dart:ui';

import 'package:gdar_design/typography/font_config.dart';
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
    final deviceService = context.watch<DeviceService>();

    final double scaleFactor = FontLayoutConfig.getEffectiveScale(
      context,
      settingsProvider,
    );

    final double screenWidth = MediaQuery.sizeOf(context).width;

    final isDarkMode = theme.brightness == Brightness.dark;
    final isTrueBlackMode = isDarkMode && settingsProvider.useTrueBlack;
    final isFruitColor = themeProvider.themeStyle == ThemeStyle.fruit;
    final double denseMultiplier =
        isFruitColor && !settingsProvider.fruitDenseList ? 1.3 : 1.0;
    final double tabScaleFactor = scaleFactor * denseMultiplier;
    final bool hideTabText = settingsProvider.hideTabText;
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

    // Reduce horizontal padding if in PWA standalone mode OR if the web window is narrow
    // to allow items to spread closer to the edge.
    final double sidePadding = (deviceService.isPwa || screenWidth < 600)
        ? 8.0 * tabScaleFactor
        : 32.0 * tabScaleFactor;

    final content = Container(
      decoration: BoxDecoration(color: backgroundColor),
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      child: SizedBox(
        height: (48.0 + 32.0) * tabScaleFactor, // Base content + padding space
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: sidePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: _FruitTabItem(
                  icon: LucideIcons.playCircle,
                  label: 'PLAYING',
                  isActive: selectedIndex == 0,
                  scaleFactor: tabScaleFactor,
                  hideText: hideTabText,
                  onTap: () {
                    if (audioProvider.currentShow != null) {
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
                  scaleFactor: tabScaleFactor,
                  hideText: hideTabText,
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
                  scaleFactor: tabScaleFactor,
                  hideText: hideTabText,
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
                  scaleFactor: tabScaleFactor,
                  hideText: hideTabText,
                  onTap: () {
                    onTabSelected(3);
                  },
                ),
              ),
            ],
          ),
        ),
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
        child: DecoratedBox(decoration: decoration, child: stack),
      );
    }

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
        child: DecoratedBox(decoration: decoration, child: stack),
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
  final bool hideText;

  final bool isLoading;
  final bool enableHaptics;
  final bool useAnimatedRandomIcon;

  const _FruitTabItem({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.scaleFactor,
    required this.onTap,
    this.hideText = false,
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
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
    final double iconSize = (widget.hideText ? 30 : 24) * widget.scaleFactor;

    // Fixed layout slots to prevent vertical drift
    final double iconSlotHeight = 32.0 * widget.scaleFactor;
    final double textSlotHeight = 16.0 * widget.scaleFactor;
    final double totalHeight = (48.0) * widget.scaleFactor;

    return SizedBox(
      height: totalHeight,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Slot: Always centered in the same vertical range
          SizedBox(
            height: iconSlotHeight,
            child: Center(
              child: (widget.label == 'RANDOM' && widget.useAnimatedRandomIcon)
                  ? AnimatedDiceIcon(
                      onPressed: widget.onTap,
                      isLoading: widget.isLoading,
                      enableHaptics: widget.enableHaptics,
                      naked: true,
                      disableSquash: true,
                      useLucide: true,
                      iconColor: color,
                    )
                  : Icon(widget.icon, color: color, size: iconSize),
            ),
          ),

          // Label Slot: Occupies fixed space if visible, otherwise empty but stable
          if (!widget.hideText)
            SizedBox(
              height: textSlotHeight,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(height: 2 * widget.scaleFactor), // Reduced gap
                  Text(
                    widget.label.toUpperCase(),
                    style: TextStyle(
                      fontFamily: FontConfig.resolve('Inter'),
                      fontSize: 8.5 * widget.scaleFactor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2.0,
                      color: color,
                    ),
                  ),
                ],
              ),
            )
          else
            // Reserve invisible space if you want ZERO movement,
            // but usually we allow the item to center slightly if the bar height is fixed.
            // Since we already fixed the TabBar height to 80,
            // the 48px slot is already centered.
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
