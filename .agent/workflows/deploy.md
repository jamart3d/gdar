---
description: Zero-friction production release - alias for /shipit with always-patch.
---
# Deploy Workflow (Monorepo)
// turbo-all

**TRIGGERS:** deploy, push-prod, ship-it-now

Run the `/shipit` workflow identically, always using `patch` as the bump type.

- `/deploy` and `/shipit` behave the same (both are zero-friction, no plan, no prompts).
- For minor version releases, use `/shipit minor` instead.
