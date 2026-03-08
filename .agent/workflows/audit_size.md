---
description: Audits application and asset size for Google TV storage constraints.
---
# Size Audit Workflow

**When to use:** To verify that recent asset additions or code changes don't exceed the 30MB APK target, especially for TV builds.

1.  **Trigger Skill:** Execute the `size_guard` skill.
2.  **Asset Scan**: Run the appropriate asset audit script:
    - **Windows**: `./.agent/skills/size_guard/scripts/audit_assets.ps1`
    - **Linux/bash**: `./.agent/skills/size_guard/scripts/audit_assets.sh`
3.  **Binary Audit:** Analyze the Flutter APK size:
    ```bash
    flutter build apk --analyze-size --target-platform android-arm64
    ```
4.  **Evaluate Thresholds:** Compare results against the thresholds in `.agent/skills/size_guard/SKILL.md`.
5.  **Report:** Provide a summary of large assets and total budget status.
