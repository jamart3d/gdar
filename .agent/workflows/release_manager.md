---
description: Manage the building and deployment of the GDAR application for Android and Web.
---
# Release Manager Workflow

**TRIGGERS:** build, release, shipit, aab, google play, web, firebase, deploy

## Android Release
1. Update the `version` in `pubspec.yaml` (e.g., `1.0.3+3`).
2. (Optional) Run `flutter clean` to ensure a fresh build.
3. Run `flutter build appbundle --release` to build the signed Android App Bundle.
4. The output file will be at `build/app/outputs/bundle/release/app-release.aab`.
5. Upload to [Google Play Console](https://play.google.com/console) internal testing.
6. Update `CHANGELOG.md` and copy summary to Play Console.

## Web Release
1. Run `flutter build web --release` to build the web assets.
2. The output will be in `build/web`.
3. Run `firebase deploy --only hosting` to deploy to Firebase Hosting.

## Shipit (Combined Workflow)
To run the full production release cycle, use the dedicated workflow:
1. Run `/shipit` to start the automated process (Version bump -> Build -> Git).

## Quick Rebuild
1. Run `flutter build appbundle --release` without version bump.
2. Upload the new AAB to Google Play Console.
