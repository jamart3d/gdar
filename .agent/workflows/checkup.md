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

## 0. Platform Detection (MUST RUN FIRST)
1. Run this command immediately:
   ```bash
   uname -s 2>/dev/null || echo "Windows_NT"
   ```
2. **If output is `Linux` (Chromebook):**
   - Notify the user: "Chromebook detected — skipping Visual/Design Check and auto-commit."
   - Run steps 0.5, 1, and 2 (process hygiene + smart skip + health suite) then **stop**. Do not run step 3 or commit.
3. **If output is `Windows_NT` (Windows 10):**
   - Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
   - Continue all steps end-to-end.

## 0.5. Process Hygiene
Follow `.agent/rules/process_hygiene.md` to detect and handle any hung `flutter`, `dart`, or `melos` processes before proceeding. Re-run `git status --porcelain` after killing any processes — lock files from a hung process can make a clean worktree appear dirty.

## 1. Smart Skip (Pre-flight)
1. Check if we can skip the full verification:
   - Run `git status --porcelain` to check for uncommitted changes.
   - Read `.agent/notes/verification_status.json`.
   - Compare current `git rev-parse HEAD` with `last_verification_commit` in the status file.
2. If (Status is Clean) AND (Current SHA == `last_verification_commit`) AND (status == "PASS"):
   - **SKIP** to Summary. Report "No changes since last verified pass." and display the cached `results` from `verification_status.json` as the last known Health Score.
   - Note: A `"PARTIAL"` result does **not** qualify for skip — run the full suite.

## 2. Atomic Health Pass (Fail-Fast)
1. Resolve `$MELOS_CAN_HANDLE` per `.agent/rules/platform_detection.md`.
2. Run automated fixes first to clean up low-hanging fruit:
   - `melos run fix` (runs `dart fix --apply` across the workspace)
3. Format code:
   - `melos run format`
4. Fast workspace analysis:
   - `melos run analyze` (now uses `dart analyze .` internally)
5. Comprehensive tests with platform-aware concurrency:
   - `melos run test`

## 3. Visual/Design Check (Micro)
1. Run the Git Diff Micro-Scanner to catch styling violations automatically.
   - Run `dart run scripts/scan_diffs.dart`
2. If the scanner fails, halt the workflow and report the violations.
3. **Audit App Size:** Run only **Step 1 (Fast Asset Scan)** of the `size_guard` workflow — flag files over 500 KB, unoptimized images, and dead assets. Do **not** run the binary size build step; that belongs in `shipit`.

## 4. Summary & Finalization
1. Compute the **Health Score** (start at 100, apply deductions):
   | Issue | Deduction |
   |---|---|
   | Each analyzer error | -10 |
   | Each analyzer warning | -3 |
   | Each failing test | -10 |
   | Design scanner violation | -5 each |
   | Asset over 500 KB (unoptimized) | -2 each |
   | Format changes needed | -1 |
2. If Errors = 0 and Tests = Pass:
   - Update `.agent/notes/verification_status.json` with the current SHA, "passed" status, and health score.
   - `git add . && git commit -m "chore: checkup pass [score: <N>/100] [skip ci]" && git push`
3. List all automated fixes applied.
4. If tests failed, offer to trigger the `/issue_report` workflow.
