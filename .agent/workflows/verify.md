---
description: Native cross-platform formatting and analysis check.
---
# Verify Workflow (Monorepo)

**When to use:** For standard code hygiene checks before committing or after significant edits. Much faster than `/validate` for local-only validation.

// turbo-all

> [!NOTE]
> **MONOREPO**: `scripts/verify.dart` now operates from the workspace root and recurses into `apps/` and `packages/`.

1.  **Read Tool:** `scripts/verify.dart`.
2.  **Run Verify:** Execute the local verification command from the workspace root.
    ```powershell
    dart run scripts/verify.dart
    ```
3.  **Filtered Run (Optional):** If the user specifies targets or skips.
    ```powershell
    dart run scripts/verify.dart apps/gdar_mobile/lib --no-analyze
    dart run scripts/verify.dart packages/shakedown_core/lib --no-analyze
    ```
