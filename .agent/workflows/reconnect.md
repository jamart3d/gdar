---
description: Reconnect to Android device via ADB using phone_soft
---

1. Run `adb devices` to check for connected devices.
2. Run `adb tcpip 5555` to restart ADB in TCP mode.
3. Run `adb connect phone_soft` to connect to the phone over the network.
