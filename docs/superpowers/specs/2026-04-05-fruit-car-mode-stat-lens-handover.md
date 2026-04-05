# Fruit Car Mode Stat Lens Handover

**Date:** 2026-04-05

**Scope:** Web Fruit car mode playback screen only. This work does not target TV playback, non-Fruit themes, or non-car-mode playback.

**Branch:** `feat/fruit-car-mode-stat-font-size-v2`

**Related plan:** `docs/superpowers/plans/2026-04-04-fruit-car-mode-stat-font-size.md`

## Summary

This session followed up on the earlier `17 -> 18` stat-chip value increase, which was too subtle to matter visually on the web Fruit car mode playback screen.

The current branch changes the top-row stat chips (`DFT`, `HD`, `NXT`, `LG`) to:

- reclaim internal chip space without changing chip size
- raise the value font to `24 * scaleFactor`
- add a value-only lens effect when `fruitEnableLiquidGlass` is enabled
- keep the label size and external chip row layout unchanged

## Implemented

### `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`

- `_FruitCarModeStatCard` now reads `fruitEnableLiquidGlass` from `SettingsProvider`
- value text is built once with:
  - `fontSize: 24 * scaleFactor`
  - existing single-line ellipsis behavior
- when Liquid Glass is enabled:
  - the value is wrapped in a small lens treatment keyed as `fruit_car_mode_stat_value_lens`
  - the lens is a subtle pill-shaped optical overlay behind the value
  - the value itself gets a slight `Transform.scale(1.03)` boost to support the magnified read
- chip internals were tightened to make room:
  - vertical padding reduced to `6 * scaleFactor`
  - label-to-value gap reduced to `2 * scaleFactor`

### `packages/shakedown_core/test/screens/playback_screen_test.dart`

- `MockSettingsProvider` now supports `setFruitEnableLiquidGlass(bool value)`
- the Fruit car mode stat-chip regression test now verifies:
  - web Fruit car mode with Liquid Glass enabled
  - representative long value `1200ms` still renders
  - value font size is `24.0`
  - four lens overlays are present via `fruit_car_mode_stat_value_lens`
  - no layout exceptions are thrown

## Verification

Verified in this branch:

- `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart`
  - passed (`11` tests)
- `flutter analyze`
  - passed with `No issues found!`

## Files Changed

- `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`
- `packages/shakedown_core/test/screens/playback_screen_test.dart`

## Notes For Next Session

- At handoff time, this branch was verified and awaiting merge.
- If the visual lens effect needs tuning, the safest knobs are:
  - lens gradient alpha
  - lens width factor (`0.92`)
  - text scale inside the lens (`1.03`)
- If the numbers still do not read large enough in-browser, increase the lens treatment first before pushing the base font past `24`, because the chip height is fixed.
