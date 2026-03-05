import 'package:flutter/material.dart';

class FruitIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final Color? color;
  final double size;
  final double padding;

  const FruitIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.color,
    this.size = 24.0,
    this.padding = 8.0,
  });

  @override
  State<FruitIconButton> createState() => _FruitIconButtonState();
}

class _FruitIconButtonState extends State<FruitIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.onSurface;

    Widget content = Padding(
      padding: EdgeInsets.all(widget.padding),
      child: IconTheme(
        data: IconThemeData(
          color: effectiveColor,
          size: widget.size,
        ),
        child: widget.icon,
      ),
    );

    if (widget.tooltip != null) {
      content = Tooltip(
        message: widget.tooltip!,
        child: content,
      );
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      onTap: widget.onPressed,
      behavior: HitTestBehavior.opaque,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: _isPressed ? 0.4 : 1.0,
        child: content,
      ),
    );
  }
}
