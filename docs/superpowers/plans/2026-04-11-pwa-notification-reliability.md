# PWA Notification Reliability Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix six reliability gaps in the Web PWA Media Session / OS notification layer, improving lock-screen controls, background survival visibility, and state consistency during engine handoffs.

**Architecture:** All fixes are in the JS layer (`apps/gdar_web/web/`) except Task 6 which adds Dart JS-interop bindings. No Flutter widget or Dart provider changes are required. Each task is self-contained and can be shipped independently.

**Tech Stack:** Vanilla ES5/ES6 JS (IIFE modules), Media Session API, Web Audio API, HTML5 `<audio>`, Dart `dart:js_interop` (extension-type pattern).

**Source report:** `reports/2026-04-11_14-30_v1.3.89+299_web_pwa_notification_reliability_v2.md`

---

## Non-Goals (Out of Scope)

To prevent scope creep during implementation:

- **No Flutter widget or provider refactor.** The Dart audio provider and HUD widgets stay untouched.
- **No Dart-side wiring of `gdar-heartbeat-blocked` telemetry.** Task 5 ends at JS `CustomEvent` dispatch. Consuming the event in Dart is a follow-up.
- **No artwork pipeline changes.** Media Session artwork is already handled by `audio_mediasession.js` and is not part of this plan.
- **No full MediaSession anchor rewrite.** We patch the existing `_gdarMediaSession` singleton, not replace it.
- **No Task 2 finding #2 fix** (engine handoff race / dual writers). Deferred until a concrete repro is available.
- **No HUD wiring for tiered heartbeat state** (finding #6). Task 5 exposes `blockedCount()` on the JS anchor; wiring it into the Dart HUD is a follow-up.

## Dependencies & Load Order

All JS tasks assume the following load order in `apps/gdar_web/web/index.html` (unchanged by this plan):

1. `audio_utils.js` — defines `window._gdarIsHeartbeatNeeded`
2. `audio_mediasession.js` — defines `window._gdarMediaSession`
3. `audio_heartbeat.js` — defines `window._gdarHeartbeat`
4. Engine files (`gapless`, `hybrid_html5`, `passive`, etc.)
5. `hybrid_audio_engine.js` — assembles `window._hybridAudio`

Tasks 1, 3, and 4 access `window._gdarMediaSession` inside `hybrid_audio_engine.js`, which is safe because `audio_mediasession.js` has already run at that point. All access is already guarded with `if (window._gdarMediaSession)` — keep those guards.

---

## File Map

| File | Tasks | Changes |
|---|---|---|
| `apps/gdar_web/web/hybrid_audio_engine.js` | 1, 3, 4 | Add seek handlers with clamping; re-push metadata in `_syncMediaSession`; hidden-tab pulse |
| `apps/gdar_web/web/audio_heartbeat.js` | 2, 5 | Volume 0.01 → 0; failure telemetry with payload contract |
| `packages/shakedown_core/lib/audio/web_interop_web.dart` | 6 | Rewrite to extension-type pattern; add `updateMetadata` + `updatePositionState` |
| `packages/shakedown_core/lib/audio/web_interop_stub.dart` | 6 | Add stub no-ops |

**Note on mock harness:** `apps/gdar_web/web/tests/mock_harness.js:221` already mocks
`setActionHandlers: () => { }` as a no-op function (not a callback object). No change
is needed there — the new callbacks pass through the no-op without issue.

---

## Task 1: Register `seekBackward` / `seekForward` MediaSession Handlers

**Files:**
- Modify: `apps/gdar_web/web/hybrid_audio_engine.js:822-832` (`_setupMediaSession`)

**Background:** `_setupMediaSession()` currently passes only `onPlay`, `onPause`,
`onNext`, `onPrevious`, `onSeekTo`. `onSeekBackward` and `onSeekForward` are
`undefined` → `audio_mediasession.js:setActionHandlers` calls
`navigator.mediaSession.setActionHandler('seekbackward', null)`, which removes the
skip buttons from the OS notification. Handler bodies read live position from
`_activeEngine.getState()` at call time and clamp to `[0, duration]`.

- [ ] **Step 1: Replace `_setupMediaSession` with clamped seek handlers**

Replace the entire `_setupMediaSession` function (currently lines 822-832):

```js
    function _setupMediaSession() {
        if (!window._gdarMediaSession) return;
        window._gdarMediaSession.setActionHandlers({
            onPlay: () => api.play(),
            onPause: () => api.pause(),
            onNext: () => api.seekToIndex(_currentIndex + 1),
            onPrevious: () => api.seekToIndex(_currentIndex - 1),
            onSeekTo: (e) => {
                const t = Number(e && e.seekTime);
                if (!Number.isFinite(t) || t < 0) return;
                api.seek(t);
            },
            onSeekBackward: (e) => {
                const s = _activeEngine.getState();
                const pos = Number(s && s.position) || 0;
                const offset = Number(e && e.seekOffset) || 10;
                api.seek(Math.max(0, pos - offset));
            },
            onSeekForward: (e) => {
                const s = _activeEngine.getState();
                const pos = Number(s && s.position) || 0;
                const dur = Number(s && s.duration);
                const offset = Number(e && e.seekOffset) || 10;
                const target = pos + offset;
                api.seek(Number.isFinite(dur) && dur > 0 ? Math.min(target, dur) : target);
            },
        });
    }
```

- [ ] **Step 2: Manual smoke test in browser**

Load PWA. Play a track. On desktop Chrome, open a new tab and navigate to
`chrome://media-internals` → Media Sessions. Confirm `seekbackward` and `seekforward`
appear in the registered actions list.

On Android Chrome, pull down the notification shade. Confirm the skip-backward and
skip-forward buttons appear. Tap each; confirm position scrubs by 10s.

On iOS Safari PWA, lock the screen; confirm the skip buttons appear on the lock
screen media widget.

**Acceptance criteria:** All three browsers show registered actions; tapping either
skip button moves position by the browser-provided `seekOffset` (or 10s fallback)
without exceeding `[0, duration]`.

- [ ] **Step 3: Commit**

```bash
git add apps/gdar_web/web/hybrid_audio_engine.js
git commit -m "fix(web): register seekBackward/seekForward MediaSession handlers with clamping"
```

---

## Task 2: Fix Heartbeat Audio Volume (0.01 → 0)

**Files:**
- Modify: `apps/gdar_web/web/audio_heartbeat.js:31`

**Background:** `_heartbeatAudio.volume = 0.01` is ≈ −40 dBFS — audible on
high-gain headphones in quiet environments. The OS keeps the tab alive based on the
audio element being in a `playing` state, not on audible output.

- [ ] **Step 1: Change volume to 0**

In `apps/gdar_web/web/audio_heartbeat.js`, line 31:

```js
// Before
_heartbeatAudio.volume = 0.01;

// After
_heartbeatAudio.volume = 0;
```

- [ ] **Step 2: Verify tab-keep-alive still works**

Open PWA in Chrome. Play a track. Background the tab. Leave it for 60+ seconds.
Bring the tab back to foreground. Confirm playback state is still current (track
hasn't silently stalled, engine state shows `heartbeatActive: true` in HUD).
Confirm no audio output from headphones during the test.

**Acceptance criteria:** Tab remains alive ≥60s backgrounded; HUD `heartbeatActive`
stays true; no audible hiss.

- [ ] **Step 3: Commit**

```bash
git add apps/gdar_web/web/audio_heartbeat.js
git commit -m "fix(web): set heartbeat audio volume to 0 (true silence)"
```

---

## Task 3: Re-Push Metadata After Engine Handoff

**Files:**
- Modify: `apps/gdar_web/web/hybrid_audio_engine.js:834-842` (`_syncMediaSession`)

**Background:** `_syncMediaSession()` resets the dedup cache via `forceSync()` and
pushes playback state + position state, but never calls `updateMetadata`. After an
engine handoff mid-track, `_lastMetadata` is zeroed, but nothing triggers a metadata
re-push until the next track change — leaving the OS notification's title/artist
correct but unrewritten through a dedup-stale gap.

The current track lives at `_playlist[_currentIndex]`. `_currentIndex = -1` at
startup is a valid state — `_playlist[-1]` returns `undefined` in JS, and the
`if (track)` guard handles it. **Do not "fix" this with an extra `_currentIndex >= 0`
check** — it's deliberately minimal.

- [ ] **Step 1: Add metadata re-push to `_syncMediaSession`**

Replace the `_syncMediaSession` function body (currently lines 834-842):

```js
    /** Force-sync: reset dedup guards, re-register handlers, push current state. */
    function _syncMediaSession() {
        if (!window._gdarMediaSession) return;
        window._gdarMediaSession.forceSync();
        _setupMediaSession();
        // Re-push metadata so the OS notification stays current after a handoff.
        const track = _playlist[_currentIndex];
        if (track) {
            window._gdarMediaSession.updateMetadata({
                title: track.title || '',
                artist: track.artist || '',
                album: track.album || '',
            });
        }
        const state = _activeEngine.getState();
        window._gdarMediaSession.updatePlaybackState(_playing);
        window._gdarMediaSession.updatePositionState(state);
    }
```

- [ ] **Step 2: Manual smoke test**

Play a track. In DevTools console, force a handoff with:

```js
window._hybridAudio.setHybridBackgroundMode('heartbeat');
```

Then background the tab briefly and bring it back. Open the OS notification
(Android shade / lock screen). Confirm the title/artist still match the currently
playing track.

**Acceptance criteria:** After a forced handoff, the OS notification metadata still
reflects the currently playing track; no "stale from previous track" gap.

- [ ] **Step 3: Commit**

```bash
git add apps/gdar_web/web/hybrid_audio_engine.js
git commit -m "fix(web): re-push track metadata to MediaSession after engine handoff"
```

---

## Task 4: Add Hidden-Tab MediaSession Pulse

**Files:**
- Modify: `apps/gdar_web/web/hybrid_audio_engine.js`
  - Add `_hiddenPulseTimer` state variable (near line 72)
  - Add `_startHiddenPulse` / `_stopHiddenPulse` helpers (after `_syncMediaSession`)
  - Insert calls into `visibilitychange` listener at lines 509 and 535
  - Add startup guard in `init` at line 857

**Background:** iOS Safari can silently clear MediaSession metadata when a system
audio event fires while the tab is hidden. GDAR's dedup cache thinks state is
current and won't re-push. A periodic pulse while hidden **and playing** ensures
the OS UI stays in sync.

**Interval rationale:** iOS Safari's background tab suspension interval is
~30s minimum under "audio playing" conditions; 15s gives two refresh attempts
before suspension. Tab is already kept alive by the heartbeat, so the wall-clock
cost is a single `setInterval` callback every 15s.

**Pulse gating:** Only runs when `_playing === true`. Paused-and-hidden tabs
need no pulse — dedup is already accurate.

- [ ] **Step 1: Add state variable**

In the state block near line 72 (adjacent to `_heartbeatEscalateTimer`), add:

```js
    let _hiddenPulseTimer = null;
```

- [ ] **Step 2: Add pulse helpers**

Immediately after `_syncMediaSession` (after line 842), add:

```js
    /** Starts a 15s repeating MediaSession pulse while tab is hidden and playing. */
    function _startHiddenPulse() {
        if (_hiddenPulseTimer) return; // already running
        if (!_playing) return;         // only pulse during active playback
        _hiddenPulseTimer = setInterval(function () {
            // Self-cancel if conditions change
            if (document.visibilityState !== 'hidden' || !_playing) {
                _stopHiddenPulse();
                return;
            }
            _syncMediaSession();
        }, 15000);
    }

    function _stopHiddenPulse() {
        if (_hiddenPulseTimer) {
            clearInterval(_hiddenPulseTimer);
            _hiddenPulseTimer = null;
        }
    }
```

- [ ] **Step 3: Wire pulse into `visibilitychange` listener**

Open `apps/gdar_web/web/hybrid_audio_engine.js:505-544`. The listener has a mobile
vs desktop branch inside the `hidden` path — do **not** refactor it. Make two
surgical insertions:

**At line 509**, immediately after `_applyHiddenSurvivalStrategy();`:

```js
            _applyHiddenSurvivalStrategy();
            _startHiddenPulse();   // ← add
```

**At line 535**, immediately after `_log.log('[hybrid] Tab visible. Ensuring survival tricks are off.');`:

```js
            _log.log('[hybrid] Tab visible. Ensuring survival tricks are off.');
            _stopHiddenPulse();    // ← add
```

- [ ] **Step 4: Add startup guard in `init`**

At the end of the `init` method (after line 857 `_setupMediaSession();`):

```js
        init: function () {
            _fgEngine.init();
            _bgEngine.init();
            if (typeof _fgEngine.onPlayBlocked === 'function') {
                _fgEngine.onPlayBlocked(_emitPlayBlocked);
            }
            if (typeof _bgEngine.onPlayBlocked === 'function') {
                _bgEngine.onPlayBlocked(_emitPlayBlocked);
            }
            if (window._gdarScheduler) window._gdarScheduler.start();
            _setupMediaSession();
            // PWA may resume directly into a hidden-playing state on iOS; the
            // visibilitychange event never fires in that case. Prime the pulse.
            if (document.visibilityState === 'hidden') {
                _startHiddenPulse();
            }
        },
```

**Also stop the pulse in `pause` and `stop` API methods** (find them in the `api`
object around lines 948 and 991). Add `_stopHiddenPulse();` at the top of each.
Restart it in `play` if currently hidden:

```js
        play: function () {
            _playing = true;
            // ... existing play logic unchanged ...
            // After the existing logic at the end of play():
            if (document.visibilityState === 'hidden') {
                _startHiddenPulse();
            }
        },

        pause: function () {
            _stopHiddenPulse();
            // ... existing pause logic unchanged ...
        },

        stop: function () {
            _stopHiddenPulse();
            // ... existing stop logic unchanged ...
        },
```

**Note:** No `destroy` method exists on the hybrid engine `api` object. The IIFE
runs for the lifetime of the page. The pulse self-cancels via its internal guard
and via the `visibilitychange` visible branch, so no explicit teardown is needed.

- [ ] **Step 5: Manual test**

On Chrome desktop with DevTools open:
1. Play a track.
2. Tab away for 60 seconds.
3. Confirm console shows periodic `[mediasession] Updating metadata: <title>` log
   lines every ~15 seconds (one per pulse, because `forceSync` resets dedup).
4. Pause playback while still hidden. Confirm log lines stop within ~15s
   (next pulse tick self-cancels).
5. Resume playback while still hidden. Confirm log lines resume within ~15s.

**Acceptance criteria:** Pulse runs only while `visibilityState === 'hidden'` **and**
`_playing === true`. Stops within 15s of either condition becoming false. Starts
within one event-loop tick of both becoming true (via `play`/`visibilitychange`).

- [ ] **Step 6: Commit**

```bash
git add apps/gdar_web/web/hybrid_audio_engine.js
git commit -m "fix(web): add 15s hidden-tab MediaSession pulse gated on active playback"
```

---

## Task 5: Add Heartbeat Failure Telemetry

**Files:**
- Modify: `apps/gdar_web/web/audio_heartbeat.js`
  - Add module state: `_heartbeatBlockedCount`
  - Add private helper: `_dispatchBlocked(type, reason)`
  - Update `startAudioHeartbeat` and `startVideoHeartbeat` to call it
  - Expose `blockedCount()` on `api`

**Background:** Both `startAudioHeartbeat` and `startVideoHeartbeat` silently swallow
`.play()` failures. No counter, no event, no way for Dart or future HUD work to
detect blocked heartbeats.

**Telemetry contract (stable):**

- **Event name:** `gdar-heartbeat-blocked`
- **Dispatch target:** `window`
- **Payload (`event.detail`):**
  ```ts
  {
    type: 'audio' | 'video',
    reason: string,        // err.message (may be empty)
    timestampMs: number,   // Date.now() at dispatch
    count: number,         // cumulative blocked count (pre-dispatch increment)
  }
  ```

Dart-side wiring of this event is **out of scope** for this plan. This task ends
at the JS `dispatchEvent` call.

- [ ] **Step 1: Add counter + dispatch helper**

In `apps/gdar_web/web/audio_heartbeat.js`, immediately after the `_log` declaration
at the top of the IIFE (around line 15), add:

```js
    // Module state for failure telemetry
    let _heartbeatBlockedCount = 0;

    function _dispatchBlocked(type, reason) {
        _heartbeatBlockedCount++;
        _log.warn('[gdar heartbeat] ' + type + ' heartbeat blocked:', reason || '(no reason)');
        try {
            window.dispatchEvent(new CustomEvent('gdar-heartbeat-blocked', {
                detail: {
                    type: type,
                    reason: reason || '',
                    timestampMs: Date.now(),
                    count: _heartbeatBlockedCount,
                },
            }));
        } catch (_) { /* CustomEvent unavailable — swallow */ }
    }
```

- [ ] **Step 2: Replace `startAudioHeartbeat` body**

Replace the existing function (lines 56-63):

```js
        startAudioHeartbeat: function () {
            _initAudio();
            if (_heartbeatAudio.paused) {
                _heartbeatAudio.play().catch(err => {
                    _dispatchBlocked('audio', err && err.message);
                });
            }
        },
```

- [ ] **Step 3: Replace `startVideoHeartbeat` body**

Replace the existing function (lines 65-73):

```js
        startVideoHeartbeat: function () {
            _initVideo();
            if (_heartbeatVideo.paused) {
                _heartbeatVideo.play().then(() => {
                    _log.log('[gdar heartbeat] Video survival heartbeat started.');
                }).catch(err => {
                    _dispatchBlocked('video', err && err.message);
                });
            }
        },
```

- [ ] **Step 4: Expose `blockedCount()` on the api**

In the `api` object, add a new method alongside `isActive`:

```js
        blockedCount: function () {
            return _heartbeatBlockedCount;
        },
```

- [ ] **Step 5: Verify event fires in DevTools**

In DevTools console before triggering play:

```js
window.addEventListener('gdar-heartbeat-blocked', e => {
    console.warn('HEARTBEAT BLOCKED', e.detail);
});
```

Simulate a block by disabling autoplay: `chrome://settings/content/sound` → block
for the site. Reload, hit play. Confirm the event fires with `{type, reason,
timestampMs, count}` and `count` increments on repeated attempts.

**Acceptance criteria:** Event fires on `.play()` rejection; `detail` matches the
contract above; `count` is monotonic.

- [ ] **Step 6: Commit**

```bash
git add apps/gdar_web/web/audio_heartbeat.js
git commit -m "fix(web): emit gdar-heartbeat-blocked CustomEvent with stable payload contract"
```

---

## Task 6: Dart Interop — `updateMetadata` + `updatePositionState` Bindings

**Files:**
- Modify: `packages/shakedown_core/lib/audio/web_interop_web.dart` (rewrite)
- Modify: `packages/shakedown_core/lib/audio/web_interop_stub.dart` (add stubs)

**Background:** The current `web_interop_web.dart` binds only `updatePlaybackState`
via a top-level `@JS('window._gdarMediaSession.updatePlaybackState')` external.
The rest of the codebase uses the **extension-type** interop pattern
(see `packages/shakedown_core/lib/audio/hybrid_audio_engine_web.dart:10-70` for the
canonical example). This task migrates `WebInterop` to that same pattern and adds
the two missing methods.

**Why not `.jsify()`:** `grep '\.jsify(' packages/` returns zero matches. The
codebase standard is anonymous extension types with factory constructors.

- [ ] **Step 1: Rewrite `web_interop_web.dart` using extension-type pattern**

Replace the entire file contents:

```dart
import 'dart:async';
import 'dart:js_interop';
import 'package:web/web.dart' as web;

// ─── JS interop bindings ─────────────────────────────────────────────────────

@JS('_gdarMediaSession')
external _GdarMediaSession? get _mediaSession;

/// Mirrors the JS API in `apps/gdar_web/web/audio_mediasession.js`.
@JS()
@anonymous
extension type _GdarMediaSession(JSObject _) {
  external void updatePlaybackState(bool playing);
  external void updateMetadata(_MediaMetadataArg metadata);
  external void updatePositionState(_PositionStateArg state);
  external void forceSync();
}

@JS()
@anonymous
extension type _MediaMetadataArg._(JSObject _) implements JSObject {
  external factory _MediaMetadataArg({
    required String title,
    required String artist,
    required String album,
  });
}

@JS()
@anonymous
extension type _PositionStateArg._(JSObject _) implements JSObject {
  external factory _PositionStateArg({
    required double duration,
    required double position,
    required bool playing,
  });
}

// ─── Public WebInterop surface ───────────────────────────────────────────────

/// Utility class for JS Interop and Web-specific background stability.
class WebInterop {
  /// Syncs playback state through the centralised JS MediaSession anchor.
  static void syncMediaSession(bool isPlaying) {
    try {
      _mediaSession?.updatePlaybackState(isPlaying);
    } catch (_) {
      // Anchor not available
    }
  }

  /// Pushes track metadata to the OS notification via the JS MediaSession anchor.
  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
  }) {
    try {
      _mediaSession?.updateMetadata(
        _MediaMetadataArg(title: title, artist: artist, album: album),
      );
    } catch (_) {
      // Anchor not available
    }
  }

  /// Pushes scrubber position state to the OS notification.
  static void updatePositionState({
    required double duration,
    required double position,
    bool playing = true,
  }) {
    try {
      _mediaSession?.updatePositionState(
        _PositionStateArg(duration: duration, position: position, playing: playing),
      );
    } catch (_) {
      // Anchor not available
    }
  }

  /// Listens for the custom 'gdar-worker-tick' event, fired by a Web Worker
  /// to bypass 1Hz background clamping.
  static Stream<web.Event> get onWorkerTick {
    final controller = StreamController<web.Event>.broadcast();
    web.window.addEventListener(
      'gdar-worker-tick',
      (web.Event event) {
        controller.add(event);
      }.toJS,
    );
    return controller.stream;
  }
}
```

- [ ] **Step 2: Update the stub**

Replace `packages/shakedown_core/lib/audio/web_interop_stub.dart`:

```dart
class WebInterop {
  static void syncMediaSession(bool isPlaying) {}

  static void updateMetadata({
    required String title,
    required String artist,
    required String album,
  }) {}

  static void updatePositionState({
    required double duration,
    required double position,
    bool playing = true,
  }) {}
}
```

- [ ] **Step 3: Run analyzer**

```bash
melos run analyze
```

**Expected:** No new errors. The existing `WebInterop.syncMediaSession(true)` call
in `packages/shakedown_core/lib/audio/web_audio_engine.dart:79` continues to work
unchanged because the public signature is preserved.

- [ ] **Step 4: Run targeted tests**

```bash
flutter test packages/shakedown_core/
```

**Expected:** All tests pass. Stub class is used in tests; new methods are no-ops.
Known pre-existing failure in `verify_data_integrity_test.dart` (asset dependency)
is unrelated.

- [ ] **Step 5: Commit**

```bash
git add packages/shakedown_core/lib/audio/web_interop_web.dart \
        packages/shakedown_core/lib/audio/web_interop_stub.dart
git commit -m "feat(web): migrate WebInterop to extension-type JS interop and add metadata/position bindings"
```

---

## Rollback Notes

If any JS-layer change regresses playback after merge, rollback paths by task:

- **Task 1:** Revert the commit — strictly additive, zero side effects.
- **Task 2:** One-line revert (`volume = 0` → `0.01`).
- **Task 3:** Revert. Metadata re-push is additive; removing it restores prior
  (dedup-stale) behavior.
- **Task 4:** Revert. The pulse is self-contained in `_hiddenPulseTimer`; removing
  the interval-based logic has no load-order or lifecycle dependencies.
- **Task 5:** Revert. The `CustomEvent` has no listeners yet (Dart wiring is
  out of scope), so removing it cannot break consumers.
- **Task 6:** Revert. The existing `syncMediaSession` call site is unchanged; the
  rewrite preserves the public signature.

If a finer-grained rollback is needed, each task commits independently and
can be reverted in isolation via `git revert <sha>`.

---

## Self-Review

| Report finding | Task | Coverage |
|---|---|---|
| 1 — Missing seekBackward/seekForward handlers | Task 1 | Full, with null/NaN/duration clamping |
| 2 — Engine handoff race (Dart vs JS writer) | Out of scope (Non-Goals §) | Documented |
| 3 — De-duplication staleness (no hidden pulse) | Task 4 | Full, gated on `_playing` |
| 4 — Heartbeat failure no telemetry | Task 5 | Full, stable payload contract |
| 5 — Dart interop missing metadata bindings | Task 6 | Full, extension-type pattern |
| 6 — `isActive()` masks audio failure | Task 5 (`blockedCount` exposed) | Partial — Dart HUD wiring out of scope |
| 7 — Heartbeat volume 0.01 | Task 2 | Full |
| 8 — `onStop` never registered | Intentional — no task | Documented |
| 9 — `_syncMediaSession` doesn't re-push metadata | Task 3 | Full |

**Placeholder scan:** No TBDs, no "implement later", all code blocks complete.

**Type consistency:** `track.title/artist/album` usage in Task 3 matches
`gapless_audio_engine.js:786-790`. Extension-type JS interop pattern in Task 6
matches `hybrid_audio_engine_web.dart:10-70`. The `_currentIndex = -1` edge case
in Task 3 is explicitly documented to prevent a "defensive fix" from a future
reviewer.

**Verified against source:**
- `hybrid_audio_engine.js:822-832` — `_setupMediaSession` current callback list
- `hybrid_audio_engine.js:834-842` — `_syncMediaSession` current body
- `hybrid_audio_engine.js:505-544` — `visibilitychange` listener structure
- `hybrid_audio_engine.js:847-858` — `init` method
- `hybrid_audio_engine.js:1011-1014` — `api.seek` signature (takes seconds)
- `hybrid_audio_engine.js:1157` — global exposed as `window._hybridAudio`
- `hybrid_audio_engine.js` — no `destroy` method exists
- `audio_heartbeat.js:31` — `volume = 0.01` line
- `audio_heartbeat.js:56-73` — both heartbeat start functions
- `audio_mediasession.js:91-116` — `setActionHandlers` action list (includes seek*)
- `tests/mock_harness.js:221` — `setActionHandlers` mock is a no-op function
- `hybrid_audio_engine_web.dart:10-70` — canonical extension-type interop pattern
