part of 'tv_screensaver_section.dart';

class _PaletteSegmentedButton extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;
  final ColorScheme colorScheme;

  const _PaletteSegmentedButton({
    required this.selected,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final keys = StealConfig.palettes.keys.toList();

    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final idx = keys.indexOf(selected);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && idx > 0) {
            onSelect(keys[idx - 1]);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              idx < keys.length - 1) {
            onSelect(keys[idx + 1]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SegmentedButton<String>(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.all(Colors.transparent),
          foregroundColor: WidgetStateProperty.all(Colors.transparent),
          iconColor: WidgetStateProperty.all(Colors.transparent),
          side: WidgetStateProperty.all(BorderSide.none),
          padding: WidgetStateProperty.all(EdgeInsets.zero),
        ),
        segments: keys.map((key) {
          final isSelected = key == selected;
          return ButtonSegment<String>(
            value: key,
            label: _AnimatedPaletteSegment(
              paletteKey: key,
              isSelected: isSelected,
              colorScheme: colorScheme,
            ),
          );
        }).toList(),
        selected: {selected},
        onSelectionChanged: (Set<String> selection) =>
            onSelect(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _AnimatedPaletteSegment extends StatefulWidget {
  final String paletteKey;
  final bool isSelected;
  final ColorScheme colorScheme;

  const _AnimatedPaletteSegment({
    required this.paletteKey,
    required this.isSelected,
    required this.colorScheme,
  });

  @override
  State<_AnimatedPaletteSegment> createState() =>
      _AnimatedPaletteSegmentState();
}

class _AnimatedPaletteSegmentState extends State<_AnimatedPaletteSegment>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<Color> _colors;

  static const Duration _stepDuration = Duration(milliseconds: 2000);

  @override
  void initState() {
    super.initState();
    _colors = StealConfig.palettes[widget.paletteKey]!;
    _controller = AnimationController(
      vsync: this,
      duration: _stepDuration * _colors.length,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color get _currentColor {
    final t = _controller.value * _colors.length;
    final idx = t.floor() % _colors.length;
    final next = (idx + 1) % _colors.length;
    final frac = t - t.floor();
    return Color.lerp(_colors[idx], _colors[next], frac)!;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isFruit = themeProvider.themeStyle == ThemeStyle.fruit;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final color = _currentColor;
        final isSelected = widget.isSelected;
        return Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: isSelected ? 0.85 : 0.28),
            border: Border.all(
              color: isSelected ? color : color.withValues(alpha: 0.0),
              width: 2,
            ),
          ),
          child: isSelected
              ? Icon(
                  isFruit ? LucideIcons.check : Icons.check_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                )
              : const SizedBox.shrink(),
        );
      },
    );
  }
}

class _ReactiveHint extends StatelessWidget {
  final String message;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final bool isFruit;

  const _ReactiveHint({
    required this.message,
    required this.colorScheme,
    required this.textTheme,
    required this.isFruit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: colorScheme.primary.withValues(alpha: 0.28),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Icon(
              isFruit ? LucideIcons.activity : Icons.graphic_eq,
              size: 14,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QualitySegmentedButton extends StatelessWidget {
  final int selectedLevel;
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;

  const _QualitySegmentedButton({
    required this.selectedLevel,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildSegment('HIGH', 0, isFirst: true),
        _buildSegment('BALANCED', 1),
        _buildSegment('FAST', 2, isLast: true),
      ],
    );
  }

  Widget _buildSegment(
    String label,
    int level, {
    bool isFirst = false,
    bool isLast = false,
  }) {
    final isSelected = selectedLevel == level;
    return Expanded(
      child: TvFocusWrapper(
        onTap: () => onSelect(level),
        borderRadius: BorderRadius.horizontal(
          left: isFirst ? const Radius.circular(8) : Radius.zero,
          right: isLast ? const Radius.circular(8) : Radius.zero,
        ),
        child: Container(
          height: 36,
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.horizontal(
              left: isFirst ? const Radius.circular(8) : Radius.zero,
              right: isLast ? const Radius.circular(8) : Radius.zero,
            ),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final ColorScheme colorScheme;

  const _SectionHeader({required this.title, required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: colorScheme.primary,
          ),
        ),
        const SizedBox(height: 4),
        Divider(color: colorScheme.outlineVariant, height: 1),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final FocusNode? focusNode;
  final FocusOnKeyEventCallback? onKeyEvent;

  const _ToggleRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    required this.colorScheme,
    required this.textTheme,
    this.focusNode,
    this.onKeyEvent,
  });

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      focusNode: focusNode,
      onKeyEvent: onKeyEvent,
      onTap: () => onChanged(!value),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }
}

class _BandSegmentedButton extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelect;
  final ColorScheme colorScheme;

  const _BandSegmentedButton({
    required this.selected,
    required this.onSelect,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final options = [-2, -1, 0, 1, 2, 3, 4, 5, 6, 7];

    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final idx = options.indexOf(selected);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && idx > 0) {
            onSelect(options[idx - 1]);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              idx < options.length - 1) {
            onSelect(options[idx + 1]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SegmentedButton<int>(
        segments: options.map((value) {
          late final String label;
          if (value == -2) {
            label = 'NONE';
          } else if (value == -1) {
            label = 'DEF';
          } else if (value == 0) {
            label = '0:SUB';
          } else if (value == 7) {
            label = '7:AIR';
          } else {
            label = value.toString();
          }

          return ButtonSegment<int>(
            value: value,
            label: Text(
              label,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            ),
          );
        }).toList(),
        selected: {selected},
        onSelectionChanged: (Set<int> selection) => onSelect(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}

class _BeatDetectorSegmentedButton extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _BeatDetectorSegmentedButton({
    required this.selected,
    required this.onSelect,
  });

  static const List<String> _modes = [
    'auto',
    'hybrid',
    'bass',
    'mid',
    'broad',
    'pcm',
  ];

  static const Map<String, String> _labels = {
    'auto': 'Auto',
    'hybrid': 'Hybrid',
    'bass': 'Bass',
    'mid': 'Mid',
    'broad': 'Broad',
    'pcm': 'Enhanced',
  };

  @override
  Widget build(BuildContext context) {
    return TvFocusWrapper(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          final idx = _modes.indexOf(selected);
          if (event.logicalKey == LogicalKeyboardKey.arrowLeft && idx > 0) {
            onSelect(_modes[idx - 1]);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight &&
              idx >= 0 &&
              idx < _modes.length - 1) {
            onSelect(_modes[idx + 1]);
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: SegmentedButton<String>(
        segments: _modes
            .map(
              (mode) => ButtonSegment<String>(
                value: mode,
                label: Text(_labels[mode] ?? mode.toUpperCase()),
              ),
            )
            .toList(),
        selected: {selected},
        onSelectionChanged: (Set<String> selection) =>
            onSelect(selection.first),
        showSelectedIcon: false,
      ),
    );
  }
}
