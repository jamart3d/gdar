# Dev Tools Skill

Utilities for interacting with connected devices and capturing debug information.

**TRIGGERS:** reconnect, adb, screenshot, device, android

## ADB Reconnect
1. Run `adb devices`.
2. Restart in TCP mode: `adb tcpip 5555`.
3. Connect: `adb connect phone_soft`.

## Capture Screenshot
1. Ensure directory: `mkdir -p tool/screenshots`.
2. Capture: `adb shell screencap -p /sdcard/capture.png`.
3. Pull: `adb pull /sdcard/capture.png tool/screenshots/latest_capture.png`.
4. Clean: `adb shell rm /sdcard/capture.png`.
5. Notify user of location: `tool/screenshots/latest_capture.png`.
