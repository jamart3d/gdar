# Release Manager Skill

Manage the building and deployment of the GDAR application for Android and Web.

**TRIGGERS:** build, release, shipit, aab, google play, web, firebase, deploy

## Android Release
1. Update the `version` in `pubspec.yaml` (e.g., `1.0.3+3`).
2. Run `flutter build clean` to ensure a fresh build.
3. Run `flutter build appbundle --release` to build the signed Android App Bundle.
4. The output file will be at `build/app/outputs/bundle/release/app-release.aab`.
5. Upload to [Google Play Console](https://play.google.com/console) internal testing.
6. Update `RELEASE_NOTES.txt` and copy to Play Console.

## Web Release
1. Run `flutter build web --release` to build the web assets.
2. The output will be in `build/web`.
3. Run `firebase deploy --only hosting` to deploy to Firebase Hosting.

## Shipit (Combined Workflow)
1. Increment `pubspec.yaml` version and build number.
2. Update `RELEASE_NOTES.txt`.
3. Run `flutter build appbundle --release`.
4. Stage changes: `git add .`.
5. Commit with version number in message.
6. Push: `git push`.
7. Notify user of AAB location for manual Play Store upload.

## Quick Rebuild
1. Run `flutter build appbundle --release` without version bump.
2. Upload the new AAB to Google Play Console.
