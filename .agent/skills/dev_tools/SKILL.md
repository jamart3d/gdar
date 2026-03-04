---
name: dev_tools
description: ADB wrappers and utilities for interacting with connected Android/TV devices.
---
# Dev Tools Skill

**TRIGGERS:** adb, screenshot, screencap, logcat, pull

This skill provides the standard commands for interacting with a connected physical device or emulator.

## 1. Screenshots (UI Auditing)
*   **Action:** Capture the screen and pull it to the local temp directory for analysis.
*   **Command 1:** `adb shell screencap -p /sdcard/gdar_screen.png`
*   **Command 2:** `adb pull /sdcard/gdar_screen.png ./temp/gdar_screen.png`
*   **Note:** Once pulled, the agent can use the path `./temp/gdar_screen.png` to analyze the UI against specific design rules (e.g., via the `/screenshot_audit` workflow).

## 2. Live Logs (Crash Isolation)
*   **Action:** Dump the recent device logcat, filtering for GDAR or Flutter errors.
*   **Command:** `adb logcat -d -v time flutter:V "*:S"`
*   *(Note: Add `> ./temp/device_log.txt` if the output is too large for context).*

## 3. Permissions Testing
*   **Action:** Force-grant or revoke permissions via ADB to test app resilience (e.g., testing the screensaver visualizer without Microphone permission).
*   **Command (Grant):** `adb shell pm grant com.jamart3d.gdar android.permission.RECORD_AUDIO`
*   **Command (Revoke):** `adb shell pm revoke com.jamart3d.gdar android.permission.RECORD_AUDIO`
