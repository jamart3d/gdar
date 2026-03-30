# Monorepo Scorecard

Date: 2026-03-17
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`

## Overall Score

**7/10**

This is a solid monorepo with real structure, real platform intent, and enough
shared-core discipline to scale. It is clearly beyond a casual or improvised
repo.

The score stops at 7 because complexity is starting to outrun consolidation in
some key areas, especially settings/state management and the web audio stack.

## Category Breakdown

### Architecture: 8/10

Strengths:

- Good separation between app entrypoints and shared packages.
- `packages/shakedown_core` acts like a real product core, not just a dump of
  reusable code.
- Platform-aware design is visible across phone, TV, and web.
- Provider usage follows a recognizable app architecture instead of ad hoc
  widget-local state everywhere.

Weaknesses:

- Some provider and screen classes have grown too large and are now carrying
  orchestration, persistence, migration, and UI coordination at the same time.
- Web behavior is split across Dart, JS bootstrap, and JS runtime logic, which
  raises the mental cost of making safe changes.

### Maintainability: 6/10

Strengths:

- Naming is mostly understandable.
- There is enough structure that new work can usually be placed in the right
  layer.
- Shared defaults and shared services reduce duplication.

Weaknesses:

- `SettingsProvider` is overloaded and is now acting as defaults registry,
  migration layer, persistence layer, feature switchboard, and runtime policy
  object.
- Some config paths appear partially implemented or drifting, especially in web
  audio/hybrid settings.
- Large files increase review difficulty and regression risk.

### Test Quality: 7/10

Strengths:

- The repo has meaningful test coverage across providers, screens, widgets,
  and web-specific behavior.
- There are regression-style tests, not just smoke tests.
- The test surface suggests the team is using tests to preserve behavior, not
  only to satisfy tooling.

Weaknesses:

- The most complex integration boundaries, especially Dart-to-JS web engine
  behavior, still have room for stronger contract testing.
- A repo with this much platform branching benefits from more explicit
  cross-layer tests around resolved settings and engine selection.

### Platform Discipline: 8/10

Strengths:

- The repo has strong platform intent.
- TV, web/Fruit, and Android styles are treated as distinct products rather
  than lightly themed copies.
- There is evidence of careful handling for focus, screensaver, deep links,
  and input differences.

Weaknesses:

- The web defaults currently blur the intended Fruit experience by pushing
  performance-first behavior on first run.
- Some platform contracts exist more clearly in intent than in consistently
  enforced implementation.

### Web Audio Design: 6/10

Strengths:

- The web audio path is ambitious and more advanced than most Flutter web
  apps.
- The hybrid strategy shows serious thought about hidden-tab survival,
  handoffs, and gapless playback tradeoffs.
- Diagnostics/HUD support is a strong engineering asset.

Weaknesses:

- There is config drift between Dart settings and JS runtime behavior.
- Requested mode versus resolved mode is not consistently represented in the
  UI and runtime contract.
- Some settings appear dead or not fully wired, which lowers trust in the
  control surface.

## What Makes It Better Than Average

- It is a real monorepo, not a single app with extra folders.
- Shared code is substantial and product-specific.
- Platform specialization is intentional.
- The project has enough structure that future cleanup would pay off quickly.

## What Keeps It From 8-9/10

- Too much state and policy concentrated in a few large files.
- Incomplete consolidation of experimental web/hybrid audio work.
- A few places where the settings UI promises more determinism than the runtime
  currently guarantees.
- Reviewability is starting to degrade because some core files are doing too
  much.

## Path To Higher Score

To move this repo from 7 to 8+, the highest-value steps would be:

1. Split `SettingsProvider` into smaller concerns.
2. Define one authoritative resolved web audio config contract.
3. Remove dead settings or fully wire them through.
4. Tighten platform contract enforcement for Fruit versus Android-style UI.
5. Add a few focused integration tests around web engine resolution and hybrid
   mode behavior.

## Bottom Line

This is a good monorepo with strong product thinking and above-average
engineering structure. It is already credible. The main risk is not lack of
architecture, but accumulated complexity in the places where settings,
platform behavior, and web audio orchestration meet.
