import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/ui/widgets/theme/fruit_icon_button.dart';
import 'package:shakedown_core/ui/widgets/theme/liquid_glass_wrapper.dart';

/// Central visual tokens for Fruit UI.
class FruitTokens {
  static const double radiusSmall = 14.0;
  static const double radiusMedium = 20.0;
  static const double radiusLarge = 28.0;
  static const double blurSoft = 8.0;
  static const double blurStrong = 15.0;
  static const double opacitySoft = 0.55;
  static const double opacityStrong = 0.7;
}

/// Canonical Fruit surface wrapper. Keeps Fruit structure even when blur is off.
class FruitSurface extends StatelessWidget {
  final Widget child;
  final BorderRadius borderRadius;
  final double blur;
  final double opacity;
  final bool showBorder;
  final EdgeInsetsGeometry? padding;

  const FruitSurface({
    super.key,
    required this.child,
    required this.borderRadius,
    this.blur = FruitTokens.blurStrong,
    this.opacity = FruitTokens.opacityStrong,
    this.showBorder = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final isFruit =
        context.watch<ThemeProvider>().themeStyle == ThemeStyle.fruit;
    final surfaceColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.black
        : Colors.white;

    final content = Container(
      padding: padding,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: showBorder
            ? Border.all(
                color: surfaceColor.withValues(alpha: 0.12),
                width: 0.8,
              )
            : null,
      ),
      child: child,
    );

    return LiquidGlassWrapper(
      enabled: isFruit && settings.fruitEnableLiquidGlass,
      borderRadius: borderRadius,
      blur: blur,
      opacity: opacity,
      showBorder: false,
      child: content,
    );
  }
}

/// Canonical Fruit icon action control (non-M3 interaction).
class FruitActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;
  final String? tooltip;

  const FruitActionButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return FruitSurface(
      borderRadius: BorderRadius.circular(100),
      blur: FruitTokens.blurSoft,
      opacity: FruitTokens.opacitySoft,
      padding: const EdgeInsets.all(2),
      child: FruitIconButton(
        icon: Icon(icon),
        onPressed: onPressed,
        tooltip: tooltip,
      ),
    );
  }
}

/// Canonical Fruit text action control (non-M3 interaction).
class FruitTextAction extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final String? semanticLabel;

  const FruitTextAction({
    super.key,
    required this.label,
    required this.onPressed,
    this.semanticLabel,
  });

  @override
  State<FruitTextAction> createState() => _FruitTextActionState();
}

class _FruitTextActionState extends State<FruitTextAction> {
  bool _pressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return Semantics(
      button: true,
      label: widget.semanticLabel ?? widget.label,
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
                widget.onPressed();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            onTap: widget.onPressed,
            behavior: HitTestBehavior.opaque,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _pressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Text(
                  widget.label,
                  style: TextStyle(
                    color: primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
