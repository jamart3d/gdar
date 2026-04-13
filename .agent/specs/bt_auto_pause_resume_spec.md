
  ▎ Implement the Web/PWA Audio Route Monitor per the spec at .agent/specs/bt_auto_pause_resume_spec.md. Read that file and CLAUDE.md first.          
  ▎                                                                                                                                                   
  ▎ Execute in two phases — do NOT skip phase 1:                                                                                                      
  ▎                                                                                                                                                   
  ▎ Phase 1 — Diagnostic probe. Before writing the real module, ship a temporary console.log harness inside apps/gdar_web/web/hybrid_init.js (after   
  ▎ the MediaSession block). Log every navigator.mediaDevices.addEventListener('devicechange', ...) firing plus the full audiooutput list from 
  ▎ enumerateDevices() with deviceIds, groupIds, and labels. Build, deploy to the PWA, and ask me to run the probe on my Android Chrome PWA with a BT 
  ▎ headset: pair → play a show → walk out of range → walk back in → disconnect headset deliberately → pair a different headset. Report the log 
  ▎ output. Only after we both see the event fires and the audiooutput count actually changes do we proceed. If the count does NOT change (e.g. 
  ▎ Android collapses to a single default entry without mic permission), STOP and report — the spec calls for a fallback path in that case and we'll
  ▎ need to revise.
  ▎
  ▎ Phase 2 — Implementation. With probe data confirmed, build:                                                                                       
  ▎ 1. apps/gdar_web/web/audio_route_monitor.js — self-registered window._gdarRouteMonitor with attach(engine, strategy), detach(), getStatus(). State
  ▎  machine in the spec. Chain onto the engine's existing onStateChange by wrapping — preserve the downstream Dart callback. Read                    
  ▎ localStorage.getItem('flutter.pause_on_output_disconnect') — absent or "true" → enabled, "false" → disabled. 3-min resume window is a const, not 
  ▎ configurable. Auto-pause flag cleared on: window expiry, external playing:true transition, external playing:false transition distinct from our own
  ▎  pause call.                                                          
  ▎ 2. Script-tag insertion in apps/gdar_web/web/index.html in the load order shown in the spec.
  ▎ 3. One-liner in hybrid_init.js after the setActionHandlers block: if (window._gdarRouteMonitor) window._gdarRouteMonitor.attach(selectedEngine,   
  ▎ strategy);                                                                                                                                        
  ▎ 4. SettingsProvider pref pauseOnOutputDisconnect — key pause_on_output_disconnect, defaults via _dBool(true, false, false) (web/tv/phone).        
  ▎ 5. Web settings UI toggle (find the audio section — don't add a new screen).                                                                      
  ▎ 6. Remove the diagnostic probe before requesting commit.                                                                                          
  ▎                                                                                                                                                   
  ▎ Verification: run through the eight-step device test plan at the bottom of the spec on my Android Chrome PWA before asking for commit. Do not     
  ▎ commit until I confirm on device. No Dart changes beyond the settings provider and the UI toggle.                                                 
  ▎                                                                                                                                                   
  ▎ Do not regress: the MediaSession handler block added in commit <TBD after current save> in hybrid_init.js. The hybrid-path still owns its own     
  ▎ handlers via _setupMediaSession() — leave that alone.



# Web/PWA Audio Route Monitor — Auto-Pause / Timed Auto-Resume

**Status:** Spec — not implemented. Written 2026-04-12.

## Problem

When a Bluetooth audio device disconnects mid-playback on the PWA, audio
sometimes continues through the phone speaker instead of pausing. The OS's
"becoming noisy" broadcast auto-pauses `<audio>` elements reliably only when
the element is streaming; once the html5 engine's inner `Track` promotes to a
Web Audio `BufferSourceNode` (html5_audio_engine.js ~line 186,
`switchToWebAudio`), the broadcast subscription is effectively lost and the
source keeps producing samples.

The gapless (pure Web Audio) and passive engines have the same gap for
different reasons. The hybrid orchestrator is partially protected because it
falls back to HTML5 streaming in the background, but swaps during handoff can
still slip through.

Additionally: the OS never auto-resumes on reconnect. The user wants that
behavior — they reconnect, audio resumes where it left off.

## Design Decisions

- **Pause-on-disconnect: always on** — no reason to defer
- **Resume-on-reconnect: time-windowed (B)** — resume only if a new audio
  output device appears within **3 minutes** of the auto-pause. Constant, not
  a user setting. If they dislike the window, they pause themselves.
- **Manual override kills the window (D)** — if the engine transitions to
  `playing: true` at any point between auto-pause and reconnect (meaning the
  user resumed manually), discard the flag. Never auto-resume.
- **Settings gate:** `pause_on_output_disconnect` (default `true`). Users can
  opt out from the web settings page. Persisted via SharedPreferences with
  `flutter.` prefix on web, read by JS directly from localStorage.
- **Wired-vs-BT:** indistinguishable on the web (`MediaDeviceInfo` gives no
  transport type). Treat wired unplug the same as BT disconnect — users
  generally want that behavior anyway.
- **Platform support:** Android Chrome PWA is the primary target. iOS Safari
  PWA is best-effort — if `devicechange` doesn't fire there, document and
  move on. Desktop browsers get it for free.
- **Scope:** JS-side only for the detection/dispatch. One Dart change to
  expose the settings toggle. No engine-internal changes — all engines
  already expose `play()`, `pause()`, and `getState()`.

## Detection Heuristic

The web platform does not expose "which sink is the active output" on mobile,
so we approximate:

> If the count of `audiooutput` devices decreases while the engine is playing,
> the active output probably just disappeared. Pause.

Conversely:

> If the count increases while the auto-pause flag is set AND we are within
> the 3-minute window AND the user hasn't manually touched transport → play.

This is imperfect (a user unplugging one headset and plugging in another in
quick succession will pause-then-resume). Accepted because it's reliable
across Chrome/Firefox/Safari and doesn't require device-identity heuristics
that break on mobile (blank labels, `default`-only ids without `getUserMedia`
permission).

## State Machine

```
idle
  ↓  (engine state → playing:true)
armed                 ← snapshot audiooutput device set
  ↓  (devicechange with count decrease)
auto-paused           ← engine.pause() called; _autoPausedAt = now
  ├─ (devicechange with count increase, within 3 min) → engine.play() → armed
  ├─ (engine state → playing:true, from external) → armed (manual resume; no auto-resume later)
  ├─ (engine state → playing:false, external; e.g. user tapped pause again) → idle (they want it stopped)
  └─ (3 min elapses) → idle
idle
  ↓  (engine state → playing:true)
armed
```

Transitions are driven by two signals only: `devicechange` events and
`onStateChange` callbacks chained ahead of Dart's existing callback.

## Where it lives

New file: `apps/gdar_web/web/audio_route_monitor.js`

Loaded in `index.html` after `audio_utils.js` and after all engine files, but
**before** `hybrid_init.js` (the monitor module self-initializes but waits
for `window._gdarAudio` to be assigned by hybrid_init). The cleanest order:

```
audio_utils.js
hybrid_audio_engine.js
gapless_audio_engine.js
html5_audio_engine.js
passive_audio_engine.js
hybrid_html5_engine.js
audio_mediasession.js
audio_route_monitor.js   ← NEW
audio_scheduler.js
hybrid_init.js            ← reads route monitor pref and calls monitor.attach(selectedEngine, strategy)
```

API:

```js
window._gdarRouteMonitor = {
    attach(engine, strategy) {...},   // called by hybrid_init after engine selection
    detach() {...},                   // for completeness; not expected to be called
    getStatus() {...},                // diagnostic
};
```

## Dart / Settings Wiring

1. Add `pauseOnOutputDisconnect` to `SettingsProvider` (defaults: web=`true`,
   tv=`false`, phone=`false` — native platforms already have proper audio
   focus handling, this is a web-only hack).
2. Add a toggle in web settings UI (somewhere in the audio section).
3. On web, `SettingsProvider` already persists via `flutter.`-prefixed keys
   in localStorage, so the JS side reads
   `localStorage.getItem('flutter.pause_on_output_disconnect')` and treats
   `"true"` / absent-as-default=`true` → enabled.

No JS state needs to be bridged back to Dart. This is a fire-and-forget
behavior — Dart will observe the resulting play/pause transitions through
the normal `onStateChange` callback chain.

## Verification Plan

Before writing code:

1. **Diagnostic probe first** — ship a temporary `console.log` harness that
   logs `devicechange` events and the output of `enumerateDevices()` on
   Android Chrome PWA. Pair a BT headset, play a show, walk out of range,
   walk back. Confirm:
   - Event fires on disconnect → yes/no
   - Event fires on reconnect → yes/no
   - Device count changes as expected
   - Labels present or blank (affects nothing in our design but good to know)
2. Only if the probe confirms the assumption, proceed with the real
   implementation.

After implementation:

1. Android Chrome PWA — play show → walk out of BT range → audio pauses
   within 1s.
2. Reconnect within 3 min → audio resumes automatically.
3. Reconnect after 3 min → audio stays paused.
4. Disconnect → manually tap Fruit pause button → reconnect → stays paused.
5. Disconnect → manually tap Fruit play button (resumes through speaker) →
   reconnect → stays as-is (already playing, no-op).
6. Wired headphone unplug on desktop → audio pauses.
7. Disable `pause_on_output_disconnect` in settings → reload → BT disconnect
   no longer pauses.
8. Desktop Chrome hybrid path — verify no regression to media key
   integration.

## Risks & Known Limitations

- **iOS Safari PWA may not fire `devicechange`** — if so, iOS users get
  neither pause nor resume. Document and accept.
- **Ghost `default` device** on some browsers — `enumerateDevices()` can
  return a "default" entry that duplicates a real device, shifting counts in
  ways that don't map 1:1 to physical connect/disconnect. Probe will
  confirm whether this affects our delta heuristic.
- **Two devices in/out in quick succession** — see Detection Heuristic
  caveat.
- **No `getUserMedia` permission** — labels blank, but deviceIds should
  still be distinguishable. If Android Chrome collapses all outputs to a
  single `default` entry without permission, the count delta will fail to
  detect disconnect. Probe this specifically.
- **If the probe fails on Android** — fallback option is to listen for
  `visibilitychange` + the HTMLAudioElement `pause` event (which the OS
  fires on becoming-noisy), and plumb that into the Web Audio engines too.
  More invasive; defer unless needed.

## Not Doing (YAGNI)

- Configurable resume window — 3 min is the window, period.
- Per-device memory — "only resume for headset X" — too flaky on mobile.
- Native OS integration via additional Android manifest tweaks — scope is
  web/PWA only.
- Showing a UI banner ("audio paused, your headset disconnected") — can be
  added later if users want it; the pause itself is the UX.

## File Change Summary

- New: `apps/gdar_web/web/audio_route_monitor.js`
- Edit: `apps/gdar_web/web/index.html` (script tag insertion)
- Edit: `apps/gdar_web/web/hybrid_init.js` (one call to
  `window._gdarRouteMonitor.attach(selectedEngine, strategy)` after the
  MediaSession handler block)
- Edit: `packages/shakedown_core/lib/providers/settings_provider.dart` —
  add `pauseOnOutputDisconnect` pref with web-default `true`, tv/phone=`false`
- Edit: web settings UI — one toggle row
- Edit: `.agent/notes/pending_release.md` — changelog entry
