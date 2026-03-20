# Phase 2 — QualityConfig + PerformanceManager

**Project:** gdar_tv — Sheep screensaver  
**Goal:** Establish a performance tier system before adding any visual complexity. Every future system reads from QualityConfig. Auto mode steps down under load.

---

## Why before Phase 3

Google TV 2020 has modest GPU/CPU headroom. Building the quality system first means every system added in Phases 3–6 is automatically gated from day one — no retrofitting later.

---

## Quality level definitions

| Setting | Level 1 — safe | Level 2 — balanced | Level 3 — full |
|---------|---------------|-------------------|----------------|
| Target FPS | 30 | 45 | 60 |
| Render scale | 0.67 (720p) | 1.0 (1080p) | 1.0 (1080p) |
| Particles | 500 | 2,000 | 8,000 |
| Trail length | 8 frames | 20 frames | 40 frames |
| IFS iterations | off | 50k/frame | 200k/frame |
| Boids | off | 50 agents | 200 agents |

---

## Step 1 — QualityConfig

Create `lib/screensaver/sheep/quality_config.dart`:

```dart
// Note: QualityLevel enum lives in screensaver_settings.dart (Phase 0)
// Import from there, do not redefine here
import '../screensaver_settings.dart';

class QualityConfig {
  final QualityLevel level;
  const QualityConfig(this.level);

  // Rendering
  double get renderScale     => const [0.67, 1.0,    1.0   ][_i];
  int    get targetFps       => const [30,   45,     60    ][_i];
  double get targetFrameMs   => 1000.0 / targetFps;

  // Visuals
  int    get trailLength     => const [8,    20,     40    ][_i];
  int    get particleCount   => const [500,  2000,   8000  ][_i];
  int    get boidCount       => const [0,    50,     200   ][_i];
  int    get ifsIterations   => const [0,    50000,  200000][_i];

  // Feature flags
  bool   get particlesEnabled => particleCount > 0;
  bool   get boidsEnabled     => boidCount     > 0;
  bool   get ifsEnabled       => ifsIterations > 0;

  // Internal
  int get _i => level == QualityLevel.auto ? 1 : level.index; // auto defaults to balanced
}
```

---

## Step 2 — PerformanceManager

Create `lib/screensaver/sheep/performance_manager.dart`:

```dart
import '../screensaver_settings.dart';

class PerformanceManager {
  QualityLevel _level;
  final List<double> _frameTimes = [];

  // How many frames to sample before evaluating
  static const int _sampleSize = 60;

  // How much over target before stepping down (20% headroom)
  static const double _tolerance = 1.2;

  PerformanceManager(QualityLevel initialLevel) : _level = initialLevel;

  QualityLevel get level => _level;

  // Call this every frame with the frame delta in milliseconds
  void recordFrame(double deltaMs) {
    _frameTimes.add(deltaMs);
    if (_frameTimes.length >= _sampleSize) _evaluate();
  }

  void _evaluate() {
    final avg = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    _frameTimes.clear();

    final config = QualityConfig(_level);
    final target = config.targetFrameMs;

    if (avg > target * _tolerance) {
      _stepDown();
    }
  }

  void _stepDown() {
    if (_level == QualityLevel.safe) return; // already at floor
    if (_level == QualityLevel.auto || _level == QualityLevel.balanced) {
      _level = QualityLevel.safe;
    } else if (_level == QualityLevel.full) {
      _level = QualityLevel.balanced;
    }
    onLevelChanged?.call(_level);
  }

  // Optional callback — use to notify UI or log
  void Function(QualityLevel)? onLevelChanged;

  // Manual override from settings
  void setLevel(QualityLevel level) {
    _level = level;
    _frameTimes.clear();
  }
}
```

---

## Step 3 — Wire into SheepScreensaver

Update `lib/screensaver/sheep/sheep_screensaver.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import '../screensaver_settings.dart';
import 'quality_config.dart';
import 'performance_manager.dart';

class SheepScreensaver extends StatefulWidget {
  final QualityLevel quality;
  const SheepScreensaver({super.key, required this.quality});

  @override
  State<SheepScreensaver> createState() => _SheepScreensaverState();
}

class _SheepScreensaverState extends State<SheepScreensaver>
    with SingleTickerProviderStateMixin {

  late PerformanceManager _perf;
  late Ticker _ticker;
  Duration _lastTime = Duration.zero;

  @override
  void initState() {
    super.initState();
    _perf = PerformanceManager(widget.quality)
      ..onLevelChanged = (level) {
        debugPrint('Quality stepped down to: ${level.name}');
        setState(() {}); // rebuild with new config
      };

    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    final deltaMs = _lastTime == Duration.zero
        ? 0.0
        : (elapsed - _lastTime).inMicroseconds / 1000.0;
    _lastTime = elapsed;

    if (deltaMs > 0) _perf.recordFrame(deltaMs);

    setState(() {}); // trigger repaint — replace with CustomPainter in Phase 3+
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final config = QualityConfig(_perf.level);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Screensaver content goes here in Phase 3+
          const SizedBox.expand(),

          // Debug overlay — remove before release
          Positioned(
            top: 16, right: 16,
            child: _DebugOverlay(config: config, perf: _perf),
          ),
        ],
      ),
    );
  }
}

class _DebugOverlay extends StatelessWidget {
  final QualityConfig config;
  final PerformanceManager perf;
  const _DebugOverlay({required this.config, required this.perf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black54,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('Quality: ${perf.level.name}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Target: ${config.targetFps} fps',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Particles: ${config.particleCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('Boids: ${config.boidCount}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
          Text('IFS: ${config.ifsEnabled ? config.ifsIterations : "off"}',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}
```

---

## Step 4 — Testing on device

Use the debug overlay to confirm behaviour at each level:

1. Set quality to **Full** in settings
2. Launch Sheep screensaver
3. Watch overlay — confirm target FPS shows 60
4. Simulate load (add a busy loop temporarily) — confirm auto steps down to Balanced, then Safe
5. Remove busy loop — confirm it stays at the stepped-down level (no automatic step-up)
6. Restart screensaver — confirm it reloads from saved setting

> Note: PerformanceManager does not step back up automatically. Step-up is manual (user changes setting). This avoids oscillation.

---

## File structure after Phase 2

```
lib/
  screensaver/
    screensaver_settings.dart        ← Phase 0
    screensaver_router.dart          ← Phase 0
    sheep/
      sheep_screensaver.dart         ← updated this phase
      quality_config.dart            ← new
      performance_manager.dart       ← new
```

---

## Done when

- [ ] QualityConfig returns correct values for all three levels
- [ ] PerformanceManager steps down from Full → Balanced under load
- [ ] PerformanceManager steps down from Balanced → Safe under load
- [ ] Does not step down at Safe (floor)
- [ ] Does not automatically step back up (by design)
- [ ] Debug overlay visible and accurate on Google TV hardware
- [ ] Remove debug overlay before release build
