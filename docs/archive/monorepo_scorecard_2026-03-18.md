# Monorepo Scorecard

Date: 2026-03-18
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`

## Overall Score

**7.5/10**

This is a strong, credible Flutter monorepo with real platform separation,
substantial shared-core value, and a clearer workspace contract than it had a
day earlier.

The score improves slightly from the prior 7/10 because the repo now reads more
consistently as a monorepo: root `pubspec.yaml` is the workspace coordinator,
monorepo rules are clearer, and test-boundary guidance is better aligned with
shared package ownership.

It does not move higher yet because complexity is still concentrated in a few
very large files, and there is still meaningful uncertainty at the test runner
and web-audio integration boundaries.

## Category Breakdown

### Architecture: 8.5/10

Strengths:

- App entrypoints are thin and platform-specific instead of duplicating core
  behavior.
- `packages/shakedown_core` remains the real center of gravity for shared UI,
  providers, services, and platform contracts.
- The root `pubspec.yaml` now clearly acts as the workspace orchestrator,
  including melos scripts for analyze, test, and format.
- Platform differentiation is intentional across Android, TV, and web/Fruit.

Weaknesses:

- Some shared provider and screen classes are still carrying too many
  responsibilities at once.
- Architectural safety depends heavily on team discipline because the shared
  core is broad and high-impact.

### Maintainability: 6.5/10

Strengths:

- The repo is structured enough that new work usually has an obvious home.
- Shared docs such as `docs/MONOREPO_RULES.md` and `docs/TEST_PLANNING.md`
  are doing more real coordination work now.
- The app-host versus shared-package boundary is becoming more explicit.

Weaknesses:

- `SettingsProvider` is still extremely overloaded and remains the clearest
  maintainability hotspot.
- A few core files are large enough to make safe review and refactoring slower
  than they should be.
- The current workspace still has signs of migration drift in tests and docs,
  even if that drift is now being corrected.

### Test Quality: 7/10

Strengths:

- Coverage exists across providers, services, screens, widgets, and web-specific
  behavior.
- The repo contains real regression tests, not only smoke tests.
- Test-planning guidance is now more monorepo-aware: shared behavior belongs in
  `packages/shakedown_core/test`, while `apps/*/test` should stay focused on
  host-app behavior.

Weaknesses:

- Some app-level tests appear to have drifted during the monorepo transition
  and were modeling outdated bootstrap assumptions.
- The local Flutter test/analyze runner behavior is still not fully trustworthy
  for targeted file-level verification in the current environment.
- The highest-risk integration boundaries still need stronger, more deterministic
  contract tests.

### Platform Discipline: 8.5/10

Strengths:

- TV, Android, and Fruit are treated as distinct products, not superficial
  themes.
- The TV host behavior is clearer now: boot through `SplashScreen`, then land in
  the TV experience without inventing a TV onboarding flow.
- Focus, input, screensaver, and platform-specific behavior are clearly first-
  class concerns.

Weaknesses:

- Some platform contracts are still better expressed in docs and intent than in
  small, enforceable runtime contracts.
- Fruit enforcement still depends on vigilance in shared UI code.

### Web Audio Design: 6/10

Strengths:

- The web audio strategy is still ambitious and more sophisticated than average.
- Hybrid behavior, diagnostics, and engine selection all show serious product
  thinking.
- The web stack is important enough in this repo that it is being treated as an
  engineering system, not a side path.

Weaknesses:

- Config drift and trust issues around requested mode versus resolved mode still
  appear unresolved.
- The control surface remains harder to reason about than it should be.
- This area still carries the most architectural and regression risk.

## What Improved Since 2026-03-17

- Monorepo orchestration is clearer and better documented around the root
  `pubspec.yaml` and melos-backed commands.
- Test-boundary guidance is better: shared TV/widget behavior is being pushed
  toward `packages/shakedown_core/test` instead of living only in app-level
  repro files.
- The TV app bootstrap assumptions are more consistent with the actual product
  behavior.

## What Still Caps The Score

- `SettingsProvider` is still too large and too central.
- Web audio/hybrid behavior still needs a more authoritative resolved-runtime
  contract.
- Test reliability is not yet where it should be for a repo with this much
  platform branching.
- A few core files still do enough that reviewability and safe change velocity
  are below the repo's architectural potential.

## Path To 8+

1. Split `SettingsProvider` into smaller concerns such as persistence,
   defaults, migration, and runtime policy.
2. Define one authoritative resolved web-audio contract and surface it
   consistently in runtime state and UI.
3. Continue migrating stale app-level tests into package-level shared-behavior
   tests.
4. Add deterministic contract tests around app bootstrap flows and shared TV
   focus/random-play behavior.
5. Shrink the largest shared files enough that review scope becomes easier to
   reason about.

## Bottom Line

GDAR is still a good monorepo, and it looks slightly healthier today than it
did on 2026-03-17. The repo's main risks are no longer about whether the
monorepo structure is real; they are about how much complexity is concentrated
in the settings/runtime layer and how reliably the test surface expresses the
current platform contracts.
