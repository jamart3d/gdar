---
description: Zero-friction production publish - alias for /publish with always-patch.
---
# Deploy Workflow (Monorepo)
// turbo-all

**TRIGGERS:** deploy, push-prod, ship-it-now

Run the `/publish` workflow identically, always using `patch` as the bump type.

- `/deploy` and `/publish` behave the same (both are zero-friction, no plan, no prompts).
- For minor version releases, use `/publish minor` instead.
