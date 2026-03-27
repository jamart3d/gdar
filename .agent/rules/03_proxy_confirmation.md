# Rule 4

**PROXY CONFIRMATION.**

1. For **non-destructive prompts** encountered during authorized workflows (e.g., `Continue? [y/n]`, `Apply fixes?`, `Proceed with staging?`), the agent MUST treat Rule 3 (Zero-Friction) as the answer and automatically send `y`. 
2. For **destructive prompts** (e.g., `Delete permanently?`, `Remove-Item`, `Drop database?`), or prompts where the context is unclear, the agent MUST pause and **ASK** per Rule 1.
