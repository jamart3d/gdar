# TV Background Spheres — Implementation Plan

**Date:** 2026-04-02 (revised 2026-04-03)
**Target:** TV main dual-pane home screen
**Scope:** Add an optional animated background of soft floating spheres behind
the TV home layout, with user controls in Settings → Interface (TV-only).

---

## Goal

Create a TV-only background treatment with:

- Soft, slightly out-of-focus spheres at different scales
- Overlap allowed to fake depth of field
- Slow floating motion
- Theme-derived color palette (`colorScheme.primary/secondary/tertiary`)
- A settings toggle to turn the effect on or off
- A 3-way amount control: `Small`, `Medium`, `More`

The `More` setting should aim toward the reference image density, but
stay within the active theme's color scheme.

---

## Agreed Direction

- Do **not** use `Flame` or `Forge2D`
- Extract the existing `_FruitFloatingSpheres` from Fruit car mode into a
  shared, public, reusable widget
- Mount the effect behind the full TV dual-pane home shell
- Keep the effect TV-only (controls gated with `isTv`)
- Default the feature to `off`
- Persist both the enabled state and amount selection in `SettingsProvider`
- **No `performanceMode` gating** — the sphere toggle is the off-switch
  (see `tv_performance_mode_analysis.md` for rationale: TV has no user-facing
  perf mode toggle)
- Settings controls go in **Interface** section, not Appearance

---

## Source Widget: Existing Fruit Floating Spheres

The current implementation lives in
`packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart`
(lines 1758-2001) and consists of:

- `_FruitFloatingSpheres` — `StatefulWidget` with `Timer.periodic` at 48ms
- `_FruitSphereNode` — data class (position, radius, color, velocity, depth)
- `_FruitFloatingSpheresPainter` — `CustomPainter` with `MaskFilter.blur`

This implementation is already Sabrina-safe:
- Timer-driven at ~21 fps — no `AnimationController`/vsync overhead
- 6 spheres × 2 `drawCircle` calls = 12 draw calls per frame
- `MaskFilter.blur` is per-circle, not a global pass
- Wrapped in `RepaintBoundary` — isolates repaint from the tree

---

## Visual Model

Fake depth using 3 z-bands:

1. **Far layer**
   Very large, faint, slowest drift, softest edges
2. **Mid layer**
   Medium sizes, moderate opacity, slightly faster drift
3. **Near layer**
   Smaller bright accents, a little more movement, still soft and defocused

Rules:

- All spheres remain slightly out of focus
- Spheres may overlap freely
- Motion should feel slow and ambient, not like particles or bubbles
- No sharp circle outlines as a default visual language
- Colors derive from `Theme.of(context).colorScheme` (not hardcoded orange)

---

## Amount Tiers

```dart
enum SphereAmount {
  tiny(6),     // Fruit car mode only (backward compat)
  small(12),   // TV default — safe for Sabrina
  medium(22),  // Mid-density ambient field
  more(38);    // Dense field — hardware-test required

  const SphereAmount(this.count);
  final int count;
}
```

| Tier | Count | Draw calls/frame | Where used |
|---|---|---|---|
| `tiny(6)` | 6 | ~12 | Fruit car mode only |
| `small(12)` | 12 | ~24 | TV option (default) |
| `medium(22)` | 22 | ~44 | TV option |
| `more(38)` | 38 | ~76 | TV option |

Only `small`, `medium`, and `more` appear in the TV settings picker.
`tiny` exists solely for Fruit backward compatibility.

Fruit car mode uses `SphereAmount.tiny` — preserving the existing 6-sphere
behavior exactly.

---

## Implementation Steps

### 1. Extract shared widget

**[NEW]** `packages/shakedown_core/lib/ui/widgets/backgrounds/floating_spheres_background.dart`

Extract and make public:
- `FloatingSpheresBackground` (from `_FruitFloatingSpheres`)
- `SphereNode` (from `_FruitSphereNode`)
- `FloatingSpheresPainter` (from `_FruitFloatingSpheresPainter`)
- `SphereAmount` enum

Parameters:
```dart
const FloatingSpheresBackground({
  required this.colorScheme,
  required this.animate,
  this.sphereCount = SphereAmount.medium,
  super.key,
});
```

**[MODIFY]** `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart`

Remove private classes, replace with import of new shared widget.

**[MODIFY]** `packages/shakedown_core/lib/shakedown_core.dart`

Add barrel export.

---

### 2. Add settings model

**[MODIFY]** `packages/shakedown_core/lib/config/default_settings.dart`

```dart
static const bool enableTvBackgroundSpheres = false;
static const String tvBackgroundSphereAmount = 'small';
```

**[MODIFY]** `packages/shakedown_core/lib/providers/settings_provider_core.dart`

- Key constants: `_enableTvBackgroundSpheresKey`, `_tvBackgroundSphereAmountKey`
- Fields: `late bool _enableTvBackgroundSpheres`, `late String _tvBackgroundSphereAmount`
- Getters: `enableTvBackgroundSpheres`, `tvBackgroundSphereAmount`
- Mutators: `toggleEnableTvBackgroundSpheres()`, `setTvBackgroundSphereAmount(SphereAmount)`

**[MODIFY]** `packages/shakedown_core/lib/providers/settings_provider_initialization.dart`

Load in `_loadCorePreferences()`.

---

### 3. Mount behind TV home shell

**[MODIFY]** `packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart`

Insert into existing `Stack` in `Scaffold.body` as the first child:

```dart
body: Stack(
  children: [
    if (settingsProvider.enableTvBackgroundSpheres)
      Positioned.fill(
        child: IgnorePointer(
          child: RepaintBoundary(
            child: FloatingSpheresBackground(
              colorScheme: Theme.of(context).colorScheme,
              animate: true,
              sphereCount: settingsProvider.tvBackgroundSphereAmount,
            ),
          ),
        ),
      ),
    // Existing dual-pane content...
  ],
),
```

Requires adding `context.watch<SettingsProvider>()` to the build method.

---

### 4. Add TV Interface controls

**[MODIFY]** `packages/shakedown_core/lib/ui/widgets/settings/interface_section.dart`

Add in the `isTv` block (after existing TV-specific tiles):

- `Background Spheres` — `TvSwitchListTile` toggle
- `Sphere Amount` — `SegmentedButton<SphereAmount>` with only 3 segments:
  Small | Medium | More (excludes `tiny`)
  Visible only when spheres are enabled
  Defaults to `small` on first enable

---

### 5. Tune for Sabrina hardware

Evaluate on Google TV 2020 Sabrina-class hardware and tune:

- Sphere count per tier
- Size ranges per depth band
- Opacity ranges
- Drift speed
- Whether `MaskFilter.blur` is affordable at the "More" tier (80 draw calls)

Priority: **Stable frame pacing over perfect visual density**

---

### 6. Add tests

- Settings defaults contract test (new keys)
- FakeSettingsProvider / mock parity (`/check_mock_parity`)
- Interface section visibility (TV-only gate)
- Widget render test per amount tier

Test files:
- `packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
- `packages/shakedown_core/test/ui/widgets/settings/interface_section_test.dart`

---

## Hardware Context: Google TV Sabrina (2020)

- **SoC:** Amlogic S905X3 — quad-core Cortex-A55 @ 1.9 GHz
- **GPU:** Mali-G31 MP2 — entry-level, 2 execution engines
- **RAM:** 2 GB (shared with system)
- **Flutter rendering:** Skia (software fallback possible under pressure)

At "More" tier (38 spheres → ~80 draw calls/frame), `MaskFilter.blur`
cost scales linearly. Hardware testing will confirm whether the blur sigma
needs to be reduced or spheres simplified at this tier.

---

## Performance Notes

- Prefer a small number of animated primitives over many layered effects
- Avoid expensive per-frame global blur passes
- Use deterministic motion (Timer-driven, not simulation-heavy)
- Keep animation subtle and low-frequency (~21 fps)
- The sphere toggle itself is the kill switch (no performanceMode dependency)

---

## Key Decision: No performanceMode Gating

The `performanceMode` toggle is **not exposed in the TV settings UI**. It's
gated behind `isFruitAllowed` which is `false` on TV (`kIsWeb && !isTv`).

Since TV users cannot toggle perf mode, gating spheres on it would create a
hidden dependency with no user-facing control. Instead, the dedicated
`enableTvBackgroundSpheres` toggle is the sole off-switch.

Full analysis: `apps/gdar_tv/docs/tv_performance_mode_analysis.md`

---

## Open Questions

- Whether `More` needs a few thin highlight rims on some spheres, or if all
  spheres should stay fully soft
- Whether a tiny amount of warm haze should sit behind the orb field
- Whether the default should remain `off` after hardware testing, or switch to
  `on + medium`
