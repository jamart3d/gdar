import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/ui/widgets/tv/tv_focus_wrapper.dart';
import 'dart:math' as math;

class TvScrollbar extends StatefulWidget {
  final ItemPositionsListener itemPositionsListener;
  final ItemScrollController itemScrollController;
  final int itemCount;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;

  const TvScrollbar({
    super.key,
    required this.itemPositionsListener,
    required this.itemScrollController,
    required this.itemCount,
    this.onLeft,
    this.onRight,
  });

  @override
  State<TvScrollbar> createState() => _TvScrollbarState();
}

class _TvScrollbarState extends State<TvScrollbar> {
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    widget.itemPositionsListener.itemPositions
        .addListener(_updateScrollPosition);
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions
        .removeListener(_updateScrollPosition);
    super.dispose();
  }

  void _updateScrollPosition() {
    if (widget.itemCount == 0) return;

    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the min index visible
    final minIndex = positions
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((min, position) => position.index < min.index ? position : min)
        .index;

    // Find the max index visible
    final maxIndex = positions
        .where((ItemPosition position) => position.itemLeadingEdge < 1)
        .reduce((max, position) => position.index > max.index ? position : max)
        .index;

    // Simple estimation: average of min/max or just min
    final current =
        minIndex / math.max(1, widget.itemCount - (maxIndex - minIndex));

    if (mounted) {
      setState(() {
        _scrollProgress = current.clamp(0.0, 1.0);
      });
    }
  }

  void _scrollBy(int offset) {
    if (widget.itemCount == 0 || !widget.itemScrollController.isAttached) {
      return;
    }

    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty) return;

    // Find the first visible item index
    final firstIndex = positions
        .where((ItemPosition position) => position.itemTrailingEdge > 0)
        .reduce((min, position) => position.index < min.index ? position : min)
        .index;

    final targetIndex = (firstIndex + offset).clamp(0, widget.itemCount - 1);

    widget.itemScrollController.scrollTo(
      index: targetIndex,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent) {
          if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
            _scrollBy(-3);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
            _scrollBy(3);
            return KeyEventResult.handled;
          } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
            if (widget.onLeft != null) {
              widget.onLeft!();
              return KeyEventResult.handled;
            }
          } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
            if (widget.onRight != null) {
              widget.onRight!();
              return KeyEventResult.handled;
            }
          }
        }
        return KeyEventResult.ignored;
      },
      child: TvFocusWrapper(
        onTap: () {
          // Toggle mode or something? iterating focus does key events
        },
        borderRadius: BorderRadius.circular(4),
        child: Container(
          width: 12,
          height: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(6),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackHeight = constraints.maxHeight;
              // Thumb height based on list size approximation (min 40)
              final thumbHeight = math.max(
                  40.0, trackHeight * (10 / math.max(10, widget.itemCount)));
              final availableRun = trackHeight - thumbHeight;
              final topOffset = availableRun * _scrollProgress;

              return Stack(
                children: [
                  Positioned(
                    top: topOffset,
                    child: Container(
                      width: 12,
                      height: thumbHeight,
                      decoration: BoxDecoration(
                        color:
                            colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
