---
trigger: always_on
---
# Test Expectation Hygiene

## Purpose
Prevent false-red builds when behavior or layout was intentionally changed.

## Mandatory Rule
When a code change intentionally alters behavior, copy, timing, or layout, the
agent MUST evaluate whether impacted tests are now stale and update them in the
same change set.

## Required Flow
1. Classify each failure as one of:
   - **Regression:** product contract is broken.
   - **Stale expectation:** product contract changed intentionally and test
     assertion no longer matches reality.
2. For stale expectations, update tests to the new contract with the smallest
   safe assertion change (avoid broad weakening).
3. Prefer resilient assertions:
   - contract intent over exact pixel/value constants unless strict constants are
     part of the contract,
   - semantic/finder assertions over brittle implementation details.
4. Verify in order:
   - exact failing test/case,
   - affected test file or local test bucket,
   - required workflow suite (`melos run test` for release gates).

## Hard Constraints
- Never leave intentional product changes and stale tests out of sync.
- Never silence failures by deleting assertions without replacement.
- Never claim fix complete without fresh test evidence from this session.

## Ship/Release Gate
For `/shipit`, `/deploy`, and `/checkup`, unresolved stale expectations are
release blockers until triaged and either fixed or explicitly documented by the
user.
