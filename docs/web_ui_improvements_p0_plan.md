# Web UI Improvements — P0 Plan (Jules)

## Phase Goal
Stabilize background playback (prevent OS reclaim and timer clamp failures).

## Success Criteria
- Background playback remains active across track boundaries.
- MediaSession state remains consistent during transitions.
- Worker-tick timing drives background polling where applicable.


## Jules Expectations

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
- [ ] Prefer worker-tick driven timers where available; minimize mixed `setInterval`/RAF timing.
- [ ] Ensure MediaSession `playbackState` is updated on play/pause/stop and during track transitions.
- [ ] Centralize heartbeat-needed detection and expose it consistently across engines and HUD.
- [ ] Persistent MediaSession Anchor: keep `playbackState` and metadata stable across src swaps.
- [ ] Hybrid Fence: force engine swaps only at boundaries when backgrounded.
- [ ] If a show is blocked or offline, the sentinel should skip or downgrade prefetch for that entry.