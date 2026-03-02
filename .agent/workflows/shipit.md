---
description: Combined workflow for versioning, building, and deploying the GDAR application.
---
# Shipit Workflow

**TRIGGERS:** shipit, release, prod, deploy

This workflow automates the entire release process from version bumping to git synchronization.

## 1. Preparation
1. Increment the `version` number and build number in `pubspec.yaml`.
2. Update `docs/RELEASE_NOTES.txt` with the latest changes and bug fixes.
3. (Optional) Run `flutter clean` to ensure a fresh build if major changes were made.

## 2. Build Production Bundle
// turbo
1. Run `flutter build appbundle --release` to generate the signed Android App Bundle.
   - Output: `build/app/outputs/bundle/release/app-release.aab`

## 3. Web Deployment (If Applicable)
// turbo
1. Run `flutter build web --release`.
// turbo
2. Run `firebase deploy --only hosting` to update the web version.

## 4. Git Synchronization
// turbo
1. Stage all changes: `git add .`
// turbo
2. Commit with the version number in the message: `git commit -m "Release vX.X.X+X"`
// turbo
3. Push to origin: `git push`

## 5. Final Notification
1. Inform the user that the build is ready. 
2. Remind them to upload `build/app/outputs/bundle/release/app-release.aab` to the [Google Play Console](https://play.google.com/console).
3. Provide the summary of the release notes for convenience.
