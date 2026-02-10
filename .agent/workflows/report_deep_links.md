---
description: Generate a comprehensive versioned manifest of available deep links.
---

1. **Scan Android Manifest**: Read `android/app/src/main/AndroidManifest.xml` to identify registered intent filters, schemes (e.g., `shakedown://`), and deep linking flags.
2. **Scan Dart Logic**: Inspect `lib/main.dart` or the primary link handler (look for `AppLinks` usage) to map host patterns (e.g., `play-random`, `navigate`) and their corresponding query parameters.
3. **Verify App Actions**: Check `android/app/src/main/res/xml/shortcuts.xml` to see how Assistant/Gemini intents map to internal deep links.
4. **Extract Project Metadata**: Get the current version from `pubspec.yaml`.
5. **Generate Manifest**: Create a file named `DEEP_LINK_MANIFEST_V<version>.md` including:
    - Current Date
    - AI Assistant Name (Antigravity) and Model Version (Gemini 2.0)
    - App Version
    - Categorized links (Release Mode vs Debug Mode)
    - App Action / Intent mappings
6. **Cleanup**: Remove any older, non-versioned report files (e.g., `report.md`).
