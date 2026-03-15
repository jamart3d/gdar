# Web UI Improvements — P2 Plan 

## Phase Goal
Polish diagnostics and optional advanced behaviors.

## Success Criteria
- HUD is stable and readable during rapid state changes.
- Advanced diagnostics and optional continuity features are available.


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



## P2 Checklist
- [ ] Add a unified HUD snapshot stream to reduce nested `StreamBuilder`s and improve testability.
- [ ] Show Stitching (Soft): treat a show as a virtual continuity segment without true concatenation.
- [ ] Fallback Glue Track: inject short silence between tracks if background stability drops.
- [ ] Cross-show forward navigation can be treated as a “soft stitch” when Continuous Play is enabled.
