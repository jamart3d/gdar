# Code Hygiene Quick-Wins Backlog
Date: 2026-04-10
Source baseline:
- `reports/CODE_HYGIENE_REPORT_2026-04-10_RERUN.md`
- `reports/DEAD_CODE_REMOVAL_PLAN_2026-04-10.md`

## Why This Matters
- Current hygiene score: `7/10`
- Duplicate-risk groups: `30`
- Dead private candidates: `42`
- Analyzer status: clean (`No issues found`)

Goal: reduce maintenance drag and regression risk with low-friction, staged
work that protects TV/Web/Fruit behavior contracts.

## Effort and Importance Summary
- Dead code cleanup:
  - Effort: `Low -> Medium` (about 4-12 hours for a safe first pass)
  - Importance: `Medium`
- Duplicate cleanup:
  - Effort: `Medium -> High` (about 16-40 hours depending on consolidation depth)
  - Importance: `Medium-High`

## Ranked Backlog (Quick Wins First)

1. Scanner false-positive hardening (dead-code)
- Priority: P0
- Effort: 3-5 hours
- Importance: High (unblocks safe removals)
- Risk: Low
- Scope:
  - Ignore underscore tokens in string literals / JSON keys.
  - Ignore `@JS(...)` interop anchors.
  - Reduce part-file private type-name noise.
- Exit criteria:
  - Dead-private candidate list shrinks with no behavior changes.

2. Remove trivial dead executable members (batch 1)
- Priority: P0
- Effort: 2-4 hours
- Importance: Medium
- Risk: Low-Medium
- Scope:
  - Remove only executable private members confirmed unused after scanner
    hardening.
  - Skip interop/audio/splash/screensaver sensitive paths in first batch.
- Exit criteria:
  - Analyzer clean, targeted tests pass, no runtime regressions.

3. About screen dedupe (`about_screen` + `about_section`)
- Priority: P1
- Effort: 2-4 hours
- Importance: Medium-High
- Risk: Low
- Scope:
  - Extract shared widget/content builder in `shakedown_core`.
  - Keep platform-specific styling hooks where needed.
- Exit criteria:
  - Shared source used by both call sites, visuals unchanged.

4. Playback helper dedupe (TV/non-TV helper pair)
- Priority: P1
- Effort: 4-8 hours
- Importance: High
- Risk: Medium
- Scope:
  - Consolidate duplicate helper logic between:
    - `playback_screen_helpers.dart`
    - `tv_playback_screen_helpers.dart`
  - Keep TV D-pad/focus specifics separated.
- Exit criteria:
  - Shared helper layer introduced, behavior parity retained.

5. Mobile/TV app init micro-dedupe (`main.dart` short block)
- Priority: P1
- Effort: 1-2 hours
- Importance: Medium
- Risk: Low
- Scope:
  - Extract identical startup/config snippet to shared function.
- Exit criteria:
  - Both apps compile and run with unchanged startup behavior.

6. Fruit pending-overlay dedupe
- Priority: P2
- Effort: 1-3 hours
- Importance: Medium
- Risk: Low
- Scope:
  - Unify duplicate pending-overlay build logic in Fruit playback widgets.
- Exit criteria:
  - Fruit visuals remain identical; no Material widget leakage.

7. Show list vs TV show list deep consolidation (defer)
- Priority: P3
- Effort: 12-24 hours
- Importance: High (long-term)
- Risk: High
- Scope:
  - Large shared structure extraction while preserving TV navigation patterns.
- Exit criteria:
  - Dedicated refactor branch with focused regression test coverage.

## Suggested Execution Cadence
- Week 1 (quick wins): items 1, 2, 5
- Week 2 (targeted dedupe): items 3, 6
- Week 3+ (higher-risk): item 4, then item 7 when bandwidth allows

## Verification Gate For Every Item
- Run:
  - `dart run melos run analyze`
  - targeted tests for touched modules
- Re-run hygiene audit:
  - `dart run scripts/code_hygiene_audit.dart`
- Update report:
  - write a dated hygiene delta report in `reports/`

## Definition of Done (Phase)
- Duplicate groups reduced from baseline without platform regressions.
- Dead-private list reflects true executable candidates, not scanner artifacts.
- No violations of Fruit/TV platform UI contract during dedupe refactors.
