part of 'tv_playback_screen.dart';

class _RatingStars extends StatelessWidget {
  final int rating;
  final Color color;

  const _RatingStars({required this.rating, required this.color});

  @override
  Widget build(BuildContext context) {
    const total = 3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 2,
      children: List.generate(total, (index) {
        final filled = index < rating;
        return Icon(
          filled ? Icons.star : Icons.star_border,
          size: 16,
          color: filled ? color : color.withValues(alpha: 0.3),
        );
      }),
    );
  }
}

class _FruitHeaderButton extends StatefulWidget {
  final VoidCallback onTap;
  final IconData icon;
  final double scaleFactor;
  final String semanticLabel;

  const _FruitHeaderButton({
    required this.onTap,
    required this.icon,
    required this.scaleFactor,
    required this.semanticLabel,
  });

  @override
  State<_FruitHeaderButton> createState() => _FruitHeaderButtonState();
}

class _FruitHeaderButtonState extends State<_FruitHeaderButton> {
  bool _isPressed = false;
  bool _isFocused = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final settingsProvider = context.watch<SettingsProvider>();
    final isSimple = settingsProvider.performanceMode;
    final isTv = context.watch<DeviceService>().isTv;

    Widget content = SizedBox(
      width: 44 * widget.scaleFactor,
      height: 44 * widget.scaleFactor,
      child: Icon(
        widget.icon,
        size: 24 * widget.scaleFactor,
        color: colorScheme.onSurfaceVariant,
      ),
    );

    if (!isSimple && !isTv) {
      content = NeumorphicWrapper(
        intensity: 0.6,
        borderRadius: 12 * widget.scaleFactor,
        child: content,
      );
    }

    return Semantics(
      button: true,
      label: widget.semanticLabel,
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
                widget.onTap();
                return null;
              },
            ),
          },
          child: GestureDetector(
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            child: AnimatedOpacity(
              duration: const Duration(milliseconds: 100),
              opacity: _isPressed ? 0.6 : (_isFocused ? 0.85 : 1.0),
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
