import 'package:flutter/material.dart';

class HighlightableSetting extends StatefulWidget {
  final Widget child;
  final bool startWithHighlight;
  final GlobalKey? settingKey;

  const HighlightableSetting({
    super.key,
    required this.child,
    this.startWithHighlight = false,
    this.settingKey,
  });

  @override
  State<HighlightableSetting> createState() => _HighlightableSettingState();
}

class _HighlightableSettingState extends State<HighlightableSetting>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Color?> _colorAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final colorScheme = Theme.of(context).colorScheme;
    _colorAnimation = ColorTween(
      begin: Colors.transparent,
      end: colorScheme.tertiaryContainer.withValues(alpha: 0.6),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.startWithHighlight) {
      // Pulse 3 times
      _controller.forward().then((_) => _controller.reverse().then((_) =>
          _controller.forward().then((_) => _controller.reverse().then((_) =>
              _controller.forward().then((_) => _controller.reverse())))));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _colorAnimation,
      builder: (context, child) {
        return Container(
          key: widget.settingKey,
          decoration: BoxDecoration(
            color: _colorAnimation.value,
            borderRadius: BorderRadius.circular(16),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
