---
trigger: always_on
---

# GDAR Architecture Context

## Project Shape
Dart/Flutter monorepo. Three apps share `packages/shakedown_core` for all providers, services, and shared widgets. Platform-specific entrypoints live in `apps/`.

## Key Providers
- **`SettingsProvider`** — all user prefs via `SharedPreferences`. Platform defaults via `_dBool(webVal, tvVal, phoneVal)`. 1,960+ lines. Splitting requires a separate class or mixin — NOT Dart extension methods (static dispatch breaks provider fakes).
- **`AudioProvider`** — wraps the active engine. `audioPlayer.activeMode` is the **resolved** mode; `sp.audioEngineMode` is the **stored** preference (may be `auto`). Always gate UI on the resolved mode, not the stored enum.
- **`ThemeProvider`** — `ThemeStyle` has exactly two values: `android` and `fruit`. `isFruitAllowed = kIsWeb && !isTv`.
- **`DeviceService`** — `isTv`, `isMobile`, `isDesktop`, `isSafari`, `isPwa`.

## Platform Policy
| Platform | App | Theme |
|---|---|---|
| Web/PWA | `gdar_web` | Fruit (Liquid Glass) — `kIsWeb && !isTv` only |
| Google TV | `gdar_tv` | Material Dark, D-Pad focus, dual-pane |
| Android Phone | `gdar_mobile` | Material 3 Expressive |

## Hard Constraints
- **True Black mode**: removes background colors but preserves subtle shadows for depth. Never fully disable shadows when glow intensity > 0.
- **Scaffold padding**: when using a custom `Positioned` AppBar inside a `Stack`, set `primary: false` on the parent `Scaffold` to prevent double top-padding.
- **Async playback sync**: never use `Future.delayed` to sync UI with audio state. Use `currentIndexStream` or `MediaItem` tag streams as the authoritative source.
- **Routing**: do not migrate routing packages to fix navigation bugs. Fix within the current paradigm.
- **Data parsing**: `output.optimized_src.json` is 8MB. Always use `compute()` or Isolates. Never parse on the main thread.
