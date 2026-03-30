---
description: Quick-save workflow to commit and push changes.
---
# Save Workflow

**TRIGGERS:** save, backup, commit

// turbo-all

## 1. Unified Save & Sync (Turbo)

// turbo
1. Run the unified sync script:
   - `dart scripts/save_sync.dart "[Auto-Save] <generate descriptive message here>"`

This script atomically handles:
- `git add .`
- `git commit` with a descriptive message.
- `git push` to origin.
- Pruning empty `.agent/notes/*.md` files.
- Updating `.agent/notes/verification_status.json` with the new Git SHA and `saved` status.

**POST-SAVE:** If this session involved test fixes or core model changes, you MUST suggest the `/jules` handoff workflow to the user.
