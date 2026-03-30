# Monorepo Scorecard

Date: 2026-03-30
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`
Reference: Workspace-state rerun of the 2026-03-29 scorecard against `89c982a` with local uncommitted and untracked changes present

## Overall Score

**8.8/10**

Up from 8.6 on 2026-03-29. The codebase remains structurally strong, the workspace analyzer and monorepo tests are still green, and two of the largest shared UI hotspots were materially improved today: the TV screensaver settings builder was reduced again, and the old monolithic `playback_screen_build.dart` has now been split into a small coordinator plus focused Fruit and layout parts.

This is still a **workspace-state** score, not a clean-release score. The repo currently has active local modifications and a few unrelated untracked directories/files, so this score reflects the present working tree rather than a pristine branch tip.

## Category Breakdown

### Architecture: 9.0/10

Flat from the prior run.

The core structure remains healthy:
- `SettingsProvider` stays split behind part files such as `settings_provider_core.dart`, `settings_provider_initialization.dart`, and `settings_provider_web.dart`.
- `AudioProvider` remains decomposed into focused files for controls, diagnostics, lifecycle, playback, and state concerns.
- The monorepo boundary between `apps/` and reusable packages is still clear and productive.

Nothing in the current rerun suggests the repo is slipping back toward the earlier God-class pattern.

### Maintainability: 8.8/10

Up from 8.4.

This is the biggest change in the March 30 rerun. Two previously bulky shared UI surfaces were improved:
- `tv_screensaver_section_build.dart` is now **1,050 lines**, down from **1,296** on 2026-03-29 after the audio/performance slice was extracted.
- `playback_screen_build.dart` is no longer an 878-line monolith. It is now a **162-line coordinator**, with focused logic moved into:
  - `playback_screen_fruit_build.dart` at **472 lines**
  - `playback_screen_layout_build.dart` at **399 lines**

The repo still has several expensive hotspots:
- `steal_graph.dart`: 1,930 lines
- `steal_banner.dart`: 1,041 lines
- `rating_control.dart`: 871 lines
- `track_list_screen_build.dart`: 868 lines
- `appearance_section_controls.dart`: 867 lines
- `track_list_view.dart`: 860 lines
- `fruit_now_playing_card.dart`: 841 lines

But this rerun now shows clear forward motion on the “extract the largest shared UI files” goal instead of just identifying the problem.

### Test Quality: 8.7/10

Slightly up from 8.6.

The current evidence is healthy:
- `dart run melos run analyze`: green in the current workspace (`melos exec` -> `dart analyze .` -> `SUCCESS`)
- `dart run melos run test`: green in the current workspace (`melos exec` -> `flutter test` -> `SUCCESS`)
- Focused playback-screen analysis after the refactor also passed: `dart analyze packages/shakedown_core/lib/ui/screens/playback_screen.dart` -> `No issues found!`

That combination is enough to keep confidence high while the current UI extraction work is still in flight.

### Platform Discipline: 9.1/10

Slightly up from 9.0.

Platform branching still looks disciplined, and this rerun has better runtime evidence than the March 29 pass:
- Fruit/web was smoke-tested from the correct app path (`apps/gdar_web`) instead of from the repo root.
- The web UI was reported as looking correct in that launch context.
- Fruit-specific playback structure remains separated from the standard scaffold after the playback extraction instead of being interleaved through one giant builder.

That is not the same as exhaustive platform testing, but it is a stronger signal than the earlier widget-test-only confidence.

### Web Audio / Runtime Reliability: 8.0/10

Up from 7.5.

The March 29 rerun held this category flat because there was no dedicated browser-runtime evidence. This time, there was a direct Chrome launch from `apps/gdar_web`, and the web UI came up clean in the correct context.

Important nuance:
- the earlier March 30 web errors were launch-context-related when run from the wrong directory
- the corrected run from `apps/gdar_web` did not reproduce those startup errors

This is enough to move the category upward modestly, but not enough to call the web/audio stack fully proven end to end.

## What Improved Since 2026-03-29

- `tv_screensaver_section_build.dart` dropped from 1,296 lines to 1,050 after the audio/performance extraction.
- `playback_screen_build.dart` was decomposed from a single 878-line builder into a 162-line coordinator with dedicated Fruit and layout part files.
- The safe dependency batch was updated in `pubspec.yaml`:
  - `logger` -> `2.7.0`
  - `shared_preferences` -> `2.5.5`
  - `build_runner` -> `2.13.1`
  - `melos` -> `7.5.0`
  - `mockito` -> `5.6.4`
- The outdated dependency backlog improved from **39** incompatible packages to **34**.
- A dedicated Fruit/web runtime pass was completed from the correct app directory, and the web UI was reported healthy there.

## What Still Caps The Score

- Several shared UI files are still in the 840-1,930 line range, especially in screensaver, playback-adjacent widgets, and settings surfaces.
- The dependency backlog is improved, but **34 packages with newer incompatible versions** still remain.
- The web runtime pass was a smoke run, not a deeper browser/audio verification pass.

## Path To 9.0+

1. Keep `dart run melos run analyze` and `dart run melos run test` green while the current UI extractions remain uncommitted.
2. Continue extracting the next shared UI hotspots, especially `steal_graph.dart`, `steal_banner.dart`, and `track_list_screen_build.dart`.
3. Do a second dependency pass only for carefully selected higher-risk upgrades rather than sweeping all remaining majors at once.
4. Add one more dedicated web runtime check that exercises playback/audio behavior, not just shell/UI boot.

## Bottom Line

GDAR is incrementally healthier than it was on 2026-03-29, not just theoretically but in concrete shared UI surfaces. The repo still carries some large-file drag and an outdated-dependency backlog, but the March 30 rerun shows real maintainability progress, green workspace validation, and better Fruit/web runtime confidence than the prior scorecard.
