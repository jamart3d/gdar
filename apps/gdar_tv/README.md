# GDAR TV

`gdar_tv` is the dedicated Google TV / Android TV host for GDAR. It locks the
app into TV mode, boots in landscape, and uses the shared TV-oriented logic in
`packages/shakedown_core`.

## What This Target Does

- Runs the TV-first D-pad experience directly
- Uses the Android theme stack with TV-specific behavior enabled
- Provides a dedicated host for TV development and debugging
- Does not produce a separate Play Store release artifact

Important: TV is distributed through the same Android release AAB built from
`apps/gdar_mobile`. This target exists for direct TV development and testing.

## Run Locally

From the workspace root:

```bash
flutter run -t apps/gdar_tv/lib/main.dart -d <DEVICE_ID>
```

From this directory:

```bash
flutter run -t lib/main.dart -d <DEVICE_ID>
```

## TV Debugging

Useful deep links:

```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://settings?key=force_tv&value=true" com.jamart3d.shakedown
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown
```

See:

- `apps/gdar_tv/docs/TV_DEBUGGING.md`
- root `README.md`

## Build Notes

This target is useful for running and testing the TV shell directly, but the
standard Android store release is still built from `apps/gdar_mobile`.

## Branding

Launcher icon assets are sourced from `packages/shakedown_core/assets/images/`.
Workspace-wide icon regeneration is handled with:

```bash
melos run icons
```

## Notes

- The app starts with `isTv = true`
- Orientation is locked to landscape
- TV screensaver and D-pad flows are owned by shared core code, not duplicated
  in this target
