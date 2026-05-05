# PWA Chrome Android Media Controls — Companion (Handoff + Verification Prompts)

Use this doc to hand off execution to a human or an agent, and to ensure verification is performed consistently.

---

## Handoff prompt (copy/paste)

```text
Context: gdar_web Android Chrome installed PWA. Notification/lock-screen play/pause sometimes stops controlling playback after background/resume.

Goal: Make MediaSession play/pause controls remain reliable across lifecycle transitions on Android Chrome PWA.

Constraints:
- Keep child-engine rule: only the orchestrator/dispatcher layer sets MediaSession action handlers.
- Don’t change Flutter providers unless absolutely necessary.
- Preserve existing strategy routing (hybrid/html5/webaudio/passive/standard).

Plan index:
- docs/superpowers/plans/2026-04-27-pwa-chrome-android-media-controls.md

Execute phases in order:
1) Phase 1 routing fix
2) Phase 2 anchor resync API
3) Phase 3 lifecycle rebind + html5 hidden pulse
4) Phase 4 regression tests
5) Phase 5 manual verification + report

After each phase:
- Run node apps/gdar_web/web/tests/run_tests.js
- Summarize what changed and why it prevents the Android PWA control stall
- List any risk/edge cases discovered
```

---

## Verification prompts (ask these every time)

### Repro prompts

- What exact environment reproduces the stall?
  - Device model
  - Android version
  - Chrome version
  - Installed PWA vs browser tab
  - Audio strategy selected at runtime (`window._shakedownAudioStrategy`)

- What was the lifecycle transition?
  - app backgrounded (how long)
  - screen locked/unlocked
  - app killed/reopened
  - switched networks

### Instrumentation prompts

- Are MediaSession action handlers still installed?
  - Confirm logs when handlers are (re)bound.
  - Confirm action callback fires when tapping notification play/pause.

- Does the action callback hit the correct engine?
  - Confirm handler delegates to `window._gdarAudio` at call time.
  - Confirm active engine implements `play()` / `pause()`.

- After tapping play/pause, does the anchor resync?
  - Confirm anchor `playbackState` matches actual playback.
  - Confirm `setPositionState` isn’t failing due to invalid duration/position.

---

## Manual test script (Android Chrome installed PWA)

Run these in order and record Pass/Fail.

1) Fresh launch, start playback, pause/resume from notification (foreground).
2) Background app for 2–5 minutes; use notification pause/resume.
3) While playing, lock screen for 30–60s; unlock; use lock-screen controls.
4) From recents, re-open; use notification controls again.
5) While hidden, let a track boundary occur; then pause/resume from notification.

For each scenario capture:
- Did the callback fire? (log evidence)
- Did audio actually pause/play?
- Did notification icon update correctly?
- Any errors in console?

---

## “Done” checklist (must all be true)

- [ ] Non-hybrid MediaSession actions dispatch to the live active engine, not a captured engine reference.
- [ ] Anchor exposes a safe hard resync API used on lifecycle return.
- [ ] On Android resume (visibility/pageshow), handlers are reinstalled and state is resynced.
- [ ] html5-only strategy has a hidden-state pulse that keeps notification state fresh.
- [ ] New regression tests cover handler recovery and dynamic engine swap.
- [ ] Manual verification report is written under `reports/` and committed.

