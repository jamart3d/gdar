# Test Planning Matrix

This document helps agents and contributors derive high-value tests for GDAR's
monorepo without treating this file as the canonical product spec.

Use this as a planning aid. For implementation details, always cross-check the
relevant code, workflows, and feature docs before writing tests.

## How To Use This Doc
- Start from the feature area that matches the current change.
- Prefer targeted tests near the changed package or app target.
- Use automated tests for stable logic and UI contracts.
- Keep long-running, device-specific, or browser-specific validation as manual
  QA unless there is already a reliable harness.
- When in doubt, use this doc to generate a test plan first, then refine using
  source files and existing tests.

## Monorepo Scope
- **Mobile app:** `apps/gdar_mobile`
- **TV app:** `apps/gdar_tv`
- **Web app:** `apps/gdar_web`
- **Shared core logic/widgets/providers:** `packages/shakedown_core`
- **Shared styles/themes:** `packages/styles`

## Monorepo Boundary Rule
- Keep `apps/*/test` focused on app host behavior such as entrypoint wiring, app-shell startup, and platform-specific boot rules.
- Put shared widget, provider, and screen behavior under `packages/shakedown_core/test`, even when that behavior is currently exercised through `apps/gdar_tv` or another app target.
- When migrating pre-monorepo tests, prefer moving or rewriting them as package tests instead of re-creating full app bootstrap in the app test directory.
- For TV specifically, do not model a TV onboarding flow in app tests; the TV host boots through `SplashScreen` and then lands in the TV UI.
- If a widget test needs many providers or startup services, that is a signal to add seams/fakes and move coverage closer to the shared package that owns the behavior.

## Core Health Checks

### Workspace hygiene
- **Scope:** workspace root, all apps, all packages
- **Test type:** automated
- **Primary checks:** format, analyze, targeted tests, clean worktree expectations
- **Useful commands:** `melos run format`, `melos run analyze`, `melos run test`
- **References:** `docs/MONOREPO_RULES.md`, `.agent/workflows/verify.md`

### Package publishing safety
- **Scope:** `apps/gdar_mobile`, `apps/gdar_tv`, `apps/gdar_web`
- **Test type:** automated or review-time validation
- **Primary checks:** each app target keeps `publish_to: none`; workspace config remains consistent

## TV / Android TV

### Focus and navigation
- **Scope:** `apps/gdar_tv`, `packages/shakedown_core/lib/ui/widgets/tv`
- **Test type:** widget tests first, manual QA second
- **Primary checks:** D-pad navigation, no focus traps, correct back-to-master flow, stable focus after rebuilds
- **Good assertions:** focus moves predictably, detail pane does not trap focus, active item remains recoverable after state changes

### TV branding and typography
- **Scope:** TV screens/widgets in `apps/gdar_tv` and shared TV widgets in `packages/shakedown_core`
- **Test type:** widget tests and visual/manual QA
- **Primary checks:** TV styling continues to honor the active app font and TV-specific presentation rules

## Web / PWA

### Audio engine selection and hybrid behavior
- **Scope:** `apps/gdar_web`, `packages/shakedown_core`
- **Test type:** unit/integration where practical, manual QA for browser/runtime behavior
- **Primary checks:** engine mode resolution, hybrid handoff settings, persisted settings behavior, runtime mode vs requested mode consistency
- **References:** `docs/web_ui_audio_engines.md`, `docs/web_ui_audio_hybrid_review_2026-03-17.md`
- **Keep manual:** hidden-tab behavior, long-session playback, browser throttling, audio handoff timing

### Fruit UI behavior
- **Scope:** `apps/gdar_web`, shared web-facing widgets in `packages/shakedown_core`
- **Test type:** widget tests plus manual browser QA
- **Primary checks:** Fruit structure remains intact, no Material 3 leakage, performance-mode fallback preserves Fruit structure instead of swapping to Material components

### Web drag and scroll overlays
- **Scope:** show list and related web widgets
- **Test type:** manual QA unless a stable harness exists
- **Primary checks:** overlay alignment during drag, no pointer drift, acceptable behavior under throttling

## Mobile / Shared Playback

### Playback and gapless behavior
- **Scope:** `packages/shakedown_core`, app integrations as needed
- **Test type:** unit tests, widget tests, selective manual QA
- **Primary checks:** track changes, queue behavior, state restoration, playback UI state, gapless expectations where deterministic
- **Keep manual:** long-running background playback, lock-screen behavior, OS media integration edge cases

### Persistence and settings
- **Scope:** `packages/shakedown_core/lib/providers`, settings-related tests across apps
- **Test type:** unit and widget tests
- **Primary checks:** ratings persist, blocked items persist, scroll position or UI state restoration behaves as intended, newly added settings are mirrored in test fakes/mocks
- **References:** `docs/TEST_MOCKING_TEMPLATES.md`

## Data and Performance

### Shared data asset handling
- **Scope:** `packages/shakedown_core/assets/data/output.optimized_src.json`, related loaders/parsers
- **Test type:** unit tests and review-time validation
- **Primary checks:** large JSON stays off the main thread, schema expectations remain stable, regressions do not break parsing assumptions

### Asset size discipline
- **Scope:** workspace assets and build outputs
- **Test type:** automated audit plus review-time checks
- **Primary checks:** oversized assets, unoptimized images, budget drift
- **References:** `scripts/size_guard`, `.agent/workflows/audit_size.md`

## What Not To Over-Automate
- Device-specific background playback survival
- Browser-specific audio quirks and hidden-tab behavior
- Visual polish checks that lack a stable golden/screenshot harness
- Long soak tests that are expensive and flaky in CI

## Agent Guidance
- Use this doc to propose a focused test plan, not a blanket test explosion.
- Prefer adding tests close to the changed code.
- If a scenario is better suited to manual QA, say so explicitly.
- When writing tests from this matrix, cite the target package/app and the expected user-facing behavior.



