---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Checkup Workflow (Monorepo)
// turbo-all

**TRIGGERS:** checkup, health, quick-audit, lint-fix

> [!IMPORTANT]
> Execute immediately upon trigger. No plans, no confirmation prompts.
> Follow `.agent/skills/zero_friction_execution/SKILL.md` for
> long-running command polling.

## 1. Preflight & Verification
// turbo
- `dart scripts/preflight_check.dart`
- If output contains `CHROMEBOOK:STOP` → notify user and **stop**.
  Checkup does not run design scans or commit on Chromebook.
- If output contains `WINDOWS_10:VERIFIED` → proceed to Step 2.

The script handles platform detection, toolchain checks, process hygiene,
smart-skip melos (format, analyze, test), and `verification_status.json`
update. If the SHA already matches a PASS, the suite is skipped.

## 2. Automated Fixes
// turbo
- `melos run fix` (runs `dart fix --apply` across the workspace)

This step is what makes `/checkup` different from `/shipit` —
checkup auto-fixes, shipit only verifies.

## 3. Visual/Design Check
1. Run the Git Diff scanner: `dart run scripts/scan_diffs.dart`
2. If the scanner fails, halt and report violations.
3. Run **Step 1 only** of `/size_guard` (fast asset scan) —
   flag files over 500 KB, unoptimized images, dead assets.
   Do not run the binary size build step.

## 4. Summary & Finalization
1. Compute the **Health Score** (start at 100):

   | Issue | Deduction |
   |---|---|
   | Analyzer error | -10 each |
   | Analyzer warning | -3 each |
   | Failing test | -10 each |
   | Design scanner violation | -5 each |
   | Asset over 500 KB | -2 each |
   | Format changes needed | -1 |

2. If errors = 0 and tests pass:
   - `git add .`
   - `git commit -m "chore: checkup pass [score: <N>/100] [skip ci]"`
   - `git push`
3. List all automated fixes applied.
4. If tests failed, offer to trigger `/issue_report`.
