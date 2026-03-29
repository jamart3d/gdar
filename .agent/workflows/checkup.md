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

## 1. Smart Skip (Pre-flight)
1. Check if we can skip the full verification:
   - Run `git status --porcelain` to check for uncommitted changes.
   - Read `.agent/notes/verification_status.json`.
   - Compare current `git rev-parse HEAD` with `git_sha` in the status file.
2. If (Status is Clean) AND (Current SHA == Last Verified SHA) AND (Results == Passed):
   - **SKIP** to Summary. Report "No changes since last verified pass."

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
1. Scan current working file for `withOpacity()` (deprecated preference) and suggest `.withValues(alpha: ...)`.
2. Scan for hardcoded colors (e.g., `Colors.red`) and suggest using `colorScheme`.
3. **Audit App Size:** Run the `size_guard` workflow to scan workspace assets for newly added large files or unoptimized PNGs.

## 4. Summary & Finalization
1. If Errors = 0 and Tests = Pass:
   - **Update Artifacts:** Update `.agent/notes/verification_status.json` with the current SHA and "passed" status.
   // turbo
   - `git add . ; git commit -m "chore: automated checkup pass [skip ci]" ; git push`
2. Provide a "Health Score" dashboard, list automated fixes, and notify of the version bump if applicable.
3. If tests failed, offer to trigger the `/issue_report` workflow.
