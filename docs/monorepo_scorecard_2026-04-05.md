# Monorepo Scorecard

Date: 2026-04-05
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-03 scorecard against
`07e4f61`, with a clean pre-doc worktree, fresh full-workspace
`format`/`analyze`/`test` passes, and a fresh large-file scan

## Overall Score

**8.8/10**

Slightly down from 8.9 on 2026-04-03.

This rerun has better live validation evidence than the April 3 scorecard did:

- `git status --short` was clean before this scorecard file was written
- `dart run melos run format` passed
- `dart run melos run analyze` passed with no issues across all workspace
  packages
- `dart run melos run test` passed across the active test packages

The small downgrade is not about a red validation lane. It is about the shape
of the backlog:

- `appearance_section_controls.dart` is now the largest shared UI hotspot at
  **926** lines
- several other shared UI files still sit in the **800-870** line range
- no fresh browser-runtime pass was captured in this rerun
- `.agent/notes/verification_status.json` still points at an older commit even
  though the live workspace validation rerun was green

So GDAR still reads as a strong monorepo, but the drag is once again shared UI
surface size and evidence automation depth rather than architecture.

## Category Breakdown

### Architecture: 9.1/10

Flat.

The package graph still looks healthy in the live repo:

- `packages/styles/gdar_fruit/pubspec.yaml` depends on `gdar_design`
- `packages/styles/gdar_fruit/pubspec.yaml` does not depend on
  `shakedown_core`
- `packages/shakedown_core/pubspec.yaml` depends on `gdar_design`
- `packages/screensaver_tv/pubspec.yaml` is still a minimal workspace package
- app targets remain isolated under `apps/`

There is no fresh package-boundary regression in this rerun. The monorepo
structure still matches the intended layering much better than it did in older
scorecards.

### Maintainability: 8.6/10

Down slightly.

Current large-file scan of `packages/shakedown_core/lib`:

- `appearance_section_controls.dart`: **926** lines
- `rating_control.dart`: **872** lines
- `fruit_now_playing_card.dart`: **869** lines
- `track_list_screen_build.dart`: **868** lines
- `track_list_view.dart`: **866** lines
- `steal_graph_render_corner.dart`: **853** lines
- `dev_audio_hud_build.dart`: **825** lines
- `playback_screen_fruit_car_mode.dart`: **815** lines
- `tv_playback_screen_build.dart`: **798** lines

This is not a collapse, but it is enough to keep maintainability from
improving. The backlog remains concentrated in shared UI surfaces where
iteration cost is high and safe refactors require strong test coverage.

### Test Quality: 9.1/10

Up slightly.

This is the strongest part of the current rerun:

- `dart run melos run format` returned clean
- `dart run melos run analyze` returned clean across all eight workspace
  packages
- `dart run melos run test` returned green across `gdar_mobile`, `gdar_tv`,
  `gdar_web`, and `shakedown_core`

That is a materially stronger evidence set than a targeted-file or
user-reported pass. The only deduction here is process drift: the
machine-readable verification receipt still records
`d20ff8f998a296a076bd3a0dbc6798f6b7c8922c`, not the current `HEAD`, so the
automation trail is weaker than the live command evidence.

### Platform Discipline: 9.0/10

Flat.

Platform intent still reads clearly:

- app-specific entrypoints stay under `apps/`
- shared logic and reusable UI stay in workspace packages
- the style-layer dependency direction remains clean
- the test lane still exercises mobile, TV, web, and shared package surfaces

This category remains strong. The deduction is about evidence depth around
runtime behavior, not platform confusion in the repo layout.

### Web Audio / Runtime Reliability: 8.0/10

Slightly down.

Nothing in this rerun suggests a new web/audio regression, and the web test
lane passed cleanly. But this scorecard does not have fresh browser-runtime
evidence:

- no new Chrome or browser playback smoke pass was captured in this session
- confidence comes from analyzer and test signal rather than a fresh manual
  runtime verification
- `apps/gdar_web` remains well-covered by tests, but runtime depth is still
  shallower than the static validation depth

That keeps this category positive, but still conservative.

## Evidence Used In This Rerun

- current `HEAD`: `07e4f61`
- clean pre-doc worktree from repo root:
  `git -c core.excludesfile=.git/info/exclude status --short`
- fresh workspace format pass:
  `dart run melos run format`
- fresh workspace analyze pass:
  `dart run melos run analyze`
- fresh workspace test pass:
  `dart run melos run test`
- live dependency checks in:
  `packages/styles/gdar_fruit/pubspec.yaml`
- live dependency checks in:
  `packages/shakedown_core/pubspec.yaml`
- live dependency checks in:
  `packages/gdar_design/pubspec.yaml`
- live dependency checks in:
  `packages/screensaver_tv/pubspec.yaml`
- current large-file scan of `packages/shakedown_core/lib`
- current verification receipt in `.agent/notes/verification_status.json`,
  which still points at `d20ff8f998a296a076bd3a0dbc6798f6b7c8922c`
- attempted receipt refresh via `dart scripts/preflight_check.dart --record-pass`
  did not complete before the terminal tool timeout, so the fresh green rerun is
  documented here from the direct command output instead

## What Changed Since 2026-04-03

- a fresh full-workspace `format`/`analyze`/`test` rerun is now green
- the pre-doc workspace was clean at the repo root
- `appearance_section_controls.dart` has become the largest shared UI hotspot
- no fresh browser-runtime pass was added in this rerun
- the verification receipt is now the main process artifact lagging behind the
  live repo state

## What Still Caps The Score

- several shared UI files still sit between roughly **800** and **930** lines
- the machine-readable verification receipt is stale relative to `HEAD`
- web/audio confidence is currently test-backed more than runtime-backed

## Path To 9.0+

1. Split `appearance_section_controls.dart` and continue through the next UI
   hotspot tier: `rating_control.dart`, `fruit_now_playing_card.dart`,
   `track_list_screen_build.dart`, and `track_list_view.dart`.
2. Fix the `preflight_check.dart --record-pass` path or the underlying process
   hygiene issue so `.agent/notes/verification_status.json` reliably matches
   the current `HEAD`.
3. Add a fresh browser playback smoke pass for `apps/gdar_web` with the
   browser, runtime mode, and console/error status written down.
4. Keep the workspace-wide `format`/`analyze`/`test` lane green after the next
   maintainability refactor, not just before it.

## Bottom Line

GDAR still looks like a healthy monorepo with strong package boundaries and a
fresh green validation lane. The reasons it is not back above 9.0 are now
clearer and more ordinary: oversized shared UI surfaces, a stale verification
receipt, and missing fresh browser-runtime evidence, not architectural
slippage.
