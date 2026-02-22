# TODO: Diagnose Logo Translation Jump

## Problem
Logo visually jolts/resets position every few minutes with audio reactivity off.
Root cause not yet identified despite extensive investigation.

## What's Been Ruled Out
- Shader audio nudge — gated on `uOverallEnergy > 0.01`, inactive without reactivity
- Palette cycling — `flowSpeed`/`orbitDrift` not changing between palettes
- Woodstock mode — colors only, no position writes
- Banner logic — only reads `smoothedLogoPos`, never writes
- `InactivityService.start()` — guarded by `_isEnabled`, never resets timer on repeat calls
- `StealGame` recreation — `StealVisualizer` is `StatefulWidget`, game survives rebuilds
- `didUpdateWidget` spurious calls — fixed with `StealConfig ==`, no longer fires on every tick

## Hypothesis
Either:
1. `_smoothedPos` itself is jumping (meaning `game.time` resets or config values change mid-session)
2. `_smoothedPos` is smooth but the shader is doing something visually jarring

## Debug Task
Add a **snackbar or toast** that fires when a large position jump is detected.

### Where to add it
`steal_background.dart` → `update()` method, after `_smoothedPos` is updated.

### Logic
```dart
final prevPos = _smoothedPos; // capture before update
// ... existing lerp code ...
// after update:
final dx = (_smoothedPos.dx - prevPos.dx).abs();
final dy = (_smoothedPos.dy - prevPos.dy).abs();
if (dx > 0.05 || dy > 0.05) {
  // fire snackbar/toast with:
  // "JUMP: prev=(${prevPos.dx.toStringAsFixed(3)}, ${prevPos.dy.toStringAsFixed(3)})
  //  new=(${_smoothedPos.dx.toStringAsFixed(3)}, ${_smoothedPos.dy.toStringAsFixed(3)})"
}
```

### Challenge
`StealBackground` is a Flame `PositionComponent` — no `BuildContext` available.
Need to either:
- Pass a callback from `ScreensaverScreen` into `StealGame` → `StealBackground`
- Use a global `ScaffoldMessenger` key
- Use a third-party toast package (e.g. `fluttertoast`) that doesn't need context

### Goal
Determine whether the jump is:
- A sudden change in `_smoothedPos` → points to `game.time` reset or config change
- Smooth `_smoothedPos` but visual jolt → points to shader

## Next Session
Implement the debug toast, trigger the jolt, read the output.
