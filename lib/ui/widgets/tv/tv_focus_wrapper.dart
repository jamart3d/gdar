import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';
import 'package:shakedown/utils/web_runtime.dart';

/// A wrapper widget that handles TV focus states with premium animations.
/// It provides a spring-based scale effect and optional RGB animated border.
class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleOnFocus;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final Color? focusBackgroundColor;
  final Color? focusColor;
  final bool showGlow;
  final bool useRgbBorder;
  final bool isPlaying;
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;
  final bool? overridePremiumHighlight;

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnFocus = 1.05,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius,
    this.focusColor,
    this.showGlow = false,
    this.useRgbBorder = false,
    this.isPlaying = false,
    this.onKeyEvent,
    this.focusBackgroundColor,
    this.onFocusChange,
    this.overridePremiumHighlight,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _longPressHandled = false;
  bool _isActionKeyPressed = false;

  @override
  void initState() {
    super.initState();
    // Initialize focus state from the node or autofocus property.
    _isFocused = widget.focusNode?.hasFocus ?? widget.autofocus;
  }

  @override
  void didUpdateWidget(TvFocusWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync focus state if the focus node or autofocus changed,
    // which is critical during widget recycling in lists.
    if (widget.focusNode != oldWidget.focusNode ||
        widget.autofocus != oldWidget.autofocus) {
      setState(() {
        _isFocused = widget.focusNode?.hasFocus ?? widget.autofocus;
      });
    }
  }

  void _handleFocusChange(bool focused) {
    if (!mounted) return;
    setState(() {
      _isFocused = focused;
      if (!focused) {
        _cancelLongPressTimer();
        _isActionKeyPressed = false;
      }
    });
    widget.onFocusChange?.call(focused);
  }

  void _cancelLongPressTimer() {
    _longPressTimer?.cancel();
    _longPressTimer = null;
    _longPressHandled = false;
  }

  bool _isActionKey(LogicalKeyboardKey key) {
    return key == LogicalKeyboardKey.select ||
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.numpadEnter ||
        key == LogicalKeyboardKey.gameButtonA;
  }

  @override
  void dispose() {
    _cancelLongPressTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final sp = context.watch<SettingsProvider>();
    final radius = widget.borderRadius ?? BorderRadius.circular(28);
    // Only the actively focused item can be premium
    final isPremium =
        (widget.overridePremiumHighlight ?? sp.oilTvPremiumHighlight) &&
        _isFocused;
    final showPremium = isPremium;

    // The playing track gets an RGB border.
    // If it is ALSO focused and premium is ON, showPremium takes precedence below.
    final showPlayingRgb =
        widget.isPlaying && sp.highlightPlayingWithRgb && !showPremium;

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? widget.focusBackgroundColor : null,
        borderRadius: radius,
        border: Border.all(
          color:
              (showPremium ||
                  (widget.useRgbBorder && _isFocused) ||
                  showPlayingRgb)
              ? Colors.transparent
              : _isFocused
              ? (widget.focusColor ?? colorScheme.primary).withValues(
                  alpha: 0.6,
                )
              : Colors.transparent,
          width: sp.isTv ? 4.0 : 3.0,
        ),
        boxShadow: (widget.showGlow && _isFocused && !isWasmSafeMode())
            ? [
                BoxShadow(
                  color: (widget.focusColor ?? colorScheme.primary).withValues(
                    alpha: 0.2,
                  ),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: ClipRRect(borderRadius: radius, child: widget.child),
    );

    // Unified logic for the decorative border.
    // We always mount AnimatedGradientBorder to keep the widget tree stable,
    // preventing focus-loss "loops" during layout shifts.
    final double activeBorderWidth;
    final double activeGlowOpacity;
    final bool activeShowShadow;
    final bool activeShowGlow;
    final double activeAnimationSpeed;

    if (showPremium) {
      activeBorderWidth = 4.0;
      activeGlowOpacity = 0.45;
      activeShowShadow = true;
      activeShowGlow = true;
      activeAnimationSpeed = sp.rgbAnimationSpeed * 1.5;
    } else if (showPlayingRgb || (widget.useRgbBorder && _isFocused)) {
      activeBorderWidth = _isFocused ? 4.0 : 2.5;
      activeGlowOpacity = 0.0;
      activeShowShadow = false;
      activeShowGlow = true; // Still true to render the line
      activeAnimationSpeed = sp.rgbAnimationSpeed;
    } else {
      activeBorderWidth = 0.0;
      activeGlowOpacity = 0.0;
      activeShowShadow = false;
      activeShowGlow = false;
      activeAnimationSpeed = 1.0;
    }

    // We compensate for the padding injected by AnimatedGradientBorder so the overall
    // dimensions of the TvFocusWrapper never change, preventing list flow jumping.
    // However, if the feature is globally OFF, we don't want to inject extra
    // empty space into the UI.
    final bool isFeaturePossible =
        sp.oilTvPremiumHighlight ||
        sp.highlightPlayingWithRgb ||
        widget.useRgbBorder;

    final double maxBorderWidth = isFeaturePossible ? 6.0 : activeBorderWidth;

    content = AnimatedGradientBorder(
      borderRadius: radius.topLeft.x,
      borderWidth: activeBorderWidth,
      ignoreGlobalClock: true,
      animationSpeed: activeAnimationSpeed,
      colors: const [
        Colors.red,
        Colors.yellow,
        Colors.green,
        Colors.cyan,
        Colors.blue,
        Colors.purple,
        Colors.red,
      ],
      showGlow: activeShowGlow,
      showShadow: activeShowShadow,
      glowOpacity: activeGlowOpacity,
      backgroundColor: Colors.transparent,
      usePadding: true, // Necessary for stability
      enabled:
          isFeaturePossible, // Only enable if we might actually show something
      child: Padding(
        padding: EdgeInsets.all(maxBorderWidth - activeBorderWidth),
        child: content,
      ),
    );

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (node, event) {
        // ... external listener logic ...
        if (widget.onKeyEvent != null) {
          final result = widget.onKeyEvent!(node, event);
          if (result != KeyEventResult.ignored) return result;
        }

        if (!_isActionKey(event.logicalKey)) return KeyEventResult.ignored;

        if (event.runtimeType == KeyDownEvent) {
          _isActionKeyPressed = true;
          if (_longPressTimer == null && !_longPressHandled) {
            _longPressTimer = Timer(const Duration(milliseconds: 600), () {
              if (mounted) {
                _longPressHandled = true;
                widget.onLongPress?.call();
                AppHaptics.mediumImpact(context.read<DeviceService>());
              }
            });
          }
          return KeyEventResult.handled;
        }

        if (event.runtimeType == KeyRepeatEvent) {
          _isActionKeyPressed = true;
          return KeyEventResult.handled;
        }

        if (event.runtimeType == KeyUpEvent) {
          final wasLongPress = _longPressHandled;
          final wasPressed = _isActionKeyPressed;
          _cancelLongPressTimer();
          _isActionKeyPressed = false;

          if (!wasLongPress && wasPressed) {
            widget.onTap?.call();
          }
          return KeyEventResult.handled;
        }

        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        child: AnimatedScale(
          scale: _isFocused ? widget.scaleOnFocus : 1.0,
          duration: const Duration(milliseconds: 80),
          curve: Curves.fastOutSlowIn,
          child: content,
        ),
      ),
    );
  }
}
