import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_tooltip.dart';

class FruitIconButton extends StatefulWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final String? semanticLabel;
  final Color? color;
  final double size;
  final double padding;

  const FruitIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.tooltip,
    this.semanticLabel,
    this.color,
    this.size = 24.0,
    this.padding = 8.0,
  });

  @override
  State<FruitIconButton> createState() => _FruitIconButtonState();
}

class _FruitIconButtonState extends State<FruitIconButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  void _activate() {
    widget.onPressed?.call();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveColor =
        widget.color ?? Theme.of(context).colorScheme.onSurface;

    Widget content = Padding(
      padding: EdgeInsets.all(widget.padding),
      child: IconTheme(
        data: IconThemeData(color: effectiveColor, size: widget.size),
        child: widget.icon,
      ),
    );

    if (widget.tooltip != null) {
      final isFruit =
          context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;
      if (isFruit) {
        content = FruitTooltip(message: widget.tooltip!, child: content);
      } else {
        content = Tooltip(message: widget.tooltip!, child: content);
      }
    }

    final isEnabled = widget.onPressed != null;
    final interactive = FocusableActionDetector(
      enabled: isEnabled,
      mouseCursor: isEnabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
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
        onTapDown: isEnabled ? (_) => setState(() => _isPressed = true) : null,
        onTapUp: isEnabled ? (_) => setState(() => _isPressed = false) : null,
        onTapCancel: isEnabled
            ? () => setState(() => _isPressed = false)
            : null,
        onTap: isEnabled ? _activate : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 100),
          opacity: _isPressed ? 0.4 : (_isFocused ? 0.85 : 1.0),
          child: content,
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: widget.semanticLabel ?? widget.tooltip,
      child: ExcludeSemantics(child: interactive),
    );
  }
}
