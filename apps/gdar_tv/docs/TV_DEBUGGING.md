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
43: 
44: ## 5. Automation & Scripting (GDAR Core)
45: 
46: Use the `shakedown://automate` deep link to execute scripted sequences of UI actions. This is useful for verifying cold-starts, audio reactivity, and screensaver transitions in a single command.
47: 
48: ### 5.1 Dice & Screensaver Sequence
49: Plays a random show, waits for loading, enables audio reactivity with a debug graph, and launches the screensaver.
50: 
```powershell
adb shell pm grant com.jamart3d.shakedown android.permission.RECORD_AUDIO
``

51: ```powershell
52: adb shell am start -W -a android.intent.action.VIEW `
53:   -d "shakedown://automate?steps=dice,sleep:4,   adb shell am start -W -a android.intent.action.VIEW -d "shakedown://automate?steps=dice,sleep:4,settings:oil_enable_audio_reactivity=true,settings:oil_audio_graph_mode=beat_debug,screensaver" com.jamart3d.shakedown/.MainActivity
55: ```

```powershell
   adb shell am start -W -a android.intent.action.VIEW `
  -d "shakedown://automate?steps=settings:oil_audio_graph_mode=corner_only,screensaver" `
  com.jamart3d.shakedown/.MainActivity
```
```powershell
   adb shell am start -W -a android.intent.action.VIEW ` -d "shakedown://automate?steps=settings:oil_audio_graph_mode=beat_debug,screensaver"` com.jamart3d.shakedown/.MainActivity
```


57: ### 5.2 Supported Automation Steps
58: 
59: | Step | Syntax | Description |
60: |---|---|---|
61: | **Dice** | `dice` | Triggers a random show selection. |
62: | **Wait** | `sleep:N` | Pauses for `N` seconds (e.g., `sleep:5`). |
63: | **Settings** | `settings:KEY=VALUE` | Updates any `SettingsProvider` key (e.g. `force_tv=true`). |
64: | **Screensaver**| `screensaver` | Launches the screensaver overlay immediately. |
65: 
66: > [!IMPORTANT]
67: > **Permissions**: Audio reactivity requires microphone access. Ensure it is granted before running automation:
68: > `adb shell pm grant com.jamart3d.shakedown android.permission.RECORD_AUDIO`
