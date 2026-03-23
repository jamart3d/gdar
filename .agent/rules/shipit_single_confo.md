# Shipit Single Confirmation Rule

When an explicit release intent (e.g., "shipit", "/shipit", "release") is triggered:

1.  **Unified Plan**: The agent MUST provide a single, comprehensive "Release Plan" covering Preflight, Versioning, Changelog, Build, and Deploy steps.
2.  **Explicit Consent**: The agent MUST wait for exactly ONE user confirmation for the entire plan.
3.  **Unattended Execution**: Once approved, the agent MUST run ALL subsequent `run_command` steps with `SafeToAutoRun: true` in a chained execution (using `;` in PowerShell or `&&` in Bash) until the process is complete OR an error occurs.
4.  **Error Handling**: If a step in the release chain fails, the agent MUST immediately stop execution and report the specific failure without attempting to "fix and proceed" without user review.
