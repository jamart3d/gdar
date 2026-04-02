# Monorepo Scorecard

Date: 2026-04-02
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-01 scorecard against `4ac7394`

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
very large shared UI files remain, browser-runtime evidence is still thin, and
some architecture docs have not fully caught up to the current package graph.

## Category Breakdown

### Architecture: 9.1/10

Up from 8.7.

The biggest April 1 architectural concern has been resolved in the live repo:

- `packages/styles/gdar_fruit/pubspec.yaml` now depends on `gdar_design`
- it no longer depends on `shakedown_core`
- the workspace package graph now matches the intended lower-layer design
  direction much more closely

That is a meaningful monorepo health improvement, not a cosmetic one.

The small deduction here is now about documentation drift, not package
structure:

- `docs/MONOREPO_ARCHITECTURE_PLAN.md` says the migration is complete
- but its `Current Problem` section still repeats the old
  `gdar_fruit -> shakedown_core` issue

So the architecture is stronger than the documentation snapshot.

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

This category does not move higher because this rerun did not include a fresh
workspace analyzer pass in the final evidence set.

### Platform Discipline: 9.0/10

Essentially flat.

The monorepo still expresses platform intent clearly:

- app composition remains separated under `apps/`
- shared feature logic remains in reusable packages
- the style-layer dependency direction is now cleaner than it was in the prior
  scorecard

This stays strong, but there was no fresh browser or device smoke pass in this
rerun to justify a higher score.

### Web Audio / Runtime Reliability: 7.9/10

Flat.

Nothing in the current rerun points to a new web-audio regression, but this is
still an evidence-depth category rather than a confirmed-strength category:

- no fresh browser runtime playback pass was included
- the current confidence remains test-first rather than browser-runtime-first

So this stays positive but conservative.

## Evidence Used In This Rerun

- clean `git status --short` from the repo root
- live dependency check in `packages/styles/gdar_fruit/pubspec.yaml`
- current large-file scan of `packages/shakedown_core/lib`
- user-reported serial workspace test pass:
  `dart run melos exec -c 1 --dir-exists=test --ignore="screensaver_tv" -- flutter test`
- user-reported focused HUD regression pass:
  `dart run melos exec -c 1 --scope=shakedown_core -- flutter test test/ui/widgets/playback/dev_audio_hud_test.dart`

## What Changed Since 2026-04-01

- the `gdar_fruit -> shakedown_core` dependency issue named in the April 1
  scorecard is no longer present in the live package graph
- the current workspace appears clean instead of carrying active local changes
- most of the largest shared UI hotspots are slightly smaller than in the prior
  scorecard
- `tv_screensaver_section_build.dart` has grown again and remains a prominent
  maintainability hotspot
- the rerun evidence set includes fresh serial test passes, but not a fresh
  analyzer pass or browser smoke pass

## What Still Caps The Score

- a persistent large-file backlog in shared UI and screensaver surfaces
- stale architecture documentation that still describes an already-resolved
  dependency smell
- no fresh workspace analyzer pass in this rerun
- no fresh browser runtime playback pass in this rerun

## Path To 9.0+

1. Keep the serial workspace test lane green and add a matching fresh serial
   analyzer rerun to strengthen scorecard-quality evidence.
2. Continue extracting the largest shared UI hotspots, especially
   `steal_graph.dart`, `tv_screensaver_section_build.dart`, and
   `steal_banner.dart`.
3. Update `docs/MONOREPO_ARCHITECTURE_PLAN.md` so the architecture narrative
   matches the live package graph.
4. Add a fresh browser runtime pass for Fruit/web playback so the web
   reliability score is backed by runtime evidence, not just tests.

## Bottom Line

GDAR is in better shape than the April 1 scorecard suggested. The main package
layering concern has been fixed in the live repo, the workspace appears clean,
and the serial test evidence is still green. The remaining drag is now more
about large shared UI files and evidence depth than about a serious monorepo
boundary problem.
