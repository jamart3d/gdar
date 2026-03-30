# Fruit Theme Refactor Plan

This document captures the implementation plan for aligning the current Fruit
theme with the updated Liquid Glass specification.

Related reference:

- `.agent/specs/fruit_theme_spec.md` is the current Fruit implementation
  contract

## Scope

- Web / PWA Fruit UI only
- Diagnostic HUD remains unchanged
- Appearance settings must continue to govern the experience
- Visible behavior changes should remain Fruit-only unless the task explicitly
  targets TV

## Goals

1. Replace the current stacked blur/card treatment with a single-sheet liquid
   material model.
2. Improve tactile response so Fruit controls feel physical instead of
   opacity-driven.
3. Upgrade transport loading behavior to a liquid pending transition.
4. Keep Fruit calm and native. If glow and RGB are not Apple-like, they should
   not shape Fruit behavior or appear in Fruit settings.
5. Preserve all existing settings gates and performance fallbacks.

## Current Status

- Spec updated to the single-sheet liquid direction
- Canonical Fruit surface introduced and applied to key playback chrome
- Fruit playback / track list / settings / tab bar refined through multiple
  visual passes
- Glow and RGB removed from Fruit behavior and hidden from Fruit settings
- Diagnostic HUD intentionally excluded from scope

## Out of Scope

- Dev HUD / diagnostics UI
- Android Material UI
- Planned TV feature work
- Non-Fruit themes

## Settings Contract

The refactor must continue honoring these settings:

- `fruitEnableLiquidGlass`
- `performanceMode`
- `fruitStickyNowPlaying`
- `fruitDenseList`

Notes:

- `glowMode` and `highlightPlayingWithRgb` still exist for non-Fruit modes
- Fruit should ignore them and avoid showing them in Fruit settings

## Work Plan

### 1. Canonical Fruit Surface

Create one shared Fruit liquid surface primitive that owns:

- blur/refractive treatment
- edge sheen and inner highlight behavior
- soft optical border logic
- reduced/performance fallback behavior
- optional accent energy derived from settings

Primary target:

- `packages/shakedown_core/lib/ui/widgets/theme/liquid_glass_wrapper.dart`
- `packages/shakedown_core/lib/ui/widgets/theme/fruit_ui.dart`

Deliverable:

- one shared Fruit surface primitive for playback chrome
- liquid edge/highlight logic centralized in one place
- clear reduced-mode behavior when `fruitEnableLiquidGlass` is off

Status:

- largely implemented

### 2. Single-Sheet Hierarchy

Refactor Fruit playback chrome so header, sticky now-playing, and inline
now-playing share the same material language instead of stacking multiple blur
surfaces.

Primary target:

- `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`

Deliverable:

- no stacked glass slabs for header + sticky now-playing + inline now-playing
- one consistent material language across those states

Status:

- partially implemented
- playback header, now-playing, and sticky states have been moved closer to one
  language, but more visual cleanup may still be possible

### 3. Remove Plastic Feel

Reduce or remove Fruit neumorphic treatments where they conflict with the
single-sheet liquid model.

Primary target:

- `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`
- any Fruit-only wrappers that currently read as stacked plastic

Deliverable:

- remove or reduce conflicting neumorphic treatment in Fruit playback chrome
- preserve usability without reverting to Material styling

Status:

- partially implemented

### 4. Physical Press Response

Replace opacity-only Fruit press handling with a light sink/rebound interaction
that remains performant on web.

Primary target:

- `packages/shakedown_core/lib/ui/widgets/theme/fruit_icon_button.dart`
- `packages/shakedown_core/lib/ui/widgets/theme/fruit_ui.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`

Deliverable:

- shared Fruit press behavior with sink/rebound feel
- no opacity-only primary interaction states

Status:

- first pass implemented

### 5. Liquid Pending Transition

Replace the plain play/pause swap and generic loading treatment in Fruit
transport controls with a liquid pending state.

Primary target:

- `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`

Deliverable:

- pending/buffering state that feels integrated with the glass surface
- replace simple play/pause swap as the primary transport transition

Status:

- first pass implemented in Fruit now-playing controls

### 6. Glow and RGB Reinterpretation

Fruit no longer uses glow and RGB as part of its native visual identity.

Rules:

- Fruit should ignore `glowMode`
- Fruit should ignore `highlightPlayingWithRgb`
- Fruit settings should not show controls that Fruit ignores
- non-Fruit modes may continue using those settings

Deliverable:

- default Fruit path stays calm and native
- expressive settings remain available outside Fruit

Status:

- implemented

### 7. Verification

Verify that the Fruit playback UI:

- still respects all appearance toggles
- leaves the diagnostic HUD untouched
- does not regress compact/dense layouts
- does not introduce Material interaction patterns
- remains usable in reduced/performance mode

Status:

- still pending as a broader end-to-end pass

## Suggested Implementation Order

1. Canonical Fruit surface
2. Header and now-playing hierarchy cleanup
3. Remove conflicting neumorphism
4. Press interaction upgrade
5. Pending transport transition
6. Glow/RGB reinterpretation
7. Verification pass

## Work Added During Iteration

- Fruit track list header cleanup to better match playback
- Fruit settings header/button cleanup
- Fruit show list app bar cleanup and title font override support
- Web tab bar blur containment fix for Fruit liquid glass

## Non-Plan Regression Cleanup

The following work happened as regression cleanup rather than core Fruit plan
items:

- TV settings black-surface restoration
- TV current-show card black background restoration
- TV stepper black-surface restoration
- TV source filtering chip upgrade
- TV default changes for `Hide TV Scrollbars` and `TV Highlight`

## File Watch List

- `packages/shakedown_core/lib/ui/widgets/theme/liquid_glass_wrapper.dart`
- `packages/shakedown_core/lib/ui/widgets/theme/fruit_ui.dart`
- `packages/shakedown_core/lib/ui/widgets/theme/fruit_icon_button.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`
- `packages/shakedown_core/lib/ui/screens/playback_screen.dart`

## Notes

- The diagnostic HUD is intentionally excluded from this refactor.
- The goal is to make Fruit feel more native and liquid, not more decorative.
- Default Fruit should stay calm; glow and RGB remain optional user-controlled
  expressive modes.
