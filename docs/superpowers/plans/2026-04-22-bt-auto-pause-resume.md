# Web/PWA Bluetooth Route Monitor Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use `superpowers:subagent-driven-development` to execute this plan. Dispatch one subagent per task, in order. Do NOT skip the HUMAN GATE checkpoints between phases — stop and ask the user before continuing.

**Spec (use for compliance review):** `docs/superpowers/specs/2026-04-22-bt-auto-pause-resume-design.md`

**Goal:** Implement auto-pause on Bluetooth disconnect and 3-minute auto-resume on reconnect for the GDAR Web PWA.

**Architecture:** A JS-side "Route Monitor" module that watches `navigator.mediaDevices` and communicates with the active audio engine. Settings are toggled in Dart and read from `localStorage`.

**Tech Stack:** JavaScript (ES6), Dart (Flutter Web), MediaDevices API.

---

## Task Dependency Map

```
Task 1 (Probe)  ──┐
                  ├──► HUMAN GATE A (publish + hardware verify) ──► Task 3 (Monitor JS)  ──┐
Task 2 (Settings) ─────────────────────────────────────────────────► Task 4 (UI Toggle)  ──┤
                                                                                             └──► HUMAN GATE B (publish + BT test)
```

**Rules:**
- Task 1 and Task 2 are independent — run Task 1 first, then Task 2 (or either order).
- **Do NOT start Task 3 until HUMAN GATE A is cleared by the user.**
- Task 4 requires Task 2 to be complete first (needs `pauseOnOutputDisconnect` getter).
- Task 3 and Task 4 can run in either order once their prerequisites are met.

---

## PHASE 1 — Probe + Settings

> Run Task 1, then Task 2. Then stop at HUMAN GATE A.

---

### Task 1: Diagnostic Probe
**Files:**
- Modify: `apps/gdar_web/web/hybrid_init.js`

**Context for subagent:** This is a temporary diagnostic probe added to confirm that the browser's `devicechange` event fires correctly on real Bluetooth hardware. It will be replaced in Task 3. The probe is self-contained and does not affect other features.

- [ ] **Step 1: Add diagnostic logging to hybrid_init.js**
Add the following block after the `MediaSession` handler setup in `hybrid_init.js` (around line 180):
```javascript
    // --- DIAGNOSTIC PROBE (Temporary — replaced in Task 3) ---
    if ('mediaDevices' in navigator && navigator.mediaDevices.addEventListener) {
        navigator.mediaDevices.addEventListener('devicechange', async () => {
            const devices = await navigator.mediaDevices.enumerateDevices();
            const outputs = devices.filter(d => d.kind === 'audiooutput');
            console.log(`%c[GDAR-PROBE] devicechange fired. Total outputs: ${outputs.length}`, 'color: #00ff00; font-weight: bold;');
            outputs.forEach(d => console.log(` - Device: ${d.label || 'unlabeled'} (${d.deviceId})`));
        });
        console.log('[GDAR-PROBE] Monitor initialized.');
    }
```

- [ ] **Step 2: Commit**
```bash
git add apps/gdar_web/web/hybrid_init.js
git commit -m "chore: add bluetooth diagnostic probe"
```

---

### Task 2: Settings Provider
**Files:**
- Modify: `packages/shakedown_core/lib/providers/settings_provider_web.dart`

**Context for subagent:** `SettingsProvider` is a large (~1960 line) provider split into extensions. The web-specific fields live in `_SettingsProviderWebFields` and web-specific methods in `_SettingsProviderWebExtension`. All settings must be loaded from `SharedPreferences` in the init/`_loadPrefs` path — not just declared as field defaults — or they will be ignored after page reload. The SharedPreferences key for JS to read via `localStorage` will be `flutter.pause_on_output_disconnect` (Flutter auto-prefixes with `flutter.`).

- [ ] **Step 1: Add field, prefs load, getter, and toggle**
```dart
// In _SettingsProviderWebFields — declare field with web-on default
bool _pauseOnOutputDisconnect = kIsWeb;

// In the init / _loadPrefs method — load persisted value (add alongside other getBool calls)
_pauseOnOutputDisconnect = _prefs.getBool('pause_on_output_disconnect') ?? kIsWeb;

// In _SettingsProviderWebExtension
bool get pauseOnOutputDisconnect => _pauseOnOutputDisconnect;

void togglePauseOnOutputDisconnect() {
  _pauseOnOutputDisconnect = !_pauseOnOutputDisconnect;
  _prefs.setBool('pause_on_output_disconnect', _pauseOnOutputDisconnect);
  notifyListeners();
}
```

- [ ] **Step 2: Commit**
```bash
git commit -am "feat: add pauseOnOutputDisconnect setting"
```

---

## ⛔ HUMAN GATE A — Stop here. Do not proceed to Phase 2.

**Agent instructions:** Tasks 1 and 2 are complete. Tell the user:

> "Phase 1 complete. Please publish the PWA (`.agent/workflows/publish.md`) and test the probe on a real Android device with Bluetooth:
> - Play audio in the PWA. Connect/disconnect Bluetooth.
> - Confirm `[GDAR-PROBE] devicechange fired` appears in the console with correct output count.
> - Also test with the tab in the background (switch apps, then disconnect BT). Note whether the event fires in background — this affects the UX guarantee.
> Reply **'probe ok'** (or describe any issues) to continue."

**If the user reports the event does NOT fire in the background:** Note this in the task context when dispatching Task 3. The subagent will need to add a `visibilitychange` fallback re-check.
**If the user reports the event does NOT fire at all:** Do not proceed. Escalate — the feature may not be viable on the target browser.

---

## PHASE 2 — Monitor JS + UI Toggle

> Run Task 3, then Task 4. Then stop at HUMAN GATE B.

---

### Task 3: Route Monitor Module
**Files:**
- Create: `apps/gdar_web/web/audio_route_monitor.js`
- Modify: `apps/gdar_web/web/index.html`
- Modify: `apps/gdar_web/web/hybrid_init.js`

**Context for subagent:** This task builds the core JS monitor. It replaces the diagnostic probe from Task 1. The monitor attaches to the active audio engine (`window._gdarAudio`) and watches for Bluetooth device count changes. Key constraints from the spec:
- Filter strictly on `kind === 'audiooutput'` — `devicechange` fires for all device types.
- Debounce pause by 400ms to avoid false positives from A2DP codec renegotiation.
- Auto-resume window is 3 minutes from time of auto-pause.
- Manual play or pause (including headset buttons) must clear the auto-resume window.
- The monitor must be engine-agnostic — it works regardless of which web engine (Gapless, Hybrid, HTML5) is active.
- `audio_route_monitor.js` must load after `audio_utils.js` and before `hybrid_init.js` in `index.html`.
- The JS reads the setting directly from `localStorage` as `flutter.pause_on_output_disconnect`.

- [ ] **Step 1: Read engine API before writing**
Read `apps/gdar_web/web/gapless_audio_engine.js` and `apps/gdar_web/web/hybrid_audio_engine.js` to confirm:
  - How to check play state (e.g. `getState().playing`, `isPlaying`, or a state string).
  - How to observe manual play/pause (event, callback, or state listener).
Adjust the implementation to match the real API. Do not assume `getState()` exists verbatim.

- [ ] **Step 2: Create `apps/gdar_web/web/audio_route_monitor.js`**
```javascript
(function() {
    'use strict';
    let _activeEngine = null;
    let _lastCount = 0;
    let _autoPausedAt = 0;
    let _debounceTimer = null;
    const RESUME_WINDOW = 3 * 60 * 1000;
    const DEBOUNCE_MS = 400;

    function _isEnabled() {
        const rawVal = localStorage.getItem('flutter.pause_on_output_disconnect');
        return rawVal === null || rawVal === 'true';
    }

    function _clearAutoResume() {
        _autoPausedAt = 0;
    }

    function _onEnginePlayStateChange(playing) {
        if (_autoPausedAt > 0) {
            console.log('[gdar-route] Manual play/pause detected. Clearing auto-resume window.');
            _clearAutoResume();
        }
    }

    window._gdarRouteMonitor = {
        attach: function(engine) {
            if (_activeEngine) this.detach();
            _activeEngine = engine;
            navigator.mediaDevices.enumerateDevices().then(devices => {
                _lastCount = devices.filter(d => d.kind === 'audiooutput').length;
            });
            navigator.mediaDevices.addEventListener('devicechange', _onDeviceChange);
            // Adjust event name/registration to match actual engine API (see Step 1).
            if (typeof engine.onPlayStateChange === 'function') {
                engine.onPlayStateChange(_onEnginePlayStateChange);
            }
        },
        detach: function() {
            navigator.mediaDevices.removeEventListener('devicechange', _onDeviceChange);
            if (_activeEngine && typeof _activeEngine.offPlayStateChange === 'function') {
                _activeEngine.offPlayStateChange(_onEnginePlayStateChange);
            }
            _activeEngine = null;
            _autoPausedAt = 0;
            if (_debounceTimer) { clearTimeout(_debounceTimer); _debounceTimer = null; }
        }
    };

    async function _onDeviceChange() {
        const devices = await navigator.mediaDevices.enumerateDevices();
        const count = devices.filter(d => d.kind === 'audiooutput').length;

        if (!_isEnabled() || !_activeEngine) {
            _lastCount = count;
            return;
        }

        const state = _activeEngine.getState(); // adjust to actual API per Step 1
        if (count < _lastCount && state.playing) {
            // Debounce: absorb transient drops from A2DP codec renegotiation.
            if (_debounceTimer) clearTimeout(_debounceTimer);
            _debounceTimer = setTimeout(() => {
                _debounceTimer = null;
                if (!_isEnabled() || !_activeEngine) return;
                const currentState = _activeEngine.getState();
                if (currentState.playing) {
                    console.log('[gdar-route] Disconnect confirmed. Pausing.');
                    _activeEngine.pause();
                    _autoPausedAt = Date.now();
                }
            }, DEBOUNCE_MS);
        } else if (count > _lastCount && !state.playing && _autoPausedAt > 0) {
            if (Date.now() - _autoPausedAt < RESUME_WINDOW) {
                console.log('[gdar-route] Reconnect within window. Resuming.');
                _activeEngine.play();
            } else {
                console.log('[gdar-route] Reconnect after window expired. Staying paused.');
            }
            _clearAutoResume();
        }

        _lastCount = count;
    }
})();
```

- [ ] **Step 3: Add script tag to `index.html`**
Open `index.html` and check how `audio_utils.js` and `hybrid_init.js` are loaded (`defer`, `async`, or plain `<script>`). Use the same pattern. Insert the monitor tag **after `audio_utils.js` and before `hybrid_init.js`**:
```html
<script src="audio_route_monitor.js" defer></script>
```
Only use `defer` if `hybrid_init.js` also uses `defer`. Match the existing pattern exactly.

- [ ] **Step 4: Replace diagnostic probe in `hybrid_init.js`**
Remove the `// --- DIAGNOSTIC PROBE ---` block (the one added in Task 1) and replace it with:
```javascript
if (window._gdarRouteMonitor && window._gdarAudio) {
    window._gdarRouteMonitor.attach(window._gdarAudio);
}
```
If the engine is ever re-initialized at runtime (user switches engine in settings), `detach()` must be called before re-attaching.

- [ ] **Step 5: Commit**
```bash
git add apps/gdar_web/web/audio_route_monitor.js apps/gdar_web/web/index.html apps/gdar_web/web/hybrid_init.js
git commit -m "feat: add bluetooth route monitor (auto-pause/resume)"
```

---

### Task 4: UI Toggle in Settings
**Files:**
- Modify: `packages/shakedown_core/lib/ui/widgets/settings/playback_section_web.dart`

**Context for subagent:** Task 2 added `pauseOnOutputDisconnect` and `togglePauseOnOutputDisconnect()` to `SettingsProvider`. This task adds the UI toggle. The toggle must go in the **general Web playback section** — NOT inside `_buildWebGaplessSection`. The route monitor is engine-agnostic; if the toggle is inside the Gapless section it will be invisible when other engines are active. Use `_buildHighlightableToggle` following the same pattern as existing toggles in that file.

- [ ] **Step 1: Add toggle in the general Web section**
```dart
_buildHighlightableToggle(
  context,
  keyName: 'pause_on_output_disconnect',
  title: 'Auto-Pause on Disconnect',
  subtitle: 'Pause when headset is disconnected (PWA)',
  value: settingsProvider.pauseOnOutputDisconnect,
  onChanged: (value) => settingsProvider.togglePauseOnOutputDisconnect(),
  secondary: Icon(isFruit ? LucideIcons.bluetooth : Icons.bluetooth_disabled_rounded),
)
```

- [ ] **Step 2: Local regression check**
Run the PWA locally (no Bluetooth needed) and verify:
  - Toggle appears in the correct settings section (general Web, not inside Gapless).
  - Toggling ON/OFF updates the UI immediately.
  - Setting persists after a page reload (open DevTools → Application → Local Storage, confirm `flutter.pause_on_output_disconnect` is written).
  - `melos run analyze` passes with no errors.
  - No visual regressions in the Settings screen.

- [ ] **Step 3: Commit**
```bash
git commit -am "feat: add auto-pause on disconnect UI toggle"
```

---

## ⛔ HUMAN GATE B — Stop here. Do not mark work complete.

**Agent instructions:** Tasks 3 and 4 are complete. Tell the user:

> "Phase 2 complete. Please publish the PWA (`.agent/workflows/publish.md`) and verify BT behavior on real hardware:
> 1. **Disconnect:** Play audio → disconnect BT headset → audio pauses within ~1s.
> 2. **Reconnect in window:** Disconnect → reconnect within 2 min → audio resumes automatically.
> 3. **Expiry:** Disconnect → wait 4+ min → reconnect → audio stays paused.
> 4. **Manual override:** Disconnect → tap Pause in app → reconnect → audio stays paused.
> 5. **Opt-out:** Toggle setting OFF → disconnect → audio continues through speaker.
> Reply with results to complete the feature."
