import 'dart:ui';

class LedSegmentGeometry {
  final Rect leftRect;
  final Rect rightRect;
  final bool leftActive;
  final bool rightActive;
  final bool leftPeak;
  final bool rightPeak;

  const LedSegmentGeometry({
    required this.leftRect,
    required this.rightRect,
    required this.leftActive,
    required this.rightActive,
    required this.leftPeak,
    required this.rightPeak,
  });
}

List<LedSegmentGeometry> buildLedStripGeometry({
  required double stripLeft,
  required double baseY,
  required double stripWidth,
  required double stripHeight,
  required double labelReserve,
  required int segmentCount,
  required double horizontalPadding,
  required double columnGap,
  required double segmentGap,
  required int leftActive,
  required int rightActive,
  required int leftPeak,
  required int rightPeak,
}) {
  final usableHeight = stripHeight - labelReserve;
  final segmentHeight =
      (usableHeight - (segmentCount - 1) * segmentGap) / segmentCount;
  final columnWidth = (stripWidth - horizontalPadding * 2 - columnGap) / 2;

  return List<LedSegmentGeometry>.generate(segmentCount, (segment) {
    final segmentBottom =
        baseY - labelReserve - segment * (segmentHeight + segmentGap);
    final segmentTop = segmentBottom - segmentHeight;
    final leftColumnLeft = stripLeft + horizontalPadding;
    final rightColumnLeft =
        stripLeft + horizontalPadding + columnWidth + columnGap;

    return LedSegmentGeometry(
      leftRect: Rect.fromLTRB(
        leftColumnLeft,
        segmentTop,
        leftColumnLeft + columnWidth,
        segmentBottom,
      ),
      rightRect: Rect.fromLTRB(
        rightColumnLeft,
        segmentTop,
        rightColumnLeft + columnWidth,
        segmentBottom,
      ),
      leftActive: segment <= leftActive,
      rightActive: segment <= rightActive,
      leftPeak: segment == leftPeak,
      rightPeak: segment == rightPeak,
    );
  });
}
