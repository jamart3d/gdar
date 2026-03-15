# Web UI Improvements — P1 Plan 

## Phase Goal
Improve recovery and observability for background/PWA playback.

## Success Criteria
- Drift, context, and recovery diagnostics are visible and consistent.
- Prefetch and recovery logic prioritize stability under background throttling.


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



## P1 Checklist
- [x] Use a monotonic clock for drift calculations to avoid wall-clock jumps.
- [x] Propagate settings changes to JS engines live (background/handoff/forceHtml5) without reload.
- [x] Define a minimal QA matrix (foreground/background, PWA vs tab, iOS Safari vs Chrome Android, low-power mode).
- [x] Boundary Sentinel: pre-warm next track at T-10s to guarantee gapless transition.
- [x] Adaptive Prefetch Budget: increase next-track buffer when hidden (90s) vs foreground (30s).
- [x] Time-boxed Recovery: auto-handoff to HTML5 if WebAudio stalls > X seconds.
- [x] Session History can seed a “boundary sentinel” prefetch of the *next show* when current show ends.
- [x] Use SessionEntry timestamps to prioritize which upcoming show gets background prefetch budget.
- [x] Add Setting toggle for Run Detection (def off)
