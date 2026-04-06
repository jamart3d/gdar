# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Fixed
- Jules merge (`b87e230`, `a1f70b4`) broke Linux checkup: `preflight_check.dart` treated Linux as Chromebook, `checkup.md` removed `LINUX:VERIFIED` from proceed condition, `audit_assets.sh` scanned a non-existent `assets/` dir. All three restored.

### Changed (feat/autocorr-beat-improvements — implemented this session)
- Merged locally to `main` in `2791a6b`, then completed the parked follow-up
  work as `f91f5a5`.
- Autocorrelation beat detection refactored (VisualizerPlugin.kt):
  - Removed coarse 20Hz fallback RMS path (±30 BPM resolution — too coarse to be useful)
  - Fixed unconditional BPM override: autocorr now only overrides `trackedBeatBpm` when `beatGridConfidence < 0.4`
  - Capped O(n²) correlation loop at 256 samples with documented cost bound
  - Implemented second-pass refinement with two modes: parabolic interpolation (Mode A, cheap) and 4× upsample narrow-window re-search (Mode B, HQ)
  - Sabrina (Chromecast with Google TV) hardware gate: Mode B always disabled on Sabrina regardless of Flutter setting
  - Extracted `useAutocorr` as a single local variable (was duplicated for `beatBpm` and `beatIbiMs` — divergence risk)
  - `corrValues` now allocated only for Mode A; Mode B and no-second-pass skip the allocation
  - Mode B inner loop `-1` bound documented (ensures `lo+1` stays in bounds)
  - Removed `!!` on `autocorrIbiMs`; replaced with local `ibi` variable
- New SettingsProvider prefs: `beat_autocorr_second_pass` (TV default: on), `beat_autocorr_second_pass_hq` (default: off everywhere)
- New TV Settings → Appearance toggles: "Beat Precision Refinement" and "High-Quality Refinement" (HQ shown only when refinement is enabled)
- `updateConfig` pipeline extended end-to-end: `AudioReactor` interface → `VisualizerAudioReactor` → `screensaver_screen` → `tv_screensaver_preview_panel`
- `FakeSettingsProvider` and `FakeAudioReactor` test stubs updated for new interface
- While restoring pre-existing dirty `main` work, the `VisualizerPlugin.kt`
  overlap was resolved by keeping both:
  - the new second-pass autocorrelation / confidence-gating logic
  - the snapshot-based stereo RMS read via `StereoCapture.getRmsSnapshot()`

### Changed (stereo-capture-rms-hardening — implemented this session)
- TV stereo RMS hardening implemented from [`docs/superpowers/plans/2026-04-05-stereo-capture-rms-hardening.md`](docs/superpowers/plans/2026-04-05-stereo-capture-rms-hardening.md):
  - `StereoCapture.kt`: moved RMS history size to companion object as `RMS_HISTORY_SIZE`
  - `StereoCapture.kt`: privatized RMS history state, added dedicated RMS lock, and added `getRmsSnapshot()` returning oldest→newest snapshot copies
  - `StereoCapture.kt`: reset path now clears RMS ring-buffer state under the same lock used for reader/writer synchronization
  - `StereoCapture.kt`: removed fixed `SAMPLE_RATE`/`RMS_BLOCK_SIZE`; `start()` now accepts a preferred sample rate, then derives effective `capturedSampleRate` from `AudioRecord.sampleRate` and recomputes `rmsBlockSize`
  - `MainActivity.kt`: queries `AudioManager.PROPERTY_OUTPUT_SAMPLE_RATE` and passes it into `stereoCapture.start(...)`
  - `VisualizerPlugin.kt`: replaced direct reads of `fullRmsHistory`/`rmsHistoryIndex`/`rmsHistoryCount` with `getRmsSnapshot()`
- Added Android JVM regression test setup for TV native code:
  - `apps/gdar_tv/android/app/build.gradle.kts`: added `testImplementation("junit:junit:4.13.2")`
  - `StereoCaptureTest.kt`: covers empty-history snapshot and wrapped ring-buffer ordering
- Plan doc updated during implementation to tighten Step 7 and document the effective-sample-rate approach

### Changed (fruit-car-mode-stat-font-size — implemented this session)
- Fruit car mode stat-chip typography increased without changing chip height or row layout:
  - `playback_screen_fruit_widgets.dart`: reduced the internal label→value gap from `10 * scaleFactor` to `8 * scaleFactor`
  - `playback_screen_fruit_widgets.dart`: increased stat value text from `17 * scaleFactor` to `18 * scaleFactor`
  - This was the largest clean bump that fit the existing `74`-pixel chip without overflow; larger candidates (`20` and `24`) overflowed during TDD
- Added widget regression coverage:
  - `playback_screen_test.dart`: new test `PlaybackScreen Fruit car mode increases stat value typography without overflow`
  - Test asserts representative long value `1200ms` still renders and that the stat value font size is `18.0`
- Merged locally to `main` in commit `65e26b5`

### Changed (feat/fruit-car-mode-stat-font-size-v2 — pending merge)
- Web Fruit car mode stat chips were reworked to improve legibility when Liquid Glass is enabled:
  - `playback_screen_fruit_widgets.dart`: value text is now `24 * scaleFactor`
  - `playback_screen_fruit_widgets.dart`: internal vertical padding reduced to `6 * scaleFactor`
  - `playback_screen_fruit_widgets.dart`: label→value gap reduced to `2 * scaleFactor`
  - `playback_screen_fruit_widgets.dart`: added a value-only lens treatment (`fruit_car_mode_stat_value_lens`) behind the number when `fruitEnableLiquidGlass` is on
  - `playback_screen_fruit_widgets.dart`: lens path applies a slight `Transform.scale(1.03)` boost to the value text for a magnified watch-crystal read
- Test support and regression coverage updated:
  - `playback_screen_test.dart`: `MockSettingsProvider` now supports `setFruitEnableLiquidGlass(bool value)`
  - `playback_screen_test.dart`: replaced the earlier size-only stat-chip regression with `PlaybackScreen Fruit car mode shows a magnified value lens when glass is enabled`
  - The new test asserts long value `1200ms` still renders, the value font size is `24.0`, four lens overlays are present, and no layout exceptions occur
- Handover summary saved to:
  - `docs/superpowers/specs/2026-04-05-fruit-car-mode-stat-lens-handover.md`

### Changed (fruit-car-mode-stalled-playback — investigation/planning this session)
- Evaluated `reports/2026-04-05_14-46_v1.3.61+271_fruit_car_mode_stalled_playback.md` against the current codebase on `94c1f8e`
- Confirmed the Fruit car mode screen is only a consumer of `positionStream` / `durationStream`; the likely fault domain is the web engine to Dart bridge, not Fruit UI layout
- Confirmed current web stack already has worker-tick and watchdog behavior in JS (`html5`, `hybrid`, and `webAudio` paths), so the report's original fix direction was too broad
- Identified `apps/gdar_web/web/hybrid_init.js` as the real engine selection path and noted that PWA/mobile often routes to HTML5 or hybrid, not pure Web Audio
- Wrote implementation plan:
  - `docs/superpowers/plans/2026-04-05-fruit-car-mode-stalled-playback.md`
- Plan scope:
  - add a root-cause regression test at the JS engine boundary
  - add a narrow Dart-side `getState()` resync path on visibility restore / stale tick
  - add Dart regression coverage for resumed progress updates
- No runtime fix has been implemented yet in this session

### Changed (web-buffer-agent-recovery — implemented in this worktree)
- Implemented and verified Task 1:
  - added `packages/shakedown_core/lib/services/buffer_agent_stall_policy.dart`
  - updated `BufferAgent` to use `10s` for visible web playback and `20s` otherwise
  - treated web `AppLifecycleState.inactive` as visible for both threshold selection and recovery visibility behavior
  - added `packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart`
- Implemented and verified Task 2:
  - added `GaplessPlayer.playBlockedStream` on web and native
  - bridged JS `onPlayBlocked` into Dart in the web player
  - added a dispose-safe `_emitPlayBlocked()` guard to avoid late callback writes after stream closure
  - added `packages/shakedown_core/test/services/gapless_player_play_blocked_stream_test.dart`
  - regenerated only the mock files that needed the new `playBlockedStream` getter
- Implemented and verified Task 3:
  - updated `audio_provider.dart`, `audio_provider_diagnostics.dart`, `audio_provider_lifecycle.dart`, and `audio_provider_state.dart`
  - `AudioProvider` resume prompts now use a transient playback-recovery path instead of seeding sticky issue state
  - `playBlockedStream` and `suspended_by_os` prompts now clear when playback reports `playing=true`
  - added provider coverage for the real recovery path:
    - `playBlockedStream sets the browser resume agent message`
    - `playBlockedStream prompt clears after playback resumes`
  - updated `packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.dart`
  - fixed `packages/shakedown_core/test/verify_data_integrity_test.dart` so package-level test runs succeed from the monorepo root
- Session handoff saved to:
  - `.agent/notes/session_handoff.md`
- No commit was made in this session

### Fixed (pwa-startup-flicker — implemented this session)
- PWA startup three-layer flicker eliminated (report: `reports/2026-04-05_15-56_v1.3.61+271_pwa_startup_flicker.md`):
  - `manifest.json`: `background_color` `#000000` → `#080808` — aligns OS splash background with HTML splash
  - `index.html` `body`: `background-color` `#000000` → `#080808`
  - `index.html`: replaced `<img src="icons/Icon-512.png">` with `<div id="splash-title">Shakedown</div>` in RockSalt font (24px, weight 400, `#00E676`, `letter-spacing: 1.2px`) — matches Flutter `ShakedownTitle` to eliminate layout snap at HTML→Flutter seam
  - `index.html`: RockSalt font preloaded via `<link rel="preload">` + `@font-face` (`font-display: block`, correct descriptor weight 400)
  - `index.html`: added indeterminate `#00E676` sweep progress bar (`#splash-progress-track` / `#splash-progress-fill`) using `transform: translateX` animation — GPU-composited, loops continuously, fades with splash (no snap risk)
  - `index.html`: splash fade reduced from 700ms total (100ms delay + 600ms) to 200ms; pre-hide delay removed
  - `index.html`: returning-user fast path via `localStorage` key `gdar_pwa_visited` — 100ms fade on cached app revisit vs 200ms on first visit
  - `hybrid_init.js`: `gdar_pwa_visited` added to `?flush=true` allowlist
- Commits: `11721e0` → `dd3fb99` (7 commits, web-only, no Dart changes)

### Verification Notes
- Autocorr merge tip verified in an isolated worktree before integration:
  - `dart run melos exec -c 1 --dir-exists=test --ignore=screensaver_tv -- flutter test`
    passed on the merged result of `main` + `feat/autocorr-beat-improvements`
- Autocorr follow-up settings/runtime commit verified before integration:
  - WIP was committed in `.worktrees/feat-autocorr-improvements` as
    `67b1916 feat(tv): expose autocorr refinement controls`
  - `dart run melos exec -c 1 --dir-exists=test --ignore=screensaver_tv -- flutter test`
    passed in `.worktrees/feat-autocorr-improvements`
- `git diff --check` passed for the updated Kotlin, plan, and Android test files
- `flutter build apk --debug` reached Android SDK configuration, then failed on host setup before Kotlin compilation:
  - NDK package `ndk;28.2.13676358` license not accepted
  - this Chromebook environment exposes `/usr/lib/android-sdk/platform-tools` only; `sdkmanager` is not installed on `PATH`
- Fruit car mode stat-chip change verified on merged `main`:
  - `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart` passed (`11` tests)
  - `flutter analyze` passed with `No issues found!`
- Fruit car mode stat-lens follow-up verified in `feat/fruit-car-mode-stat-font-size-v2`:
  - `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart` passed (`11` tests)
  - `flutter analyze` passed with `No issues found!`
- Web buffer agent recovery work verified in `web-buffer-agent-recovery` worktree:
  - `git diff --check` passed
  - `flutter test packages/shakedown_core/test/services/buffer_agent_stall_policy_test.dart` passed
  - `flutter test packages/shakedown_core/test/services/buffer_agent_test.dart` passed
  - `flutter test packages/shakedown_core/test/services/gapless_player_play_blocked_stream_test.dart -r compact` passed
  - Dart MCP analyze of `packages/shakedown_core/lib` and `packages/shakedown_core/test` returned no errors
  - Dart MCP full `packages/shakedown_core/test` run passed
