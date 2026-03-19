# Web UI Audio Engines & Audio HUD

This doc describes the current web audio engine stack, how runtime engine
selection works, how the Audio HUD reflects active state, and which Playback
settings affect the web path.

## Current Engine Stack

The web app can run one of these engine modes:

- `auto`: persisted preference only; resolves at runtime.
- `webAudio`: pure Web Audio engine.
- `html5`: HTML5 streaming engine.
- `hybrid`: hybrid orchestrator that starts in HTML5 and hands off to Web
  Audio when possible.
- `standard`: disables the custom JS engines and falls back to `just_audio`.
- `passive`: supported in the enum/JS bootstrap, but not exposed in the main
  Web settings UI.

On the Dart side, `GaplessPlayer` uses the JS engine whenever the resolved
strategy is not `standard`.

## Runtime Resolution

The runtime selector lives in `apps/gdar_web/web/hybrid_init.js`.

Resolution rules today:

- Explicit stored override wins for any value except `auto`.
- `standard` short-circuits JS engine selection entirely.
- Chromebook (`CrOS`) resolves to `webAudio`.
- Mobile/tablet-like environments resolve to `html5`.
- Desktop defaults to `hybrid`.
- If the preferred engine is unavailable, bootstrap falls back to another
  loaded engine unless the user explicitly requested `webAudio`.

Important consequence:

- `audioEngineMode = auto` does not mean a unique runtime engine.
- On desktop it normally resolves to `hybrid`.
- On mobile/tablet it normally resolves to `html5`.

The resolved runtime strategy is exposed to Dart through:

- `_shakedownAudioStrategy`
- `_shakedownAudioReason`

`GaplessPlayer.activeMode` maps that resolved strategy back into the Dart enum.

## Web Defaults and Adaptive Profile

Web defaults currently come from `WebDefaults` plus one-time adaptive profile
logic in `SettingsProvider`.

Current defaults:

- `WebDefaults.audioEngineMode = auto`
- `WebDefaults.useNeumorphism = true`
- `WebDefaults.performanceMode = true`
- `WebDefaults.useOilScreensaver = false`
- `WebDefaults.showSplashScreen = false`

On first web initialization, if the user has not already made an explicit
engine choice, `SettingsProvider` applies an adaptive web profile:

- `modern`
  - `hiddenSessionPreset = balanced`
  - `audioEngineMode = hybrid`
  - `hybridHandoffMode = buffered`
  - `hybridBackgroundMode = heartbeat`
  - `allowHiddenWebAudio = false`
  - `hybridForceHtml5Start = true`
- `legacy`
  - `hiddenSessionPreset = stability`
  - `audioEngineMode = html5`
  - `hybridHandoffMode = buffered`
  - `hybridBackgroundMode = video`
  - `allowHiddenWebAudio = false`
  - `hybridForceHtml5Start = true`

This adaptive profile is only applied once unless the user clears settings.

## Engine Selector in Playback Settings

The Playback settings selector writes `SettingsProvider.audioEngineMode`.

Main Web UI options:

- `Web Audio`
- `HTML5`
- `Hybrid`

Notes:

- `auto` is persisted in state and exists in the enum, but is not shown in the
  main Playback selector.
- `standard` and `passive` are not shown in the main Web selector.
- The HUD can still display the resolved engine when the stored setting is
  `auto`.

## Audio HUD Behavior

The Audio HUD is driven by `AudioProvider.currentHudSnapshot`, which is built
from both settings state and runtime JS engine state.

### Layout & Appearance

The HUD uses an **"Ultra-High-Density" (UHD)** layout optimized for professional real-time diagnostics:

- **Stacked Performance Columns:** To prevent layout "jitter," performance chips use a **fixed-width slot (84px)** that perfectly aligns with the four sparkline types (`DFT`, `HD`, `BUF`, `NX`). This creates vertical columns for real-time visual-to-numeric correlation.
- **Sparkline Suite:** The top row contains four real-time trend graphs, each with a **tiny integrated label** (`DFT`, `HD`, `BUF`, `NX`) in the lower corner.
- **Status & Messaging Row:** The bottom row is reserved for logic signals (`SIG`) and detailed engine messages (`MSG`), using an automatic scrolling **Marquee** for text over 30 characters.
- **Horizontal Heartbeat:** Background performance status is indicated by a **horizontal traffic-light pulse** integrated directly into the `BG` (Background) performance chip.
- **Environmental Context:** The `DET` (Detection) chip is compacted to **52px** to preserve space for telemetry while showing the detected hardware profile.

For a comprehensive guide to performance tuning and metric definitions, see [DevAudioHud: Advanced Diagnostic Interface](dev_audio_hud.md).

### HUD Abbreviations

Common diagnostic chips (organized by their diagnostic columns):

- `DFT`: state tick drift (seconds since last update)
- `HD`: headroom remaining (seconds)
- `BUF`: current buffered amount (MB or 0B)
- `NX`: next-track prefetch progress
- `PF`: prefetch threshold toggle (30s vs 60s)
- `HF`: hybrid handoff mode (imm, buf, bnd, off)
- `BG`: hybrid survival mode (h5, hb, vid, none) + heartbeat pulse
- `STB`: hidden-session preset (STB, BAL, MAX)
- `ENG`: effective engine mode (WBA, H5, HYB, STD)
- `DET`: detected profile label (L, P, D, W)
- `AE`: Active engine context. Variants: **`-New`** (Native), **`-Opt`** (Optimized). A pulsing **standard plus (`+`)** and **Indigo background** indicate active survival mode. The pulse is precisely synced (220ms) with the `BG` heartbeat indicator.
- `V`: visibility status and hidden duration (VIS, HID)
- `E`: error state flag
- `ST`: raw engine status code
- `SIG`: signal source (AGT, ISS, NTF or --)
- `MSG`: message content (clears on tap)

### Interactive HUD Controls
Tapping these chips opens a popup menu to adjust engine behavior on-the-fly:
- `ENG`, `HF`, `BG`, `STB`, `PF`

### Messaging & Signals (Bottom Row)

The bottom row is reserved for status signals and detailed messages:

- `SIG`: **Signal Source** (Fixed-width slot)
  - `ISS`: **Issue** - Active playback error or warning.
  - `NTF`: **Notification** - System-level informational update.
  - `AGT`: **Agent** - Engine or orchestrator status (e.g., handoff alerts).
  - `--`: **Default** - No active signal.
- `MSG`: **Message Content** (Expanded to fill row)
  - Automatically displays as a scrolling **Marquee** if the text exceeds 30
    characters.

#### Message Clearing Logic

- **Manual:** Tapping the `MSG` chip manually triggers
  `AudioProvider.clearLastIssue()`.
- **Automatic:** Notifications (`NTF`) clear after 5–8 seconds. Agent messages
  (`AGT`) clear automatically when the engine state resolves.
- **Stop:** All messages are cleared when playback is stopped.

### Effective Mode in HUD

The HUD uses this rule:

- if `SettingsProvider.audioEngineMode == auto`, show the resolved runtime mode
  from `audioPlayer.activeMode`
- otherwise, show the explicitly stored mode

That means the HUD is currently the clearest place to see what engine is really
running when the stored preference is `auto`.

## Hybrid Engine Runtime Behavior

The hybrid orchestrator lives in `apps/gdar_web/web/hybrid_audio_engine.js`.

Current behavior:

- Foreground engine: Web Audio
- Background/instant-start engine: HTML5
- Startup normally prefers HTML5 instant start unless the strategy is locked to
  pure `webAudio`
- Web Audio is prepared in parallel and may take over later depending on
  handoff mode and track conditions

### Handoff Modes

Stored in `SettingsProvider.hybridHandoffMode` and synced to JS.

Current supported modes:

- `immediate`: hand off to Web Audio as soon as foreground is ready
- `buffered`: stay on HTML5 until long-track buffer exhaustion approaches, then
  swap to Web Audio
- `boundary`: defer Web Audio swap to the next track boundary
- `none`: stay on HTML5 and disable Web Audio handoff

Additional current runtime rules:

- Short tracks under about 15 seconds stay on HTML5.
- Long-track buffered handoff logic uses worker ticks and emits
  `handoff_countdown` before swapping.
- If Web Audio stalls for more than 5 seconds while active, hybrid falls back
  to HTML5.
- If Web Audio is suspended by the OS while playing, hybrid marks the state as
  `suspended_by_os` and performs a failure handoff to HTML5.

### Background Survival Strategy

Stored in `SettingsProvider.hybridBackgroundMode` and synced to JS.

Current supported values:

- `html5`: rely on HTML5/background handoff without heartbeat tricks
- `heartbeat`: start the audio heartbeat helper when hidden
- `video`: start the video heartbeat helper when hidden
- `none`: no survival trick

### Allow Web Audio While Hidden

Stored in `SettingsProvider.allowHiddenWebAudio` and synced to JS.

Current behavior:

- if enabled, hybrid is allowed to keep Web Audio active while hidden
- if disabled, hybrid favors handing off away from Web Audio when hidden

Hidden-tab behavior is platform-sensitive:

- on mobile-like devices, hybrid pre-emptively swaps to HTML5 when hidden if
  hidden Web Audio is not allowed
- on desktop, hybrid typically fences the handoff until the next track boundary

### Handoff Crossfade

Stored in `SettingsProvider.handoffCrossfadeMs` and synced to JS.

Current behavior:

- valid range is 0 to 200 ms
- `0` disables crossfade and stops HTML5 immediately on swap
- values above `0` create a short fade between HTML5 and Web Audio during
  foreground restore

## Track Transition Mode and Prefetch

### Track Transition Mode

`SettingsProvider.trackTransitionMode` is still present and is synced to JS.
Current supported values are:

- `gap`
- `gapless`

In practice, web is treated as gapless-first and the current settings UI no
longer emphasizes transition switching.

### Prefetch Window

`SettingsProvider.webPrefetchSeconds` is used to determine how far in advance the 
next track buffer is opened.

- **Greedy (-1)**: Triggered automatically when `audioEngineMode == webAudio`. 
  Attempts to prefetch as much as possible for maximum gapless reliability.
- **User-Tunable**: Toggleable via the `PF` chip in the HUD between **30s** and **60s**.
- Default behavior: Starts at 30s but can be overridden on-the-fly for poor 
  network conditions.

## Hidden Session Presets

`SettingsProvider.hiddenSessionPreset` sets multiple fields together.

Current preset mappings:

### `stability`

- `audioEngineMode = hybrid`
- `hybridHandoffMode = buffered`
- `hybridBackgroundMode = video`
- `allowHiddenWebAudio = false`
- `hybridForceHtml5Start = true`

### `balanced`

- `audioEngineMode = hybrid`
- `hybridHandoffMode = buffered`
- `hybridBackgroundMode = heartbeat`
- `allowHiddenWebAudio = false`
- `hybridForceHtml5Start = true`

### `maxGapless`

- `audioEngineMode = webAudio`
- `hybridHandoffMode = immediate`
- `hybridBackgroundMode = heartbeat`
- `allowHiddenWebAudio = true`
- `hybridForceHtml5Start = false`

## Known Mismatch in Current Project State

`hybridForceHtml5Start` exists in:

- defaults
- adaptive profile logic
- hidden-session presets
- `SettingsProvider`
- `AudioProvider` sync
- Dart JS interop surface

But the current JS hybrid engine does not implement a corresponding
`setHybridForceHtml5Start` method, and bootstrap logic does not appear to use
that setting directly.

Practical implication:

- the setting exists in app state
- the setting is documented in presets
- the setting is not currently a reliable JS runtime control

Until it is wired through, treat it as an incomplete setting rather than a
stable behavior guarantee.

## Current Playback Settings That Affect Web Audio

The Web Playback section currently affects these runtime controls:

- Engine selection -> `audioEngineMode`
- Hidden Session Preset -> multiple engine-related fields
- Hybrid Handoff Mode -> `hybridHandoffMode`
- Background Survival Strategy -> `hybridBackgroundMode`
- Allow Web Audio while hidden -> `allowHiddenWebAudio`
- Handoff Crossfade -> `handoffCrossfadeMs`
- Track transition mode still exists in state and sync logic, but is not a
  primary user-facing web control anymore

## Current Caveats

- `auto` is a stored preference, not a distinct runtime engine.
- Default desktop behavior still often ends up on hybrid even if the UI shows
  `auto` elsewhere.
- Some advanced hybrid controls are easier to understand from the HUD than from
  the main settings screen.
- `?flush=true` currently clears all `localStorage` for the origin, not just
  GDAR keys.
