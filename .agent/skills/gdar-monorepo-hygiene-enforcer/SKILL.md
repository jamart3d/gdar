---
name: gdar-monorepo-hygiene-enforcer
description: Use when running or editing GDAR operational workflows such as verify, checkup, save, shipit, deploy, and script automation where preflight, host gating, shell compatibility, path hygiene, and sequential build safety must be enforced.
---

# GDAR Monorepo Hygiene Enforcer

Apply hygiene and execution constraints before running workflow commands.

## Preflight Discipline
1. Start with unified preflight:
   - `dart scripts/preflight_check.dart --preflight-only` for checkup-like tasks.
   - `dart scripts/preflight_check.dart --release` for ship/deploy tasks.
2. Respect host gate outputs:
   - `CHROMEBOOK:STOP` means stop release/build flow.
   - Verified host output means continue.

## Execution Safety
1. Keep builds strictly sequential.
2. Stop immediately on first failing command in release chains.
3. Do not run parallel git mutations.
4. Use shell-native syntax:
   - PowerShell on Windows.
   - Bash syntax on Linux/macOS.

## Path and Workspace Hygiene
1. Keep root clean; no temp/debug artifacts at repo root.
2. Keep platform folders under `apps/<target>/`.
3. Skip discovery in `archive`, `temp`, and `backups` unless directly requested.

## Verification Baseline
- `melos run format`
- `melos run analyze`
- `melos run test`

## Done Checklist
- Correct preflight mode was run before workflow execution.
- Host gate output was respected (`CHROMEBOOK:STOP` vs verified host).
- Build and release steps are strictly sequential.
- Shell syntax matches host environment.
- Discovery skips `archive`, `temp`, and `backups` unless explicitly targeted.
- Verification baseline passes or workflow halts on first failure.

Use workflow-specific commands from `.agent/workflows/*.md` for full pipelines.
