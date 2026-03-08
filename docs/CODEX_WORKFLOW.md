# Codex Workflow

Updated: 2026-03-07
Workspace: C:\Users\jeff\StudioProjects\gdar

## Memory model
- Codex does not keep persistent memory outside the current thread/session.
- Reliable memory sources are:
  - Conversation history.
  - Repo files (especially docs handoff files).
  - Project instructions (`AGENTS.md`, `.agent/rules/...`).

## Directory conventions
- Prefer `tool/` for Dart runnable utility scripts (ecosystem convention).
- Keep `tools/` for non-Dart helpers/scripts if needed.
- Current project policy:
  - `tool/` = Dart CLI helpers (for example `tool/verify.dart`).
  - `tools/` = other utility artifacts.

## Start-of-session checklist
1. Read `AGENTS.md`.
2. Read `.agent/rules/...` files if present/referenced.
3. Read `pubspec.yaml`.
4. Read `analysis_options.yaml`.
5. Inspect `lib/` structure and locate files relevant to the request.
6. Read latest handoff in `docs/` (for example `SESSION_HANDOFF_*.md`).

## Per-prompt workflow
1. Parse the request precisely (what UI/screen/behavior/file).
2. Open only directly affected files first.
3. Check related config/provider/model files for side effects.
4. Implement minimal targeted edits.
5. Run formatting and analysis on changed files:
   - `dart format <changed files>`
   - `dart analyze <changed files>`
6. Report what changed + any validation limits.
7. Update handoff doc when changes are substantial.

## Validation defaults
- Prefer targeted checks for speed while iterating.
- Before handoff/review, run broader verification when practical:
  - `dart run tool/verify.dart`
- User may run full test/build pipeline manually.

## Environment caveat (Codex sandbox)
- In this environment, sandboxed `dart` commands may timeout intermittently.
- If that happens, rerun with approved escalation.

## Handoff policy
- Keep concise handoff docs in `docs/` for fast agent onboarding.
- Include:
  - What changed.
  - Why it changed.
  - Files touched.
  - Validation run.
  - Known risks / follow-ups.
