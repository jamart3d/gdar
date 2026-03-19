# Monorepo Scorecard

Date: 2026-03-19
Project: GDAR
Workspace: `C:\Users\jeff\StudioProjects\gdar`

## Overall Score

**7.8/10**

This remains a solid Flutter monorepo, and it looks slightly healthier than it
did on 2026-03-18.

The score moves up because today’s work improved an important part of monorepo
reliability: app-shell wiring and platform ownership. The TV app now restores a
missing runtime integration for the screensaver, there is a focused app-level
test for that host behavior, and recent UI work has been pushed back toward a
clearer "Fruit-only unless explicitly TV" boundary.

The repo does not move higher yet because the same structural ceiling still
exists: very large shared runtime classes, a wide settings surface, and a test
story that is improving but still uneven across host apps versus shared
packages.

## Category Breakdown

### Architecture: 8.5/10

Strengths:

- Platform hosts and shared packages continue to read like a real monorepo
  rather than a single app with folders.
- `packages/shakedown_core` still carries the right kind of shared weight:
  providers, services, models, and reusable platform UI.
- App-host wiring got more credible today because TV-specific runtime behavior
  is now actually attached in the TV app shell instead of only existing as
  shared code and settings.
- Platform contracts are clearer in practice: Fruit work is being re-scoped
  back to Fruit, and TV runtime behavior is being fixed in `apps/gdar_tv`.

Weaknesses:

- Too much high-impact behavior still lives in a few large shared files.
- Shared runtime classes still blur orchestration, persistence, platform policy,
  and UI-facing state in ways that make architectural intent harder to enforce.

### Maintainability: 6.8/10

Strengths:

- The repo keeps getting easier to reason about at the boundary level:
  host-app work now has a clearer place, and shared package work now has
  clearer limits.
- Recent handoff and plan documentation was brought up to date, which helps the
  next contributor avoid re-learning context.
- The TV screensaver bug was a good example of maintainability work: the fix was
  localized to app bootstrap rather than patching around symptoms deeper in the
  stack.

Weaknesses:

- `SettingsProvider` is still the largest maintainability hotspot.
- Shared playback/runtime code still carries enough branching to make safe
  changes slower than ideal.
- Some UI cleanup still depends on iterative screenshot-driven tuning rather
  than smaller reusable layout primitives.

### Test Quality: 7.4/10

Strengths:

- The test story improved today in a monorepo-meaningful way: the TV host app
  now has a focused startup/screensaver regression test for behavior that truly
  belongs at the app-shell layer.
- Shared provider tests continue to cover meaningful runtime flows such as
  random-show queueing and playback transitions.
- The repo is increasingly treating regressions as contract failures that
  deserve targeted tests, not just manual repro notes.

Weaknesses:

- Verification is still mixed between true automated checks and visual/manual
  confirmation.
- Some app-level TV regression coverage still looks transitional or partially
  stale from the monorepo migration.
- A few important host-app flows still lack direct contract tests.

### Platform Discipline: 8.8/10

Strengths:

- This is the category that improved most today.
- Fruit and TV are being treated as genuinely different products, and the repo
- is actively correcting scope drift when shared changes leak from one platform
  into another.
- TV defaults, TV black-surface restoration, TV source filter improvements, and
  TV screensaver wiring all reinforce that the TV app is not just another theme.
- Fruit work is being shaped by a real style contract instead of generic shared
  widget reuse.

Weaknesses:

- Platform discipline still depends too much on review vigilance in shared UI
  code.
- A stronger set of small automated platform contract tests would make these
  boundaries less socially enforced.

### Web Audio / Runtime Reliability: 6.5/10

Strengths:

- The runtime layer is not static; it is being hardened with regression tests
  and race-condition fixes.
- Today’s random-show queueing work improved robustness around
  prequeue-versus-fallback interactions.
- The project continues to treat playback/runtime behavior as an engineering
  surface that deserves explicit logic and tests.

Weaknesses:

- The audio/runtime layer is still highly stateful and concentrated.
- It still takes real inspection effort to prove what behavior is canonical
  versus incidental.
- This remains the repo’s highest-risk shared subsystem.

## What Improved Since 2026-03-18

- The TV app shell now actually wires inactivity monitoring to the screensaver,
  which fixes a classic monorepo integration regression where settings and
  shared code existed but app-host glue did not.
- A focused TV startup/screensaver regression test now exists at the app level,
  which is the right ownership layer for that behavior.
- Fruit scope discipline improved: visible Fruit work was pulled back toward
  Fruit-specific behavior instead of letting shared UI changes drift across
  platforms.
- Shared playback logic got a more explicit guard against duplicate random-show
  fallback after successful prequeueing.

## What Still Caps The Score

- `SettingsProvider` is still too central.
- Shared playback/runtime classes remain large and state-heavy.
- Test coverage is improving, but host-app wiring and shared-package behavior
  still are not covered evenly.
- The repo still relies on a combination of docs, discipline, and manual review
  more than small enforceable contracts in a few key places.

## Path To 8+

1. Continue turning platform regressions into narrow host-app contract tests,
   especially for TV startup, screensaver, and focus routing.
2. Split `SettingsProvider` into smaller concerns so app defaults, persistence,
   migration, and runtime policy are easier to reason about.
3. Keep pushing shared behavior tests into `packages/shakedown_core/test` while
   keeping `apps/*/test` focused on real host-app bootstrap and runtime wiring.
4. Shrink the largest shared playback/runtime files so state transitions are
   easier to audit.
5. Add a small number of explicit platform-boundary checks so Fruit, TV, and
   Android visual/runtime contracts are less dependent on human memory.

## Bottom Line

GDAR looks a little more like a disciplined monorepo today than it did
yesterday. The biggest positive change is not cosmetic: the repo is getting
better at reconnecting shared code to app-specific runtime ownership and then
capturing that ownership in tests. The next jump comes from reducing shared
state complexity, not from adding more structure.
