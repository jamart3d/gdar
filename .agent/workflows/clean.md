description: Monorepo hygiene audit with root drift checks and selective recursive cleanup.
---

# Clean Workflow (Monorepo)

**TRIGGERS:** clean, home, hygiene, scrub, doctor

This workflow is for monorepo hygiene in the GDAR workspace. It starts with a
root-level drift audit, then performs selective recursive cleanup in
low-risk member areas such as `apps/`, `packages/`, and `scripts/`. Treat it
as an audit-first workflow. Do not delete or move files blindly on a dirty
worktree.

## 1. Root Directory Audit
1. List all files and directories in the project root.
2. Recursively search `apps/`, `packages/`, and `scripts/` for transient
   artifacts (`*.log`, `*.tmp`, `test_out.txt`, etc).
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

#### Recursive Target Cleanup (`apps/`, `packages/`, and `scripts/`)
- Transient artifacts scattered within member targets:
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
6. Do not recursively clean `docs/`, `.agent/`, or `data/` unless the user
   explicitly targets them.

## 4. Report Back
Summarize:
- what was identified
- what was deleted safely
- what still needs user confirmation
- any root-level files that appear to reflect repo drift rather than temp noise
