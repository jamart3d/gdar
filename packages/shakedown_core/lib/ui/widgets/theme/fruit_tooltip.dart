import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shakedown_core/providers/settings_provider.dart';
import 'package:shakedown_core/providers/theme_provider.dart';
import 'package:shakedown_core/utils/web_runtime.dart';

class FruitTooltip extends StatefulWidget {
  final Widget child;
  final String message;
  final Duration showDelay;

  const FruitTooltip({
    super.key,
    required this.child,
    required this.message,
    this.showDelay = const Duration(milliseconds: 500),
  });

  @override
  State<FruitTooltip> createState() => _FruitTooltipState();
}

class _FruitTooltipState extends State<FruitTooltip> {
  OverlayEntry? _entry;
  Timer? _timer;
  Timer? _exitDebounce;
  Timer? _autoDismiss;
  bool _hovering = false;
  bool _tapped = false;

  void _showTooltip() {
    if (_entry != null || widget.message.isEmpty) return;
    final RenderBox box = context.findRenderObject() as RenderBox;
    final overlay = Overlay.of(context, rootOverlay: true);
    final colorScheme = Theme.of(context).colorScheme;
    final settings = context.read<SettingsProvider>();
    final bool useGlass =
        settings.fruitEnableLiquidGlass && !settings.performanceMode;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Size size = box.size;
    final Offset globalTopLeft = box.localToGlobal(Offset.zero);
    final double centerX = globalTopLeft.dx + size.width / 2;
    final MediaQueryData mq = MediaQuery.of(context);
    final double screenWidth = mq.size.width;
    final double screenHeight = mq.size.height;
    final double left = (centerX - 120).clamp(12.0, screenWidth - 12 - 240);
    // Anchor by bottom so tooltip always grows upward, clear of the chip/cursor.
    final double bottom = screenHeight - globalTopLeft.dy + 8;
    _entry = OverlayEntry(
      builder: (overlayContext) => Positioned(
        left: left,
        bottom: bottom,
        child: Material(
          color: Colors.transparent,
          child: IgnorePointer(
            child: Container(
              constraints: const BoxConstraints(minWidth: 80, maxWidth: 240),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              child: AnimatedOpacity(
                duration: const Duration(milliseconds: 120),
                opacity: _hovering ? 1.0 : 0.0,
                child: _buildTooltipBubble(useGlass, isDark, colorScheme),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
  }

  Widget _buildTooltipBubble(
    bool useGlass,
    bool isDark,
    ColorScheme colorScheme,
  ) {
    final bool disableBlur = kIsWeb && isWasmRuntime();
    final bool effectiveGlass = useGlass && !disableBlur;

    final Widget content = Text(
      widget.message,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: isDark ? colorScheme.onSurface : colorScheme.onSurface,
      ),
    );

    final decoration = BoxDecoration(
      color: effectiveGlass
          ? (isDark
                ? Colors.black.withValues(alpha: 0.48)
                : Colors.white.withValues(alpha: 0.9))
          : (isDark ? Colors.black87 : Colors.white),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: effectiveGlass
            ? Colors.white.withValues(alpha: 0.25)
            : colorScheme.outlineVariant,
        width: 0.8,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.2),
          blurRadius: effectiveGlass ? 22 : 8,
          offset: const Offset(0, 6),
        ),
      ],
    );

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Semantics(
        label: widget.message,
        tooltip: widget.message,
        child: content,
      ),
    );

    if (!effectiveGlass) {
      return Container(decoration: decoration, child: child);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(decoration: decoration, child: child),
      ),
    );
  }

  void _hideTooltip() {
    _timer?.cancel();
    _timer = null;
    _exitDebounce?.cancel();
    _exitDebounce = null;
    _autoDismiss?.cancel();
    _autoDismiss = null;
    _tapped = false;
    _entry?.remove();
    _entry = null;
  }

  void _handleTap() {
    if (_tapped) {
      _hideTooltip();
      return;
    }
    _tapped = true;
    _hovering = true;
    _showTooltip();
    _autoDismiss?.cancel();
    _autoDismiss = Timer(const Duration(seconds: 4), _hideTooltip);
  }

  void _scheduleShow() {
    _exitDebounce?.cancel();
    _exitDebounce = null;
    _hovering = true;
    // ??= so a spurious re-enter after a spurious exit does not reset the
    // 500ms countdown back to zero. The tooltip appears 500ms after the
    // *first* enter, regardless of how many spurious exit/enter pairs fire.
    _timer ??= Timer(widget.showDelay, _showTooltip);
  }

  void _cancelShow() {
    // Cancel the show timer immediately so it cannot fire and insert an entry
    // during the debounce window (which would then be removed by the debounce
    // callback, causing a visible flash).
    _timer?.cancel();
    _timer = null;
    _hovering = false;
    // ??= so multiple rapid exits (e.g. from AnimatedContainer repaints) do
    // not keep resetting the deadline. Only the first exit arms the timer;
    // a real re-enter cancels it.
    _exitDebounce ??= Timer(const Duration(milliseconds: 300), () {
      _exitDebounce = null;
      if (!_hovering) _hideTooltip();
    });
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _hideTooltip();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final bool showFruitTooltip = themeProvider.themeStyle == ThemeStyle.fruit;

    if (!showFruitTooltip) {
      return widget.child;
    }

    return GestureDetector(
      onTap: _handleTap,
      child: MouseRegion(
        onEnter: (_) => _scheduleShow(),
        onExit: (_) => _cancelShow(),
        cursor: SystemMouseCursors.click,
        child: FocusableActionDetector(
          onShowFocusHighlight: (value) {
            if (value) {
              _scheduleShow();
            } else {
              _cancelShow();
            }
          },
          shortcuts: const <ShortcutActivator, Intent>{
            SingleActivator(LogicalKeyboardKey.enter): ActivateIntent(),
            SingleActivator(LogicalKeyboardKey.space): ActivateIntent(),
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (_) {
                _scheduleShow();
                return null;
              },
            ),
          },
          child: widget.child,
        ),
      ),
    );
  }
}
