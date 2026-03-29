---
name: verify_navigation_sync
description: Verifies the bridge between AudioProvider playback events and UI navigation transitions in GDAR.
---

# Verify Navigation Sync

## Overview
This skill guides the agent in verifying "Play Random" and "Initial Start" scenarios where a playback attempt triggers a redirect via `SplashScreen` or tab-switching in the `Fruit` theme.

## Verification Protocol
When tasked with verifying navigation sync, the agent MUST perform the following structural checks:

1. **Audio Engine State Tracking**: 
   - Search the codebase using `grep_search` to verify that `AudioProvider.engineState` transitions are triggered *before* the UI router completes a redirect (especially if `delayPlayback` is active).
2. **Auto-Navigation Validation (Fruit Theme)**: 
   - Inspect the `FruitTabHostScreen` code to confirm it observes the correct state from `AudioProvider` and routes to the Playback Tab when a track begins.
3. **Splash Persistence**: 
   - Verify that `SplashScreen` does not push routes until the core systems (`AudioProvider`, `SettingsProvider`) are fully bootstrapped.

## Troubleshooting Logic
If a user is stuck on a splash screen or fails to swap tabs:
1. **Check activeMode:** Search for `SettingsProvider.activeMode` resolution (Web vs. TV vs. Mobile) to see if a strict platform constraint is interfering.
2. **Trace State Flags:** Locate `isNavigatingToTrack` within `AudioProvider` and ensure it is properly reset to `false` within `finally` blocks or upon track load completion.
