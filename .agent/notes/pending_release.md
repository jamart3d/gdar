# Pending Release Notes

### Status
- **Current Version**: `1.2.8+208`
- **Git State**: Clean and pushed to main.
- **Goal**: Monitoring feedback after `1.2.8+208` release.

### What's In This Release (1.2.8+208)
- **TV Bootstrap**: Standardized `SharedPreferences` injection in `GdarTvApp` to ensure consistent state initialization on TV devices.
- **Testing**: Hardened TV startup regression tests by addressing race conditions between specialized app navigation and inactivity timers.

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
