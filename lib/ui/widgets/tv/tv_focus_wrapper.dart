import 'package:flutter/material.dart';

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

  const TvFocusWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleOnFocus = 1.05,
    this.focusNode,
    this.autofocus = false,
    this.borderRadius,
  });

  @override
  State<TvFocusWrapper> createState() => _TvFocusWrapperState();
}

class _TvFocusWrapperState extends State<TvFocusWrapper> {
  bool _isFocused = false;

  void _handleFocusChange(bool focused) {
    setState(() {
      _isFocused = focused;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = widget.borderRadius ?? BorderRadius.circular(28);

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onFocusChange: _handleFocusChange,
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
                    ? colorScheme.primary.withValues(alpha: 0.8)
                    : Colors.transparent,
                width: 3.0,
              ),
              boxShadow: _isFocused
                  ? [
                      BoxShadow(
                        color: colorScheme.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
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
