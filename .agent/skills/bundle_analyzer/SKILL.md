---
name: bundle_analyzer
description: Tools for auditing application and asset size.
---

# Bundle Analyzer Skill

This skill analyzes the Flutter project's build artifacts to identify large assets or code dependencies.

## Usage

1. **Analyze Web Bundle**:
   - Run `flutter build web --source-maps --release`
   - Use `npx source-map-explorer build/web/main.dart.js` (if available) or manually audit `build/web/assets/`.

2. **Analyze Android Bundle**:
   - Run `flutter build appbundle --release`
   - Use the `size_guard` tool or `flutter build apk --analyze-size`.

## Size Guard Integration
- When running `/audit_size`, always check the `assets/` directory for non-WebP images.
- Propose conversion of PNG/JPG to WebP for 10-foot UI assets.
