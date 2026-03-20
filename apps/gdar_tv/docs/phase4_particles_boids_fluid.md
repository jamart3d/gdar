# Phase 4 — Particles, Boids + Fluid Simulation

**Project:** gdar_tv — Sheep screensaver  
**Goal:** Add three visual systems — particles, boids, and fluid sim — all genome-driven and quality-gated. Each system uses Forge2D body positions as anchors or force sources.

---

## Prerequisites

- Phase 2 complete — QualityConfig available
- Phase 3 complete — SheepGenome available
- Forge2D world running with at least one body (logo)

---

## System overview

| System | Forge2D relationship | Quality gate |
|--------|---------------------|--------------|
| Particles | Spawn at body positions | 500 / 2,000 / 8,000 |
| Boids | Bodies act as attractors | off / 50 / 200 agents |
| Fluid sim | Bodies inject force into fluid | off / half-res / full-res |

All three run in parallel at Level 2+. At Level 1 (safe), only particles run at reduced count.

---

## Part A — Particle System

### How it works

Particles spawn at Forge2D body positions, inherit a fraction of body velocity, then age and die. Color, size, and opacity are driven by the genome's particle genes.

### Step 1 — Particle data model

Create `lib/screensaver/sheep/particles/particle.dart`:

```dart
import 'dart:ui';

class Particle {
  Offset   position;
  Offset   velocity;
  double   age;        // 0.0 = just born, 1.0 = dead
  double   lifetime;   // seconds until age reaches 1.0
  double   size;
  double   hue;

  Particle({
    required this.position,
    required this.velocity,
    required this.age,
    required this.lifetime,
    required this.size,
    required this.hue,
  });

  bool get isDead => age >= 1.0;

  void update(double deltaSecs) {
    position += velocity * deltaSecs;
    age      += deltaSecs / lifetime;
    velocity *= 0.98; // drag
  }
}
```

### Step 2 — Particle system

Create `lib/screensaver/sheep/particles/particle_system.dart`:

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../genome/sheep_genome.dart';
import '../quality_config.dart';
import 'particle.dart';

class ParticleSystem {
  final List<Particle> _particles = [];
  final Random         _rng       = Random();
  double               _spawnAccumulator = 0.0;

  void update({
    required double        deltaSecs,
    required SheepGenome   genome,
    required QualityConfig config,
    required List<Offset>  spawnPoints, // Forge2D body positions
    required List<Offset>  spawnVelocities,
  }) {
    if (!config.particlesEnabled) {
      _particles.clear();
      return;
    }

    // Age and remove dead particles
    for (final p in _particles) p.update(deltaSecs);
    _particles.removeWhere((p) => p.isDead);

    // Enforce count cap
    while (_particles.length > config.particleCount) {
      _particles.removeAt(0);
    }

    // Spawn new particles
    _spawnAccumulator += genome.spawnRate * deltaSecs;
    while (_spawnAccumulator >= 1.0 && _particles.length < config.particleCount) {
      _spawnAccumulator -= 1.0;
      if (spawnPoints.isEmpty) break;
      final idx = _rng.nextInt(spawnPoints.length);
      _spawnParticle(spawnPoints[idx], spawnVelocities[idx], genome);
    }
  }

  void _spawnParticle(Offset origin, Offset bodyVel, SheepGenome genome) {
    final angle  = _rng.nextDouble() * genome.velocitySpread * (pi / 180.0);
    final speed  = _rng.nextDouble() * 80.0 + 20.0;
    final vx     = cos(angle) * speed + bodyVel.dx * 0.3;
    final vy     = sin(angle) * speed + bodyVel.dy * 0.3;

    _particles.add(Particle(
      position: origin,
      velocity: Offset(vx, vy),
      age:      0.0,
      lifetime: genome.particleLife * (0.8 + _rng.nextDouble() * 0.4),
      size:     4.0 + _rng.nextDouble() * 8.0,
      hue:      genome.colorHueStart +
                _rng.nextDouble() * (genome.colorHueEnd - genome.colorHueStart),
    ));
  }

  void paint(Canvas canvas) {
    for (final p in _particles) {
      final opacity = (1.0 - p.age).clamp(0.0, 1.0);
      final size    = p.size * (1.0 - p.age * 0.5);
      final paint   = Paint()
        ..color = HSLColor.fromAHSL(opacity, p.hue, 0.8, 0.6).toColor()
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0);
      canvas.drawCircle(p.position, size, paint);
    }
  }

  int get count => _particles.length;
}
```

---

## Part B — Boids

### How it works

Boids follow three rules: alignment (steer toward neighbors' heading), cohesion (steer toward neighbors' center), separation (avoid crowding). Forge2D bodies act as attractors — boids are gently drawn toward body positions.

### Step 1 — Boid data model

Create `lib/screensaver/sheep/boids/boid.dart`:

```dart
import 'dart:ui';

class Boid {
  Offset position;
  Offset velocity;

  Boid({required this.position, required this.velocity});
}
```

### Step 2 — Boids system

Create `lib/screensaver/sheep/boids/boids_system.dart`:

```dart
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../genome/sheep_genome.dart';
import '../quality_config.dart';
import 'boid.dart';

class BoidsSystem {
  final List<Boid> _boids = [];
  final Random     _rng   = Random();
  Size             _bounds = Size.zero;

  void init(Size bounds, SheepGenome genome, QualityConfig config) {
    _bounds = bounds;
    _boids.clear();
    for (int i = 0; i < config.boidCount; i++) {
      _boids.add(Boid(
        position: Offset(
          _rng.nextDouble() * bounds.width,
          _rng.nextDouble() * bounds.height,
        ),
        velocity: Offset(
          (_rng.nextDouble() - 0.5) * 100,
          (_rng.nextDouble() - 0.5) * 100,
        ),
      ));
    }
  }

  void update({
    required double        deltaSecs,
    required SheepGenome   genome,
    required QualityConfig config,
    required List<Offset>  attractors, // Forge2D body positions
  }) {
    if (!config.boidsEnabled) return;

    // Resize flock if quality level changed
    while (_boids.length < config.boidCount) {
      _boids.add(Boid(
        position: Offset(
          _rng.nextDouble() * _bounds.width,
          _rng.nextDouble() * _bounds.height,
        ),
        velocity: Offset(0, 0),
      ));
    }
    while (_boids.length > config.boidCount) _boids.removeLast();

    for (final boid in _boids) {
      final neighbors = _neighborsOf(boid, genome.cohesionRadius);

      final alignment  = _alignment(boid, neighbors) * genome.alignWeight;
      final cohesion   = _cohesion(boid, neighbors)  * 1.0;
      final separation = _separation(boid, neighbors, genome.separationDist) * 1.5;
      final attraction = _attractorForce(boid, attractors) * 0.5;

      boid.velocity += (alignment + cohesion + separation + attraction) * deltaSecs;

      // Clamp to max speed
      final speed = boid.velocity.distance;
      if (speed > genome.maxSpeed) {
        boid.velocity = boid.velocity / speed * genome.maxSpeed;
      }

      boid.position += boid.velocity * deltaSecs;

      // Wrap around screen edges
      boid.position = Offset(
        boid.position.dx % _bounds.width,
        boid.position.dy % _bounds.height,
      );
    }
  }

  List<Boid> _neighborsOf(Boid boid, double radius) {
    return _boids.where((other) {
      if (other == boid) return false;
      return (other.position - boid.position).distance < radius;
    }).toList();
  }

  Offset _alignment(Boid boid, List<Boid> neighbors) {
    if (neighbors.isEmpty) return Offset.zero;
    var avg = neighbors.fold(Offset.zero, (sum, b) => sum + b.velocity);
    avg = avg / neighbors.length.toDouble();
    return avg - boid.velocity;
  }

  Offset _cohesion(Boid boid, List<Boid> neighbors) {
    if (neighbors.isEmpty) return Offset.zero;
    var center = neighbors.fold(Offset.zero, (sum, b) => sum + b.position);
    center = center / neighbors.length.toDouble();
    return center - boid.position;
  }

  Offset _separation(Boid boid, List<Boid> neighbors, double minDist) {
    var steer = Offset.zero;
    for (final other in neighbors) {
      final delta = boid.position - other.position;
      final dist  = delta.distance;
      if (dist < minDist && dist > 0) steer += delta / dist;
    }
    return steer;
  }

  Offset _attractorForce(Boid boid, List<Offset> attractors) {
    var force = Offset.zero;
    for (final attractor in attractors) {
      final delta = attractor - boid.position;
      final dist  = delta.distance.clamp(50.0, 500.0);
      force += delta / dist;
    }
    return force;
  }

  void paint(Canvas canvas, SheepGenome genome) {
    final paint = Paint()
      ..color = HSLColor.fromAHSL(
        0.7,
        genome.colorHueStart,
        genome.colorSaturation,
        0.7,
      ).toColor()
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (final boid in _boids) {
      final angle  = atan2(boid.velocity.dy, boid.velocity.dx);
      final tip    = boid.position + Offset(cos(angle) * 8, sin(angle) * 8);
      final left   = boid.position + Offset(cos(angle + 2.4) * 4, sin(angle + 2.4) * 4);
      final right  = boid.position + Offset(cos(angle - 2.4) * 4, sin(angle - 2.4) * 4);
      final path   = Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close();
      canvas.drawPath(path, paint..style = PaintingStyle.fill);
    }
  }

  int get count => _boids.length;
}
```

---

## Part C — Fluid Simulation

### How it works

A simplified 2D Navier-Stokes fluid simulation on a grid. Forge2D body movement injects velocity and dye into the fluid each frame. The result is painted as a colored overlay on top of other visuals.

### Quality gate

- Level 1: fluid off
- Level 2: grid at 1/4 screen resolution, rendered upscaled
- Level 3: grid at 1/2 screen resolution

### Step 1 — Fluid grid

Create `lib/screensaver/sheep/fluid/fluid_grid.dart`:

```dart
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import '../genome/sheep_genome.dart';
import '../quality_config.dart';

class FluidGrid {
  late int      _w, _h;
  late Float32List _velX, _velY, _velX0, _velY0;
  late Float32List _dye,  _dye0;

  void init(Size screenSize, QualityLevel level) {
    final scale = level == QualityLevel.full ? 0.5 : 0.25;
    _w = (screenSize.width  * scale).round();
    _h = (screenSize.height * scale).round();
    final n = _w * _h;
    _velX  = Float32List(n); _velX0 = Float32List(n);
    _velY  = Float32List(n); _velY0 = Float32List(n);
    _dye   = Float32List(n); _dye0  = Float32List(n);
  }

  int _idx(int x, int y) =>
      x.clamp(0, _w - 1) + y.clamp(0, _h - 1) * _w;

  void addVelocity(int x, int y, double vx, double vy) {
    final i = _idx(x, y);
    _velX[i] += vx;
    _velY[i] += vy;
  }

  void addDye(int x, int y, double amount) {
    _dye[_idx(x, y)] += amount;
  }

  void step(SheepGenome genome) {
    _diffuse(_velX0, _velX, genome.viscosity);
    _diffuse(_velY0, _velY, genome.viscosity);
    _advect(_velX, _velX0, _velX0, _velY0);
    _advect(_velY, _velY0, _velX0, _velY0);
    _diffuse(_dye0, _dye, genome.diffusion);
    _advect(_dye, _dye0, _velX, _velY);

    // Fade dye over time
    for (int i = 0; i < _dye.length; i++) {
      _dye[i] *= 0.99;
    }
  }

  void _diffuse(Float32List x, Float32List x0, double diff) {
    final a = diff * 20;
    for (int k = 0; k < 4; k++) {
      for (int j = 1; j < _h - 1; j++) {
        for (int i = 1; i < _w - 1; i++) {
          x[_idx(i, j)] = (x0[_idx(i, j)] +
              a * (x[_idx(i-1, j)] + x[_idx(i+1, j)] +
                   x[_idx(i, j-1)] + x[_idx(i, j+1)])) / (1 + 4 * a);
        }
      }
    }
  }

  void _advect(Float32List d, Float32List d0,
               Float32List u, Float32List v) {
    for (int j = 1; j < _h - 1; j++) {
      for (int i = 1; i < _w - 1; i++) {
        double x = i - u[_idx(i, j)] * 0.5;
        double y = j - v[_idx(i, j)] * 0.5;
        x = x.clamp(0.5, _w - 1.5);
        y = y.clamp(0.5, _h - 1.5);
        final i0 = x.floor(), i1 = i0 + 1;
        final j0 = y.floor(), j1 = j0 + 1;
        final s1 = x - i0, s0 = 1 - s1;
        final t1 = y - j0, t0 = 1 - t1;
        d[_idx(i, j)] =
            s0 * (t0 * d0[_idx(i0, j0)] + t1 * d0[_idx(i0, j1)]) +
            s1 * (t0 * d0[_idx(i1, j0)] + t1 * d0[_idx(i1, j1)]);
      }
    }
  }

  void paint(Canvas canvas, Size screenSize, SheepGenome genome) {
    final scaleX = screenSize.width  / _w;
    final scaleY = screenSize.height / _h;
    final paint  = Paint();

    for (int j = 0; j < _h; j++) {
      for (int i = 0; i < _w; i++) {
        final density = _dye[_idx(i, j)].clamp(0.0, 1.0);
        if (density < 0.01) continue;
        paint.color = HSLColor.fromAHSL(
          density * genome.dyeIntensity,
          genome.colorHueStart,
          0.8,
          0.5 + density * 0.3,
        ).toColor();
        canvas.drawRect(
          Rect.fromLTWH(i * scaleX, j * scaleY, scaleX + 1, scaleY + 1),
          paint,
        );
      }
    }
  }

  // Inject force at a normalized position (0.0–1.0)
  void injectAt(double nx, double ny, double vx, double vy,
                double dyeAmount) {
    final x = (nx * _w).round().clamp(0, _w - 1);
    final y = (ny * _h).round().clamp(0, _h - 1);
    addVelocity(x, y, vx * 0.01, vy * 0.01);
    addDye(x, y, dyeAmount);
  }
}
```

---

## Step 2 — Wire all three systems into SheepScreensaver

Add to `sheep_screensaver.dart`:

```dart
late ParticleSystem _particles;
late BoidsSystem    _boids;
late FluidGrid      _fluid;
bool                _fluidInitialized = false;

@override
void initState() {
  super.initState();
  _particles = ParticleSystem();
  _boids     = BoidsSystem();
  _fluid     = FluidGrid();
  // ... existing init
}

// In _onTick, after evolution update:
void _onTick(Duration elapsed) {
  // ... existing delta calc

  final genome = _evolution.activeGenome;
  final config = QualityConfig(_perf.level);

  // Initialize fluid grid once we have screen size
  if (!_fluidInitialized && _screenSize != Size.zero) {
    _fluid.init(_screenSize, _perf.level);
    _boids.init(_screenSize, genome, config);
    _fluidInitialized = true;
  }

  // Get Forge2D body data
  final positions   = _getBodyPositions();
  final velocities  = _getBodyVelocities();

  // Update systems
  _particles.update(
    deltaSecs:       deltaSecs,
    genome:          genome,
    config:          config,
    spawnPoints:     positions,
    spawnVelocities: velocities,
  );

  _boids.update(
    deltaSecs: deltaSecs,
    genome:    genome,
    config:    config,
    attractors: positions,
  );

  if (config.boidsEnabled) {  // fluid reuses boids flag for Level 2+
    for (int i = 0; i < positions.length; i++) {
      _fluid.injectAt(
        positions[i].dx   / _screenSize.width,
        positions[i].dy   / _screenSize.height,
        velocities[i].dx,
        velocities[i].dy,
        genome.dyeIntensity * 0.5,
      );
    }
    _fluid.step(genome);
  }

  setState(() {});
}

// In your CustomPainter.paint():
void paint(Canvas canvas, Size size) {
  _fluid.paint(canvas, size, genome);      // fluid underneath
  _particles.paint(canvas);                // particles on top
  _boids.paint(canvas, genome);            // boids on top of particles
  // ... logo and trails painted last
}
```

---

## File structure after Phase 4

```
lib/
  screensaver/
    sheep/
      particles/
        particle.dart                ← new
        particle_system.dart         ← new
      boids/
        boid.dart                    ← new
        boids_system.dart            ← new
      fluid/
        fluid_grid.dart              ← new
```

---

## Performance notes for Google TV 2020

- Boids O(n²) neighbor search — keep Level 2 at 50, never exceed 200 at Level 3
- Fluid grid diffuse loop runs 4 iterations — reduce to 2 if Level 2 struggles
- Particle paint with `MaskFilter.blur` is expensive — remove blur at Level 1
- All three systems run simultaneously at Level 2+ — test combined load on device

---

## Done when

- [ ] Particles spawn at logo body position and drift away
- [ ] Particle color changes visibly between sheep genomes
- [ ] Boids flock visible at Level 2+, invisible at Level 1
- [ ] Boids visibly attracted toward logo body
- [ ] Fluid dye spreads and fades from logo movement at Level 2+
- [ ] No frame drops at Level 2 (balanced) after 10 min on Google TV 2020
- [ ] All three systems respond visibly to genome evolution transitions
