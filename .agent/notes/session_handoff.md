# Session Handoff — 2026-04-21 (Fruit car-mode HD/NXT chip gauges + live-update fix)

## State at Handoff

User requested a car-mode HUD change for the top-row `HD` and `NXT` chips:

- keep chip size/layout unchanged
- turn each chip background into a visible bar-graph style gauge
- make it readable from car distance
- keep within current Fruit theme constraints

That work is implemented in code and verified with focused Flutter tests.

## What Changed

### `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`

`_FruitCarModeStatCard` now supports persistent internal gauge rendering for
chips that pass `fillFraction`:

- a faint full-width themed track is always visible
- a stronger left-to-right fill is layered on top
- chip size/layout is unchanged
- `DFT` and `LG` still render without gauge backgrounds

### `packages/shakedown_core/lib/ui/screens/playback_screen.dart`

Added/updated car-mode gauge helpers:

- `computeFruitCarModeHeadroomFill(...)`
  - now uses a fixed `0s..30s` full-scale gauge for `HD`
  - intended as a readable “full tank” reserve gauge for car mode
- `computeFruitCarModeNextTrackFill(...)`
  - now uses `nextBuffered / nextTrackTotal`
  - so `NXT` reflects actual next-file load progress instead of
    `webPrefetchSeconds`
- `parseFruitCarModeDurationText(...)`
  - shared parser for formatted chip display text

### `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_hud.dart`

Wired the new chip fills:

- `HD` uses the fixed 30-second full-scale gauge
- `NXT` uses real next-file total duration from
  `audioProvider.audioPlayer.nextTrackTotal`

Also fixed a live-update bug:

- car-mode chips were previously gated by a nested `playerStateStream`
  `StreamBuilder`
- this could leave the chip row visually frozen until a play/pause event
- chip freeze/live-update now keys off `liveHud.isPlaying` from the
  continuously refreshed `hudSnapshotStream`

Result:

- during playback, `HD` / `NXT` chips continue updating live
- when paused, chip values still freeze as intended

## Test Coverage Added / Updated

### `packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`

Added/updated focused unit coverage for:

- `HD` fixed 30-second full-scale normalization
- `NXT` normalization against next-file total
- unknown-total fallback behavior
- shared chip-duration parsing helpers

### `packages/shakedown_core/test/screens/playback_screen_test.dart`

Updated widget coverage for:

- gauge track visibility on `HD` / `NXT`
- paused-state freezing
- live chip updates during playback without a separate player-state event
- zero/low-fill visual expectations under the new `HD` scale

Also updated the test fake audio provider to support emitted HUD snapshots and
added the missing `nextTrackTotal` mock stub.

## Verification Evidence

Commands run and passing in this session:

- `flutter test packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`
- `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart`

## Files Touched This Session

- `.agent/notes/pending_release.md`
- `.agent/notes/session_handoff.md`
- `AGENTS.md`
- `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
- `packages/shakedown_core/lib/ui/screens/playback_fruit_car_mode/fruit_car_mode_hud.dart`
- `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_widgets.dart`
- `packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`
- `packages/shakedown_core/test/screens/playback_screen_test.dart`

## Remaining Follow-Up

No known failing tests remain.

One manual validation item remains for the user:

- rerun web car mode in Chrome and confirm `HD` / `NXT` chip backgrounds now
  continue updating live during playback and visually read well at distance

Possible future enhancement already discussed with the user:

- make `HD` full-scale adjustable in a later version instead of fixed at
  `30s`
