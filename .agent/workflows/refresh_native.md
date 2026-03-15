---
description: Rapidly clean and refresh native build artifacts and plugin registration.
---
# Refresh Native Workflow (Monorepo)

Use this workflow when facing `MissingPluginException`, `GeneratedPluginRegistrant` errors, or Gradle/CocoaPods sync issues after dependency upgrades.

> [!IMPORTANT]
> **MONOREPO**: `flutter clean` and `flutter pub get` must be run from the **app target directory**, not the workspace root.

1.  **Clean Build Cache** (run from the affected app target)
    // turbo
    ```powershell
    cd apps/gdar_mobile; flutter clean
    ```
    Or for TV: `cd apps/gdar_tv; flutter clean`

2.  **Fetch Dependencies** (from workspace root — resolves all targets)
    // turbo
    `flutter pub get`

3.  **Regenerate Registration (Android)**
    // turbo
    ```powershell
    cd apps/gdar_mobile; flutter build appbundle --debug
    ```

4.  **Verification**
    Review the output for any persistent Gradle or plugin errors.
