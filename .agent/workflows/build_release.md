---
description: Build a release Android App Bundle (AAB) for Google Play.
---

1. Update the `version` in `pubspec.yaml`. (e.g., `1.0.3+3`)
2. Run `flutter clean` to ensure a fresh build.
3. Run `flutter build appbundle --release` to build the signed Android App Bundle.
3. The output file will be located at `build/app/outputs/bundle/release/app-release.aab`.
4. Upload this file to the [Google Play Console](https://play.google.com/console) internal testing track.
5. Update `RELEASE_NOTES.txt` with the latest changes and copy them to the release notes section in the Play Console.
