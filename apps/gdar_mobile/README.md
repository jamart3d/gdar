# GDAR Mobile

`gdar_mobile` is the Android/mobile host for GDAR. It uses the shared
`shakedown_core` package and the `gdar_android` theme package for the
mobile-first Material 3 experience.

## What This Target Does

- Runs the phone and tablet UI
- Can force TV mode for local debugging via `FORCE_TV` or deep links
- Produces the Android Play Store AAB
- Shares the application id used across the Android distribution model

Important: the Play Store release is a single AAB built from this target. That
bundle is what serves both phone and TV device classes.

## Run Locally

From the workspace root:

```bash
flutter run -t apps/gdar_mobile/lib/main.dart
```

From this directory:

```bash
flutter run -t lib/main.dart
```

## TV Override for Local Testing

This target can boot the TV experience for emulator or tablet testing.

Using a Dart define:

```bash
flutter run -t lib/main.dart --dart-define=FORCE_TV=true
```

Using a deep link on a running build:

```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://settings?key=force_tv&value=true" com.jamart3d.shakedown
```

## Build

Android release bundle:

```bash
flutter build appbundle --release
```

Output:

```text
build/app/outputs/bundle/release/app-release.aab
```

## Shared Dependencies

This target depends on:

- `packages/shakedown_core` for shared providers, services, screens, and assets
- `packages/styles/gdar_android` for Android visual styling

## Notes

- Mobile and TV Android distribution share the same release AAB
- Root workspace commands such as `melos run analyze` and `melos run test`
  should still be run from the repo root
- For shared release guidance, see the root `README.md` and
  `.agent/workflows/shipit.md`
