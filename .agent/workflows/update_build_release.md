---
description: Rebuild the release Android App Bundle (AAB) without updating the version number.
---

1. Run `flutter build appbundle --release` to build the signed Android App Bundle.
2. The output file will be located at `build/app/outputs/bundle/release/app-release.aab`.
3. Upload this file to the [Google Play Console](https://play.google.com/console) internal testing track.
