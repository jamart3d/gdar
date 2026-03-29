---
trigger: always_on, mobile, android, phone, theme, layout
---
# GDAR Architecture Context & Mobile Rules

## Project Shape
* **Workspace type:** Dart/Flutter monorepo managed from the root `pubspec.yaml`
* **Architecture:** Clean Architecture - UI (Widgets), Logic (Provider), Data (Repository)
* **Apps:** `apps/gdar_mobile`, `apps/gdar_tv`, `apps/gdar_web`
* **Packages:** `packages/shakedown_core` (reusable logic, models, services), `packages/styles`

## Key Providers
- **`SettingsProvider`** — all user prefs via `SharedPreferences`. Platform defaults via `_dBool(webVal, tvVal, phoneVal)`. 1,960+ lines. Splitting requires a separate class or mixin — NOT Dart extension methods (static dispatch breaks provider fakes).
- **`AudioProvider`** — wraps the active engine. `audioPlayer.activeMode` is the **resolved** mode; `sp.audioEngineMode` is the **stored** preference (may be `auto`). Always gate UI on the resolved mode, not the stored enum.
- **`ThemeProvider`** — `ThemeStyle` has exactly two values: `android` and `fruit`. `isFruitAllowed = kIsWeb && !isTv`.
- **`DeviceService`** — `isTv`, `isMobile`, `isDesktop`, `isSafari`, `isPwa`.

## Platform Policy
| Platform | App | Theme & Capabilities |
|---|---|---|
| Web/PWA | `gdar_web` | Fruit (Liquid Glass) — `kIsWeb && !isTv` only |
| Google TV | `gdar_tv` | Material Dark, D-Pad focus, dual-pane |
| Android Phone | `gdar_mobile` | Material 3 Expressive. Ripples everywhere. |

## Mobile Platform Directives (Android Phone/Tablet)
- **Visuals:** Use Material 3 Expressive dynamic color tokens exclusively. Apply ink ripples on every tappable surface.
- **Constraints:** Never use `BackdropFilter`, blurs, or neumorphic shadows on mobile. Use True Black for OLED backgrounds where applicable.
- **Layout:** Place all primary interactive controls within the bottom 40% of screen height. Respect `SafeArea` on all edges. Never place primary controls in the top half of the screen.
- **Hardware Interaction:** Implement haptic feedback on every interaction: `selectionClick` / `mediumImpact` / `vibrate`.

## Hard Constraints
- **True Black mode**: removes background colors but preserves subtle shadows for depth. Never fully disable shadows when glow intensity > 0.
- **Scaffold padding**: when using a custom `Positioned` AppBar inside a `Stack`, set `primary: false` on the parent `Scaffold` to prevent double top-padding.
- **Async playback sync**: never use `Future.delayed` to sync UI with audio state. Use `currentIndexStream` or `MediaItem` tag streams as the authoritative source.
- **Routing**: do not migrate routing packages to fix navigation bugs. Fix within the current paradigm.
- **Data parsing**: `output.optimized_src.json` is 8MB. Always use `compute()` or Isolates. Never parse on the main thread.
- **Fruit Design Boundary**: Strictly forbid Material 3 interaction language (widgets, ripples, FAB patterns) on Fruit screens to preserve Liquid Glass aesthetics.
- **Performance Efficiency**: Always utilize `const` constructors where possible to minimize widget reconstruction overhead and CPU pressure on low-power targets (TV/Chromebook).
- **Web Audio Prefetch Integrity**: During gapless pre-fetch cancellation (`_cancelPrefetch`), the current target track and the immediate next track MUST be protected via an index-based whitelist. This prevents "Abortion Collisions" where manual user navigation inadvertently kills its own fetch request.
- **Adaptive HUD Telemetry**: Diagnostic chips in the `DevAudioHUD` (e.g., `CAC`, `BUF`, `SCH`) MUST implement adaptive color-coded health warnings:
  - **Red**: Imminent playback gap risk or fatal engine state (e.g., `val == 0` while playing).
  - **Amber**: Performance caution or cache overflow (e.g., `CAC > 3`).
  - **Green**: Healthy synchronization and standard buffer depth.
