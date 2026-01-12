---
description: Build a release Android App Bundle (AAB) for Google Play.
---

1. Run `flutter clean` to ensure a fresh build.
2. Run `flutter build appbundle --release` to build the signed Android App Bundle.
3. The output file will be located at `build/app/outputs/bundle/release/app-release.aab`.
4. Upload this file to the [Google Play Console](https://play.google.com/console) internal testing track.
