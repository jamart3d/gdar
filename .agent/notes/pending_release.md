# Pending Release Notes

### Status
- **Current Version**: `1.3.1+211`
- **Git State**: RELEASE PENDING
- **Goal**: Monitoring feedback after `1.3.1+211` release.

### What's In This Release (1.3.1+211)
- **TV Enhancement**: Implemented `StereoCapture` for the Android TV engine, providing high-fidelity PCM capture for real-time visualizers.
- **TV Architecture**: Added specialized TV banner assets and startup metadata configurations for enhanced Leanback visibility.
- **Screensaver**: Optimized EKG spread and beat detection sensitivity in `default_settings.dart` for a more responsive reactive experience.
- **TV Debugging**: Expanded and refined the `TV_DEBUGGING.md` documentation with new deep-link automation sequences for rapid UI verification.

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
