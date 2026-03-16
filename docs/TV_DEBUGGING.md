# TV Debugging & Simulation Guide

This document provides specialized instructions for simulating and debugging the GDAR TV environment on non-TV devices (specifically Tablet Emulators).

## 1. Using VS Code "Run" (Permanent / Recommended)
To hard-boot into the TV UI while developing, use the pre-configured VS Code launch profile. This bypasses hardware detection and forces the TV mode at the compilation level.

1.  Open the **Run and Debug** sidebar:
    *   Click the **Play with Bug** icon in the bar on the far left.
    *   Or use the shortcut: `Ctrl + Shift + D` (Win/Linux) or `Cmd + Shift + D` (macOS).
2.  Select **`GDAR Mobile (TV Override)`** (or `GDAR TV`) from the configuration dropdown at the top.
3.  Press **F5**.

**How it works:** This profile injects `--dart-define=FORCE_TV=true`, which is checked in `main.dart` to initialize the TV theme and dual-pane layout.

## 2. Using ADB Intents (Instant / Runtime)
Use deep links to toggle the `force_tv` setting while the app is already running. This will trigger a confirmation dialog and an automated app restart.

### Enable TV Mode
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://settings?key=force_tv&value=true" com.jamart3d.shakedown/.MainActivity
```

### Disable TV Mode
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://settings?key=force_tv&value=false" com.jamart3d.shakedown/.MainActivity
```

## 3. UI Scaling Tests
TV interfaces often require larger text for "10-foot" viewing. 

*   **Toggle Scaling**: `adb shell am start -W -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown/.MainActivity`
*   **Audit Navigation**: Use the D-Pad/Arrow keys on your emulator to verify "High Intensity Highlight" (RGB Glow) follows the focus node correctly.

## 4. Troubleshooting
The app determines TV mode via three paths:
1.  **Hardware**: Android's `UiModeManager.getCurrentModeType()` (via `MethodChannel`).
2.  **Compilation**: `--dart-define=FORCE_TV=true`.
3.  **Persistence**: `prefs.setBool('force_tv', true)` (triggered by the ADB intent).

If ADB returns `/system/bin/sh: ... inaccessible or not found`, ignore it; this is a shell interpretation error. As long as **`Status: ok`** is displayed, the intent was received.
