part of 'dev_audio_hud.dart';

class _HudSparklinePainter extends CustomPainter {
  final List<double> values;
  final double baseline;
  final Color strokeColor;
  final Color guideColor;

  const _HudSparklinePainter({
    required this.values,
    required this.baseline,
    required this.strokeColor,
    required this.guideColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final guidePaint = Paint()
      ..color = guideColor
      ..strokeWidth = 1;
    final centerY = size.height / 2;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      guidePaint,
    );

    if (values.isEmpty || size.width <= 1 || size.height <= 1) {
      return;
    }

    var minV = values.first;
    var maxV = values.first;
    for (final v in values) {
      if (v < minV) minV = v;
      if (v > maxV) maxV = v;
    }

    final lo = math.min(minV, baseline);
    final hi = math.max(maxV, baseline);
    final range = (hi - lo).abs() < 0.001 ? 1.0 : (hi - lo);
    final sampleCount = values.length;
    final xStep = sampleCount <= 1
        ? size.width
        : size.width / (sampleCount - 1);

    final path = Path();
    for (var i = 0; i < sampleCount; i++) {
      final x = i * xStep;
      final normalized = (values[i] - lo) / range;
      final y = size.height - (normalized * size.height);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _HudSparklinePainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.baseline != baseline ||
        oldDelegate.strokeColor != strokeColor ||
        oldDelegate.guideColor != guideColor;
  }
}
