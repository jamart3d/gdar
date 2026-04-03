# Monorepo Scorecard

Date: 2026-04-02
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-01 scorecard against `4ac7394`,
with same-day evidence addendum captured against `518adaa`

## Overall Score

**8.9/10**

Slightly up from 8.7 on 2026-04-01.

The most important correction in this rerun is architectural: the live package
graph is healthier than the April 1 scorecard reported. `packages/styles/gdar_fruit`
now depends on `packages/gdar_design`, not `packages/shakedown_core`, so the
main style-layer dependency smell called out in the prior scorecard is no
longer present.

This rerun also used a cleaner workspace signal than the April 1 writeup:

- `git status --short` returned clean in the current workspace
- serial workspace tests were reported `PASS`
- the focused HUD regression rerun was also reported `PASS`

The remaining drag is still mostly structural rather than red-bar validation:
very large shared UI files remain, the fresh analyzer rerun surfaced one
warning, and browser-runtime evidence is still shallow even after a same-day
manual web verification.

## Category Breakdown

### Architecture: 9.1/10

Up from 8.7.

The biggest April 1 architectural concern has been resolved in the live repo:

- `packages/styles/gdar_fruit/pubspec.yaml` now depends on `gdar_design`
- it no longer depends on `shakedown_core`
- the workspace package graph now matches the intended lower-layer design
  direction much more closely

That is a meaningful monorepo health improvement, not a cosmetic one.

The documentation drift noted earlier in the day has now been corrected in
`docs/MONOREPO_ARCHITECTURE_PLAN.md`, so the remaining deduction here is minor
and mostly about long-term ownership pressure in shared UI, not package-graph
health.

### Maintainability: 8.7/10

Up slightly from 8.6.

Current large-file scan of `packages/shakedown_core/lib`:

- `steal_graph.dart`: **2,060** lines
- `tv_screensaver_section_build.dart`: **1,124** lines
- `steal_banner.dart`: **1,041** lines
- `appearance_section_controls.dart`: **899** lines
- `rating_control.dart`: **871** lines
- `track_list_screen_build.dart`: **868** lines
- `track_list_view.dart`: **865** lines
- `fruit_now_playing_card.dart`: **839** lines
- `dev_audio_hud_build.dart`: **823** lines

Most of the biggest shared UI surfaces are modestly smaller than they were in
the April 1 scorecard, which is real forward motion. The notable exception is
`tv_screensaver_section_build.dart`, which has grown again and is now the
second-largest file in the package.

This leaves the repo in a better place overall, but the large-file backlog is
still concentrated in shared UI and screensaver surfaces where safe iteration
is expensive.

### Test Quality: 8.7/10

Flat to slightly down from the April 1 confidence level.

Current evidence used here:

- serial workspace tests were reported `PASS`
- focused HUD regression rerun was reported `PASS`

That is enough to keep validation confidence strong, especially because the
April 1 HUD issue was already reclassified as a stale test-contract mismatch
rather than a product regression.

A fresh serial analyzer pass was added later on 2026-04-02, but it returned one
warning in `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart`.
That improves evidence depth without making the validation picture fully clean.

### Platform Discipline: 9.0/10

Essentially flat.

The monorepo still expresses platform intent clearly:

- app composition remains separated under `apps/`
- shared feature logic remains in reusable packages
- the style-layer dependency direction is now cleaner than it was in the prior
  scorecard

This stays strong. A same-day user-reported Fruit/web playback verification now
exists, but it was a single manual pass and the browser was not recorded, so it
is positive evidence rather than deep platform coverage.

### Web Audio / Runtime Reliability: 7.9/10

Flat.

Nothing in the current rerun points to a new web-audio regression, and there is
now a same-day user-reported standard Fruit/web playback verification. This is
still an evidence-depth category rather than a confirmed-strength category:

- the current runtime evidence is a single manual pass
- the browser/runtime environment was not recorded
- confidence is still stronger on test/build signal than on repeated browser
  runtime signal

So this stays positive but conservative.

## Evidence Used In This Rerun

- clean `git status --short` from the repo root
- live dependency check in `packages/styles/gdar_fruit/pubspec.yaml`
- current large-file scan of `packages/shakedown_core/lib`
- user-reported serial workspace test pass:
  `dart run melos exec -c 1 --dir-exists=test --ignore="screensaver_tv" -- flutter test`
- user-reported focused HUD regression pass:
  `dart run melos exec -c 1 --scope=shakedown_core -- flutter test test/ui/widgets/playback/dev_audio_hud_test.dart`
- fresh serial analyzer rerun:
  `dart run melos exec -c 1 --dir-exists=lib -- flutter analyze --no-pub`
  -> one warning in
  `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart:19`
- user-reported standard Fruit/web verification: "runs fine"
- user-reported web release build command:
  `flutter build web --release --no-pub -t lib/main.dart`

## What Changed Since 2026-04-01

- the `gdar_fruit -> shakedown_core` dependency issue named in the April 1
  scorecard is no longer present in the live package graph
- the current workspace appears clean instead of carrying active local changes
- most of the largest shared UI hotspots are slightly smaller than in the prior
  scorecard
- `tv_screensaver_section_build.dart` has grown again and remains a prominent
  maintainability hotspot
- a fresh serial analyzer rerun now exists and found one warning rather than a
  clean pass
- a fresh same-day manual Fruit/web verification now exists, but with limited
  environment detail

## What Still Caps The Score

- a persistent large-file backlog in shared UI and screensaver surfaces
- one fresh analyzer warning in
  `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart:19`
- browser-runtime evidence is still limited to a single user-reported manual
  pass with no browser recorded

## Path To 9.0+

1. Clear the fresh analyzer warning in
   `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart:19`.
2. Continue extracting the largest shared UI hotspots, especially
   `steal_graph.dart`, `tv_screensaver_section_build.dart`, and
   `steal_banner.dart`.
3. Repeat the Fruit/web runtime pass with the browser and environment recorded,
   and capture any console/runtime errors if present.
4. Keep the serial workspace test lane green alongside the analyzer lane so the
   evidence set stays current.

## Bottom Line

GDAR is in better shape than the April 1 scorecard suggested. The main package
layering concern remains fixed in the live repo, the architecture doc now
matches that state, and the evidence set is stronger than it was earlier in the
day. The remaining drag is now large shared UI files, one analyzer warning, and
still-thin browser-runtime evidence rather than a package-boundary problem.
