# Pending Release Notes

### Status
- **Current Version**: `1.3.7+217`
- **Git State**: LIVE
- **Goal**: Monitoring release success and preparing for next cycle.

### What's In This Release
- **TV Enhancement**: New `InactivityService` for reliable screensaver triggering.
- **TV Enhancement**: Improved Android Manifest for better Google TV compatibility.
- **Testing**: Added regression tests for TV inactivity and screensaver flow.

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
