import 'dart:ui' as ui;

class TrailSnapshot {
  final ui.Offset pos;
  final double size;
  final ui.Color color;

  const TrailSnapshot(this.pos, this.size, this.color);

  static TrailSnapshot lerp(TrailSnapshot a, TrailSnapshot b, double t) {
    return TrailSnapshot(
      ui.Offset.lerp(a.pos, b.pos, t)!,
      ui.lerpDouble(a.size, b.size, t) ?? a.size,
      ui.Color.lerp(a.color, b.color, t)!,
    );
  }
}

class TrailBufferTick {
  final int head;
  final int frameCount;

  const TrailBufferTick({required this.head, required this.frameCount});
}

int trailSnapshotInterval(double trailLength) {
  return (1 + (trailLength * 14.5).round()).clamp(1, 30);
}

TrailBufferTick tickTrailBuffer({
  required List<TrailSnapshot> buffer,
  required int head,
  required int frameCount,
  required double logoScale,
  required double trailLength,
  required TrailSnapshot snapshot,
}) {
  if (logoScale <= 0.0 || buffer.isEmpty) {
    return TrailBufferTick(head: head, frameCount: frameCount);
  }

  final interval = trailSnapshotInterval(trailLength);
  final nextFrameCount = frameCount + 1;
  if (nextFrameCount < interval) {
    return TrailBufferTick(head: head, frameCount: nextFrameCount);
  }

  final nextHead = (head + 1) % buffer.length;
  buffer[nextHead] = snapshot;
  return TrailBufferTick(head: nextHead, frameCount: 0);
}

List<TrailSnapshot> trailSnapshots({
  required List<TrailSnapshot> buffer,
  required int head,
  required int frameCount,
  required int count,
  required double trailLength,
  required TrailSnapshot currentSnapshot,
}) {
  final result = <TrailSnapshot>[currentSnapshot];
  if (buffer.isEmpty || count <= 1) {
    return result;
  }

  final interval = trailSnapshotInterval(trailLength);
  final frac = frameCount / interval.toDouble();
  final clamped = count.clamp(0, buffer.length);

  for (int i = 1; i < clamped; i++) {
    final findK = i - frac;
    final k = findK.floor();
    final t = (findK - k).clamp(0.0, 1.0);

    final idx1 = ((head - k) % buffer.length + buffer.length) % buffer.length;
    final idx2 =
        ((head - (k + 1)) % buffer.length + buffer.length) % buffer.length;

    result.add(TrailSnapshot.lerp(buffer[idx1], buffer[idx2], t));
  }

  return result;
}
