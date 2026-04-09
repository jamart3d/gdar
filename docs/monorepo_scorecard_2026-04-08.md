# Monorepo Scorecard

Date: 2026-04-08
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-07 scorecard against
`2a9d998`, with a clean pre-doc worktree and fresh full-workspace
`format`/`analyze`/`test` passes

## Overall Score

**8.7/10**

Down from 8.9 on 2026-04-07.

This rerun keeps strong architecture and validation signals, but the current
shared UI hotspot profile is heavier than the previous run:

- `dart run melos run format` passed
- `dart run melos run analyze` passed
- `dart run melos run test` passed
- `git -c core.excludesfile=.git/info/exclude status --short` was clean before
  this scorecard file was written
- the top maintainability hotspots are now larger than in the 2026-04-07
  scorecard

Two recurring deductions remain:

- there is still no fresh browser-runtime playback pass in this rerun
- `.agent/notes/verification_status.json` is still stale relative to current
  `HEAD`

## Category Breakdown

### Architecture: 9.1/10

Flat.

The package graph remains healthy:

- `packages/styles/gdar_fruit/pubspec.yaml` depends on `gdar_design`
- `packages/styles/gdar_fruit/pubspec.yaml` does not depend on
  `shakedown_core`
- `packages/shakedown_core/pubspec.yaml` depends on `gdar_design`
- app targets remain isolated under `apps/`
- workspace packages and apps still use `resolution: workspace`

No package-boundary regression was found in this rerun.

### Maintainability: 8.4/10

Down.

Current large-file scan of `packages/shakedown_core/lib`:

- `playback_screen_fruit_car_mode.dart`: **993** lines
- `steal_graph_render_corner.dart`: **972** lines
- `track_list_screen_build.dart`: **922** lines
- `settings_provider_initialization.dart`: **841** lines
- `show_list_card_fruit_car_mode.dart`: **811** lines
- `interface_section.dart`: **769** lines
- `screensaver_screen.dart`: **751** lines
- `steal_config.dart`: **722** lines
- `utils.dart`: **689** lines
- `steal_background.dart`: **676** lines

This is a heavier hotspot profile than April 7, with multiple files now in the
900+ range. The backlog is still tractable, but pressure is increasing in
shared UI surfaces.

### Test Quality: 9.2/10

Strong.

This rerun again has full-workspace validation evidence:

- `dart run melos run format` returned clean
- `dart run melos run analyze` returned clean
- `dart run melos run test` returned green

As in prior runs, the deduction is process receipt drift: direct command
evidence is current, but the machine-readable receipt does not match `HEAD`.

### Platform Discipline: 9.0/10

Flat.

Platform structure is still clear and consistent:

- mobile, TV, and web remain separated under `apps/`
- shared logic and reusable UI remain in workspace packages
- style-layer dependency direction remains clean
- the test lane still covers shared and app package surfaces

No structural platform-discipline regressions were observed.

### Web Audio / Runtime Reliability: 7.9/10

Slightly down.

No new web/audio regression signal appears in this rerun, and the workspace
test lane passed. But runtime evidence is still thin for this scorecard cycle:

- no fresh Chrome or browser playback smoke pass was captured in this session
- confidence still comes more from analyzer/test signal than from fresh runtime
  verification
- `apps/gdar_web` remains healthy structurally, but runtime depth is still not
  refreshed

## Evidence Used In This Rerun

- current `HEAD`: `2a9d998`
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
- live dependency checks in:
  `apps/gdar_mobile/pubspec.yaml`
- live dependency checks in:
  `apps/gdar_tv/pubspec.yaml`
- live dependency checks in:
  `apps/gdar_web/pubspec.yaml`
- current large-file scan of `packages/shakedown_core/lib`
- current verification receipt in `.agent/notes/verification_status.json`,
  which points at `d9c1d864f6f4eff49e53c4e6d0aaf6cf1478b9ba` from
  `2026-04-08T07:33:03.911601`
- attempted preflight gate:
  `dart scripts/preflight_check.dart --preflight-only` (timed out in this
  environment)

## What Changed Since 2026-04-07

- a fresh full-workspace `format`/`analyze`/`test` rerun is green again
- the pre-doc workspace was clean at the repo root
- the large-file hotspot profile regressed, with the top three files now at
  **993**, **972**, and **922** lines
- there is still no fresh browser-runtime playback evidence in this rerun
- the verification receipt is newer than April 7 but still does not match
  current `HEAD`

## What Still Caps The Score

- several shared UI and presentation files still sit between roughly **750**
  and **1000** lines
- the machine-readable verification receipt is still stale relative to `HEAD`
- web/audio confidence is still more test-backed than runtime-backed

## Path To 9.0+

1. Split the current largest hotspot tier:
   `playback_screen_fruit_car_mode.dart`, `steal_graph_render_corner.dart`,
   `track_list_screen_build.dart`, and
   `settings_provider_initialization.dart`.
2. Ensure the verification receipt workflow updates
   `.agent/notes/verification_status.json` to current `HEAD` on each successful
   verification cycle.
3. Add a fresh browser playback smoke pass for `apps/gdar_web` with browser,
   runtime mode, and console/error status recorded explicitly.
4. Keep the workspace-wide `format`/`analyze`/`test` lane green after the next
   maintainability refactor.

## Bottom Line

GDAR still shows strong monorepo fundamentals and a fresh green validation
lane, but the April 8 rerun scores lower than April 7 because shared UI
hotspots grew and runtime evidence was not refreshed. The project is still
close to 9.0, but it needs one maintainability pass plus fresh runtime and
receipt hygiene evidence to cross that threshold.
