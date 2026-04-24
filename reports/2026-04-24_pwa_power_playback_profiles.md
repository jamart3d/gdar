# PWA Power Playback Profiles Verification

Date: 2026-04-24
Branch: `feature/pwa-power-playback-profiles`
Head: `09b8be1`
Worktree: `.worktrees/pwa-power-playback-profiles`

## Scope

This work adds explicit web PWA power playback behavior for two operating conditions:

- Battery / unknown charging state: prioritize durable long sessions by keeping Hybrid on HTML5/video survival, disabling immediate Web Audio handoff, disabling hidden Web Audio, and not requesting wake lock.
- Charging: prioritize gapless playback by keeping Hybrid, enabling immediate Web Audio handoff, allowing hidden Web Audio, increasing web prefetch, and enabling wake lock.

It also keeps installed standalone PWAs on Hybrid by default unless the device is detected as low-power mobile, exposes the profile in Fruit settings, adds charging detection plumbing, adds heartbeat blocked diagnostics, updates docs, and records current verification status.

## Implementation Summary

- Installed PWA launch logic now treats standalone Android/iOS PWAs as Hybrid by default, while installed low-power PWAs and mobile browser tabs stay on HTML5.
- Added `WebPlaybackPowerProfile` policy mapping for `auto`, `batterySaver`, `chargingGapless`, and `custom`.
- Added web battery/charging bridge loaded before `hybrid_init.js`.
- Wired settings provider persistence, charging-state updates, and profile-to-engine setting application.
- Added Fruit-compatible `Power Playback` selector in the web playback settings section.
- Added heartbeat blocked-count and last-reason diagnostics through JS, Dart web accessors, DNG snapshot, HUD snapshot, and audio provider diagnostics.
- Updated web playback decision docs and first-run preset docs to distinguish hidden session preset from power profile.
- Updated stale checked-in test fakes/mocks so their `setHiddenSessionPreset` override matches the new named parameter.

## Verification Run

| Check | Command | Result |
| --- | --- | --- |
| Dart format | `HOME=/tmp XDG_CONFIG_HOME=/tmp DART_SUPPRESS_ANALYTICS=true /home/jam/development/flutter/bin/cache/dart-sdk/bin/dart format --output=none --set-exit-if-changed packages/shakedown_core/lib packages/shakedown_core/test` | PASS: `Formatted 381 files (0 changed)` |
| Dart analyze | `HOME=/tmp XDG_CONFIG_HOME=/tmp DART_SUPPRESS_ANALYTICS=true /home/jam/development/flutter/bin/cache/dart-sdk/bin/dart analyze packages/shakedown_core apps/gdar_web` | PASS: `No issues found!` |
| JS PWA strategy regression | `/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/pwa_strategy_regression.js` | PASS: installed normal Android PWA -> Hybrid, installed low-power Android PWA -> HTML5, iOS standalone PWA -> Hybrid |
| JS web audio regression suite | `/home/jam/.config/nvm/versions/node/v24.14.0/bin/node apps/gdar_web/web/tests/run_tests.js` | PASS: `All tests passing!` |
| Diff whitespace | `git diff --check` | PASS |

## Blocked Verification

- Flutter VM tests are blocked in the current sandbox because Flutter's test harness cannot bind a loopback server socket: `Failed to create server socket (OS Error: Operation not permitted, errno = 1), address = 127.0.0.1, port = 0`.
- Flutter web/Chrome widget tests are also blocked by the same socket restriction; the tool diagnostics additionally report no Chrome executable at `google-chrome`.
- Plain Flutter launcher commands try to write `/home/jam/development/flutter/bin/cache/engine.stamp` and fail because the SDK cache is read-only. Running through the existing `flutter_tools.snapshot` with `FLUTTER_ALREADY_LOCKED=true` avoids the startup write, but tests still need local sockets.
- A Flutter test invocation without `--no-pub` attempted to resolve packages and failed because network access is restricted: `Got socket error trying to find package hive_ce_generator at https://pub.dev`.
- Manual Android/iOS installed-PWA long-session testing was not run in this sandbox. It still needs physical-device or browser validation for real OS background behavior.
- Git commits are blocked in this environment because `.git/worktrees/.../index.lock` cannot be created on the read-only Git metadata filesystem. A patch/tar backup is preserved under `/tmp`.

## Manual Device Validation To Run Next

1. Android installed PWA on battery: launch installed PWA, confirm engine starts Hybrid, profile resolves to Battery, handoff is none, hidden Web Audio is off, wake lock is off, and playback survives screen-off/background as far as browser policy allows.
2. Android installed PWA on charger: confirm profile resolves to Charging, immediate handoff is active, hidden Web Audio is allowed, wake lock is requested, and gapless transitions are improved.
3. iOS installed PWA on battery: confirm `navigator.standalone` path selects Hybrid, Battery profile avoids hidden Web Audio/wake lock assumptions, and diagnostics capture heartbeat blocking if Safari pauses survival helpers.
4. iOS installed PWA on charger: confirm Charging profile behavior, noting iOS may still restrict wake lock and background JavaScript despite the app policy.
5. For any paused/killed session, capture HUD/DNG values including `PWR`, `HBB`, and heartbeat last blocked reason.

## Changed Surface

Tracked modified files: 30
Untracked new files: 7

Key new files:

- `apps/gdar_web/web/tests/pwa_strategy_regression.js`
- `apps/gdar_web/web/web_power_state.js`
- `packages/shakedown_core/lib/utils/web_power_state.dart`
- `packages/shakedown_core/lib/utils/web_power_state_stub.dart`
- `packages/shakedown_core/lib/utils/web_power_state_web.dart`
- `packages/shakedown_core/test/providers/settings_provider_power_profile_test.dart`
- `docs/superpowers/plans/2026-04-24-pwa-power-playback-completion.md`

## Backup

A fresh backup should include:

- tracked diff from `git diff --binary`
- untracked files tarball from `git ls-files --others --exclude-standard`

