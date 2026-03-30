# Agent Session Bootstrap Checklist (GDAR)

This protocol defines the mandatory discovery and verification steps performed by the Antigravity agent at the start of any new session.

## 1. Structural Mapping (First Turn Only)
- **Mandatory Discovery**: Run `ls -R .agent/` or `git ls-files .agent/`.
- **Goal**: Register absolute paths for all workflow triggers (/shipit, /checkup), rules, and docs without human intervention.

## 2. Rule & Style Calibration
- **Persona Context**: Read `AGENTS.md` to verify version-branching, coding standards, and monorepo layout strategies.
- **Platform Contracts**: Refresh the specific constraints for:
  - Material 3 (Mobile)
  - Material Dark/Dual-pane (Google TV)
  - Fruit/Liquid Glass (Web/PWA)
- **Gate Synchronization**: Check `.agent/rules/` for active performance mode toggles or Wasm-handling bypasses.

## 3. Autonomy Authorization Scoping
- **Zero-Friction Mandate**: Verify the list of authorized autonomous workflows in `always_proceed.md`.
- **Command Syntax Verification**: Silently check CLI help signatures (`melos --help`, `flutter --help`) before first execution.
- **Auto-Approve Audit**: Refresh the read-only whitelist in `auto_approve.md`.

## 4. Continuity & Versioning
- **Current Baseline**: Identify the current build (`+XXX`) and SEMVER version from `CHANGELOG.md`.
- **Staging Awareness**: Scan the `[Unreleased]` section of the changelog to understand pending logic or architectural shifts.

## 5. Constraint & Safety Gates
- **High-Risk Path Verification**: Ensure `APPDATA` and other reserved cache directories are NOT redirected into `.agent/appdata`.
- **Isolate Safety Check**: Confirm the 8MB JSON data path is correctly mapped and threading rules (`compute()`) are active.
