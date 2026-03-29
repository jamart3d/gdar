---
description: Quick-save workflow to commit and push changes.
---
# Save Workflow

**TRIGGERS:** save, backup, commit

// turbo-all

## Usage
Run this workflow whenever you want to quickly backup your work.

1. **Check Status**: `git status`
2. **Add Files**: `git add .`
3. **Commit**: `git commit -m "[Auto-Save] <generate descriptive message here>"`
4. **Push**: `git push`

## Post-Save Hygiene
1. **Prune Notes**: The agent MUST delete any empty `.agent/notes/*.md` files to maintain workspace hygiene.
2. **Update Receipt**: The agent MUST update `.agent/notes/verification_status.json` with the new Git SHA and mark the status as `saved` to ensure the "Smart Receipt" accurately tracks the current codebase state.

**POST-SAVE:** If this session involved test fixes or core model changes, you MUST suggest the `/jules` handoff workflow to the user.
