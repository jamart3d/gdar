import 'dart:math' as math;
import 'dart:ui';

class VuNeedleGeometry {
  final Offset pivot;
  final Offset start;
  final Offset tip;
  final double angle;

  const VuNeedleGeometry({
    required this.pivot,
    required this.start,
    required this.tip,
    required this.angle,
  });
}

class VuScaleMark {
  final double fraction;
  final Offset inner;
  final Offset outer;
  final String label;
  final bool showLabel;

  const VuScaleMark({
    required this.fraction,
    required this.inner,
    required this.outer,
    required this.label,
    required this.showLabel,
  });
}

VuNeedleGeometry buildVuNeedleGeometry({
  required Offset pivot,
  required double level,
  required double sweepHalf,
  required double needleLength,
  double spindleRadius = 4.5,
}) {
  final totalSweep = sweepHalf * 2;
  final angle =
      -math.pi / 2 + (-sweepHalf + level.clamp(0.0, 1.0) * totalSweep);
  return VuNeedleGeometry(
    pivot: pivot,
    angle: angle,
    start: Offset(
      pivot.dx + math.cos(angle) * spindleRadius,
      pivot.dy + math.sin(angle) * spindleRadius,
    ),
    tip: Offset(
      pivot.dx + math.cos(angle) * needleLength,
      pivot.dy + math.sin(angle) * needleLength,
    ),
  );
}

List<VuScaleMark> buildVuScaleMarks({
  required Offset pivot,
  required double sweepHalf,
  required double arcRadius,
}) {
  const fractions = [0.0, 0.2, 0.4, 0.58, 0.72, 0.84, 1.0];
  const labels = ['-20', '-10', '-7', '-3', '0', '+1', '+3'];
  const showLabel = [true, false, false, false, true, false, true];
  final totalSweep = sweepHalf * 2;

  return List<VuScaleMark>.generate(fractions.length, (index) {
    final fraction = fractions[index];
    final angle = -math.pi / 2 + (-sweepHalf + fraction * totalSweep);
    final outerRadius = arcRadius + (fraction == 0.72 ? 9.0 : 6.0);
    return VuScaleMark(
      fraction: fraction,
      inner: Offset(
        pivot.dx + math.cos(angle) * arcRadius,
        pivot.dy + math.sin(angle) * arcRadius,
      ),
      outer: Offset(
        pivot.dx + math.cos(angle) * outerRadius,
        pivot.dy + math.sin(angle) * outerRadius,
      ),
      label: labels[index],
      showLabel: showLabel[index],
    );
  });
}
