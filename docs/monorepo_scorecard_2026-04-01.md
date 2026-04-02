# Monorepo Scorecard

Date: 2026-04-01
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-03-30 scorecard against `cc50f33`
with local uncommitted and untracked changes present

## Overall Score

**8.7/10**

Slightly down from 8.8 on 2026-03-30, but materially healthier than the
earlier April 1 draft score suggested.

This rerun used **Chromebook-safe serial workspace commands** instead of the
default `-c 2` Melos workspace concurrency. That produced a cleaner signal for
this environment and changed the diagnosis in an important way:

- the earlier failing HUD case was not a product regression
- it was a stale test expectation after the `HPD` sparkline/chip removal
- the serial workspace rerun is now green again

This remains a **workspace-state** score, not a clean-release score. The repo
currently has active local modifications and untracked files, so the score
reflects the present working tree rather than a pristine branch tip.

## Category Breakdown

### Architecture: 8.7/10

Slightly down from 9.0.

The repo still has strong high-level structure:

- `SettingsProvider` remains split across focused files
- `AudioProvider` remains decomposed by concern instead of collapsing back into
  one class
- the `apps/` and reusable package split still works productively

The main architectural drag is clearer now than it was in the March 30 score:

- `packages/styles/gdar_fruit` still depends on `packages/shakedown_core`
- that is backwards for a style package and blocks clean extraction of reusable
  Fruit presentation primitives into the style layer without creating a cycle

That does not make the monorepo unhealthy, but it is a real boundary smell and
it should count against the architecture score.

### Maintainability: 8.6/10

Slightly down from 8.8.

The codebase still has meaningful decomposition wins from the prior scorecard,
but the biggest shared-file hotspots are still expensive:

- `steal_graph.dart`: **2,097** lines
- `steal_banner.dart`: **1,174** lines
- `tv_screensaver_section_build.dart`: **1,065** lines
- `track_list_screen_build.dart`: **934** lines
- `track_list_view.dart`: **907** lines
- `rating_control.dart`: **903** lines
- `appearance_section_controls.dart`: **892** lines
- `fruit_now_playing_card.dart`: **874** lines
- `dev_audio_hud_build.dart`: **855** lines

Two signals matter here:

- the large-file backlog is still concentrated in shared UI surfaces
- `tv_screensaver_section_build.dart` has grown slightly again since the March
  30 rerun

The repo is still maintainable, but the remaining hotspots are large enough to
slow safe iteration.

### Test Quality: 8.8/10

Slightly up from 8.7.

Current evidence:

- serial workspace analyze succeeded:
  `dart run melos exec -c 1 -- dart analyze .`
- serial workspace tests succeeded:
  `dart run melos exec -c 1 --dir-exists=test --ignore="screensaver_tv" -- flutter test`
- focused HUD regression verification succeeded:
  `dart run melos exec -c 1 --scope=shakedown_core -- flutter test test/ui/widgets/playback/dev_audio_hud_test.dart`
- focused TV dual-pane analysis succeeded:
  `dart run melos exec -c 1 --scope=shakedown_core -- dart analyze lib/ui/widgets/tv/tv_dual_pane_layout.dart`

Important nuance:

- the earlier `-c 2` workspace test run on Chromebook did introduce noise
- but the more important correction was semantic, not just operational:
  the HUD failure came from an outdated test expectation for `HPD`, which had
  been intentionally removed

With the test contract corrected and the async analyzer warning fixed, the
workspace returns to a strong validation posture.

### Platform Discipline: 9.0/10

Almost flat from 9.1.

Platform boundaries still look disciplined:

- web-specific audio tests are isolated in `apps/gdar_web`
- TV startup and inactivity behavior still has direct regression coverage
- Fruit-specific UI contract tests are present

This category stays strong because the repo still expresses platform intent
clearly in code and tests. It loses a small amount of ground because this rerun
did not include a fresh browser runtime smoke pass.

### Web Audio / Runtime Reliability: 7.9/10

Essentially flat from 8.0.

This category is still held back by evidence depth, not by a confirmed new
runtime break:

- web audio tests in `apps/gdar_web` passed in the serial workspace run
- the corrected HUD failure was a stale expectation, not a web-audio engine
  failure

But:

- there was no fresh browser runtime smoke pass in this rerun
- the current evidence is still test-first, not browser-runtime-first

So the category remains positive but conservative.

## Evidence Used In This Rerun

- `dart run melos exec -c 1 -- dart analyze .`
- `dart run melos exec -c 1 --dir-exists=test --ignore="screensaver_tv" -- flutter test`
- `dart run melos exec -c 1 --scope=shakedown_core -- flutter test test/ui/widgets/playback/dev_audio_hud_test.dart`
- `dart run melos exec -c 1 --scope=shakedown_core -- dart analyze lib/ui/widgets/tv/tv_dual_pane_layout.dart`
- current large-file scan of `packages/shakedown_core/lib`

## What Changed Since 2026-03-30

- the score is now based on **serial** workspace commands, which are more
  trustworthy on this Chromebook/Crostini environment than `-c 2`
- workspace analyze is green again and warning-free in the current rerun
- workspace tests are green again in the current rerun
- the April 1 HUD issue was corrected as a test-contract mismatch rather than a
  product regression
- the incompatible dependency backlog still appears to be about **30 packages**
  from current `flutter pub get` output during test/analyze runs
- the largest shared UI hotspots remain concentrated in the same areas, with
  `tv_screensaver_section_build.dart` slightly larger than in the March 30
  scorecard

## What Still Caps The Score

- a persistent large-file backlog in shared UI and screensaver surfaces
- the `gdar_fruit -> shakedown_core` dependency direction still weakens package
  layering
- the incompatible dependency backlog remains significant
- no fresh browser runtime pass was included in this rerun

## Path To 8.9+

1. Keep Chromebook validation runs serial by default for scorecard-quality
   reruns.
2. Continue extracting the next shared UI hotspots, especially
   `steal_graph.dart`, `steal_banner.dart`, and `track_list_screen_build.dart`.
3. Start the design-layer refactor path that removes the
   `gdar_fruit -> shakedown_core` style-package dependency.
4. Add a fresh browser runtime pass for the Fruit/web playback path so web
   reliability is backed by more than package tests.

## Bottom Line

GDAR remains a strong monorepo. The most useful outcome of the April 1 rerun
was not a lower score, but a more accurate one: serial validation is the right
mode for this Chromebook environment, the workspace is green again, and the
earlier HUD failure was a stale contract mismatch rather than a live product
break. The remaining drag is mostly structural: large shared UI files, the
style-package dependency direction, and the still-significant outdated-package
backlog.
