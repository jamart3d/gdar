# Monorepo Scorecard

Date: 2026-04-07
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-05 scorecard against
`fb2cdf5`, with a clean pre-doc worktree and fresh full-workspace
`format`/`analyze`/`test` passes

## Overall Score

**8.9/10**

Up slightly from 8.8 on 2026-04-05.

This rerun keeps the same strong architecture and validation picture while
showing a healthier large-file profile in shared UI code:

- `dart run melos run format` passed
- `dart run melos run analyze` passed
- `dart run melos run test` passed
- `git -c core.excludesfile=.git/info/exclude status --short` was clean before
  this scorecard file was written
- the previous top maintainability hotspots from 2026-04-05 are no longer
  leading the table

The score does not move higher because two deductions remain unchanged:

- there is still no fresh browser-runtime playback pass in this rerun
- `.agent/notes/verification_status.json` is still stale relative to current
  `HEAD`

So GDAR reads as a strong monorepo with a slightly improved maintainability
backlog, but still not a fully evidence-complete 9.0+ state.

## Category Breakdown

### Architecture: 9.1/10

Flat.

The package graph still looks healthy in the live repo:

- `packages/styles/gdar_fruit/pubspec.yaml` depends on `gdar_design`
- `packages/styles/gdar_fruit/pubspec.yaml` does not depend on
  `shakedown_core`
- `packages/shakedown_core/pubspec.yaml` depends on `gdar_design`
- app targets remain isolated under `apps/`
- workspace packages and apps still use `resolution: workspace`

There is no fresh package-boundary regression in this rerun. The repo still
matches the intended layering well.

### Maintainability: 8.8/10

Up slightly.

Current large-file scan of `packages/shakedown_core/lib`:

- `tv_playback_screen_build.dart`: **907** lines
- `track_list_screen_build.dart`: **868** lines
- `track_list_view.dart`: **866** lines
- `steal_graph_render_corner.dart`: **838** lines
- `playback_screen_fruit_car_mode.dart`: **830** lines
- `settings_provider_initialization.dart`: **774** lines
- `interface_section.dart`: **757** lines
- `steal_config.dart`: **687** lines
- `screensaver_screen.dart`: **681** lines

This is still a real maintainability drag, but it is better-shaped than the
2026-04-05 rerun. The prior top tier led with
`appearance_section_controls.dart` at 926 lines and several other shared UI
surfaces in the 850-870 range. That hotspot mix has improved, even though the
remaining UI backlog is still substantial.

### Test Quality: 9.2/10

Strong.

This rerun again has full-workspace validation evidence:

- `dart run melos run format` returned clean
- `dart run melos run analyze` returned clean
- `dart run melos run test` returned green

That is scorecard-quality evidence from the repo root, not a narrow targeted
lane. The only deduction here is process automation drift: the machine-readable
verification receipt is still behind current `HEAD`, so the direct command
evidence is stronger than the recorded receipt trail.

### Platform Discipline: 9.0/10

Flat.

Platform intent still reads clearly:

- mobile, TV, and web remain separated under `apps/`
- shared logic and reusable UI remain in workspace packages
- style-layer dependency direction remains clean
- the test lane still covers shared and app package surfaces

This category remains strong. The deduction is about runtime evidence depth,
not repository structure.

### Web Audio / Runtime Reliability: 8.0/10

Flat.

Nothing in this rerun suggests a new web/audio regression, and the workspace
test lane passed. But this scorecard still does not include a fresh browser
runtime pass:

- no new Chrome or browser playback smoke pass was captured in this session
- confidence still comes more from analyzer and test signal than from fresh
  runtime verification
- `apps/gdar_web` remains healthy in the workspace structure, but runtime depth
  is still thinner than static validation depth

That keeps this category positive, but conservative.

## Evidence Used In This Rerun

- current `HEAD`: `fb2cdf5`
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
  which still points at `4c339241d5a890d707aca7e2fa4587da1a01a3d7` from
  `2026-04-06T23:06:21.112022`

## What Changed Since 2026-04-05

- a fresh full-workspace `format`/`analyze`/`test` rerun is green again
- the pre-doc workspace was clean at the repo root
- the large-file hotspot list is healthier than the April 5 rerun
- `tv_playback_screen_build.dart` is now the largest tracked shared hotspot at
  **907** lines
- there is still no fresh browser-runtime playback evidence in this rerun
- the verification receipt is newer than the stale receipt cited on April 5,
  but it still does not match current `HEAD`

## What Still Caps The Score

- several shared UI and presentation files still sit between roughly **750**
  and **910** lines
- the machine-readable verification receipt is still stale relative to `HEAD`
- web/audio confidence is still more test-backed than runtime-backed

## Path To 9.0+

1. Split `tv_playback_screen_build.dart` and continue through the next hotspot
   tier: `track_list_screen_build.dart`, `track_list_view.dart`,
   `steal_graph_render_corner.dart`, and
   `playback_screen_fruit_car_mode.dart`.
2. Fix the `preflight_check.dart --record-pass` workflow or the surrounding
   process hygiene so `.agent/notes/verification_status.json` reliably matches
   current `HEAD`.
3. Add a fresh browser playback smoke pass for `apps/gdar_web` with browser,
   runtime mode, and console/error status recorded explicitly.
4. Keep the workspace-wide `format`/`analyze`/`test` lane green after the next
   maintainability refactor, not just before it.

## Bottom Line

GDAR still looks like a healthy monorepo with strong package boundaries and a
fresh green validation lane. The April 7 rerun is slightly better than April 5
because the maintainability hotspot profile has improved, but the same two
gaps still keep it below 9.0: stale verification receipts and missing fresh
browser-runtime evidence.
