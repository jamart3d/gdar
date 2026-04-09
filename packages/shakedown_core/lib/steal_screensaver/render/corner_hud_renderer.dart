import 'dart:ui';

class CornerHudPanelGeometry {
  final RRect panelRect;
  final List<double> gridLineYs;
  final Offset labelOffset;

  const CornerHudPanelGeometry({
    required this.panelRect,
    required this.gridLineYs,
    required this.labelOffset,
  });
}

CornerHudPanelGeometry buildCornerHudPanelGeometry({
  required double startX,
  required double startY,
  required int cornerBarCount,
  required double barWidth,
  required double barGap,
  required double maxBarHeight,
}) {
  final width =
      (cornerBarCount * barWidth) + ((cornerBarCount - 1) * barGap) + 18;
  final panelRect = RRect.fromRectAndRadius(
    Rect.fromLTWH(
      startX - 10,
      startY - maxBarHeight - 14,
      width,
      maxBarHeight + 40,
    ),
    const Radius.circular(10),
  );

  return CornerHudPanelGeometry(
    panelRect: panelRect,
    gridLineYs: List<double>.generate(
      3,
      (index) => startY - maxBarHeight + (maxBarHeight / 4.0) * (index + 1),
    ),
    labelOffset: Offset(startX - 2, startY + 16),
  );
}
