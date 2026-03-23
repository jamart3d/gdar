# SKILL: Verify Navigation Sync

**Description**: Automates verification of the bridge between `AudioProvider` playback events and UI navigation transitions.

## Overview
This skill focuses on "Play Random" and "Initial Start" scenarios where a playback attempt may trigger a redirect via `SplashScreen` or tab-switching in the `Fruit` theme.

## Verification Checklist
- **Audio Engine State**: Ensure `AudioProvider.engineState` is updated BEFORE the UI navigation completes if `delayPlayback` is active.
- **Auto-Navigation**: Confirm that `FruitTabHostScreen` correctly switches to the Playback Tab when a track begins from search or recommendations.
- **Splash Persistence**: Verify that `SplashScreen` does not route until `AudioProvider` is fully bootstrapped.

## Troubleshooting
If navigation fails:
1. Check the `SettingsProvider.activeMode` resolution (Web vs. TV vs. Mobile).
2. Trace `AudioProvider.isNavigatingToTrack` to ensure it's reset on track load.
