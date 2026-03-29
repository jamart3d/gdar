---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Checkup Workflow (Monorepo)
// turbo-all


**TRIGGERS:** checkup, health, quick-audit, lint-fix

> [!IMPORTANT]
> **AUTONOMY OVERRIDE & PLANNING MODE**: When this workflow is triggered, proceed autonomously end-to-end (running analysis, automated fixes, and tests) without stopping for intermediate permission. Only pause if a critical error occurs. 

> [!WARNING]
> **NO BLACK BOXES**: You are strictly forbidden from chaining multiple terminal commands into a single "black box" string (e.g., `format; analyze; test`). Run each health check and workspace tool as its own step so status is reported in real-time.

> [!NOTE]
> **MONOREPO**: This is a Dart workspace. Run analysis/format/fix from the **workspace root** - the Dart tools will recurse into `apps/` and `packages/` automatically.

> [!IMPORTANT]
> **EXECUTION MECHANICS**: Follow `.agent/skills/zero_friction_execution/SKILL.md` for async command handling (`WaitMsBeforeAsync: 5000`), polling loop, and fail-fast protocol.

## 0. Platform Detection
Follow `.agent/rules/platform_detection.md` to identify the current machine and resolve `$MELOS_CAN_HANDLE`.

- **Chromebook**: Run steps 1–2 (smart skip check + health suite) and stop. Skip step 3 (Visual/Design Check) and auto-commit — notify the user that those steps require Windows.
- **Windows 10**: Run all steps end-to-end.

## 1. Smart Skip (Pre-flight)
1. Check if we can skip the full verification:
   - Run `git status --porcelain` to check for uncommitted changes.
   - Read `.agent/notes/verification_status.json`.
   - Compare current `git rev-parse HEAD` with `last_verification_commit` in the status file.
2. If (Status is Clean) AND (Current SHA == `last_verification_commit`) AND (status == "PASS"):
   - **SKIP** to Summary. Report "No changes since last verified pass."
   - Note: A `"PARTIAL"` result does **not** qualify for skip — run the full suite.

## 2. Atomic Health Pass (Fail-Fast)
1. Run automated fixes first to clean up low-hanging fruit:
   - `melos run fix` (runs `dart fix --apply` across the workspace)
2. Format code:
   - `melos run format`
3. Fast workspace analysis:
   - `melos run analyze` (now uses `dart analyze .` internally)
4. Comprehensive tests with platform-aware concurrency:
   - `melos run test` (on Linux/Windows builds, concurrency is enabled)

## 3. Visual/Design Check (Micro)
1. Run the Git Diff Micro-Scanner to catch styling violations automatically.
   - Run `dart run scripts/scan_diffs.dart`
2. If the scanner fails, halt the workflow and report the violations.
3. **Audit App Size:** Run only **Step 1 (Fast Asset Scan)** of the `size_guard` workflow — flag files over 500 KB, unoptimized images, and dead assets. Do **not** run the binary size build step; that belongs in `shipit`.

## 4. Summary & Finalization
1. If Errors = 0 and Tests = Pass:
   - **Update Artifacts:** Update `.agent/notes/verification_status.json` with the current SHA and "passed" status.
   // turbo
   - `git add . && git commit -m "chore: automated checkup pass [skip ci]" && git push`
2. Compute and report the **Health Score** (start at 100, apply deductions):
   | Issue | Deduction |
   |---|---|
   | Each analyzer error | -10 |
   | Each analyzer warning | -3 |
   | Each failing test | -10 |
   | Design scanner violation | -5 each |
   | Asset over 500 KB (unoptimized) | -2 each |
   | Format changes needed | -1 |
   List all automated fixes applied.
3. If tests failed, offer to trigger the `/issue_report` workflow.
