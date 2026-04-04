# Monorepo Scorecard

Date: 2026-04-03
Project: GDAR
Workspace: repo root `gdar`
Reference: Workspace-state rerun of the 2026-04-02 scorecard against `0f6fcb2`
with local uncommitted and untracked changes present, a fresh PASS receipt, and
fresh user-reported Chrome runtime verification

## Overall Score

**8.9/10**

Back up from the earlier April 3 draft score of 8.7, and effectively back in
line with the April 2 confidence level.

The key reason is that the two biggest maintainability deductions in the first
April 3 draft have now been directly addressed:

- `playback_screen_fruit_build.dart` was split into focused Fruit playback files
- `show_list_card_build.dart` was split by branch into smaller focused files
- `.agent/notes/verification_status.json` now matches the current `HEAD`
- a fresh Fruit/web Chrome runtime pass was reported green

This is still a workspace-state score, not a clean-release score. The repo now
contains active local modifications and new untracked files from the current
refactor pass, so the score reflects the present working tree rather than a
committed branch tip.

## Category Breakdown

### Architecture: 9.1/10

Flat.

The architectural picture remains strong:

- `packages/styles/gdar_fruit/pubspec.yaml` still depends on `gdar_design`
- it still does not depend on `shakedown_core`
- the monorepo boundary between `apps/` and shared packages remains clear

There is no fresh package-graph regression in the current rerun. The main
pressure remains implementation ownership in shared UI surfaces, not boundary
discipline.

### Maintainability: 8.7/10

Up materially from the earlier April 3 draft.

Current large-file scan of `packages/shakedown_core/lib`:

- `appearance_section_controls.dart`: **886** lines
- `rating_control.dart`: **872** lines
- `fruit_now_playing_card.dart`: **869** lines
- `track_list_screen_build.dart`: **868** lines
- `track_list_view.dart`: **866** lines
- `steal_graph_render_corner.dart`: **853** lines
- `dev_audio_hud_build.dart`: **825** lines
- `playback_screen_fruit_car_mode.dart`: **814** lines
- `tv_playback_screen_build.dart`: **798** lines

The two dominant hotspots from the earlier April 3 draft are no longer leading
the package:

- `playback_screen_fruit_build.dart` is now **463** lines
- `show_list_card_build.dart` is now **526** lines

That is a real maintainability improvement, not just a file rename. The new
Fruit playback and show-list branches are still sizable, but they are now split
by concern instead of compounding in two oversized central builders.

### Test Quality: 9.0/10

Up slightly.

Current evidence used here:

- user-reported green workspace preflight rerun
- `.agent/notes/verification_status.json` now records `PASS` against
  `0f6fcb2cbca8d00a1cc5ea19f8e8fbc14b2f53b2`
- targeted analyze on the split playback/show-list files returned clean
- targeted regression tests for playback, show-list cards, and Fruit tab-host
  transitions all passed locally

This is a stronger validation picture than either the April 2 scorecard or the
earlier April 3 draft had. The remaining deduction is simply that this is still
a workspace-state rerun with local changes rather than a fresh committed tip.

### Platform Discipline: 9.0/10

Flat.

Platform intent still reads clearly:

- app-specific targets remain under `apps/`
- shared features remain in reusable packages
- Fruit/web-specific behavior is covered by focused widget tests and a fresh
  manual runtime pass
- the style-layer dependency direction remains aligned with the intended design

This stays strong. The deduction is about evidence depth and local in-flight
changes, not platform confusion.

### Web Audio / Runtime Reliability: 8.2/10

Up from 7.9.

This category improves because the current rerun now has fresh browser-runtime
evidence instead of relying almost entirely on analyze/test signal:

- the user-reported Fruit/web Chrome runtime pass was green
- the requested runtime verification path was exercised from `apps/gdar_web`
- the reported web error log result was green as part of that same pass

This is still not deep enough to call the web/audio stack fully proven across
multiple browsers or long playback sessions, but it is materially stronger than
the evidence set in the earlier April 3 draft.

## Evidence Used In This Rerun

- current `HEAD`: `0f6fcb2`
- live dependency check in `packages/styles/gdar_fruit/pubspec.yaml`
- current large-file scan of `packages/shakedown_core/lib`
- current verification receipt in `.agent/notes/verification_status.json`
  matching `0f6fcb2cbca8d00a1cc5ea19f8e8fbc14b2f53b2`
- user-reported green preflight rerun:
  `dart scripts/preflight_check.dart --force`
- user-reported green Fruit/web Chrome runtime pass from `apps/gdar_web`
- user-reported green web error-log check after the runtime pass
- local targeted analyze of the split playback/show-list files
- local targeted regression pass:
  `packages/shakedown_core/test/screens/playback_screen_test.dart`
- local targeted regression pass:
  `packages/shakedown_core/test/widgets/show_list_card_test.dart`
- local targeted regression pass:
  `packages/shakedown_core/test/ui/screens/fruit_tab_host_race_test.dart`

## What Changed Since 2026-04-02

- the April 2 Fruit playback analyzer warning remains fixed
- the Fruit playback builder was decomposed into smaller files
- the show-list card builder was decomposed into smaller files
- the machine-readable verification receipt now matches the current `HEAD`
- a fresh Fruit/web Chrome runtime pass now exists
- the current large-file backlog is still real, but it is healthier than the
  first April 3 draft reported

## What Still Caps The Score

- several shared UI files still sit in the 800-900 line range
- the current rerun reflects a dirty workspace with active local changes
- Fruit/web runtime evidence is better, but still shallow compared with repeated
  browser playback verification

## Path To 9.0+

1. Keep the workspace green after the current refactor lands, not just during
   the in-flight workspace state.
2. Continue extracting the next shared UI hotspots, especially
   `appearance_section_controls.dart`, `rating_control.dart`, and
   `fruit_now_playing_card.dart`.
3. Repeat the Fruit/web runtime pass with longer playback and browser/runtime
   notes recorded, not just a green smoke result.
4. Convert the current workspace-state win into a committed clean-tip rerun so
   the score is backed by a stable branch state.

## Bottom Line

GDAR is back to looking like a strong monorepo rather than a structurally
slipping one. The earlier April 3 draft correctly identified a temporary
maintainability regression, but that regression has now been actively reduced by
splitting the two biggest hotspots, refreshing the verification receipt, and
adding a fresh Chrome runtime pass. The remaining drag is now ordinary shared UI
surface size and the fact that the current score still reflects an in-flight
workspace rather than a settled committed tip.
