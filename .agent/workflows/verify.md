---
description: Native cross-platform formatting and analysis check.
---
# Verify Workflow

**When to use:** For standard code hygiene checks before committing or after significant edits. Much faster than `/checkup` for local-only validation.

// turbo-all

1.  **Read Tool:** `tool/verify.dart`.
2.  **Run Verify:** Execute the local verification command.
    ```powershell
    dart run tool/verify.dart
    ```
3.  **Filtered Run (Optional):** If the user specifies targets or skips.
    ```powershell
    dart run tool/verify.dart lib/ui --no-analyze
    ```
