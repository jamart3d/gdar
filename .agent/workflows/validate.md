---
description: Rapid health check with automated fixes for linting, formatting, and tests.
---
# Validate Workflow (Monorepo)
// turbo-all

**TRIGGERS:** validate, checkup, health, quick-audit, lint-fix

> [!IMPORTANT]
> Execute immediately upon trigger. No plans, no confirmation prompts.
> Follow `.agent/skills/zero_friction_execution/SKILL.md` for
> long-running command polling.

## 1. Preflight & Verification
// turbo
- `dart scripts/preflight_check.dart --preflight-only`
- If output contains `CHROMEBOOK:STOP` -> notify user and **stop**.
  Validate does not run design scans or commit on Chromebook.
- If output contains `WINDOWS_10:VERIFIED`, `LINUX:VERIFIED`, or `MACOS:VERIFIED` -> proceed to Step 2.
- For preflight-only sandbox reliability, apply
  `.agent/rules/sandbox_preflight_fallback.md`.

The script handles platform detection, toolchain checks, and process hygiene.
In validate mode it does **not** run melos or write `verification_status.json`.

## 2. Automated Fixes
// turbo
- `melos run fix` (runs `dart fix --apply` across the workspace)

This step is what makes `/validate` different from `/publish` -
validate auto-fixes before the verification suite runs.

## 3. Verification
// turbo
- `melos run format`
- `melos run analyze`
- `melos run test`

If any step fails, halt and report the failing command.

## 4. Visual, Asset, and Config Check
1. Run the Git Diff scanner: `dart run scripts/scan_diffs.dart`
   (Diffs against `HEAD` - if the tree is clean post-save, the scan is a no-op
   and passes trivially.)
2. If the scanner fails, halt and report violations.
3. Run the fast asset scan: `dart run scripts/size_guard/audit_assets.dart`
   flag files over 500 KB and large PNG/JPG candidates in source asset roots.
   Do not run the binary size build step.
4. Run static release/config sanity checks:
   - confirm app versions match across `apps/gdar_mobile`, `apps/gdar_tv`,
     and `apps/gdar_web`
   - confirm
     `apps/gdar_mobile/android/app/src/main/AndroidManifest.xml` keeps
     `usesCleartextTraffic="false"`
   - confirm configured launcher icon paths resolve to real assets
5. If any static config check fails, halt and report the exact mismatch or
   missing path.
6. If verification and the visual/design/config checks all pass, record a fresh
   PASS:
   `dart scripts/preflight_check.dart --record-pass`

## 5. Summary & Finalization
1. Compute the **Health Score** (start at 100):

   | Issue | Deduction |
   |---|---|
   | Analyzer error | -10 each |
   | Analyzer warning | -3 each |
   | Analyzer hint/info | -1 each |
   | Failing test | -10 each |
   | Design scanner violation | -5 each |
   | Asset over 500 KB | -2 each |
   | Static config mismatch | -3 each |
   | Format changes needed | -1 |

2. If errors = 0 and tests pass:
   - print **"All green - ready to ship (Score: X/100)"**
   - summarize the fixes applied (if any)
   - recommend `/save` if the user wants to commit the repair pass
   - recommend `/release_gate` as the final gate before publish
   - recommend `/publish` after `/release_gate` passes
3. List all automated fixes applied.
4. If tests failed, offer to trigger `/issue_report`.
