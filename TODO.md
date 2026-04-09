# GDAR Open TODO

Refreshed against the current repo state on 2026-04-07.

This file is the active open backlog only. Completed, stale, migrated, and
historical audit items were intentionally removed.

## Release and Verification

- [ ] Fix the verification receipt flow so `.agent/notes/verification_status.json`
  reliably matches current `HEAD` after a successful verification pass.
- [ ] Capture a fresh browser-runtime playback smoke pass for `apps/gdar_web`
  and record browser, runtime mode, and error status explicitly.
- [ ] Keep the workspace-wide `melos run format`, `melos run analyze`, and
  `melos run test` lane green after the next refactor pass, not just before it.

## Maintainability

- [ ] Split the largest remaining shared UI hotspot:
  `packages/shakedown_core/lib/ui/screens/tv_playback_screen_build.dart`.
- [ ] Continue the next hotspot tier in shared UI:
  `track_list_screen_build.dart`, `track_list_view.dart`,
  `steal_graph_render_corner.dart`, and
  `playback_screen_fruit_car_mode.dart`.

## TV and Screensaver

- [ ] Implement the approved autocorr beat detector design from
  `docs/superpowers/specs/2026-04-06-autocorr-beat-mode-design.md`.
- [ ] Fine-tune default TV screensaver settings for a stronger out-of-box
  experience.
- [ ] Add a TV safe-area setting for older overscanned panels.
- [ ] Add an "Advanced Options" collapse/toggle in TV screensaver settings to
  reduce D-pad clutter.
- [ ] Tie trail intensity and blur to live audio energy or beat pulse.
- [ ] Tie shader "boiling" motion to real-time audio intensity in
  `packages/shakedown_core/assets/shaders/steal.frag`.
- [ ] Add a setting for screensaver auto-transition delay before advancing to
  the next show.
- [ ] Add a playback-marking option to mark a show as played when the first
  track starts instead of only at the end.
- [ ] Explore a persistent live playlist / session history flow as described in
  `.agent/specs/live_playlist_spec.md`.

## Web / PWA

- [ ] Ensure first-time Fruit defaults are correct:
  dense OFF, glass ON, simple OFF, glow OFF, RGB OFF.
- [ ] Finish the Fruit playback screen polish pass:
  lower top metadata, improve long-text marquee fade treatment, simplify the
  glass track list, and make the Now button scroll the current track into view.
- [ ] Finish the Fruit show list layout pass when not stacked.
- [ ] Refresh the Fruit rate-show dialog and glass snackbar patterns.
- [ ] Extend hidden/background playback longevity in throttled browser states.
- [ ] Fix the web track-skip-on-buffer edge case when the next track is not
  ready at the handoff point.
- [ ] Add a user-facing mobile preload setting for web playback.
- [ ] Evaluate a short fade-in option on play/resume to reduce pop artifacts.
- [ ] Clean up web audio engine wiring so runtime updates flow through the
  active player instance only.
- [ ] Sync `hybridBackgroundMode` in the same update path as the handoff mode.
- [ ] Unify the transition/crossfade contract between Dart and JS and hide
  unsupported UI until it is fully wired.
- [ ] Add a first-run PWA engine profile choice for modern vs older phones.
- [ ] Run a long background soak test matrix across `stability`, `balanced`,
  and `maxGapless` engine profiles.
- [ ] Audit `apps/gdar_web/lib/ui/` for leftover duplicate or shadow widgets
  from the monorepo transition.
- [ ] Implement true Web Advanced Cache support (service worker + Cache Storage
  strategy, preload controls, and safe eviction policy) and then re-enable
  the Usage Instructions copy from "planned" to "available."

## Testing

- [ ] Convert the remaining flaky or high-maintenance test cases into more
  reliable coverage where appropriate.
- [ ] Verify all automated tests use local mocks and never hit `archive.org`
  directly.
- [ ] Add a TV show list widget test that asserts stars and source badges stay
  visible and stable for single-source and multi-source cards.
- [ ] Run a quick TV manual smoke pass for dual-pane navigation, badges, focus,
  and scrollbar behavior.

## Native Audio

- [ ] Guard `BufferAgent` recovery paths during source switching so recovery
  does not seek/play into an in-flight reload.
- [ ] Guard processing-state completion paths during source switching so random
  show logic cannot fire while a new source load is still in progress.
