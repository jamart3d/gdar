# First-Run Playback Presets

Documents every playback-related preset applied automatically on first launch or when no stored preference exists. All logic lives in `SettingsProvider._init()` unless noted.

---

## Enum Reference

### `AudioEngineMode`
Defined in `gapless_player.dart`.

| Value | Description |
| :--- | :--- |
| `auto` | Platform-adaptive: resolves to `hybrid` on web (via profile detection), `standard` on native |
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
| `stability` | `hybrid` | `buffered` | `video` | `false` | Mobile/unreliable browsers; max survival, no WA in background |
| `balanced` | `hybrid` | `buffered` | `heartbeat` | `false` | Desktop browser default; good longevity without video trick |
| `maxGapless` | `webAudio` | `immediate` | `heartbeat` | `true` | Power-user / PWA installed; full gapless, allows WA hidden |

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
| `webPrefetchSeconds` | `30s` (or `-1` if WebAudio mode) | — | — |
| `preventSleep` | `false` | `true` | `false` |
| `playRandomOnCompletion` | `true` | `true` | `true` |
| `playRandomOnStartup` | `false` | `false` | `false` |
| `offlineBuffering` | `false` | `false` | `false` |
| `enableBufferAgent` | `true` | `true` | `true` |
| `showPlaybackMessages` | `true` | TV default | `true` |
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
| `hybridHandoffMode` | `boundary` | Defers WA restore to next track boundary — no mid-track swap |
| `hybridBackgroundMode` | `heartbeat` | Silent WA tick keeps AudioContext alive when hidden; escalates to `video` after 60s on mobile |
| `hiddenSessionPreset` | `balanced` | Closest preset label (note: handoff is `boundary`, not `buffered` as the preset normally implies) |
| `allowHiddenWebAudio` | `false` | WA does not play while tab is hidden (handoff to HTML5) |

> **PWA override:** if `isPwa()` is true on a modern-profile device, `maxGapless` is applied on top (`webAudio + immediate + allowHiddenWebAudio=true`). See §6.

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
  audioEngineMode == WebAudio  → -1 (greedy)
  hybridHandoffMode == boundary → 60s
  otherwise                    → 30s
```

If the stored pref disagrees with this calculation, it is silently corrected. The 60s window for `boundary` mode ensures the next track is fully buffered before the track boundary arrives.

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
        │         + HUD: DET=L
        └── NO  → WebEngineProfile.modern (hybrid + boundary handoff + heartbeat BG)
                  + preset label: balanced
                  + performanceMode = false → liquidGlass = false (user opt-in)
                    └── isPwa()?
                          ├── YES → maxGapless override (webAudio + immediate + allowHiddenWebAudio=true)
                          │         HUD: DET=P
                          └── NO  → HUD: DET=D (desktop) or DET=W (browser)
```

Returning user with prefs stored: adaptive profile, low-power detection, and liquid glass defaults are all skipped — stored values win.

---

## 7. Background Longevity — Engine Ranking

How well each engine/config keeps playing when the tab is hidden on a lower/mobile device.

### Survival ranking (most → least durable)

| Rank | Config | Why |
| :---: | :--- | :--- |
| 1 | `hybrid` + `backgroundMode=video` | Silent `<video>` loop is the strongest keepalive signal to Chrome Android. Belt-and-suspenders with HTML5 `<audio>` still active. |
| 2 | `html5` (pure) | `<audio>` element alone. Browser designed to keep media audio alive. Lowest resource cost — no extra tricks, no extra failure modes. |
| 3 | `hybrid` + `backgroundMode=heartbeat` | Silent Web Audio tick can itself be suspended by mobile browser. Less reliable than video on Android. Auto-escalates to video at 60s (S5). |
| 4 | `hybrid` + `backgroundMode=html5` | Same survival as pure HTML5 but carries full hybrid engine overhead for no gain in background. |
| 5 | `webAudio` hidden (`allowHiddenWebAudio=true`) | AudioContext almost always suspended within seconds on mobile when hidden. Worst longevity. |

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

The Settings → Playback "Hidden Session Preset" picker exposes three named bundles (`stability`, `balanced`, `maxGapless`) directly. The names are developer-oriented and don't communicate longevity vs gapless tradeoffs to a user.

### Should it change?

The adaptive profile (§2) now picks a sensible default for every user type (low-power, PWA, desktop). The preset exists for power-user override. The question is whether the current options and names are the right framing.

**Option A — Reframe as a longevity/compatibility scale:**

Replace the three abstract names with a ranked scale that matches the survival ranking above:

| New label | Maps to | Engine + config |
| :--- | :--- | :--- |
| Compatible | `stability` | `hybrid` + `video` BG — best longevity, gapless only when visible |
| Balanced | `balanced` | `hybrid` + `heartbeat` BG + 60s video escalation — good longevity + gapless |
| Gapless | `maxGapless` | `webAudio` + `allowHiddenWebAudio=true` — best gapless, needs strong browser |

The setting stays as three options, just renamed and reordered from most compatible → most gapless. No code changes to the preset bundles themselves — only UI label strings change.

**Option B — Add a fourth option: `html5` (Pure Compatible):**

For users on unreliable connections or very low-end devices, pure HTML5 with no hybrid overhead may outlast even `hybrid+video`. A fourth option covering `audioEngineMode=html5` would complete the ranking. Downside: four options may be too many for a simple user setting.

**Option C — Remove the setting; let adaptive profile handle it:**

If the adaptive profile (§2) is trusted to pick correctly, the only users who need to change this are those debugging or with edge-case devices. Move it to a developer/advanced section rather than main playback settings.

### Recommendation

**Option A** is the lowest-effort path and directly maps to the longevity ranking. Rename in the UI without changing any preset logic. Reorder the picker to go compatible → gapless so it reads as a tradeoff selector. Consider adding a brief description line under each option explaining the background behaviour.

---

## 9. Suggestions for Improving Defaults

### S1 — Upgrade PWA installs to `maxGapless` on first run
**Current:** PWA installs land on `modern` profile (`balanced` preset, `allowHiddenWebAudio = false`).
**Problem:** Installed PWAs have much better background audio longevity than tab browsers. The `balanced` preset's conservative `allowHiddenWebAudio = false` forces an HTML5 handoff on every tab-hide, breaking gapless.
**Suggestion:** In the adaptive profile selection, check `isPwa()` after the low-power test and apply `HiddenSessionPreset.maxGapless` (`webAudio` + `immediate` handoff + `allowHiddenWebAudio = true`) for PWA installs on non-low-power devices.

### S2 — Use `boundary` handoff mode for `modern` profile
**Current:** `modern` → `HybridHandoffMode.buffered` — waits for WA buffer, then mid-track swaps back to WA.
**Problem:** Mid-track swaps create a noticeable artifact (brief silence or pop at swap point) even with crossfade.
**Suggestion:** Change `modern` default to `HybridHandoffMode.boundary` — defer the WA restore until the next track boundary. Pure gapless is preserved and no mid-track interruption occurs. Only trade-off: WA resumes at next track, not immediately on tab-show.

### S3 — `performanceMode` should not force `stability` preset on Fruit first-run
**Current:** Fruit first-run sets `performanceMode = true`, but does not touch the audio preset. On a `modern`-profile device this leaves them on `balanced` (heartbeat), which is fine. But the combo is invisible in the HUD.
**Suggestion:** No code change needed — but document that `performanceMode` and `hiddenSessionPreset` are orthogonal. A `PM` chip in the HUD (showing `ON`/`OFF` for `performanceMode`) would make this visible to developers debugging Fruit sessions.

### S4 — Prefetch window should scale with handoff mode
**Current:** `webPrefetchSeconds = 30` for all non-WebAudio modes regardless of `handoffMode`.
**Problem:** With `boundary` handoff, the app needs to buffer the *next* track ahead of the current one to guarantee gapless at boundary. 30s may not be enough on slow connections.
**Suggestion:** When `handoffMode == boundary`, increase default to 45s or expose it as a separate `boundaryPrefetchSeconds` preference, defaulting higher.

### S5 — `video` background mode fallback for `modern` on mobile browsers
**Current:** `modern` profile uses `heartbeat` BG mode. On Chrome for Android (non-low-power flagship), heartbeat may not keep the AudioContext alive past ~60s.
**Problem:** Flagship phones with 8 cores and DPR ≥ 2.0 pass the `isLikelyLowPowerWebDevice()` test and get `modern`, but Chrome Android is still aggressive about suspending hidden AudioContexts.
**Suggestion:** In `_applyWebEngineProfile`, check `DeviceService.isMobile` (or UA mobile flag). If `modern` + mobile browser, set `backgroundMode = video` instead of `heartbeat`. This is what `stability` does and it's more reliable on Android Chrome.
