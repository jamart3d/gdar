import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shakedown/utils/app_haptics.dart';
import 'package:shakedown/services/device_service.dart';
import 'package:provider/provider.dart';
import 'package:shakedown/providers/settings_provider.dart';
import 'package:shakedown/ui/widgets/animated_gradient_border.dart';

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
  final FocusOnKeyEventCallback? onKeyEvent;
  final ValueChanged<bool>? onFocusChange;

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
    this.onKeyEvent,
    this.focusBackgroundColor,
    this.onFocusChange,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _longPressHandled = false;
  bool _isActionKeyPressed = false;

  void _handleFocusChange(bool focused) {
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

    Widget content = AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: _isFocused ? widget.focusBackgroundColor : null,
        borderRadius: radius,
        border: (widget.useRgbBorder && _isFocused)
            ? null // Do not double-pad the border if RGB is handling it
            : Border.all(
                color: _isFocused
                    ? (widget.focusColor ?? colorScheme.primary)
                        .withValues(alpha: 0.6)
                    : Colors.transparent,
                width: 3.0,
              ),
        boxShadow: (widget.showGlow && _isFocused)
            ? [
                BoxShadow(
                  color: (widget.focusColor ?? colorScheme.primary)
                      .withValues(alpha: 0.2),
                  blurRadius: 15,
                  spreadRadius: 3,
                ),
              ]
            : [],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: widget.child,
      ),
    );

    if (widget.useRgbBorder && _isFocused) {
      content = AnimatedGradientBorder(
        borderRadius: radius.topLeft.x,
        borderWidth: 4.0, // Thicker stroke for pure RGB line
        ignoreGlobalClock: true,
        animationSpeed: sp.rgbAnimationSpeed,
        showGlow: true,
        showShadow:
            false, // Explicitly false inside so we use the standard BoxShadow underneath instead
        backgroundColor: Colors.transparent,
        usePadding: false, // Tight border to match track highlight items
        child: content,
      );
    }

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

        if (event is KeyDownEvent) {
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
        } else if (event is KeyRepeatEvent) {
          return KeyEventResult.handled;
        } else if (event is KeyUpEvent) {
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
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: content,
        ),
      ),
    );
  }
}
