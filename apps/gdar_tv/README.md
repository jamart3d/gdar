# GDAR TV (Android TV Host)

This application target is the dedicated host for Google TV and Android TV devices. It utilizes the core `shakedown_core` package but is pre-configured for Leanback/D-Pad navigation and a dual-pane layout.

## 🚀 Quick Start (Development)

To run the TV interface on an emulator or connected TV device:

### VS Code
1.  Open the **Run and Debug** sidebar:
    *   Click the **Play with Bug** icon in the left-hand activity bar.
    *   Or use the shortcut: `Ctrl + Shift + D` (Windows/Linux) or `Cmd + Shift + D` (macOS).
2.  At the top of the sidebar, click the **Configuration Dropdown**.
3.  Select **`GDAR TV`** (or `GDAR Mobile (TV Override)` for tablet testing).
4.  Press **F5** or click the **Green Play** button.

*Note: The `GDAR TV` target defaults to `isTv = true` and skips mobile hardware detection.*

### Command Line
```bash
flutter run -t lib/main.dart -d <DEVICE_ID>
```

---

## 📺 TV Simulation (Tablet Emulator)

If you are testing on a standard Android Tablet emulator, you can force the TV environment logic using ADB intents.

### Force TV Mode ON
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://settings?key=force_tv&value=true" com.jamart3d.shakedown/.MainActivity
```

### Toggle UI Scaling (10-foot UI)
```powershell
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown/.MainActivity
```

---

## 🎨 Branding & Icons

This app target does not maintain its own launcher icons. It is configured via `flutter_launcher_icons` to pull branded assets directly from `shakedown_core`:
*   **Path**: `packages/shakedown_core/assets/images/gdar_icon.png`
*   **Foreground (Adaptive)**: `packages/shakedown_core/assets/images/gdar_icon_forground.png`

To regenerate icons for this target:
```bash
flutter pub run flutter_launcher_icons
```
(Or use the workspace-wide `melos run icons`).

## 🛠 Project Configuration

*   **Application ID**: `com.jamart3d.shakedown` (Shared with Mobile for universal asset/deep link parity).
*   **Theme**: Material Dark (OLED) with "Rock Salt" font overrides.
*   **Architecture**: Optimized dual-pane layout for landscape navigation.

For full technical details on TV debugging and intent parameters, see the [TV Debugging Guide](../../docs/TV_DEBUGGING.md).
