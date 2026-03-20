# Phase 5 — Flame Fractal Renderer

**Project:** gdar_tv — Sheep screensaver  
**Goal:** Add Electric Sheep's signature visual — IFS flame fractals rendered via accumulation shader, with Forge2D bodies warping the fractal in real time.

---

## How flame fractals work

1. A genome defines a set of **affine transforms** (the IFS — iterated function system)
2. A shader randomly iterates millions of points through those transforms each frame
3. Each point landing in a pixel increments that pixel's counter in a **histogram buffer**
4. After N iterations, the histogram is **tone-mapped** using log-density to produce the final image
5. The result: flowing, organic fractal shapes that evolve as the genome mutates

This is what makes Electric Sheep visually distinctive — the log-density tone mapping gives fractals their characteristic bright cores with soft, glowing edges.

---

## Flutter compute shader approach

Flutter's `FragmentShader` API (available via `dart:ui`) supports custom GLSL fragment shaders. True compute shaders aren't available in Flutter — instead we use a two-pass approach:

- **Pass 1 (accumulation):** Render many points per frame into a floating-point texture, accumulating over multiple frames
- **Pass 2 (tone-map):** Sample the accumulation texture and apply log-density mapping to produce the final color output

---

## Step 1 — IFS transform structure

Add IFS genes to `SheepGenome` (reserved slots from Phase 3: `genes[22..35]`):

```dart
// In SheepGenome — IFS transform coefficients
// Each transform needs 6 values: a, b, c, d, e, f
// Two transforms = 12 genes (genes[22..33])
// Transform weight = genes[34], color index = genes[35]

double ifsA(int t) => (genes[22 + t * 6 + 0] - 0.5) * 2.0; // -1 to +1
double ifsB(int t) => (genes[22 + t * 6 + 1] - 0.5) * 2.0;
double ifsC(int t) => (genes[22 + t * 6 + 2] - 0.5) * 2.0;
double ifsD(int t) => (genes[22 + t * 6 + 3] - 0.5) * 2.0;
double ifsE(int t) => (genes[22 + t * 6 + 4] - 0.5) * 2.0; // translation x
double ifsF(int t) => (genes[22 + t * 6 + 5] - 0.5) * 2.0; // translation y

double get ifsWeight => genes[34]; // blend between transforms
double get ifsColorIdx => genes[35];

static const int ifsTransformCount = 2; // start with 2, expand later
```

---

## Step 2 — Accumulation texture setup

Flutter doesn't expose compute shaders directly, so we use `ui.FragmentProgram` with an offscreen `Picture` rendered to a `ui.Image` each frame, then accumulated manually.

Create `lib/screensaver/sheep/fractal/fractal_accumulator.dart`:

```dart
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../genome/sheep_genome.dart';
import '../quality_config.dart';

class FractalAccumulator {
  ui.FragmentShader? _accShader;
  ui.FragmentShader? _toneShader;
  ui.Image?          _accBuffer;
  bool               _ready = false;

  final int width;
  final int height;

  FractalAccumulator({required this.width, required this.height});

  Future<void> load() async {
    final accProgram  = await ui.FragmentProgram.fromAsset('shaders/ifs_accumulate.frag');
    final toneProgram = await ui.FragmentProgram.fromAsset('shaders/ifs_tonemap.frag');
    _accShader  = accProgram.fragmentShader();
    _toneShader = toneProgram.fragmentShader();
    _ready = true;
  }

  bool get isReady => _ready;

  void update(SheepGenome genome, QualityConfig config, List<ui.Offset> bodyPositions) {
    if (!_ready) return;
    // Shader uniforms are set each frame before painting
    // See _setUniforms below
  }

  void paint(Canvas canvas, Size size, SheepGenome genome,
      QualityConfig config, List<ui.Offset> bodyPositions) {
    if (!_ready) return;
    _setAccUniforms(genome, config, bodyPositions);
    // Draw accumulation pass into offscreen buffer
    // Then draw tone-map pass to canvas
    // Implementation depends on Flutter version's offscreen rendering API
  }

  void _setAccUniforms(SheepGenome genome, QualityConfig config,
      List<ui.Offset> bodyPositions) {
    if (_accShader == null) return;
    int slot = 0;

    // IFS transforms
    for (int t = 0; t < SheepGenome.ifsTransformCount; t++) {
      _accShader!.setFloat(slot++, genome.ifsA(t));
      _accShader!.setFloat(slot++, genome.ifsB(t));
      _accShader!.setFloat(slot++, genome.ifsC(t));
      _accShader!.setFloat(slot++, genome.ifsD(t));
      _accShader!.setFloat(slot++, genome.ifsE(t));
      _accShader!.setFloat(slot++, genome.ifsF(t));
    }
    _accShader!.setFloat(slot++, genome.ifsWeight);

    // Forge2D body positions (up to 8)
    for (int i = 0; i < 8; i++) {
      final pos = i < bodyPositions.length ? bodyPositions[i] : ui.Offset.zero;
      _accShader!.setFloat(slot++, pos.dx / size.width);
      _accShader!.setFloat(slot++, pos.dy / size.height);
    }

    // Iteration count from quality config
    _accShader!.setFloat(slot++, config.ifsIterations.toDouble());
  }
}
```

---

## Step 3 — GLSL accumulation shader

Create `assets/shaders/ifs_accumulate.frag`:

```glsl
#include <flutter/runtime_effect.glsl>

// IFS transform coefficients (2 transforms × 6 coefficients)
uniform float a0, b0, c0, d0, e0, f0;
uniform float a1, b1, c1, d1, e1, f1;
uniform float ifsWeight;

// Forge2D body positions (normalized 0.0–1.0), up to 8 bodies
uniform vec2 body[8];

uniform float iterations;
uniform sampler2D prevBuffer; // previous frame accumulation

out vec4 fragColor;

// Pseudo-random from seed
float rand(vec2 co) {
  return fract(sin(dot(co, vec2(12.9898, 78.233))) * 43758.5453);
}

vec2 applyTransform(int t, vec2 p) {
  if (t == 0) return vec2(a0*p.x + b0*p.y + e0, c0*p.x + d0*p.y + f0);
  else        return vec2(a1*p.x + b1*p.y + e1, c1*p.x + d1*p.y + f1);
}

vec2 bodyWarp(vec2 p) {
  vec2 warp = vec2(0.0);
  for (int i = 0; i < 8; i++) {
    vec2  delta = p - body[i];
    float dist  = length(delta) + 0.001;
    warp += delta / (dist * dist) * 0.002; // attraction strength
  }
  return p + warp;
}

void main() {
  vec2 uv   = FlutterFragCoord().xy;
  vec2 seed = uv / vec2(textureSize(prevBuffer, 0));

  // Sample previous accumulation
  vec4 prev = texture(prevBuffer, seed);

  // Iterate a few points starting from random positions near this fragment
  float hits = 0.0;
  vec2  p    = vec2(rand(seed), rand(seed.yx)) * 2.0 - 1.0;

  int iters = int(iterations / float(textureSize(prevBuffer, 0).x *
                                     textureSize(prevBuffer, 0).y));
  iters = max(iters, 1);

  for (int i = 0; i < iters; i++) {
    int t = (rand(p + float(i)) > ifsWeight) ? 0 : 1;
    p     = applyTransform(t, p);
    p     = bodyWarp(p);          // Forge2D warp

    // Check if this point lands near our fragment
    vec2 mapped = (p + 1.0) * 0.5; // map -1..1 to 0..1
    if (length(mapped - seed) < 0.005) hits += 1.0;
  }

  // Accumulate
  fragColor = prev + vec4(hits * 0.1);
}
```

---

## Step 4 — GLSL tone-map shader

Create `assets/shaders/ifs_tonemap.frag`:

```glsl
#include <flutter/runtime_effect.glsl>

uniform sampler2D accumBuffer;
uniform float     maxDensity;
uniform float     hueStart;   // from genome
uniform float     hueEnd;     // from genome
uniform float     gamma;      // typically 2.2

out vec4 fragColor;

vec3 hsvToRgb(float h, float s, float v) {
  float c  = v * s;
  float x  = c * (1.0 - abs(mod(h / 60.0, 2.0) - 1.0));
  float m  = v - c;
  vec3  rgb;
  if      (h < 60.0)  rgb = vec3(c, x, 0);
  else if (h < 120.0) rgb = vec3(x, c, 0);
  else if (h < 180.0) rgb = vec3(0, c, x);
  else if (h < 240.0) rgb = vec3(0, x, c);
  else if (h < 300.0) rgb = vec3(x, 0, c);
  else                rgb = vec3(c, 0, x);
  return rgb + m;
}

void main() {
  vec2  uv      = FlutterFragCoord().xy / vec2(textureSize(accumBuffer, 0));
  vec4  acc     = texture(accumBuffer, uv);
  float density = log(acc.r + 1.0) / log(maxDensity + 1.0); // log-density tone map
  density       = pow(density, 1.0 / gamma);                 // gamma correction

  float hue     = mix(hueStart, hueEnd, density);
  vec3  color   = hsvToRgb(hue, 0.8, density);

  fragColor = vec4(color, density);
}
```

---

## Step 5 — Register shaders in pubspec.yaml

```yaml
flutter:
  shaders:
    - assets/shaders/ifs_accumulate.frag
    - assets/shaders/ifs_tonemap.frag
```

---

## Step 6 — Wire into SheepScreensaver

```dart
late FractalAccumulator _fractal;

@override
void initState() {
  super.initState();
  _fractal = FractalAccumulator(width: 1920, height: 1080);
  _fractal.load();
  // ... existing init
}

// In your CustomPainter:
@override
void paint(Canvas canvas, Size size) {
  if (!_fractal.isReady || !config.ifsEnabled) return;
  _fractal.paint(canvas, size, genome, config, bodyPositions);
}
```

---

## Forge2D integration — the unique part

Body positions warp the IFS transforms each frame via the `bodyWarp()` function in the shader. The logo's Forge2D body position, velocity, and collision response directly shape the fractal — collisions cause visible ripples in the fractal geometry.

```dart
// Extract body positions each frame for shader uniforms
List<ui.Offset> get bodyPositions {
  return world.bodies.map((body) {
    return ui.Offset(
      body.position.x / worldWidth  * screenWidth,
      body.position.y / worldHeight * screenHeight,
    );
  }).toList();
}
```

---

## Performance notes for Google TV 2020

- Level 1 (safe): IFS disabled — no shader cost at all
- Level 2 (balanced): 50k iterations spread across fragment shader invocations
- Level 3 (full): 200k iterations — monitor GPU temperature on device
- Accumulation buffer should be half resolution and upscaled — reduces fill rate cost
- Clear accumulation buffer on sheep transition (genome change) to avoid ghosting

---

## File structure after Phase 5

```
lib/
  screensaver/
    sheep/
      fractal/
        fractal_accumulator.dart     ← new
assets/
  shaders/
    ifs_accumulate.frag              ← new
    ifs_tonemap.frag                 ← new
```

---

## Done when

- [ ] Flame fractal visible at Quality Level 2 and 3
- [ ] Fractal shape visibly changes as genome evolves between sheep
- [ ] Forge2D body movement causes visible real-time warping of fractal
- [ ] Log-density tone mapping produces soft glowing edges (not harsh cutoffs)
- [ ] Accumulation buffer cleared cleanly on sheep transition
- [ ] No GPU overheating at Level 2 after 30 min on Google TV 2020
- [ ] Level 1 runs with IFS fully disabled — no regression
