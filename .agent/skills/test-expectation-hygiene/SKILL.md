---
name: test-expectation-hygiene
description: Use when tests fail after intentional UI or behavior adjustments and you need to distinguish real regressions from stale assertions, then update expectations safely with targeted verification.
---

# Test Expectation Hygiene

Triage test failures after intentional product changes without masking real
bugs.

## When to Use
- A test starts failing right after an intentional feature/layout/text update.
- Full-suite output contains a small number of expectation mismatches.
- Release workflow is blocked by likely stale assertions.

## Workflow
1. Reproduce the exact failing test case first.
2. Classify failure:
   - **Regression** (product contract broken) -> fix product code.
   - **Stale expectation** (contract intentionally changed) -> fix the test.
3. If stale expectation:
   - keep the assertion intent,
   - make the minimum safe update,
   - avoid over-broad weakening.
4. Re-verify in this order:
   - failing case,
   - failing file/bucket,
   - required workflow suite (`dart run melos run test` for monorepo gate).

## Assertion Guidance
- Prefer contract assertions over fragile internals.
- Use bounds/ranges only when exact constants are not the contract.
- Keep at least one positive rendering/behavior assertion after overflow or
  stability checks.

## Done Checklist
- Root cause classified as regression vs stale expectation.
- Test updates are minimal and contract-preserving.
- Targeted test case passes.
- Affected file/bucket passes.
- Workflow gate suite rerun and passing (or failure clearly isolated/documented).
