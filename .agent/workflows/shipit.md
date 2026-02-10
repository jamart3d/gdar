---
description: Automatically build release, save changes, and push (combine build_release and save).
---

// turbo-all

1. Update the `version` in `pubspec.yaml` (auto-increment build number).
2. Update `RELEASE_NOTES.txt` with a summary of recent changes.
3. Run `flutter build appbundle --release` to build the signed Android App Bundle.
4. Run `git add .` to stage all changes.
5. Generate a concise commit message including the new version number.
6. Run `git commit -m "Your generated message"`.
7. Run `git push` to upload changes.
8. Notify the user that the build is ready at `build/app/outputs/bundle/release/app-release.aab` and should be uploaded to Google Play Console.
