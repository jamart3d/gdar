# Monorepo Scorecard Summary

Date: 2026-03-18
Project: GDAR

## Overall Score

**7.5/10**

GDAR is a credible, well-structured Flutter monorepo with real platform
separation and a meaningful shared core. It looks healthier than it did in the
prior scorecard, mainly because the workspace contract is clearer and the test
boundary guidance is more aligned with the monorepo shape.

## Why The Score Improved

- Root `pubspec.yaml` plus melos now read more clearly as the real workspace
  contract.
- Monorepo guidance is more consistent in docs.
- Test ownership is moving in the right direction: app-host tests stay in
  `apps/*/test`, while shared behavior belongs in
  `packages/shakedown_core/test`.
- TV bootstrap expectations are more accurate: the TV app starts with
  `SplashScreen`, not a separate onboarding flow.

## What Still Holds It Back

- `SettingsProvider` is still too large and too central.
- Web audio/runtime behavior still feels harder to reason about than it should.
- Test verification is not yet reliable enough for a repo with this much
  platform branching.
- A few core files still carry too much responsibility, which hurts review
  speed and refactor safety.

## Short Take

This repo has real architecture and real product discipline. The next jump in
score will come less from new structure and more from reducing complexity in
settings/runtime code and making tests more trustworthy at the current
monorepo boundaries.
