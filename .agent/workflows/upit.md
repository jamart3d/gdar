---
description: Append current-session work to pending release notes.
---
# Upit Workflow

**TRIGGERS:** upit, pending release, release note, note it

**When to use:** After a focused change is complete and verified, but before
`/shipit`, to capture the user-visible impact in
`.agent/notes/pending_release.md`.

## 1. Review Session Scope
- Read the current diff and the verification performed in this session.
- Ignore unrelated dirty-worktree changes unless the user explicitly asks to
  include them.

## 2. Write Pending Release Notes
- Open `.agent/notes/pending_release.md`.
- Add or update concise `[Unreleased]` bullets that describe what changed and
  why it matters to users.
- Prefer product-facing wording over implementation detail.
- Keep bullets wrapped to the repo's normal markdown width.

## 3. Sanity Check
- Do not duplicate an existing bullet with the same user-facing meaning.
- If the change is internal-only and has no release-note value, say so instead
  of forcing an entry.

## 4. Optional Follow-Through
- If the session produced a reusable agent pattern, suggest adding a workflow,
  rule, or skill alongside the release-note update.
