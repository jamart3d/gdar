# Phase 3 — SheepGenome + Evolution System

**Project:** gdar_tv — Sheep screensaver  
**Goal:** Replace all hardcoded visual parameters with an evolvable genome. Sheep cycle through distinct visual characters automatically over time.

---

## Core concept

Every visual parameter (physics, color, particle behavior, fluid feel) is encoded as a normalized `double` in a flat list. That list is the genome. Mutation adds small random deltas. Crossover blends two parents. The app keeps a pool of sheep and cycles through them, lerping smoothly between each transition.

---

## Step 1 — SheepGenome class

Create `lib/screensaver/sheep/genome/sheep_genome.dart`:

```dart
import 'dart:math';

class SheepGenome {
  final List<double> genes; // all values 0.0–1.0

  const SheepGenome(this.genes);

  // ── Forge2D ──────────────────────────────────────────
  double get gravityX       => (genes[0]  - 0.5) * 20.0;  // -10 to +10
  double get gravityY       => (genes[1]  - 0.5) * 20.0;  // -10 to +10
  double get restitution    => genes[2];                    //  0.0 to  1.0
  double get friction       => genes[3];                    //  0.0 to  1.0
  double get jointDamping   => genes[4]  * 10.0;           //  0.0 to 10.0

  // ── Logo / trails ────────────────────────────────────
  double get trailOpacity   => genes[5]  * 0.8 + 0.1;      //  0.1 to  0.9
  double get trailHue       => genes[6]  * 360.0;           //  0 to 360 degrees
  double get trailSaturation => genes[7];                   //  0.0 to  1.0

  // ── Particles ────────────────────────────────────────
  double get spawnRate      => genes[8]  * 200.0;           //  0 to 200/sec
  double get particleLife   => genes[9]  * 4.0 + 0.5;      //  0.5 to 4.5s
  double get velocitySpread => genes[10] * 360.0;           //  0 to 360 degrees
  double get colorHueStart  => genes[11] * 360.0;
  double get colorHueEnd    => genes[12] * 360.0;
  double get colorSaturation => genes[13];

  // ── Fluid ────────────────────────────────────────────
  double get viscosity      => genes[14] * 0.1;             //  0 to 0.1
  double get diffusion      => genes[15] * 0.001;
  double get forceStrength  => genes[16] * 500.0;
  double get dyeIntensity   => genes[17];                   //  0.0 to 1.0

  // ── Boids ────────────────────────────────────────────
  double get alignWeight    => genes[18] * 2.0;
  double get cohesionRadius => genes[19] * 200.0;
  double get separationDist => genes[20] * 50.0;
  double get maxSpeed       => genes[21] * 300.0;

  // ── IFS / flame fractal (Phase 5) ────────────────────
  // genes[22..35] — IFS transform coefficients, reserved for Phase 5

  static const int geneCount = 36;

  // ── Factory constructors ─────────────────────────────

  factory SheepGenome.random() {
    final rng = Random();
    return SheepGenome(
      List.generate(geneCount, (_) => rng.nextDouble()),
    );
  }

  factory SheepGenome.defaults() {
    final genes = List<double>.filled(geneCount, 0.5);
    return SheepGenome(genes);
  }

  // ── Evolution operations ──────────────────────────────

  SheepGenome mutate({double rate = 0.05, double strength = 0.1}) {
    final rng  = Random();
    final next = List<double>.from(genes);
    for (int i = 0; i < next.length; i++) {
      if (rng.nextDouble() < rate) {
        next[i] = (next[i] + (rng.nextDouble() - 0.5) * strength)
            .clamp(0.0, 1.0);
      }
    }
    return SheepGenome(next);
  }

  SheepGenome crossover(SheepGenome other) {
    final rng = Random();
    final cut = rng.nextInt(genes.length);
    return SheepGenome([
      ...genes.sublist(0, cut),
      ...other.genes.sublist(cut),
    ]);
  }

  SheepGenome lerp(SheepGenome other, double t) {
    return SheepGenome(
      List.generate(
        genes.length,
        (i) => genes[i] + (other.genes[i] - genes[i]) * t,
      ),
    );
  }

  // ── Serialization ─────────────────────────────────────

  Map<String, dynamic> toJson() => {'genes': genes};

  factory SheepGenome.fromJson(Map<String, dynamic> json) =>
      SheepGenome(List<double>.from(json['genes'] as List));
}
```

---

## Step 2 — SheepPool

The pool manages a collection of sheep and handles cycling between them.

Create `lib/screensaver/sheep/genome/sheep_pool.dart`:

```dart
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'sheep_genome.dart';

class SheepPool {
  static const int   _poolSize        = 8;
  static const _key                   = 'sheep_pool';

  final List<SheepGenome> _pool       = [];
  int                     _currentIdx = 0;

  SheepGenome get current => _pool[_currentIdx];

  // Next sheep: either mutate current or crossover two random pool members
  SheepGenome next() {
    final rng = Random();
    SheepGenome candidate;

    if (_pool.length < 2 || rng.nextBool()) {
      candidate = current.mutate();
    } else {
      final a = _pool[rng.nextInt(_pool.length)];
      final b = _pool[rng.nextInt(_pool.length)];
      candidate = a.crossover(b).mutate(rate: 0.02, strength: 0.05);
    }

    _pool.add(candidate);
    if (_pool.length > _poolSize) _pool.removeAt(0);
    _currentIdx = _pool.length - 1;

    save(); // persist pool after each evolution
    return candidate;
  }

  // ── Persistence ───────────────────────────────────────

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final json  = prefs.getString(_key);
    if (json == null) {
      _pool.add(SheepGenome.defaults());
      return;
    }
    try {
      final list = jsonDecode(json) as List;
      _pool.addAll(list.map((e) => SheepGenome.fromJson(e as Map<String, dynamic>)));
      _currentIdx = _pool.length - 1;
    } catch (_) {
      _pool.add(SheepGenome.defaults());
    }
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, jsonEncode(_pool.map((s) => s.toJson()).toList()));
  }
}
```

---

## Step 3 — EvolutionController

Manages the timing of sheep transitions and the blend between current and next.

Create `lib/screensaver/sheep/genome/evolution_controller.dart`:

```dart
import 'sheep_genome.dart';
import 'sheep_pool.dart';

class EvolutionController {
  final SheepPool _pool;

  // How long each sheep lives before evolving
  final Duration sheepLifetime;

  // How long the crossfade between sheep takes
  final Duration blendDuration;

  EvolutionController({
    required SheepPool pool,
    this.sheepLifetime  = const Duration(seconds: 45),
    this.blendDuration  = const Duration(seconds: 8),
  }) : _pool = pool;

  SheepGenome? _blendTarget;
  double       _blendT      = 0.0; // 0.0 = current, 1.0 = target
  bool         _isBlending  = false;
  double       _elapsedSecs = 0.0;

  // Returns the genome to use this frame (may be mid-blend)
  SheepGenome get activeGenome {
    if (!_isBlending || _blendTarget == null) return _pool.current;
    return _pool.current.lerp(_blendTarget!, _blendT);
  }

  bool get isBlending => _isBlending;
  double get blendProgress => _blendT;

  // Call every frame with delta in seconds
  void update(double deltaSecs) {
    _elapsedSecs += deltaSecs;

    if (_isBlending) {
      _blendT += deltaSecs / blendDuration.inSeconds;
      if (_blendT >= 1.0) {
        _blendT       = 0.0;
        _isBlending   = false;
        _elapsedSecs  = 0.0;
        // pool.next() was already called when blend started —
        // current is now the completed target
      }
    } else if (_elapsedSecs >= sheepLifetime.inSeconds) {
      _startBlend();
    }
  }

  void _startBlend() {
    _blendTarget = _pool.next();
    _blendT      = 0.0;
    _isBlending  = true;
  }

  // Audio hook — call on strong beat to trigger early evolution
  void onBeatPulse({double energyLevel = 1.0}) {
    if (!_isBlending && energyLevel > 0.8) {
      _startBlend();
    }
  }
}
```

---

## Step 4 — Wire into SheepScreensaver

Update `sheep_screensaver.dart` to initialize pool and evolution controller:

```dart
late SheepPool           _pool;
late EvolutionController _evolution;
bool                     _ready = false;

@override
void initState() {
  super.initState();
  _initEvolution();
  // ... existing ticker setup
}

Future<void> _initEvolution() async {
  _pool = SheepPool();
  await _pool.load();
  _evolution = EvolutionController(pool: _pool);
  setState(() => _ready = true);
}

void _onTick(Duration elapsed) {
  final deltaMs   = /* as before */;
  final deltaSecs = deltaMs / 1000.0;

  if (_ready) {
    _evolution.update(deltaSecs);
    // _evolution.activeGenome is now available for rendering
  }

  _perf.recordFrame(deltaMs);
  setState(() {});
}
```

---

## Step 5 — Using the genome in your existing visuals

Map genome values to your current Forge2D and trail parameters:

```dart
SheepGenome get genome => _evolution.activeGenome;

// In your Forge2D world setup / update
world.gravity = Vector2(genome.gravityX, genome.gravityY);

// In your trail painter
trailPaint.color = HSLColor.fromAHSL(
  1.0,
  genome.trailHue,
  genome.trailSaturation,
  0.5,
).toColor().withOpacity(genome.trailOpacity);
```

---

## File structure after Phase 3

```
lib/
  screensaver/
    sheep/
      sheep_screensaver.dart         ← updated
      quality_config.dart            ← Phase 2
      performance_manager.dart       ← Phase 2
      genome/
        sheep_genome.dart            ← new
        sheep_pool.dart              ← new
        evolution_controller.dart    ← new
```

---

## Tuning the evolution feel

| Parameter | Lower | Higher |
|-----------|-------|--------|
| `sheepLifetime` | Faster evolution, more variety | Longer, more hypnotic |
| `blendDuration` | Snappy transitions | Slow, dreamy crossfades |
| `mutate rate` | Subtle changes | Wild jumps |
| `mutate strength` | Conservative drift | Dramatic mutations |

Recommended starting values for Google TV ambient display:
- `sheepLifetime`: 45 seconds
- `blendDuration`: 8 seconds
- `rate`: 0.05 (5% of genes mutate per generation)
- `strength`: 0.1 (10% shift per mutated gene)

---

## Done when

- [ ] `SheepGenome.random()` produces visually distinct results
- [ ] Sheep transitions are smooth — no pop between genomes
- [ ] Pool persists across app restarts (genome survives relaunch)
- [ ] Trail color and opacity visibly change between sheep
- [ ] Forge2D gravity visibly changes between sheep
- [ ] `onBeatPulse()` triggers an early evolution when audio energy is high
- [ ] No hardcoded visual parameters remain in screensaver code
