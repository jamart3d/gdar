import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:shakedown/models/show.dart';

/// A Material 3 expressive fast scrollbar with:
/// - Auto-hide: only visible while scrolling or dragging
/// - Draggable thumb with spring entrance animation
/// - Floating year chip (Overlay) that avoids the mini player
/// - Haptic feedback on year change
/// - Bottom padding to clear the mini player
class FastScrollbar extends StatefulWidget {
  final List<Show> shows;
  final ItemScrollController itemScrollController;
  final ItemPositionsListener itemPositionsListener;

  /// Height of the mini player (or any bottom UI) to avoid.
  /// Pass 0 if nothing is at the bottom.
  final double bottomPadding;

  final double trackWidth;
  final double thumbHeight;

  const FastScrollbar({
    super.key,
    required this.shows,
    required this.itemScrollController,
    required this.itemPositionsListener,
    this.bottomPadding = 0,
    this.trackWidth = 36,
    this.thumbHeight = 48,
  });

  @override
  State<FastScrollbar> createState() => _FastScrollbarState();
}

class _FastScrollbarState extends State<FastScrollbar>
    with TickerProviderStateMixin {
  bool _isDragging = false;
  double _thumbFraction = 0.0;
  int _lastYear = -1;

  OverlayEntry? _overlayEntry;
  Timer? _hideTimer;

  // Fade: controls thumb + track visibility (auto-hide)
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  // Scale: spring pop on drag start (M3 expressive)
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  // Auto-hide timer — hides thumb N seconds after scrolling stops
  static const Duration _autoHideDelay = Duration(seconds: 1);

  final GlobalKey _trackKey = GlobalKey();
  late List<int> _yearByIndex;
  late List<int> _uniqueYears;

  @override
  void initState() {
    super.initState();
    _buildYearIndex();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );

    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut, // M3 spring feel
    );

    widget.itemPositionsListener.itemPositions
        .addListener(_onItemPositionsChanged);
  }

  @override
  void didUpdateWidget(FastScrollbar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shows != widget.shows) {
      _buildYearIndex();
    }
  }

  @override
  void dispose() {
    widget.itemPositionsListener.itemPositions
        .removeListener(_onItemPositionsChanged);
    _removeOverlay();
    _hideTimer?.cancel();
    _fadeController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ── Year index ─────────────────────────────────────────────────────

  void _buildYearIndex() {
    _yearByIndex = widget.shows.map((s) {
      final raw = s.date;
      if (raw.length >= 4) {
        return int.tryParse(raw.substring(0, 4)) ?? 0;
      }
      return 0;
    }).toList();
    _uniqueYears = _yearByIndex.toSet().where((y) => y > 0).toList()..sort();
  }

  // ── Auto-hide scroll detection ─────────────────────────────────────

  void _onItemPositionsChanged() {
    if (_isDragging) return;
    final positions = widget.itemPositionsListener.itemPositions.value;
    if (positions.isEmpty || widget.shows.isEmpty) return;

    final sorted = positions.toList()
      ..sort((a, b) => a.index.compareTo(b.index));
    final firstVisible = sorted.first.index.clamp(0, widget.shows.length - 1);
    final fraction = firstVisible / (widget.shows.length - 1);

    if (mounted) {
      setState(() => _thumbFraction = fraction);
      _showThumb();
      _scheduleHide();
    }
  }

  void _showThumb() {
    _fadeController.forward();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(_autoHideDelay, () {
      if (mounted && !_isDragging) {
        _fadeController.reverse();
      }
    });
  }

  // ── Drag handling ──────────────────────────────────────────────────

  void _onDragStart(DragStartDetails details) {
    _isDragging = true;
    _showThumb();
    _scaleController.forward(from: 0);
    final fraction = _fractionFromGlobal(details.globalPosition.dy);
    _updateFromFraction(fraction);
    _showOverlay();
  }

  void _onDragUpdate(DragUpdateDetails details) {
    final fraction = _fractionFromGlobal(details.globalPosition.dy);
    _updateFromFraction(fraction);
    _overlayEntry?.markNeedsBuild();
  }

  void _onDragEnd(DragEndDetails _) {
    _isDragging = false;
    _scaleController.reverse();
    _removeOverlay();
    _lastYear = -1;
    _scheduleHide();
  }

  double _fractionFromGlobal(double globalY) {
    final renderBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return _thumbFraction;
    final localY = renderBox.globalToLocal(Offset(0, globalY)).dy;
    final trackH = renderBox.size.height;
    final usable = trackH - widget.thumbHeight;
    if (usable <= 0) return 0;
    return ((localY - widget.thumbHeight / 2) / usable).clamp(0.0, 1.0);
  }

  void _updateFromFraction(double fraction) {
    if (!mounted) return;
    setState(() => _thumbFraction = fraction);

    final index = (fraction * (widget.shows.length - 1))
        .round()
        .clamp(0, widget.shows.length - 1);
    widget.itemScrollController.jumpTo(index: index);

    final year = index < _yearByIndex.length ? _yearByIndex[index] : 0;
    if (year > 0 && year != _lastYear) {
      HapticFeedback.lightImpact();
      _lastYear = year;
    }
  }

  // ── Overlay ────────────────────────────────────────────────────────

  void _showOverlay() {
    _removeOverlay();
    _overlayEntry = OverlayEntry(
      builder: (_) => _YearChipOverlay(
        getPosition: _chipPosition,
        getYear: _currentYear,
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  Offset _chipPosition() {
    final renderBox =
        _trackKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) return Offset.zero;

    final trackGlobal = renderBox.localToGlobal(Offset.zero);
    final trackH = renderBox.size.height;
    final usable = trackH - widget.thumbHeight;
    final thumbTop = trackGlobal.dy + _thumbFraction * usable;
    final thumbCenterY = thumbTop + widget.thumbHeight / 2;

    // Chip sits to the left of the thumb track, vertically centered on thumb
    return Offset(
      trackGlobal.dx - 76,
      thumbCenterY - 20,
    );
  }

  String _currentYear() {
    if (widget.shows.isEmpty) return '';
    final index = (_thumbFraction * (widget.shows.length - 1))
        .round()
        .clamp(0, widget.shows.length - 1);
    final year = index < _yearByIndex.length ? _yearByIndex[index] : 0;
    return year > 0 ? '$year' : '';
  }

  // ── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Positioned(
      right: 0,
      top: 0,
      // Bottom inset clears the mini player
      bottom: widget.bottomPadding,
      width: widget.trackWidth,
      child: GestureDetector(
        onVerticalDragStart: _onDragStart,
        onVerticalDragUpdate: _onDragUpdate,
        onVerticalDragEnd: _onDragEnd,
        behavior: HitTestBehavior.opaque,
        child: FadeTransition(
          key: const Key('fast_scrollbar_fade'),
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final trackH = constraints.maxHeight;
              final usable = trackH - widget.thumbHeight;
              final thumbTop = (_thumbFraction * usable).clamp(0.0, usable);

              return Stack(
                key: _trackKey,
                clipBehavior: Clip.none,
                children: [
                  // ── Track line ─────────────────────────────────────────
                  Center(
                    child: Container(
                      width: 2,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),

                  // ── Year tick marks ────────────────────────────────────
                  ..._uniqueYears.map((year) {
                    final firstIdx = _yearByIndex.indexOf(year);
                    if (firstIdx < 0) return const SizedBox.shrink();
                    final f = firstIdx / (_yearByIndex.length - 1);
                    final top = (f * usable + widget.thumbHeight / 2)
                        .clamp(0.0, trackH);
                    return Positioned(
                      right: widget.trackWidth / 2 + 2,
                      top: top - 1,
                      child: Container(
                        width: 5,
                        height: 1.5,
                        decoration: BoxDecoration(
                          color: colorScheme.outline.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    );
                  }),

                  // ── Thumb (M3 expressive pill) ─────────────────────────
                  Positioned(
                    right: 6,
                    top: thumbTop,
                    child: ScaleTransition(
                      key: const Key('fast_scrollbar_scale'),
                      scale: Tween<double>(begin: 1.0, end: 1.4)
                          .animate(_scaleAnimation),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOutCubic,
                        width: _isDragging ? 5 : 4,
                        height: widget.thumbHeight,
                        decoration: BoxDecoration(
                          // M3: use primary for active, surfaceVariant for rest
                          color: _isDragging
                              ? colorScheme.primary
                              : colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.6),
                          borderRadius:
                              BorderRadius.circular(_isDragging ? 4 : 2),
                          boxShadow: _isDragging
                              ? [
                                  BoxShadow(
                                    color: colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                              : null,
                        ),
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

// ── Floating year chip ─────────────────────────────────────────────────────

class _YearChipOverlay extends StatelessWidget {
  final Offset Function() getPosition;
  final String Function() getYear;

  const _YearChipOverlay({
    required this.getPosition,
    required this.getYear,
  });

  @override
  Widget build(BuildContext context) {
    final pos = getPosition();
    final year = getYear();
    final colorScheme = Theme.of(context).colorScheme;

    if (year.isEmpty) return const SizedBox.shrink();

    return Positioned(
      left: pos.dx,
      top: pos.dy,
      child: Material(
        key: const Key('year_chip_material'),
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            // M3: secondary container for the chip — tonally distinct,
            // works in both light and dark without being too heavy
            color: colorScheme.secondaryContainer,
            borderRadius:
                BorderRadius.circular(28), // full pill — M3 expressive
            boxShadow: [
              BoxShadow(
                color: colorScheme.shadow.withValues(alpha: 0.15),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            year,
            style: TextStyle(
              color: colorScheme.onSecondaryContainer,
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ),
    );
  }
}
