# Unify App Orchestration Phase 3 Verification Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Verify the completed orchestration refactor across shared core, mobile, TV, and web after all implementation phases have landed.

**Architecture:** This phase is verification-first. Prefer surfacing failures over adding fixes unless the controller explicitly authorizes a narrow verification-only patch.

**Tech Stack:** Flutter, Dart, Melos

---

## Dependencies

- Requires completion of:
  - `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1a-provider-graph.md`
  - `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-1b-automation-core.md`
  - `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-2a-web-integration.md`
  - `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-2b-mobile-integration.md`
  - `docs/superpowers/plans/2026-04-25-unify-app-orchestration-phase-2c-tv-integration.md`

## Task 1: Run Targeted Tests

- [ ] **Step 1: Run provider graph test**

Run: `flutter test packages/shakedown_core/test/app/gdar_app_providers_test.dart`
Expected: PASS

- [ ] **Step 2: Run automation parser test**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_step_parser_test.dart`
Expected: PASS

- [ ] **Step 3: Run automation executor test**

Run: `flutter test packages/shakedown_core/test/services/automation/automation_executor_test.dart`
Expected: PASS

## Task 2: Run Broad Verification

- [ ] **Step 1: Run analyzer**

Run: `melos run analyze`
Expected: PASS

- [ ] **Step 2: Run tests**

Run: `melos run test`
Expected: PASS

## Task 3: Manual Smoke Checks

- [ ] **Step 1: Verify mobile manually**

Checks:
- app boots
- audio plays
- `shakedown://settings?...` still works
- automation flow still launches the correct screensaver behavior

- [ ] **Step 2: Verify TV manually**

Checks:
- app boots
- route observer behavior remains stable
- `shakedown://automate?steps=dice,sleep:1,screensaver` still works
- `lockIsTv` behavior remains intact

- [ ] **Step 3: Verify web manually**

Checks:
- app boots
- Fruit shell still renders correctly
- current web deep-link behavior is unchanged
- no provider lookup regressions appear at startup

## Task 4: Write the Final Verification Handoff

- [ ] **Step 1: Save verification results**

Save results to:
- `reports/2026-04-25_app_orchestration_final_verification.md`

Required contents:
- commands run
- pass/fail status
- failing command output summary if any
- residual risks
- recommendation: ready or not ready
