import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A wrapper widget that handles TV focus states with premium animations.
/// It provides a spring-based scale effect and a Material 3 focus border.
class TvFocusWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleOnFocus;
  final FocusNode? focusNode;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final Color? focusColor;
  final bool showGlow;

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
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;
  Timer? _longPressTimer;
  bool _longPressHandled = false;

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
      if (!focused) {
        _cancelLongPressTimer();
      }
    });
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
    final radius = widget.borderRadius ?? BorderRadius.circular(28);

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
      onKeyEvent: (node, event) {
        if (!_isActionKey(event.logicalKey)) return KeyEventResult.ignored;

        if (event is KeyDownEvent) {
          if (_longPressTimer == null && !_longPressHandled) {
            _longPressTimer = Timer(const Duration(milliseconds: 600), () {
              if (mounted) {
                _longPressHandled = true;
                widget.onLongPress?.call();
                HapticFeedback.mediumImpact();
              }
            });
          }
          return KeyEventResult.handled;
        } else if (event is KeyRepeatEvent) {
          // Keep the timer running, just prevent bubbling
          return KeyEventResult.handled;
        } else if (event is KeyUpEvent) {
          final wasLongPress = _longPressHandled;
          _cancelLongPressTimer();

          if (!wasLongPress) {
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
          curve: Curves.easeOutBack, // Spring-like effect
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _isFocused
                    ? (widget.focusColor ?? colorScheme.primary)
                        .withValues(alpha: 0.6)
                    : Colors.transparent,
                width: 2.5,
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
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
