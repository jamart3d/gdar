---
description: Root-level monorepo cleanup audit and recursive hygiene checklist.
---

# Clean Home Workflow (Monorepo)

**TRIGGERS:** clean, home, hygiene, scrub, doctor

This workflow is for workspace-root hygiene in the GDAR monorepo. Treat it as
an audit-first workflow. Do not delete or move files blindly on a dirty
worktree.

## Monorepo Awareness

GDAR is a Dart workspace monorepo coordinated from the root `pubspec.yaml`.
Build targets live under `apps/` and shared code lives under `packages/`.

Important current repo facts:
- Root orchestration uses `pubspec.yaml`, not `melos.yaml`.
- Approved top-level product directories include `apps/`, `packages/`, `docs/`,
  `scripts/`, and `.agent/`.
- Temporary build/test artifacts may appear at root during local debugging and
  should be reviewed before deletion.

## 1. Root Directory Audit
1. List all files and directories in the project root.
2. Recursively search `apps/` and `packages/` for transient artifacts (*.log, *.tmp, test_out.txt, etc).
3. Compare root files against the approved root file list:
   - `pubspec.yaml`, `pubspec.lock`
   - `analysis_options.yaml`, `build.yaml`
   - `firebase.json`, `.firebaserc`
   - `README.md`, `CHANGELOG.md`, `TODO.md`, `AGENTS.md`
   - `.gitignore`, `.editorconfig`, `.gitattributes`
   - `.metadata`, `devtools_options.yaml`
3. Compare directories against the approved root directory list:
   - `apps/`
   - `packages/`
   - `docs/`
   - `scripts/`
   - `data/`
   - `.agent/`
   - `.git/`, `.idea/`, `.vscode/`, `.dart_tool/`, `.firebase/`
   - `build/` if present and gitignored

### 2. Identify Cleanup Candidates

#### Root-Level Drift
- Temporary files such as `*.tmp`, `*.log`, `*.bak`, `*.pid`, `temp_*`
- One-off test output dumps such as `test_output*.txt`, `test_error*.txt`
- Root-level scripts that belong under `scripts/`
- Legacy root-level platform directories such as `android/`, `ios/`, `web/`,
  `linux/`, `macos/`, `windows/`
- Legacy root-level `lib/` or `test/` directories
- Report or scratch markdown files that do not belong in `docs/` or `.agent/`

#### Recursive Member Target Cleanup (apps/ and packages/)
- Transient artifacts scattered within member packages:
  - `*.log`, `*.tmp`, `*.bak`
  - `test_out.txt`, `test_output.txt`, `test_fail_lifecycle.log`
  - Misplaced `debug_*.png` or scratch JSON dumps.

## 3. Safe Cleanup Rules
1. Delete only obvious temporary files without asking:
   - `*.tmp`, `*.log`, `*.pid`
   - `test_out.txt`, `test_output*.txt`
   - transient test output dumps at root or inside targets
2. Move misplaced scripts into `scripts/` if their destination is clear.
3. Do not delete docs, workflow files, or `.agent/` content without confirming
   they are intentionally obsolete.
4. Do not remove legacy platform directories without explicit user confirmation.
5. If the worktree is dirty, report suspicious files before deleting anything
   beyond obvious temp artifacts.

## 4. Report Back
Summarize:
- what was identified
- what was deleted safely
- what still needs user confirmation
- any root-level files that appear to reflect repo drift rather than temp noise
