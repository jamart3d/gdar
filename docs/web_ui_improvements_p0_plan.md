# Web UI Improvements — P0 Plan 

## Phase Goal
Stabilize background playback (prevent OS reclaim and timer clamp failures).

## Success Criteria
- Background playback remains active across track boundaries.
- MediaSession state remains consistent during transitions.
- Worker-tick timing drives background polling where applicable.


## Expectations

- Follow Clean Architecture: UI (Widgets), Logic (Provider/State), Data (Repository).
- State management via Provider (`ChangeNotifier` / `ProxyProvider`).
- Use latest stable Flutter/Dart; resolve deprecations; prefer `.withValues()` over `withOpacity()`.
- Use `const` constructors everywhere possible; adhere to `flutter format` (80 cols).
- Enforce platform design rules: Android = Material 3 Expressive; TV = Material Dark + D-Pad; Web/PWA = Fruit (Liquid Glass) only.
- Fruit hard rule: no Material 3 widgets, ripples, FABs, or M3 interaction language on Fruit screens; no M3 fallback if glass is disabled.
- Gate Fruit logic with `kIsWeb` / PWA checks.
- Provide tests (unit/widget) for new behavior.
- When completing a feature, include: Task List, Implementation Plan, Testing suggestions, Walkthrough.



## P0 Checklist
### Diagnostics & Visibility
- [x] High-resolution drift monitor in `GaplessPlayerWeb` (measure timer clamping).
- [x] HUD Diagnostic Chips: `V` (Visibility Status) and `DFT` (Drift Timer).
- [x] Visibility change listener to track VIS/HID duration.

### Core Stability
- [x] Prefer worker-tick driven timers where available (minimizes Mixed timing clamping).
- [x] Ensure MediaSession `playbackState` is updated on play/pause/stop and during track transitions.
- [x] Centralize heartbeat-needed detection and expose it consistently across engines and HUD.
- [x] Persistent MediaSession Anchor: keep `playbackState` and metadata stable across src swaps.
- [x] Hybrid Fence: force engine swaps only at boundaries when backgrounded (Desktop optimal).
- [x] Static Sentinel: skip or downgrade prefetch for dead/blocked tracks to prevent engine spinning.
