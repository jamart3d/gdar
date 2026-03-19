---
name: Workflow Conventions
description: How to save work and hand off to Jules in this repo
type: feedback
---

Follow `.github/workflows/save.md` for saving:
1. `git add .`
2. `git commit -m "[Auto-Save] <descriptive message>"`
3. `git push`

After saving, if the session involved test fixes or core changes, send a Jules checkup:
`jules new "<title describing what to verify>"`

Jules CLI is at `/home/jam/.config/nvm/versions/node/v24.14.0/bin/jules`. Requires `jules login` if session is unauthenticated.

The repo has a branch protection rule requiring PRs, but the user's account has bypass rights — push to main directly is expected behavior. The "Bypassed rule violations" remote message is normal, not an error.

**Why:** This is the established project workflow. The save.md workflow doc is the authority.
**How to apply:** Every session that modifies code should end with a save + push. Jules checkup when tests or providers changed.
