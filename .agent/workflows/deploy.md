---
description: Zero-friction production release — runs /shipit with no plan, no confirmation, always patch bump.
---
# Deploy Workflow (Monorepo)
// turbo-all

**TRIGGERS:** deploy, push-prod, ship-it-now

Run the `/shipit` workflow with the following overrides:

## Overrides

| Behaviour | Shipit default | Deploy override |
|---|---|---|
| Release plan | Shows plan, waits for user approval | No plan, no confirmation — runs immediately |
| Version bump | Patch or minor (user chooses) | Always patch |
| Empty `[Unreleased]` block | Pauses and notifies user | Skips review — assumes changelog is correct |
| Dirty worktree | Shows files, commits, proceeds | Same — commit and proceed, no prompt |
| `melos run fix` | Not run (verify only) | Same — not run |

## Notes
- All platform detection, SHA smart skip, build flags, git tag, and completion report behaviour are inherited from `/shipit` unchanged.
- Use deploy when you have already reviewed the release plan and want a single-word trigger with no prompts.
- For minor version releases, use `/shipit` instead.
