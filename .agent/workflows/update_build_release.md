---
description: Rebuild the release Android App Bundle (AAB) without updating the version number.
---

1. Run `flutter clean` to ensure a fresh build.
2. Run `flutter build appbundle --release` to build the signed Android App Bundle.
3. The output file will be located at `build/app/outputs/bundle/release/app-release.aab`.
4. Upload this file to the [Google Play Console](https://play.google.com/console) internal testing track.
5. Update `RELEASE_NOTES.txt` with the latest changes and copy them to the release notes section in the Play Console.
