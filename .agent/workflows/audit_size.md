---
description: Audits application and asset size for Google TV storage constraints.
---
# Size Audit Workflow (Monorepo)

**When to use:** To verify that recent asset additions or code changes don't exceed the 30MB APK target, especially for TV builds.

> [!NOTE]
> **MONOREPO**: Build commands must run from the specific app target directory, not the workspace root.

1.  Run the `size_guard` workflow.
2.  **Asset Scan**: Run the appropriate asset audit script:
    - **Windows**: `./scripts/size_guard/audit_assets.ps1`
    - **Linux/bash**: `./scripts/size_guard/audit_assets.sh`
3.  **Binary Audit:** Analyze the Flutter APK size from the target app:
    ```powershell
    cd apps/gdar_mobile; flutter build apk --analyze-size --target-platform android-arm64
    ```
    For TV:
    ```powershell
    cd apps/gdar_tv; flutter build apk --analyze-size --target-platform android-arm64
    ```
4.  **Evaluate Thresholds:** Compare results against the thresholds in `.agent/workflows/size_guard.md`.
5.  **Report:** Provide a summary of large assets and total budget status.

