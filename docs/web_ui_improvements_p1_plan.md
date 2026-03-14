# Web UI Improvements — P1 Plan (Jules)

## Phase Goal
Improve recovery and observability for background/PWA playback.

## Success Criteria
- Drift, context, and recovery diagnostics are visible and consistent.
- Prefetch and recovery logic prioritize stability under background throttling.


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



## P1 Checklist
- [ ] Use a monotonic clock for drift calculations to avoid wall-clock jumps.
- [ ] Propagate settings changes to JS engines live (background/handoff/forceHtml5) without reload.
- [ ] Define a minimal QA matrix (foreground/background, PWA vs tab, iOS Safari vs Chrome Android, low-power mode).
- [ ] Boundary Sentinel: pre-warm next track at T-10s to guarantee gapless transition.
- [ ] Adaptive Prefetch Budget: increase next-track buffer when hidden, cap memory for older tracks.
- [ ] Time-boxed Recovery: auto-handoff to HTML5 if WebAudio stalls > X seconds.
- [ ] Session History can seed a “boundary sentinel” prefetch of the *next show* when current show ends.
- [ ] Use SessionEntry timestamps to prioritize which upcoming show gets background prefetch budget.