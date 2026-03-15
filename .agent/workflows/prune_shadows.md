---
description: Audit and remove redundant UI components from app targets after monorepo migration.
---
# /prune_shadows Workflow

**When to use:** Use this when an app target (e.g., `apps/gdar_tv`) contains duplicate widgets or screens that already exist in `packages/shakedown_core`.

1.  **Identify Shadowed Files**:
    *   List files in the app target: `apps/<target>/lib/ui/`.
    *   Compare them against `packages/shakedown_core/lib/ui/`.
    *   Focus on: `screens/`, `widgets/`, and `utils/`.

2.  **Verify Core Feature Parity**:
    *   Read the shadowed file in the app target.
    *   Compare its logic with the version in `shakedown_core`.
    *   **CRITICAL**: If the app-target version has unique logic required for that platform, **DO NOT DELETE**. Instead, consider refactoring the core version to support that platform's needs via `SettingsProvider` or `DeviceService`.

3.  **Update Imports**:
    *   Identify all files in the app target that import the shadowed local file.
    *   Update those imports to point to `package:shakedown_core/...`.

4.  **Prune**:
    *   Delete the local duplicate file from the app target.
    *   Run `flutter analyze` to ensure no broken references remain.

5.  **Verify Build**:
    *   Run a release build for the affected target to ensure the core component renders correctly in the app environment.
