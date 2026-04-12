---
description: Archived standalone verbose validate wrapper.
archived_on: 2026-04-11
replacement: .agent/workflows/validate.md
---
# Archived: Hammer Workflow

This standalone workflow was retired during workflow cleanup.

Reason for archival:
- it was a thin verbose wrapper around `validate`
- it did not add enough distinct behavior to justify a top-level workflow

Use instead:
- `.agent/workflows/validate.md`

If verbose execution is needed in the future, add a documented verbose mode to
`validate` rather than reintroducing a separate wrapper workflow.
