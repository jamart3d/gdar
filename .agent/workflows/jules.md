---
description: Formalized handoff to Jules for full suite verification.
---
# Jules Handoff Workflow

**TRIGGERS:** jules, handoff, verify-all

1. **Check Status**: Ensure `git status` is clean before handoff.
2. **Prompt for Title**: Use `notify_user` to ask for a session title (e.g., "Verify test regressions").
3. **Execute**: Run `jules new "[title]"` in the project root.
4. **Report**: Use `notify_user` to provide the generated URL and Session ID to the user.

> [!TIP]
> Use this workflow whenever you finish a task that involves test fixes or core provider changes.
