# Monorepo Todo List

Date: 2026-04-02
Project: GDAR
Derived from: `docs/monorepo_scorecard_2026-04-02.md`

## Goal

Turn the 2026-04-02 scorecard into a short, actionable backlog that targets
the remaining caps on the monorepo score.

## Priority 0: Refresh Evidence

- [x] Run a fresh serial workspace analyzer pass.
  Command:
  `dart run melos exec -c 1 --dir-exists=lib -- flutter analyze --no-pub`
  Done when:
  the pass is green or the failures are captured as follow-up tasks.
  Result:
  captured one warning in
  `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart:19`.

- [x] Run a fresh Fruit/web browser playback smoke pass.
  Cover:
  app startup, catalog load, play, pause, seek, next/previous, and track
  advance.
  Done when:
  the browser/runtime result is written down with date, platform, and outcome.
  Result:
  user-reported "runs fine" on 2026-04-02; release build command used:
  `flutter build web --release --no-pub -t lib/main.dart`.
  Browser was not recorded.

- [x] Add the new analyzer and browser results to the scorecard evidence trail.
  Done when:
  the scorecard or a linked follow-up note records the exact commands and
  outcomes used.

- [x] Fix the analyzer warning in
  `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart:19`.
  Issue:
  `invalid_use_of_protected_member` on `setState`.
  Result:
  fixed by routing the measurement update through
  `PlaybackScreenState._updateFruitFloatingNowPlayingHeight()`, then verified
  with `flutter analyze --no-pub packages/shakedown_core`.

## Priority 1: Fix Documentation Drift

- [x] Update `docs/MONOREPO_ARCHITECTURE_PLAN.md` so it matches the live package
  graph.
  Fix:
  remove the stale `gdar_fruit -> shakedown_core` "Current Problem" wording and
  replace it with current risks.

- [ ] Re-verify the package graph narrative against current `pubspec.yaml`
  files.
  Check:
  `packages/gdar_design`, `packages/shakedown_core`,
  `packages/styles/gdar_fruit`, `packages/styles/gdar_android`, and
  `packages/screensaver_tv`.
  Current status:
  style/core packages were checked, but
  `packages/screensaver_tv/pubspec.yaml` is currently a stub and still needs
  follow-up verification.

- [x] Add a "last verified against commit" note to the architecture doc.
  Done when:
  future scorecards can tell whether the doc reflects the current repo state.

## Priority 1: Reduce Large-File Risk

- [x] Break up
  `packages/shakedown_core/lib/steal_screensaver/steal_graph.dart`
  (2,237 lines).
  Target:
  extract rendering helpers, constants, and mode-specific draw logic into
  smaller units.
  Next pass:
  treat this as a deliberate multi-step split, not a one-shot rewrite.
  Suggested order:
  1. extract shared geometry/constants helpers,
  2. split mode-specific render paths (`vu`, `ekg`, `scope`, `corner`, etc.),
  3. keep `StealGraph` state/update flow in the main file until the render
     surface is stable.
  Result:
  split into dedicated constants, shared helpers, corner/VU/scope render,
  beat-debug render, and EKG/circular render part files; the main
  `steal_graph.dart` file is now 175 lines.

- [x] Break up
  `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_build.dart`
  (1,133 lines).
  Target:
  split by settings subsection so TV screensaver changes stay local.
  Result:
  split into dedicated system, visual, track-info, and audio/frequency part
  files; the original `tv_screensaver_section_build.dart` is now 58 lines.

- [x] Break up
  `packages/shakedown_core/lib/steal_screensaver/steal_banner.dart`
  (1,174 lines).
  Target:
  separate layout/composition from animation or paint-heavy logic.
  Result:
  split into dedicated flat-render and ring-render part files; the main
  `steal_banner.dart` file is now 444 lines.

- [ ] Triage the next maintainability tier and create file-specific extraction
  tasks.
  Files:
  `packages/shakedown_core/lib/ui/widgets/settings/appearance_section_controls.dart`
  (910),
  `packages/shakedown_core/lib/ui/widgets/rating_control.dart` (905),
  `packages/shakedown_core/lib/ui/screens/track_list_screen_build.dart` (934),
  `packages/shakedown_core/lib/ui/widgets/playback/track_list_view.dart` (913),
  `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`
  (903),
  `packages/shakedown_core/lib/ui/widgets/playback/dev_audio_hud_build.dart`
  (856).

## Suggested Order

1. Refresh analyzer and web-runtime evidence first.
2. Fix the architecture doc drift next.
3. Split the three largest UI/screensaver hotspots.
4. Re-score the repo after the evidence and refactors land.
