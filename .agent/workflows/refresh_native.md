---
description: Rapidly clean and refresh native build artifacts and plugin registration.
---
# Refresh Native Workflow

Use this workflow when facing `MissingPluginException`, `GeneratedPluginRegistrant` errors, or Gradle/CocoaPods sync issues after dependency upgrades.

1.  **Clean Build Cache**
    // turbo
    `flutter clean`

2.  **Fetch Dependencies**
    // turbo
    `flutter pub get`

3.  **Regenerate Registration (Android)**
    // turbo
    `flutter build appbundle --debug`

4.  **Verification**
    Review the output for any persistent Gradle or plugin errors.
