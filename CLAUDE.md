# GDAR — Claude Code Context

## Session Start
Read `.claude/memory/MEMORY.md` at the start of every session. It indexes memory files with user preferences, project state, workflow conventions, and key file locations. These files sync via git and work on any machine.

## Role
Senior Flutter developer and audio/multi-platform architecture expert. Act as a pair programmer. If architectural intent is unclear, ask before building.

---

## Project Overview

| Field | Value |
|---|---|
| Product | gdar — Flutter MP3 player family |
| Repo | https://github.com/jamart3d/gdar |
| Workspace | Dart/Flutter monorepo (root `pubspec.yaml`) |
| Flutter | Latest Stable Channel |
| State mgmt | Provider (`ChangeNotifier` / `ProxyProvider`) |
| Architecture | Clean Architecture: UI (Widgets) → Logic (Provider) → Data (Repository) |

---

## Monorepo Layout

```
apps/
  gdar_mobile/     # Android phone/tablet
  gdar_tv/         # Google TV / Android TV
  gdar_web/        # Web / PWA (Fruit theme)
packages/
  shakedown_core/  # Shared logic, services, widgets, providers
  styles/          # Shared theme primitives
docs/              # Audit reports, scorecards, architecture notes
```

- Use package imports across library boundaries (`package:shakedown_core/...`). No relative imports for library files.
- App-specific entrypoints live under `apps/`; everything reusable lives under `packages/`.

---

## Workspace Commands (Melos)

```bash
melos bootstrap       # Install deps
melos run format      # Format all
melos run analyze     # Analyze all
melos run test        # Run all tests
melos run clean       # Clean all
```

Run these from the repo root. `flutter test packages/shakedown_core/` also works for targeted runs.

---

## Platform Targets & UI Contract

| Platform | App | Theme |
|---|---|---|
| Android Phone/Tablet | `gdar_mobile` | Material 3 Expressive |
| Google TV / Android TV | `gdar_tv` | Material Dark, D-Pad focus, dual-pane |
| Web / PWA | `gdar_web` | Fruit (Apple Liquid Glass) |

**Hard rules:**
- Fruit theme: no Material 3 widgets, ripples, FAB patterns, or M3 interaction language.
- Fruit fallback (performance mode / settings disabled): keep Fruit structure and controls — do NOT swap to M3 components.
- `LiquidGlassWrapper` is web-only (`kIsWeb && !isTv`). Never instantiate it on phone/desktop.
- `ThemeStyle` enum has exactly two values: `android` and `fruit`. There is no `classic`.

---

## Key Providers

- **`SettingsProvider`** — 1,960+ lines, persists all user prefs via `SharedPreferences`. Platform defaults via `_dBool(webVal, tvVal, phoneVal)`. TV mode driven by `force_tv` pref key.
- **`AudioProvider`** — wraps the active audio engine; exposes `audioPlayer.activeMode` (resolved) vs `sp.audioEngineMode` (stored, may be `auto`).
- **`ThemeProvider`** — manages `ThemeStyle` (android/fruit) and dark mode. `isFruitAllowed = kIsWeb && !isTv`.
- **`DeviceService`** — `isTv`, `isMobile`, `isDesktop`, `isSafari`, `isPwa`.

---

## Web Audio Engine Layer

**JS files** (`apps/gdar_web/web/`):
- `hybrid_init.js` — bootstrap dispatcher; selects engine based on mobile UA + touch heuristic.
- `hybrid_audio_engine.js` — foreground WA + background HTML5 handoff.
- `gapless_audio_engine.js` — pure Web Audio API engine.
- `html5_audio_engine.js` / `hybrid_html5_engine.js` — HTML5 streaming engines.
- `passive_audio_engine.js` — minimal engine for low-power/background.
- `audio_utils.js` — shared utilities; defines `window._gdarIsHeartbeatNeeded()`. **Must load before all engines.**
- `audio_scheduler.js` — background tick worker; dispatches `gdar-worker-tick` events.

**Load order matters.** `audio_utils.js` must precede engine files in `index.html`.

SharedPreferences keys on web use the `flutter.` prefix. Raw GDAR keys: `audio_engine_mode`, `allow_hidden_web_audio`, `gdar_web_error_log_v1`.

**Low-power detection:** `isLikelyLowPowerWebDevice()` in `packages/shakedown_core/lib/utils/web_perf_hint.dart` (cross-platform stub). Heuristic: mobile UA + `cores <= 2 || (cores <= 4 && dpr < 2.0)`.

---

## Testing Patterns

- **Provider fakes:** implement the provider interface and use `dynamic noSuchMethod(Invocation inv) => super.noSuchMethod(inv)` for unimplemented members. This is the standard pattern throughout the test suite.
- **Extension methods break fakes:** Dart extension dispatch is static. Extensions on provider types cannot be overridden by fakes. Do not use extensions to split providers — use separate classes or mixins.
- **`kIsWeb` is compile-time:** web-specific branches in `SettingsProvider` cannot be covered by unit tests. Browser integration tests are needed.
- **TV defaults in tests:** pass `isTv: true` to `SettingsProvider(prefs, isTv: true)` constructor.
- **Asset-dependent tests:** `verify_data_integrity_test.dart` fails in CI without the 8MB data file — this is a known pre-existing failure in local test runs.

---

## Coding Standards

- Latest stable Dart, sound null safety.
- `flutter format`, line length 80.
- `const` constructors everywhere possible.
- Package-relative imports only.

---

## Data File

`packages/shakedown_core/assets/data/output.optimized_src.json` — 8MB. Always parse via `compute()` or Isolates. Never synchronously on the main thread. Schema must be preserved exactly for Hive serialization.

---

## Workflow

**Save:** `git add . && git commit -m "[Auto-Save] <message>" && git push`

**Jules checkup:** Create a task file in `.agent/tasks/` describing what to verify, following existing task file conventions in that directory.

**ADB (TV):**
```bash
# Force TV mode
adb shell am start -W -a android.intent.action.VIEW \
  -d "shakedown://settings?key=force_tv&value=true" com.jamart3d.shakedown
```

---

## Docs to Read for Context

| File | What it covers |
|---|---|
| `docs/monorepo_scorecard_2026-03-19.md` | Current quality score (8.0/10) and path to 8.5+ |
| `docs/web_ui_audio_hybrid_review_2026-03-19.md` | Web/audio audit — all findings resolved as of 2026-03-19 |
| `docs/web_ui_audio_engines.md` | JS engine architecture, config reference |
| `AGENTS.md` | Original persona/project brief (Jules-format) |
