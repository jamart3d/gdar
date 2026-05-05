# PWA Next-Track Console Errors — Companion (Handoff + Verification Prompts)

Use this doc to hand off execution to Gemini CLI (Windows) or any agent, and to verify the fixes are correct.

---

## Context

Two distinct errors fire in Chrome Android when the user taps "next track" from the PWA media notification:

### Bug 1 — `no_sleep.js` race condition (unhandled rejection)

```
[unhandledrejection] TypeError: Cannot read properties of null (reading 'completeError')
at no_sleep.js:145:39
```

**Root cause:** `wakelock_plus` (`no_sleep.js`) has a module-level `_nativeEnabledCompleter` variable.
When 3+ concurrent `enable()` calls race, the third call reuses an existing completer but fires
a new `navigator.wakeLock.request()` promise independently. When the first request settles it nulls
the completer; the third request's `.catch` then calls `.completeError(...)` on null → crash.

The built output `apps/gdar_web/build/web/assets/packages/wakelock_plus/assets/no_sleep.js`
**cannot be patched durably** (it is regenerated on every `flutter build web`).

**Fix:** Filter in `apps/gdar_web/web/web_error_logger.js` — suppress this known third-party race
in the `unhandledrejection` handler before it reaches `recordError`.

---

### Bug 2 — `_executeForegroundRestore` 50-poll timeout (5 second stall)

```
[hybrid] Handoff FAILED: Foreground never became ready. Staying on HTML5.
```

**Root cause:** After a media-notification skip, the `hybrid_audio_engine.js` tries to hand off from
HTML5 (background) to Web Audio API (foreground). The Web Audio `AudioContext` is suspended because
the media notification "next" button does NOT count as a page user gesture on Chrome Android.
`AudioContext.resume()` fails with `NotAllowedError` → `gapless_audio_engine.js` emits `onPlayBlocked`.
But `_executeForegroundRestore` ignores this signal and polls every 100ms for 5 full seconds before
giving up — wasting time and spamming 50 log entries.

**Fix:** In `hybrid_audio_engine.js`, modify the `_fgEngine.onPlayBlocked` handler (around line 899)
so that when a handoff is in progress (`_handoffInProgress === true`) it increments `_handoffRunId`
to abort the polling loop immediately (~250ms instead of 5s), then resets `_handoffInProgress`.

---

## Files to edit

| Bug | File | Change |
|-----|------|--------|
| 1 | `apps/gdar_web/web/web_error_logger.js` | Filter no_sleep.js race in `unhandledrejection` |
| 2 | `apps/gdar_web/web/hybrid_audio_engine.js` | Abort handoff poll on `onPlayBlocked` |

---

## Exact changes

### Bug 1 — `web_error_logger.js`

Find this block (near end of file, around line 81):

```js
  window.addEventListener('unhandledrejection', function (event) {
    recordError(event.reason || 'Unhandled rejection', null, 'unhandledrejection');
  });
```

Replace with:

```js
  window.addEventListener('unhandledrejection', function (event) {
    // Suppress wakelock_plus (no_sleep.js) race condition: concurrent enable()
    // calls can null _nativeEnabledCompleter before a racing .catch fires.
    // Cannot patch the built package output; suppress here instead.
    const reason = event.reason;
    if (reason instanceof TypeError) {
      const msg = reason.message || '';
      const stack = reason.stack || '';
      if (msg.includes('completeError') && stack.includes('no_sleep.js')) {
        return;
      }
    }
    recordError(reason || 'Unhandled rejection', null, 'unhandledrejection');
  });
```

---

### Bug 2 — `hybrid_audio_engine.js`

Find this block (around line 899):

```js
        if (typeof _fgEngine.onPlayBlocked === 'function') {
            _fgEngine.onPlayBlocked(_emitPlayBlocked);
        }
```

Replace with:

```js
        if (typeof _fgEngine.onPlayBlocked === 'function') {
            _fgEngine.onPlayBlocked(function () {
                // If a WA handoff poll is running and AudioContext is blocked
                // (e.g. media notification skip has no user-gesture), abort the
                // 5-second poll loop immediately instead of waiting 50 retries.
                if (_handoffInProgress) {
                    _log.log('[hybrid] onPlayBlocked during handoff — aborting poll loop early.');
                    ++_handoffRunId;
                    _handoffInProgress = false;
                }
                _emitPlayBlocked();
            });
        }
```

---

## Handoff prompt (copy/paste into Gemini)

```text
Context: gdar Flutter PWA on Chrome Android. Two console errors fire on next-track skip from
the media notification. Both root causes are identified — just implement the fixes.

Bug 1 fix — apps/gdar_web/web/web_error_logger.js:
  In the 'unhandledrejection' handler, before calling recordError(), add a guard that returns
  early if event.reason is a TypeError whose message includes 'completeError' and whose stack
  includes 'no_sleep.js'. This suppresses a known wakelock_plus race that cannot be patched
  in the built package output.

Bug 2 fix — apps/gdar_web/web/hybrid_audio_engine.js:
  In the init() function where _fgEngine.onPlayBlocked is wired (look for the block
  `_fgEngine.onPlayBlocked(_emitPlayBlocked)`), replace the direct _emitPlayBlocked reference
  with a wrapper function. The wrapper should: if _handoffInProgress is true, log a warning,
  increment _handoffRunId (to abort _executeForegroundRestore's poll loop), set
  _handoffInProgress = false. Then always call _emitPlayBlocked().

See exact change strings in:
  docs/superpowers/plans/2026-05-05-pwa-next-track-console-errors-companion.md

Do NOT use worktrees. Edit in place. Commit each bug fix as a separate commit.

Commit message template:
  fix(web): suppress no_sleep.js race unhandled rejection [Bug 1]
  fix(web): abort WA handoff poll on AudioContext blocked [Bug 2]

After each edit, verify with the verification steps in the companion doc.
```

---

## Verification — Bug 1

**Static check (Gemini / PowerShell):**

```powershell
Select-String -Path "apps/gdar_web/web/web_error_logger.js" -Pattern "no_sleep"
```

Expected: 1 match — the new filter line.

**Runtime check (Chrome DevTools → Console):**

1. Open PWA on Android Chrome (or desktop Chrome with mobile UA).
2. Start playback on a track.
3. Open DevTools (USB debugging) — filter console by `unhandledrejection`.
4. Tap "next" from the Android media notification multiple times rapidly.
5. Expected: **no** `TypeError: Cannot read properties of null (reading 'completeError')` entries.
6. The `[gdar engine] Aborting orphaned fetch` log is normal and expected — that is not this bug.

---

## Verification — Bug 2

**Static check:**

```powershell
Select-String -Path "apps/gdar_web/web/hybrid_audio_engine.js" -Pattern "onPlayBlocked during handoff"
```

Expected: 1 match in the new wrapper.

**Runtime check:**

1. Start playback in PWA on Chrome Android (media notification visible).
2. Tap "next" from notification.
3. In DevTools console, look for:
   - `[hybrid] onPlayBlocked during handoff — aborting poll loop early.` — confirms fast exit
   - `[hybrid] Handoff FAILED: Foreground never became ready.` should NO LONGER appear
   - Instead expect `[hybrid] Terminating stale handoff loop` from the ID guard
4. Confirm audio continues on HTML5 (not silent) after the skip.

---

## "Done" checklist

- [ ] `web_error_logger.js` — `unhandledrejection` handler has the no_sleep.js guard
- [ ] `hybrid_audio_engine.js` — `_fgEngine.onPlayBlocked` is a wrapper, not a bare reference
- [ ] Chrome DevTools: no `TypeError ... completeError` on rapid next-track taps
- [ ] Chrome DevTools: no `Handoff FAILED` after 5s; early abort log appears instead
- [ ] `melos run analyze` passes (no Dart changes, JS files are not analyzed — still confirm no Flutter errors)
- [ ] Audio does not go silent after media notification skip
