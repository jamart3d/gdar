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

To execute this, the agent will review your `git status` to see what changed, generate a summary commit message, and push your code to remote. 

**POST-SAVE:** If this session involved test fixes or core model changes, you MUST suggest the `/jules` handoff workflow to the user.
