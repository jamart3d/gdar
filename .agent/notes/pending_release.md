# Pending Release Notes

### Status
- **Current Version**: `1.2.7+207`
- **Git State**: Local changes staged with version bump.
- **Goal**: Finalize build and deployment for `1.2.7+207`.

### What's In This Release (1.2.7+207)
- **Web Audio**: Hardened source switching logic in `AudioProvider` to ignore transient state mismatches during manual show transitions.
- **Web Audio**: Optimized `PlaybackScreen` list synchronization by adding safety guards to scroll and jump operations, preventing crashes when the view detaches on browser re-renders.
- **Architecture**: Improved navigation between Library and Playback screens in Fruit theme by routing through a unified `FruitTabHostScreen`.
- **UI**: Refined hit-testing and layout for the `FruitNowPlayingCard` to ensure controls remain responsive during rapid state updates.
- **Testing**: Added unit tests for `AudioProvider` focusing on pre-queueing and source synchronization stability.

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
