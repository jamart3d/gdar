---
name: pwa_manifest_auditor
description: Specialized tools for auditing PWA Branding and Manifest sync.
---
# PWA Manifest Auditor Skill

This skill provides a structured process for ensuring the PWA's static configuration matches the dynamic theme logic.

## Audit Targets
1.  **`web/manifest.json`**:
    - Check `theme_color` and `background_color`.
    - Ensure they match the "Default Dark" state of the app.
2.  **`web/index.html`**:
    - Check the `<meta name="theme-color">` tag.
    - Verify the `updateThemeBranding` JavaScript function exists and matches the Dart `PwaThemeSync` calls.
3.  **`lib/providers/theme_provider.dart`**:
    - Verify `_syncPwaBranding` logic follows the rules in `.agent/rules/pwa_branding_sync.md`.

## Verification Steps
1.  **Read Manifest**:
    ```bash
    cat web/manifest.json
    ```
2.  **Read Branding Logic**:
    ```bash
    grep -A 20 "updateThemeBranding" web/index.html
    ```
3.  **Check Sync Parity**:
    - Cross-reference the hex codes used in `theme_provider.dart` with those in `index.html`'s dynamic style injection.

## Correction Rule
If the manifest or index.html falls out of sync with the app's brand colors, prioritize updating the **dynamic** logic first, then update the **static** defaults to match the most common user state (Dark Mode).
