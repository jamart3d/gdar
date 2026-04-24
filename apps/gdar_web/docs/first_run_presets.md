# First-Run Playback Presets

Documents every playback-related preset applied automatically on first launch or when no stored preference exists. All logic lives in `SettingsProvider._init()` unless noted.

---

## Enum Reference

### `AudioEngineMode`
Defined in `gapless_player.dart`.

| Value | Description |
| :--- | :--- |
| `auto` | Platform-adaptive: resolves to `hybrid` on modern web, `html5` on low-power/mobile web, and `standard` on native |
| `webAudio` | Pure Web Audio API — best gapless, requires AudioContext to survive tab-hide |
| `html5` | HTML5 `<audio>` only — most compatible, no gapless, survives background reliably |
| `standard` | Native platform player (Android/TV) |
| `passive` | Minimal low-power engine — used internally for background-only scenarios |
| `hybrid` | Foreground WebAudio + background HTML5 handoff — best of both for most web users |

### `HybridHandoffMode`
Controls when the engine switches from HTML5 back to WebAudio after tab becomes visible.

| Value | Description |
| :--- | :--- |
| `buffered` | Waits until WebAudio has buffered the track before swapping — smooth, slight delay |
| `immediate` | Swaps to WebAudio instantly on tab-show without waiting for buffer — fastest, slight gap risk |
| `boundary` | Defers swap to the next track boundary — no mid-track swap, maximizes gaplessness |
| `none` | Handoff disabled — stays on HTML5 even when foreground |

### `HybridBackgroundMode`
Controls the survival strategy when the tab is hidden.

| Value | Description |
| :--- | :--- |
| `heartbeat` | Starts `_gdarHeartbeat.startAudioHeartbeat()` — keeps AudioContext alive via silent WA tick |
| `video` | Starts `_gdarHeartbeat.startVideoHeartbeat()` — uses a hidden `<video>` to keep process alive; most compatible on mobile browsers |
| `html5` | Falls back to HTML5 `<audio>` only; no heartbeat tricks; relies on browser to keep audio alive |
| `none` | No survival strategy — tab hide will likely suspend/kill audio |

### `HiddenSessionPreset`
Bundles `audioEngineMode + handoffMode + backgroundMode + allowHiddenWebAudio` into a named config.

| Preset | `audioEngineMode` | `handoffMode` | `backgroundMode` | `allowHiddenWebAudio` | Use case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `stability` | `hybrid` | `none` | `html5` | `false` | Mobile/unreliable browsers; max survival, no WA handoff |
| `balanced` | `hybrid` | `buffered` | `heartbeat` | `false` | Desktop browser default; good longevity without video trick |
| `maxGapless` | `hybrid` | `buffered` | `none` | `true` | Power-user preset; allows hidden WA and disables survival tricks |

### `WebEngineProfile`
One-time adaptive selection stored in `_webEngineProfileChoiceKey`.

| Profile | Assigned to | Notes |
| :--- | :--- | :--- |
| `modern` | Desktop / high-power web | Applies `balanced` preset |
| `legacy` | Low-power / mobile web | Applies `stability` preset, forces `html5` engine |

### `WebRuntimeProfile` (detection only, not persisted)
Computed each launch by `detectWebRuntimeProfile()` in `pwa_detection.dart`. Checked in order; first match wins.

| Value | HUD label | Condition |
| :--- | :--- | :--- |
| `low` | `L` | `isLikelyLowPowerWebDevice()` — mobile UA + (cores ≤ 2 OR (cores ≤ 4 AND DPR < 2.0)) |
| `pwa` | `P` | `impl.isPwa()` — display-mode standalone/fullscreen |
| `desk` | `D` | `defaultTargetPlatform` is Windows/macOS/Linux |
| `web` | `W` | All other browsers |

> `low` is checked first — a low-power PWA shows `L`, never `P`.

---

## 1. Platform Playback Defaults (no stored pref)

Applied via `_dStr` / `_dBool` helpers whenever the pref key is absent.

| Setting | Web | TV | Phone |
| :--- | :--- | :--- | :--- |
| `audioEngineMode` | `auto` | `standard` | `standard` |
| `trackTransitionMode` | `gapless` | `gapless` | `gapless` |
| `crossfadeDurationSeconds` | `3.0s` | `3.0s` | `3.0s` |
| `hybridHandoffMode` | `buffered` | — | — |
| `hybridBackgroundMode` | `heartbeat` | — | — |
| `hiddenSessionPreset` | `balanced` | — | — |
| `allowHiddenWebAudio` | `false` | — | — |
| `webPrefetchSeconds` | `30s` (or `60s` when charging gapless is active) | — | — |
| `preventSleep` | `false` | `true` | `false` |
| `playRandomOnCompletion` | `true` | `true` | `true` |
| `playRandomOnStartup` | `false` | `false` | `false` |
| `offlineBuffering` | `false` | `false` | `false` |
| `enableBufferAgent` | `true` | `true` | `true` |
| `showPlaybackMessages` | `true` | `false` (TV default) | `true` |
| `showDevAudioHud` | `true` | `true` | `true` |

> These defaults apply when no adaptive profile is triggered (§2). In practice, new web users will have these overwritten by the profile selection.

---

## 2. Adaptive Web Engine Profile (first web session only)

**Guard:** `kIsWeb && web_engine_profile_init` pref absent AND no explicit engine override stored.
**Runs once** — persists to `_webEngineProfileChoiceKey` and `_webEngineProfileInitKey`.

Device classification via `isLikelyLowPowerWebDevice()` (`web_perf_hint.dart`):
> Mobile UA **AND** (`hardwareConcurrency ≤ 2` **OR** (`hardwareConcurrency ≤ 4` **AND** `devicePixelRatio < 2.0`))

### `WebEngineProfile.modern` — desktop / high-power web

| Setting | Value | Meaning |
| :--- | :--- | :--- |
| `audioEngineMode` | `hybrid` | WebAudio foreground + HTML5 background handoff |
| `hybridHandoffMode` | `buffered` | Waits for WebAudio to buffer before swapping back from HTML5 |
| `hybridBackgroundMode` | `heartbeat` | Silent WA tick keeps AudioContext alive when hidden; escalates to `video` after 60s on mobile |
| `hiddenSessionPreset` | `balanced` | Closest preset label |
| `allowHiddenWebAudio` | `false` | WA does not play while tab is hidden (handoff to HTML5) |

> **Power profile policy:** `auto` resolves to `chargingGapless` when charging is detected and to `batterySaver` when the battery is active or the Battery Status API is unavailable. `custom` leaves manual engine settings untouched.

### `WebPlaybackPowerProfile`

Power profiles are persisted separately from `HiddenSessionPreset`. They control
the runtime Hybrid knobs used by installed Android/iOS PWA sessions.

| User Profile | Resolved Source | Engine | Handoff | Background | Hidden Web Audio | Prevent Sleep | Prefetch |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `auto` + charging detected | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60s` |
| `auto` + battery detected | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `auto` + Battery Status API unavailable | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `batterySaver` | `battery` | `hybrid` | `none` | `video` | `false` | `false` | `30s` |
| `chargingGapless` | `charging` | `hybrid` | `immediate` | `video` | `true` | `true` | `60s` |
| `custom` | `custom` | unchanged | unchanged | unchanged | unchanged | unchanged | unchanged |

### `WebEngineProfile.legacy` — low-power / mobile web

| Setting | Value | Meaning |
| :--- | :--- | :--- |
| `audioEngineMode` | `html5` | HTML5 `<audio>` only — no WebAudio at all |
| `hybridHandoffMode` | `buffered` | Stored but unused in html5-only mode |
| `hybridBackgroundMode` | `video` | Hidden `<video>` trick keeps process alive on mobile browsers |
| `hiddenSessionPreset` | `stability` | Bundles the three above + `allowHiddenWebAudio = false` |
| `allowHiddenWebAudio` | `false` | N/A in html5 mode |

---

## 3. Performance Mode Cascade (web only, first run)

Two branches — determined by `isLikelyLowPowerWebDevice()` and whether `performanceMode` pref is absent.

### Low-power device (`performanceMode` forced `true`)

**Guard:** `kIsWeb && performanceMode` pref absent AND `isLikelyLowPowerWebDevice()`.

| Setting | Forced value |
| :--- | :--- |
| `performanceMode` | `true` |
| `glowMode` | `0` (off) |
| `highlightPlayingWithRgb` | `false` |
| `fruitEnableLiquidGlass` | `false` |

Low-power devices also land on `WebEngineProfile.legacy` (§2), so they get `html5` + `video` BG mode for maximum compatibility.

### Capable device (`performanceMode` stays `false`)

No additional first-run overrides. `fruitEnableLiquidGlass` is not auto-enabled — it defaults to `false` from the stored pref (absent = `false`). The user enables it manually via Settings → Appearance.

---

## 4. Prefetch Window Auto-Tuning

Runs every launch (not just first run):

```
webPrefetchSeconds =
  powerProfile == chargingGapless → 60s
  otherwise                       → 30s
```

The 60s charging window gives WebAudio more time to prepare gapless handoff while plugged in. Battery and unknown-power sessions keep the shorter 30s window.

---

## 5. Fruit Theme Playback Reset (first Fruit switch)

**Trigger:** first switch to Fruit theme when `web_fruit_theme_init_v1` pref is absent.
**Source:** `ThemeProvider._checkAndResetFruitSettings()` → `SettingsProvider.resetFruitFirstTimeSettings()`.

| Setting | Value | Why |
| :--- | :--- | :--- |
| `performanceMode` | `true` | Fruit defaults to performance mode until opted out |
| `highlightPlayingWithRgb` | `false` | Disabled with performance mode |
| `glowMode` | `0` | Disabled with performance mode |

---

## 6. Decision Tree — Which Profile a New User Gets

```
New web user
  └── isLikelyLowPowerWebDevice()?
        ├── YES → WebEngineProfile.legacy (html5 + video BG)
        │         + preset: stability (Compatible)
        │         + performanceMode = true  → liquidGlass = false
        │         + HUD: DET=L, PWR=BAT
        └── NO  → WebEngineProfile.modern (hybrid + power profile auto + heartbeat BG)
                  + preset label: balanced
                  + performanceMode = false → liquidGlass = false (user opt-in)
                    └── power status?
                          ├── charging → chargingGapless
                          │             HUD: DET=P, PWR=CHG
                          └── battery/unknown → batterySaver
                                        HUD: DET=P, PWR=BAT
```

Returning user with prefs stored: adaptive profile, low-power detection, and liquid glass defaults are all skipped — stored values win.

---

## 7. Background Longevity — Engine Ranking

How well each engine/config keeps playing when the tab is hidden on a lower/mobile device.

### Survival ranking (most → least durable)

| Rank | Config | Why |
| :---: | :--- | :--- |
| 1 | `hybrid` + `chargingGapless` + `video` | Best background survival and fastest gapless restore when the app is visible again. |
| 2 | `hybrid` + `batterySaver` + `video` | Strong background survival with the battery-safe hybrid path. |
| 3 | `hybrid` + `heartbeat` | Heartbeat keeps the AudioContext warm, but mobile browsers can still suspend it. |
| 4 | `webAudio` + no survival | Gapless while visible, but no hidden playback survival path. |
| 5 | `webAudio` hidden (`allowHiddenWebAudio=true`) | No hidden playback survival path on mobile. |

> On desktop browsers ranks 1–4 are roughly equivalent — desktop doesn't throttle hidden tabs aggressively. The ranking matters most on Android Chrome and mobile Safari.

### How `webPrefetchSeconds` (PF) behaves per engine

`PF` fires on all engines but what it achieves varies:

| Engine | Effect |
| :--- | :--- |
| `webAudio` | Full gapless — next track pre-scheduled into AudioContext. Uses `-1` (greedy). |
| `hybrid` | Gapless at handoff boundary — HTML5 pre-buffers next track while WA plays. PF=60 gives boundary handoff time to fully load. |
| `html5` | Reduces startup gap only — next track begins loading early but HTML5 always has a gap between tracks. No true gapless possible. |

---

## 8. Hidden Session Preset — Is the Setting Still Needed?

### Current state

The Settings → Playback "Hidden Session Preset" picker still exposes the three
named bundles (`stability`, `balanced`, `maxGapless`) directly. The names are
developer-oriented and do not clearly communicate the battery-safe versus
charging-gapless split.

### Should it change?

The adaptive profile (§2) now picks a sensible default for every user type
(low-power, installed PWA, desktop). The preset exists for power-user override.
The question is whether the current options and names are the right framing.

**Option A — Reframe as a longevity/compatibility scale:**

Replace the three abstract names with a ranked scale that matches the survival ranking above:

| New label | Maps to | Engine + config |
| :--- | :--- | :--- |
| Compatible | `batterySaver` | `hybrid` + `video` BG — battery-safe and survival-first |
| Charging Gapless | `chargingGapless` | `hybrid` + `video` BG + immediate handoff — best gapless while charging |
| Custom | `custom` | Manual engine values are preserved |

The setting stays as three options, just renamed and reordered from most compatible → most gapless. No code changes to the preset bundles themselves — only UI label strings change.

**Option B — Add a fourth option: `html5` (Pure Compatible):**

For users on unreliable connections or very low-end devices, pure HTML5 with no hybrid overhead may outlast even `hybrid+video`. A fourth option covering `audioEngineMode=html5` would complete the ranking. Downside: four options may be too many for a simple user setting.

**Option C — Remove the setting; let adaptive profile handle it:**

If the adaptive profile (§2) is trusted to pick correctly, the only users who need to change this are those debugging or with edge-case devices. Move it to a developer/advanced section rather than main playback settings.

### Recommendation

**Option A** is the lowest-effort path and directly maps to the longevity ranking. Rename in the UI without changing any preset logic. Reorder the picker to go compatible → gapless so it reads as a tradeoff selector. Consider adding a brief description line under each option explaining the background behaviour.

---

## 9. Suggestions for Improving Defaults

### S1 — Keep PWA installs on power profile auto
**Current:** Installed PWA launches start in Hybrid on non-low-power devices, then
resolve to `batterySaver` or `chargingGapless` based on power state.
**Problem:** The remaining question is not whether PWA should force `webAudio`,
but how visibly the power profile choice should be surfaced in the UI.
**Suggestion:** Keep the adaptive selection on `auto` and document the `BAT` /
`CHG` HUD chips clearly so users understand why playback behavior changes
without a relaunch.

### S2 — Consider `boundary` handoff mode for custom/manual profiles
**Current:** `batterySaver` disables handoff and `chargingGapless` uses
`immediate`. Manual users can still choose `boundary`.
**Problem:** `boundary` can reduce mid-track handoff risk, but it is not the
current default for power profiles.
**Suggestion:** Keep `batterySaver` and `chargingGapless` simple. If users need
more control, expose `boundary` as a documented custom/manual option.

### S3 — `performanceMode` should not force `stability` preset on Fruit first-run
**Current:** Fruit first-run sets `performanceMode = true`, but does not touch the audio preset. On a `modern`-profile device this leaves them on `balanced` (heartbeat), which is fine. But the combo is invisible in the HUD.
**Suggestion:** No code change needed — but document that `performanceMode` and `hiddenSessionPreset` are orthogonal. A `PM` chip in the HUD (showing `ON`/`OFF` for `performanceMode`) would make this visible to developers debugging Fruit sessions.

### S4 — Prefetch window should scale with power profile
**Current:** `webPrefetchSeconds = 30` for `batterySaver` and `60` for
`chargingGapless`.
**Problem:** The current split is intentionally simple, but it still hides the
reason behind the longer charging window from users.
**Suggestion:** If this needs more granularity later, expose the value as a
profile-specific setting rather than tying it to a generic prefetch slider.

### S5 — `video` background mode fallback for `batterySaver` on mobile browsers
**Current:** `batterySaver` uses `video` background survival, but some mobile
browsers still throttle hidden playback if the tab is starved of resources.
**Problem:** Even the strongest keepalive signal can lose against RAM pressure
or aggressive vendor battery policy.
**Suggestion:** If this becomes a support issue, document the kill conditions
more prominently instead of changing the default profile.
