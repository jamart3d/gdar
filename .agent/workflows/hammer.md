---
description: Verbose health check — runs /checkup with full log output, forced design scan, and a scored commit message.
---
# Hammer Workflow (Monorepo)
// turbo-all

**TRIGGERS:** hammer, turbo-checkup, brute-force, quick-fix

Run the `/checkup` workflow with the following overrides:

| Behaviour | Checkup default | Hammer override |
|---|---|---|
| Smart skip | Uses preflight-only, then runs fix + verify + scans | Never skips — always runs full suite and design scan |
| Output | Concise summary | Full verbose: print complete output of every command |
| Finalization | Summarizes and leaves commit choice to `/save` or `/shipit` | Same, but with verbose logs and forced verification |

To force full verification after fixes, run:
`melos run format`
`melos run analyze`
`melos run test`
