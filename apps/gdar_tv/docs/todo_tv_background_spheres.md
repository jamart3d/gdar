# TV Background Spheres Todo Plan

**Date:** 2026-04-02  
**Target:** TV main dual-pane home screen  
**Scope:** Add an optional animated background of soft floating spheres behind
the TV home layout, with user controls in Settings -> Appearance.

---

## Goal

Create a TV-only background treatment with:

- Soft, slightly out-of-focus spheres at different scales
- Overlap allowed to fake depth of field
- Slow floating motion
- Smooth orange-family color variation with mixed opacity
- A settings toggle to turn the effect on or off
- A 3-way amount control: `Small`, `Medium`, `More`

The `More` setting should aim toward the attached reference image density, but
stay in an orange-only palette.

---

## Agreed Direction

- Do **not** start with `Flame` or `Forge2D`
- Use a custom Flutter background widget instead
- Mount the effect behind the full TV dual-pane home shell
- Keep the effect TV-only
- Default the feature to `off`
- Persist both the enabled state and amount selection in `SettingsProvider`

Reasoning:

- The requested motion style can be achieved without a physics engine
- A lighter custom widget is safer for Google TV 2020 Sabrina-class hardware
- This keeps the effect easier to tune, test, and disable if performance dips

---

## Visual Model

Fake depth using 3 z-bands:

1. Far layer
   Very large, faint, slowest drift, softest edges
2. Mid layer
   Medium sizes, moderate opacity, slightly faster drift
3. Near layer
   Smaller bright accents, a little more movement, still soft and defocused

Rules:

- All spheres remain slightly out of focus
- Spheres may overlap freely
- Motion should feel slow and ambient, not like particles or bubbles
- No sharp circle outlines as a default visual language
- Palette stays in orange, amber, peach, and warm gold ranges

---

## Proposed Amount Tiers

Initial working budget:

- `Small`: 10-14 spheres
- `Medium`: 18-26 spheres
- `More`: 32-44 spheres

These are starting points only and should be tuned on hardware.

---

## Implementation Plan

### 1. Add settings model

Update the shared settings layer with:

- `enableTvBackgroundSpheres` as a persisted `bool`
- `tvBackgroundSphereAmount` as a persisted enum/string

Touchpoints:

- `packages/shakedown_core/lib/config/default_settings.dart`
- `packages/shakedown_core/lib/providers/settings_provider.dart`
- `packages/shakedown_core/lib/providers/settings_provider_core.dart`

---

### 2. Build the background widget

Create a reusable TV-only background widget that:

- Generates a deterministic set of spheres
- Splits them into layered depth bands
- Animates slow drifting offsets over time
- Uses soft radial fills and gentle falloff
- Minimizes repaint cost

Likely placement:

- `packages/shakedown_core/lib/ui/widgets/tv/`

---

### 3. Mount it behind the TV home shell

Attach the widget behind the content in:

- `packages/shakedown_core/lib/ui/widgets/tv/tv_dual_pane_layout.dart`

The effect should sit behind both panes so it reads as one background field.

---

### 4. Add TV Appearance controls

Add controls in:

- `packages/shakedown_core/lib/ui/widgets/settings/appearance_section.dart`
- `packages/shakedown_core/lib/ui/widgets/settings/appearance_section_build.dart`
- `packages/shakedown_core/lib/ui/widgets/settings/appearance_section_controls.dart`

Controls:

- `Background Spheres` toggle
- `Amount` segmented control with `Small`, `Medium`, `More`

These controls should only appear on TV.

---

### 5. Tune for Sabrina hardware

Evaluate on Google TV 2020 Sabrina-class hardware and tune:

- Sphere count
- Size ranges
- Opacity ranges
- Drift speed
- Repaint scope
- Whether additional blur or glow is affordable

Priority:

- Stable frame pacing over perfect visual density

---

### 6. Add tests

Add coverage for:

- TV default values
- Persistence behavior
- TV settings UI visibility
- TV settings interaction

Likely test files:

- `packages/shakedown_core/test/providers/settings_provider_defaults_contract_test.dart`
- `packages/shakedown_core/test/ui/screens/tv_settings_screen_test.dart`

---

## Performance Notes

Guidelines for the first implementation:

- Prefer a small number of animated primitives over many layered effects
- Avoid expensive per-frame global blur passes if possible
- Use deterministic motion instead of simulation-heavy motion
- Keep animation subtle and low-frequency
- Add an easy off switch and preserve user control

---

## Open Questions For Implementation

- Whether `More` needs a few thin highlight rims on some spheres, or if all
  spheres should stay fully soft
- Whether a tiny amount of warm haze should sit behind the orb field
- Whether the default should remain `off` after hardware testing, or switch to
  `on + medium`
