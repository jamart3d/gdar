---
description: Verbose health check — runs /checkup with full log output, forced design scan, and a scored commit message.
---
# Hammer Workflow (Monorepo)
// turbo-all

**TRIGGERS:** hammer, turbo-checkup, brute-force, quick-fix

Run the `/checkup` workflow with the following overrides:

| Behaviour | Checkup default | Hammer override |
|---|---|---|
| Smart skip | Skips melos if SHA matches + PASS | Never skips — always runs full suite and design scan |
| Output | Concise summary | Full verbose: print complete output of every command |
| Commit message | `chore: checkup pass [score: <N>/100] [skip ci]` | `chore: hammer pass [score: <N>/100]` |

To force full melos execution, pass `--force` to the preflight script:
`dart scripts/preflight_check.dart --force`
