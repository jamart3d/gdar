# Pending Release Notes

### Status
- Release commit `b098534` (`release: 1.2.5+205`) has been created and pushed to `origin/main`.
- App versions are synced at `1.2.5+205` in:
  - `apps/gdar_mobile/pubspec.yaml`
  - `apps/gdar_tv/pubspec.yaml`
  - `apps/gdar_web/pubspec.yaml`
- `CHANGELOG.md` and `docs/PLAY_STORE_RELEASE.txt` have been updated for `1.2.5+205`.
- Workspace verification previously completed cleanly:
  - `dart run melos run analyze`
  - `dart run melos run test` (`00:17 +180: All tests passed!`)

### What Shipped In This Release
- TV screensaver text spacing and squish-to-fit improvements for long titles.
- Overflow-safe playback header/layout hardening for constrained panel states.
- TV startup contract cleanup through `SplashScreen` with no TV onboarding flow.
- Smaller, more durable regression tests across TV startup, playback, screensaver, and shared widget coverage.
- Monorepo docs refresh and new test-planning/scorecard docs.

### Next Commands
Use PowerShell.

Android AAB:
```powershell
Set-Location C:\Users\jeff\StudioProjects\gdar\apps\gdar_mobile
flutter build appbundle --release
```

Web build:
```powershell
Set-Location C:\Users\jeff\StudioProjects\gdar\apps\gdar_web
flutter build web
```

Firebase deploy:
```powershell
Set-Location C:\Users\jeff\StudioProjects\gdar
firebase deploy --only hosting
```

### Android Artifact Path
- `apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab`

### Play Store Note
- `docs/PLAY_STORE_RELEASE.txt` is ready to paste into Play Console release notes.
