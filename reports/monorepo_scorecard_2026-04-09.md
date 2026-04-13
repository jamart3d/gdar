# Monorepo Scorecard

Date: 2026-04-09
Project: GDAR
Workspace: repo root `gdar`
Reference: Fresh workspace rerun of the 2026-04-08 scorecard against
`30f11d0`, with current full-workspace `format`/`analyze`/`test` evidence
captured in this session.

## Overall Score

**8.9/10**

Up from 8.7 on 2026-04-08.

This rerun preserves strong architecture and validation signals while showing a
meaningful improvement in the current large-file hotspot profile.

- `dart run melos run format` passed
- `dart run melos run analyze` passed
- `dart run melos run test` passed
- `git -c core.excludesfile=.git/info/exclude status --short` is clean in this
  session
- top shared-library hotspot size is down from the prior run's 900+ tier

Two deductions still remain:

- no fresh browser-runtime playback smoke pass was captured in this session
- `.agent/notes/verification_status.json` still points to a commit that does
  not match current `HEAD`

## Category Breakdown

### Architecture: 9.1/10

Flat.

The package structure remains clean and monorepo boundaries are intact.

### Maintainability: 8.8/10

Up.

Current large-file scan of `packages/shakedown_core/lib`:

- `steal_graph_render_corner.dart`: **909** lines
- `settings_provider_initialization.dart`: **739** lines
- `steal_config.dart`: **707** lines
- `show_list_card_build.dart`: **651** lines
- `rating_dialog.dart`: **647** lines
- `dev_audio_hud_fields.dart`: **646** lines
- `fruit_now_playing_card.dart`: **634** lines
- `fruit_card_layout.dart`: **620** lines
- `tv_screensaver_section_controls.dart`: **596** lines
- `dev_audio_hud_helpers.dart`: **568** lines

Compared with the prior scorecard, the hotspot profile is materially lighter and
is no longer dominated by multiple files in the 900+ range.

### Test Quality: 9.2/10

Strong.

Fresh full-workspace validation is green in this rerun:

- `dart run melos run format` returned clean
- `dart run melos run analyze` returned clean
- `dart run melos run test` returned green

Deduction remains for receipt/commit drift.

### Platform Discipline: 9.0/10

Flat.

No structural platform-discipline regressions were observed in this rerun.

### Web Audio / Runtime Reliability: 7.9/10

Flat.

Analyzer and test evidence is healthy, but no fresh browser playback runtime
smoke evidence was captured in this cycle.

## Evidence Used In This Rerun

- current `HEAD`: `30f11d0`
- current clean status check:
  `git -c core.excludesfile=.git/info/exclude status --short`
- fresh workspace format pass:
  `dart run melos run format`
- fresh workspace analyze pass:
  `dart run melos run analyze`
- fresh workspace test pass:
  `dart run melos run test`
- current large-file scan of `packages/shakedown_core/lib`
- current verification receipt in `.agent/notes/verification_status.json`,
  which points at `b22d2e6845b47652583ac12a34063c530c7e5335` from
  `2026-04-09T20:10:49.105552`

## What Changed Since 2026-04-08

- fresh full-workspace `format`/`analyze`/`test` rerun is green again
- repo status is currently clean
- maintainability hotspot profile improved substantially
- verification receipt timestamp is fresh, but commit mismatch still remains
- runtime browser playback evidence still not refreshed

## What Still Caps The Score

- largest shared files are still in the high hundreds of lines
- verification receipt commit is stale relative to current `HEAD`
- web/audio confidence is still more test-backed than runtime-backed

## Path To 9.0+

1. Split the remaining largest files in `packages/shakedown_core/lib`, starting
   with `steal_graph_render_corner.dart` and
   `settings_provider_initialization.dart`.
2. Ensure the verification receipt updates to current `HEAD` on each successful
   verification cycle.
3. Add a fresh browser playback smoke pass for `apps/gdar_web` with runtime
   mode and console/error status captured.
4. Keep workspace-wide `format`/`analyze`/`test` green after the next
   maintainability pass.

## Bottom Line

GDAR remains strong on architecture and validation, and this rerun improved from
April 8 due to a clearly lighter hotspot profile. The score is now near 9.0,
but receipt/commit drift and missing fresh browser-runtime evidence still cap
confidence.
