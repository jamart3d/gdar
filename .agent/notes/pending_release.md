# Pending Release Notes

### Status
- **Current Version**: `1.3.9+219`
- **Git State**: BUMPED
- **Goal**: Monitoring release success and preparing for next cycle.

### What's In This Release
- **TV UI**: Refined visual highlights—now ONLY the active cursor has the rainbow RGB border for maximum clarity.
- **TV UI**: Added focus memory to the track list; it now remembers your last selected item when returning to the library.
- **Web UI**: Added a "Crossfade Play/Pause" setting for smooth audio transitions on the Fruit theme.
- **Data**: Conducted a major cleanup of the Grateful Dead song structural hints, removing JGB and non-GD side projects for accuracy.

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
