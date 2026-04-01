# TV Screensaver — Architecture & Settings Reference

**Project:** gdar_tv — Steal Your Face Screensaver  
**Updated:** 2026-03-31  
**Status:** Implemented and shipping  

---

## Overview

The TV screensaver is a full-screen animated "Steal Your Face" (SYF)
visualizer that launches after a configurable period of user inactivity.
It is a pure Flutter widget tree — no Android `DreamService` — rendered by
the `StealVisualizer` backed by a `StealConfig` value object that holds
70+ tunable parameters.

There is a single screensaver implementation (SYF / "Oil"). The
`useOilScreensaver` boolean controls whether idle-triggered launch is
enabled at all. When disabled, no screensaver launches.

---

## Architecture Layers

```
┌─────────────────────────────────────────────────────────────────────┐
│                          gdar_tv  (app)                             │
│  main.dart → InactivityDetector → ScreensaverLaunchDelegate        │
└───────────────────────────────┬─────────────────────────────────────┘
                                │
┌───────────────────────────────▼─────────────────────────────────────┐
│                    shakedown_core  (package)                        │
│                                                                     │
│  SERVICES                                                           │
│    InactivityService          – polling countdown, fires callback   │
│    ScreensaverLaunchDelegate  – typedef wrapping the launch fn     │
│    WakelockService            – keeps display on during playback   │
│                                                                     │
│  PROVIDERS                                                          │
│    SettingsProvider                                                  │
│      └─ _SettingsProviderScreensaverExtension (mixin)               │
│           78 SharedPreferences keys → getters + setters             │
│                                                                     │
│  UI — SCREENS                                                       │
│    TvSettingsScreen           – dual-pane: nav list ↔ content pane  │
│    ScreensaverScreen          – full-screen visualizer host         │
│                                                                     │
│  UI — WIDGETS (settings)                                            │
│    TvScreensaverSection       – root StatefulWidget (3 part files)  │
│      part: tv_screensaver_section_build.dart       (main build)     │
│      part: tv_screensaver_section_audio_build.dart  (perf + audio)  │
│      part: tv_screensaver_section_controls.dart     (segmented UI)  │
│    TvScreensaverPreviewPanel  – live preview visualizer in left nav │
│                                                                     │
│  RENDERING                                                          │
│    StealConfig                – immutable config value object        │
│    StealVisualizer            – CustomPainter rendering engine       │
│    StealGraph                 – procedural SYF logo geometry        │
│    StealBackground            – animated gradient background        │
│    StealBanner                – ring/flat text overlay               │
│    StealGame                  – logo movement & trail logic         │
│                                                                     │
│  AUDIO REACTIVITY                                                   │
│    AudioReactorFactory        – creates right reactor per platform  │
│    VisualizerAudioReactor     – FFT / PCM capture bridge            │
│    AudioReactor (abstract)    – beat + spectrum interface            │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Persistence — SettingsProvider

All screensaver state is persisted via `SharedPreferences` through a
`part`-file mixin on `SettingsProvider`:

| File | Role |
|---|---|
| [settings_provider_screensaver.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/providers/settings_provider_screensaver.dart) | 78 pref keys, field declarations, typed getters + setters |
| [default_settings.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/config/default_settings.dart) | Base + per-platform defaults (`TvDefaults`, `WebDefaults`, `PhoneDefaults`) |

**Key design decisions:**

- **No enum-based screensaver type.** The original Phase 0 proposed a
  `ScreensaverType` enum (`stealYourFace` / `sheep`). This was never
  implemented — there is only `useOilScreensaver` (bool).
- **No `ScreensaverSettings` class or `ScreensaverRouter`.** All
  persistence is handled by the unified `SettingsProvider`.
- Settings that accept string-coded enums (palette, display mode, beat
  detector mode, font) use `_updateStringPreference` with hardcoded
  valid values enforced in the UI segmented buttons.
- Clamped ranges are enforced at the setter level
  (e.g., `oilBeatSensitivity` ∈ [0.0, 1.0]).

### TV-Specific Defaults

`TvDefaults` overrides the base `DefaultSettings` for TV:

| Setting | Base Default | TV Override |
|---|---|---|
| `oilPerformanceLevel` | `0` (High) | `1` (Balanced) |
| `preventSleep` | `false` | `true` |
| `oilAutoTextSpacing` | `true` | `true` |
| `oilAutoRingSpacing` | `true` | `true` |
| `showPlaybackMessages` | `true` | `false` |

---

## Inactivity Detection & Auto-Launch

### InactivityService

[inactivity_service.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/services/inactivity_service.dart)

| Aspect | Detail |
|---|---|
| **Strategy** | 1-second polling timer comparing wall-clock time since last activity |
| **Timeout options** | 1 min, 5 min, 15 min (enforced in setter) |
| **Activity sources** | D-pad keys, selection keys, media keys, pointer-down events |
| **Fire behavior** | Fires once per inactivity window; re-arms on next user activity |
| **Debug overlay** | `debugCountdown` ValueNotifier emits countdown string |

### InactivityDetector Widget

Wraps the app widget tree. Listens to `HardwareKeyboard` globally and
`Listener.onPointerDown` for touch. Filters out hover/move noise that would
keep the timer alive on real TV hardware.

### ScreensaverLaunchDelegate

```dart
typedef ScreensaverLaunch =
    Future<void> Function({bool allowPermissionPrompts});
```

A thin indirection so the app's `main.dart` can wire up
`ScreensaverScreen.show(context)` as the launch function. The delegate
also gates permission prompts (`allowPermissionPrompts`) for non-interactive
screensaver launches (e.g., from inactivity timeout).

---

## TV Settings Screen — Screensaver Panel

### Layout

`TvSettingsScreen` is a **dual-pane** layout:

- **Left pane (flex: 1):** Category list + live preview panel
  (`TvScreensaverPreviewPanel`) visible when "Screensaver" is selected.
- **Right pane (flex: 2):** Active settings section, scrollable.

### TvScreensaverSection — Settings Groups

The section is a `StatefulWidget` split across 3 `part` files for
maintainability. It builds 6 collapsible groups via `_buildSectionChildren`:

#### 1. System

| Control | Type | Key |
|---|---|---|
| Prevent Sleep | Toggle | `preventSleep` |
| Shakedown Screen Saver | Toggle | `useOilScreensaver` |
| Inactivity Timeout | SegmentedButton (1/5/15 min) | `oilScreensaverInactivityMinutes` |
| Start Screen Saver | Action tile | Launches via `ScreensaverLaunchDelegate` |

#### 2. Visual

| Control | Type |
|---|---|
| Color Palette | Animated palette picker (7 palettes) |
| Flat Color Mode | Toggle |
| Auto Palette Cycle | Toggle |
| Logo Scale | Stepper (10%–100%) |
| Trail Intensity | Stepper (0%–100%) |
| Dynamic Trails | Toggle |
| Trail Slices | Stepper (2–16) |
| Trail Spread | Stepper |
| Trail Initial Scale | Stepper (50%–200%) |
| Trail Decay Scale | Stepper |
| Logo Blur | Stepper |
| Motion Smoothing | Stepper |
| Flow Speed | Stepper |
| Pulse Intensity | Stepper |
| Heat Drift | Stepper |
| Sine Wave Drive | Toggle + freq/amp sub-controls |

#### 3. Track Info

| Control | Type |
|---|---|
| Show Track Info | Toggle |
| Display Style | SegmentedButton (Ring / Flat) |
| Banner Font | SegmentedButton (Rock Salt / Roboto) |
| Text Resolution | Stepper (1x–4x supersampling) |
| Auto Spacing / Auto Arc Spacing | Toggle |
| Letter Spacing, Word Spacing | Steppers (when auto-spacing off) |
| **Ring mode sub-controls** | Inner Ring Size, Title/Venue gaps, Orbit Drift, 3-ring font sizes, 3-ring spacings, Track letter/word spacing |
| **Flat mode sub-controls** | Text Placement (Above/Below), Text Proximity, Line Spacing |
| Neon Glow | Toggle + Flicker + Glow Blur sub-controls |

#### 4. Audio Reactivity

| Control | Type |
|---|---|
| Enable Audio Reactivity | Toggle (triggers permission flow) |
| Reactivity Strength | Stepper |
| Bass Boost | Stepper |
| Peak Decay | Stepper (0.990–0.999) |
| Beat Detector | SegmentedButton (Auto/Hybrid/Bass/Mid/Broad/Enhanced) |
| Beat Sensitivity | Stepper |
| Beat Impact | Stepper |
| Audio Graph | SegmentedButton (Off/Corner/Corner Only/Circular/EKG/Circ EKG/VU/Scope/Beat Debug) |
| EKG sub-controls | Radius, Line Replication, Line Spread |

#### 5. Frequency Isolation

| Control | Type |
|---|---|
| Logo Scale Source | Band selector (NONE/DEF/0-7) |
| Scale Multiplier | Stepper (0.1x–2.0x) |
| Logo Color Source | Band selector (NONE/DEF/0-7) |
| Color Pulse Multiplier | Stepper (0.0x–2.0x) |

#### 6. Performance

| Control | Type |
|---|---|
| Rendering Quality | SegmentedButton (HIGH/BALANCED/FAST) |
| Logo Anti-Aliasing | Toggle |

### D-Pad Focus Wrapping

The section implements focus wrapping: pressing **Up** on the first
control wraps to the last, and **Down** on the last wraps to the first.
`Scrollable.ensureVisible` keeps the wrapped target on-screen.

### Live Preview Panel

`TvScreensaverPreviewPanel` renders a miniature `StealVisualizer` in a
16:9 `AspectRatio` with rounded corners. It creates its own
`AudioReactor` to show real-time audio-reactive preview. Text banners are
disabled in preview mode (`showInfoBanner: false`).

---

## ScreensaverScreen — Full-Screen Rendering

[screensaver_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/screens/screensaver_screen.dart)

### Lifecycle

1. **Launch:** Pushed as a `PageRouteBuilder` with 800ms fade-in
   transition on route name `screensaver`.
2. **Audio reactor init:** Creates a `VisualizerAudioReactor` via
   `AudioReactorFactory.create()`. Handles microphone permission flow
   with a guard preventing key events from dismissing the permission
   dialog.
3. **Session ID retry:** If the initial `androidAudioSessionId` is null
   or 0 (audio hasn't started yet), retries up to 10 times at 2-second
   intervals.
4. **Config sync:** On every `build()`, reads all settings and
   constructs a fresh `StealConfig`. Pushes audio-specific config
   (`peakDecay`, `bassBoost`, etc.) only when values change.
5. **Enhanced audio capture:** Stereo PCM capture via
   `MediaProjection` is only requested when beat detector mode is
   explicitly set to `'pcm'` (Enhanced). Other modes use the cheaper
   FFT path and avoid the system share-screen prompt.
6. **Device-aware 4K limiting:** On known low-end TV dongles
   (e.g. 2020 Chromecast with Google TV, codename `sabrina`),
   the visualizer renders at 1920×1080 inside a `FittedBox`
   when the screen exceeds 1080px. Capable devices render at
   native resolution.
7. **Exit:** Any `KeyDownEvent` pops the route (unless a permission
   dialog is active). `WakelockService` is disabled on dispose.

### Song Structure Hints

The screensaver loads a `SongStructureHintCatalog` at init and
matches the current playing track title to find a
`SongStructureHintEntry`. This seed influences procedural generation
parameters (variant, confidence) for per-song visual identity.

---

## StealConfig — The Config Value Object

[steal_config.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_config.dart)

An immutable Dart class with 70+ named parameters. Supports:
- `const` default constructor
- `fromMap()` / `toMap()` serialization
- `copyWith()` for partial updates
- Value equality (`operator ==` and `hashCode`)

### Available Palettes

| Key | Colors |
|---|---|
| `psychedelic` | Magenta → Cyan → Yellow → Red |
| `acid_green` | Green → Cyan → Spring Green → Chartreuse |
| `purple_haze` | Indigo → Dark Magenta → Orchid → Light Orchid |
| `ocean` | Navy → Medium Blue → Dark Turquoise → Turquoise |
| `aurora` | Dark Blue → Spring Green → Violet → Dodger Blue |
| `cosmic` | Blue → Magenta → Orange Red → Cyan |
| `classic` | Aqua → Teal → Light Green → Gold |

### Banner Display Modes

| Mode | Description |
|---|---|
| `ring` | 3-ring concentric text arcs orbiting the logo |
| `flat` | Stacked lines above or below the logo |

### Beat Detector Modes

| Mode | Key | Description |
|---|---|---|
| Auto | `auto` | Defaults to Hybrid; can upgrade to PCM if already capturing |
| Hybrid | `hybrid` | Blends low-end, mid transients, broadband |
| Bass | `bass` | Kick and low-end thump |
| Mid | `mid` | Snare, guitar, vocal attack |
| Broad | `broad` | Overall band energy |
| Enhanced | `pcm` | Android system audio capture (MediaProjection) |

### Audio Graph Modes

| Mode | Rendering |
|---|---|
| `off` | No graph |
| `corner` | Small frequency bars in corner + logo |
| `corner_only` | Corner bars only, no logo overlay |
| `circular` | Circular EQ around logo |
| `ekg` | EKG-style horizontal trace |
| `circular_ekg` | Circular EKG |
| `vu` | VU meter |
| `scope` | Oscilloscope |
| `beat_debug` | Raw beat detection overlay |

---

## Rendering Pipeline

```
steal_screensaver/
  steal_background.dart   – animated gradient mesh (22KB)
  steal_banner.dart        – Ring/Flat text painter (37KB)
  steal_config.dart        – immutable config VO (27KB)
  steal_game.dart          – logo movement driver (9KB)
  steal_graph.dart         – SYF logo geometry + trail (67KB)
  steal_visualizer.dart    – top-level widget host (3KB)
```

The `StealVisualizer` widget creates a `StealGame` that drives logo
position updates. On each frame tick:

1. `StealBackground` paints the animated gradient
2. `StealGraph` paints the logo, trails, and optional anti-aliased edges
3. `StealBanner` paints the ring or flat text overlay
4. If audio reactivity is on, the `AudioReactor` feeds beat/spectrum
   data that modulates logo scale, trail dynamics, and color cycling

---

## Test Coverage

| Test file | Focus |
|---|---|
| `tv_screensaver_section_test.dart` | Widget test: section renders, toggles, D-pad nav |
| `tv_settings_screen_test.dart` | Integration: category navigation, section switching |
| `screensaver_screen_test.dart` | Screen launch, exit, audio reactor lifecycle |
| `screensaver_exit_test.dart` | Key dismiss behavior across permission states |
| `steal_graph_test.dart` | Logo geometry calculations |
| `steal_game_test.dart` | Movement state machine |
| `trail_snapshot_test.dart` | Trail snapshot color and scale |
| `settings_provider_test.dart` | Preference persistence round-trip |
| `settings_provider_defaults_contract_test.dart` | Default values contract |

---

## Phase 0 Retrospective — What Changed

The original `phase0_screensaver_selection.md` proposed a modular
multi-screensaver architecture. The production implementation diverged
significantly. All items below are **completed and shipping.**

| Phase 0 Proposal | What Was Actually Built | Status |
|---|---|---|
| `ScreensaverType` enum (SYF / Sheep) | Single SYF screensaver; `useOilScreensaver` bool on/off | ✅ Done |
| `QualityLevel` enum (Safe/Balanced/Full/Auto) | `oilPerformanceLevel` int (0=High, 1=Balanced, 2=Fast) | ✅ Done |
| `ScreensaverSettings` standalone class | `_SettingsProviderScreensaverExtension` mixin on SettingsProvider | ✅ Done |
| `ScreensaverRouter` with switch dispatch | Direct `ScreensaverScreen.show()` + `ScreensaverLaunchDelegate` | ✅ Done |
| `SheepScreensaver` stub widget | Not yet built — planned as second screensaver type | 🔜 Planned |
| `ScreensaverSettingsSection` in `gdar_tv` app | `TvScreensaverSection` in `shakedown_core` (shared package) | ✅ Done |
| `SharedPreferences` via standalone class | `SharedPreferences` via `SettingsProvider` mixin | ✅ Done |
| 6 simple settings fields | 78 preference keys (visual, audio, perf, typography) | ✅ Done |

### Capabilities Added Beyond Phase 0

These features were never proposed in the original spec but are now
implemented:

| Capability | Implementation |
|---|---|
| Inactivity detection | `InactivityService` with polling timer + `InactivityDetector` widget |
| Full audio reactivity | FFT, PCM capture, 6 beat detectors, 9 graph modes |
| Live preview in settings | `TvScreensaverPreviewPanel` renders mini visualizer in left nav |
| Device-aware 4K limiting | `FittedBox` downscale only on low-end TV dongles (sabrina) via `DeviceService` |
| Song-aware rendering | `SongStructureHintCatalog` matching for per-song visual identity |
| Logo motion trails | Configurable trail system with dynamic/static modes |
| Multi-font banner text | Ring and flat display modes with Rock Salt / Roboto selection |

### Open TODOs

Items that are identified for future work but **not yet started:**

- [ ] **Sheep Screensaver** — A second screensaver type is planned.
      Implementation will require adding a `ScreensaverType` enum,
      a `ScreensaverRouter` for type dispatch, and the sheep
      rendering widget. The settings UI will need a type selector
      in the System section.
- [ ] **Android DreamService integration** — The screensaver is
      currently a Flutter route, not a native Android dream. Wiring
      it into the system `DreamService` would let it appear in
      Android TV Settings → Screensaver as a selectable option.
- [ ] **Low-end device denylist expansion** — Currently only the
      2020 Chromecast dongle (`sabrina`) is flagged. Other weak
      devices (e.g. older Fire TV Sticks) could be added to the
      `DeviceService.isLowEndTvDevice` check as reports come in.
- [ ] **Performance auto-detection** — Instead of a manual
      performance level selector, auto-detect frame budget and
      downgrade rendering quality dynamically.

---

## File Map — All Screensaver-Related Files

### Core Rendering
- [steal_config.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_config.dart)
- [steal_visualizer.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_visualizer.dart)
- [steal_graph.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_graph.dart)
- [steal_background.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_background.dart)
- [steal_banner.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_banner.dart)
- [steal_game.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/steal_screensaver/steal_game.dart)

### Settings & State
- [settings_provider_screensaver.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/providers/settings_provider_screensaver.dart)
- [default_settings.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/config/default_settings.dart)

### UI Widgets (Settings)
- [tv_screensaver_section.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section.dart)
- [tv_screensaver_section_build.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_build.dart)
- [tv_screensaver_section_audio_build.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart)
- [tv_screensaver_section_controls.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_controls.dart)
- [tv_screensaver_preview_panel.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart)

### Screens
- [screensaver_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/screens/screensaver_screen.dart)
- [tv_settings_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/screens/tv_settings_screen.dart)

### Services
- [inactivity_service.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/services/inactivity_service.dart)
- [screensaver_launch_delegate.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/services/screensaver_launch_delegate.dart)

### Audio Reactivity
- [audio_reactor.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/visualizer/audio_reactor.dart)
- [audio_reactor_factory.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/visualizer/audio_reactor_factory.dart)
- [visualizer_audio_reactor.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/visualizer/visualizer_audio_reactor.dart)

### Navigation
- [route_names.dart](file:///c:/Users/jeff/StudioProjects/gdar/packages/shakedown_core/lib/ui/navigation/route_names.dart)
