# Session Handoff — 2026-04-12 (Web PWA theme-sync + MediaSession diagnosis)

## State at Handoff

One surgical fix shipped to `apps/gdar_web/web/index.html`, plus a diagnosed
(but **not yet fixed**) regression in the web PWA notification-player
controls. No tests run this session — the fix is in `web/index.html` and is
not exercised by unit tests.

## What Changed

### `apps/gdar_web/web/index.html` — runtime `--splash-bg` CSS var sync

`updateThemeBranding()` now also writes the `--splash-bg` custom property on
`<html>` alongside `document.body.style.backgroundColor`. Before, only
`body` inline style tracked runtime dark/light toggles; the `flt-glass-pane
{ background-color: var(--splash-bg) !important; }` rule stayed pinned to
the boot-time value (set once by the splash-color sync script at
`index.html:122-162`). That left the Flutter underlay frozen at
boot-time colors, which bled through anywhere the Fruit UI is transparent —
most visibly the blurred region below the `FruitTabBar` on PWA.

- Fix: `document.documentElement.style.setProperty('--splash-bg', bgColor)`
  inserted after the existing `document.body.style.backgroundColor = bgColor`
  in `updateThemeBranding`.
- Optional follow-up: rename the var to `--app-bg`. It is misnamed — it is
  the page-level app background that persists for the entire session, not a
  splash-only value. Deferred to keep this save minimal.

### Not fixed: `<html>` has no background and no `viewport-fit=cover`

On iOS Safari standalone PWA, the home-indicator region can still fall back
to `<html>`'s default (white) because the `viewport` meta at
`index.html:22` does not set `viewport-fit=cover`. Low-priority — the common
case (`<body>` + `flt-glass-pane` via the CSS var) is now covered. Revisit
only if iOS users still report a mismatched sliver.

## Open — Web PWA notification player: play/pause often no-op

**Root cause (confirmed by code read, not yet reproduced on device):** only
the `hybrid_audio_engine.js` orchestrator installs
`navigator.mediaSession.setActionHandler` bindings — via
`_setupMediaSession()` at `hybrid_audio_engine.js:825-853`, called once from
`api.init()` at line 906 and re-invoked on engine swaps through
`_syncMediaSession()`. The other four engines explicitly opt out with
identical comments ("Child engines must NOT call setActionHandlers"):

- `html5_audio_engine.js:913-914`
- `gapless_audio_engine.js:785-786`
- `passive_audio_engine.js:223-224`
- `hybrid_html5_engine.js` — never calls it at all.

That rule was safe while the Hybrid orchestrator was always top-level. But
`hybrid_init.js:81-85` promotes `window._html5Audio` directly as the
top-level engine for mobile/PWA environments:

```js
} else if (isMobiUA || isIPadOS || (hasTouch && isNarrow)) {
    strategy = 'html5';
    reason = `Mobile/Tablet/PWA environment detected -> HTML5 streaming engine (Fresh Start).`;
}
```

Result: on a PWA install the notification tile shows metadata / position
correctly (every engine calls `updateMetadata` / `updatePlaybackState` /
`updatePositionState`) but the play / pause / next / previous / seek
buttons have no handler. Transport events from Bluetooth headsets and
headset buttons are routed exclusively through `setActionHandler`, so they
are dead on mobile today. Play/pause **sometimes** works because browsers
can synthesize it from the underlying `<audio>` element — which explains
the "often" in the user's report. Once the hybrid background handoff
swaps elements, the implicit binding breaks.

**Affected strategies:** `html5` (mobile/PWA default), `webAudio` (Chromebook
override / desktop gapless), `passive`. Only `hybrid` (desktop default) is
currently correct.

### Proposed fix (minimal, not yet applied)

Install handlers once in `hybrid_init.js` right after
`window._gdarAudio = selectedEngine;` (~line 131). Route each callback to
`selectedEngine.play() / .pause() / .next() / .previous() / .seek(...)`.

Sketch:

```js
if (window._gdarMediaSession && selectedEngine) {
    window._gdarMediaSession.setActionHandlers({
        onPlay:         ()  => selectedEngine.play  && selectedEngine.play(),
        onPause:        ()  => selectedEngine.pause && selectedEngine.pause(),
        onNext:         ()  => selectedEngine.next  && selectedEngine.next(),
        onPrevious:     ()  => selectedEngine.previous && selectedEngine.previous(),
        onSeekTo:       (e) => selectedEngine.seek  && selectedEngine.seek(Number(e?.seekTime) || 0),
        onSeekBackward: (e) => {
            const s = selectedEngine.getState?.() || {};
            const off = Number(e?.seekOffset) || 10;
            selectedEngine.seek && selectedEngine.seek(Math.max(0, (s.position || 0) - off));
        },
        onSeekForward:  (e) => {
            const s = selectedEngine.getState?.() || {};
            const off = Number(e?.seekOffset) || 10;
            const t = (s.position || 0) + off;
            selectedEngine.seek && selectedEngine.seek(
                Number.isFinite(s.duration) && s.duration > 0
                    ? Math.min(t, s.duration) : t);
        },
    });
}
```

### Before implementing, verify the non-hybrid engine APIs

Each engine must expose the same method names this sketch assumes. Audit
required:

1. `html5_audio_engine.js` — confirm `play()`, `pause()`, `next()`,
   `previous()`, `seek(seconds)`, `getState()` all exist on the exported
   `api` returned via `window._html5Audio`.
2. `gapless_audio_engine.js` — same audit on `window._gdarAudio` (when
   selected by `webAudio` strategy).
3. `passive_audio_engine.js` — confirm or stub missing methods.
4. When the Hybrid orchestrator IS the selected engine, the sketch above
   still fires, but that is a no-op duplicate of what `_setupMediaSession`
   already did. Either gate on `strategy !== 'hybrid'` or accept the
   idempotent overwrite (the child engine's handlers would clobber
   Hybrid's — prefer gating).

### Suggested verification path

- Reproduce on device: connect a Bluetooth headset, play any show via PWA
  install, press the headset play/pause button. Expect: no effect today.
- After fix: same steps, expect transport to toggle.
- Also verify the Android Chrome notification tile buttons, iOS Control
  Center transport, and macOS Safari/Chrome media key integration.

## Files Touched This Session

- `apps/gdar_web/web/index.html` — one block added to `updateThemeBranding`
  (5 new lines + 1 blank) synchronising `--splash-bg` CSS var alongside
  existing body inline style.

## Not Touched / Not Investigated

- No Dart / Flutter code was changed. `_syncPwaBranding` in
  `theme_provider.dart` was read-only during diagnosis; its call graph is
  already correct.
- No engine JS files modified. The MediaSession regression is diagnosed
  only.
- No tests run. This save is documentation + a 5-line HTML/JS tweak.
