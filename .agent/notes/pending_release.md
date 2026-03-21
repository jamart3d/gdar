# Pending Release Notes

### Status
- **Current Version**: `1.3.2+212`
- **Git State**: RELEASE PENDING
- **Goal**: Monitoring feedback after `1.3.2+212` release.

### What's In This Release (1.3.2+212)
- **TV Enhancement**: Finalized infrastructure for true stereo L/R VU meters via `AudioPlaybackCapture` (API 29+).
- **TV Architecture**: Conducted a comprehensive screensaver audio audit (2026-03-21) to align native detector levels with visualizer telemetry.
- **Documentation**: Updated audio graph modes, reactivity status, and tuning guides for advanced TV configuration.
- **Maintenance**: Synchronized codebase formatting and refined performance-tier naming in `StealGraph`.

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
