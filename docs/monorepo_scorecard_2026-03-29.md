# Monorepo Scorecard

Date: 2026-03-29
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`
Reference: Rerun of the 2026-03-25 scorecard against the current workspace state (`af1b105` with local uncommitted changes present)

## Overall Score

**8.6/10**

Up from the stale 8.1 draft earlier in the day, and slightly above the 8.5 reported on 2026-03-25. The architecture work from the prior scorecard is still holding up well, the workspace-wide analyzer remains clean, and the monorepo test run is green again: `melos exec` -> `flutter test` -> `SUCCESS`.

This is still a **workspace-state** score, not a clean-release score. The repo currently contains active local changes, but the earlier test regressions called out in the first March 29 pass are no longer reproducing and the current test status is healthy again.

## Category Breakdown

### Architecture: 9.0/10

Flat from the prior run.

The large provider refactor remains a real strength:
- `SettingsProvider` is still split behind `part` files such as `settings_provider_core.dart`, `settings_provider_initialization.dart`, and `settings_provider_web.dart`.
- `AudioProvider` remains decomposed into `audio_provider_controls.dart`, `_diagnostics`, `_lifecycle`, `_playback`, and `_state`.
- The repo still reflects a healthy monorepo split across `apps/` and reusable packages.

Nothing in today's rerun suggests a structural backslide toward the old God-class pattern.

### Maintainability: 8.4/10

Slightly down from 8.5.

The modular architecture is still an improvement over earlier March snapshots, but several production UI files remain quite large:
- `steal_graph.dart`: 1,930 lines
- `tv_screensaver_section_build.dart`: 1,296 lines
- `steal_banner.dart`: 1,041 lines
- `playback_screen_build.dart`: 878 lines
- `rating_control.dart`: 871 lines
- `track_list_screen_build.dart`: 868 lines
- `appearance_section_controls.dart`: 867 lines
- `track_list_view.dart`: 860 lines
- `fruit_now_playing_card.dart`: 841 lines

This is better than the old all-in-one screen/provider layout, but it still leaves several UI hotspots expensive to reason about and easy to regress.

### Test Quality: 8.6/10

Up from the stale earlier draft and slightly above the prior 8.5.

Current test health is strong again:
- `dart run melos run analyze`: clean across all 7 analyzed packages.
- `dart run melos run test`: green again (`melos exec` -> `flutter test` -> `SUCCESS`).
- The 8 isolated `shakedown_core` failures identified earlier on 2026-03-29 were rerun individually and all passed.

That combination suggests the earlier red run was either transient, workspace-race-related, or already resolved by in-flight local changes. With the suite green again, confidence in the Fruit contracts and PlaybackPanel coverage is materially restored.

### Platform Discipline: 9.0/10

Recovered from the stale earlier draft.

The broad platform architecture is still disciplined:
- TV typography still applies a dedicated `isTv ? 1.2 : 1.0` multiplier.
- Haptics still route through `AppHaptics`, which centralizes TV gating.
- Fruit/web code paths still exist as explicit theme/platform branches throughout the shared UI.

The earlier Fruit contract failures from the first March 29 pass no longer reproduce. With those tests green again, the platform model and its enforcement layer are back in good shape, though still worth monitoring while local UI changes are active.

### Web Audio / Runtime Reliability: 7.5/10

Flat from the prior run.

This rerun did not uncover fresh analyzer issues in the web/audio stack, and the `apps/gdar_web` tests that ran under the monorepo script were green. That said, this pass was not a dedicated browser-runtime audit, so there is not enough new evidence to move this category upward.

## What Improved Since 2026-03-25

- Workspace-wide analysis is still clean, which protects the gains from the provider refactor.
- The provider decomposition from the prior scorecard is intact and still paying off structurally.
- The monorepo test run is green again.
- The earlier March 29 isolated failures in Fruit contracts and PlaybackPanel coverage no longer reproduce.
- The app-level suites for mobile, TV, and web remain green within the monorepo flow.

## What Regressed Since 2026-03-25

- Several production UI files are still quite large, especially in screensaver, playback, and settings surfaces.
- The workspace still reports **39 packages with newer incompatible versions**, which adds some maintenance drag even though it is not an immediate quality failure.

## What Still Caps The Score

- Several production UI files are still in the 800-1,900 line range, especially in the screensaver, playback, and settings surfaces.
- Test output also surfaced **39 packages with newer incompatible versions**, which is not an emergency but does add maintenance drag.

## Path To 9.0+

1. Keep `dart run melos run test` green while the current UI changes land.
2. Continue extracting the largest shared UI files, especially screensaver and playback/settings builders.
3. Trim the maintenance backlog from the outdated dependency set where safe.
4. Follow up with a dedicated Fruit/web runtime pass so the next scorecard can raise confidence beyond static and widget-test signals.

## Bottom Line

GDAR is still structurally much healthier than it was before the March provider refactors, and the analyzer confirms the codebase is not sliding into broad technical debt. With the monorepo tests green again, the repo is back in a healthy state; the main opportunities now are maintainability cleanup and keeping the current workspace changes from reintroducing UI regressions.
