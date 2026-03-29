---
description: Verbose health check — runs /checkup with full log output, forced design scan, and a scored commit message.
---
# Hammer Workflow (Monorepo)
// turbo-all

**TRIGGERS:** hammer, turbo-checkup, brute-force, quick-fix

Run the `/checkup` workflow with the following overrides:

## Overrides

| Behaviour | Checkup default | Hammer override |
|---|---|---|
| Smart skip (full) | Skips everything if SHA matches + PASS | Never fully skips — always runs step 3 (Visual/Design Check) even on SHA match |
| Output | Concise summary | Full verbose: print complete output of every command, including stack traces |
| Commit message | `chore: automated checkup pass [skip ci]` | `chore: hammer pass [score: <N>/100]` |

## Notes
- The Health Score rubric is defined in `/checkup` step 4 — hammer uses the same scoring.
- All platform detection, smart skip logic, and Chromebook stop conditions are inherited from `/checkup` unchanged.
- Use hammer when something feels wrong and you need to see every line of output, or when automated fixes require human oversight.
