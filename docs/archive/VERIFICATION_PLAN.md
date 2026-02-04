# Verification & Test Plan: Font Normalization
**Date:** 2026-01-25 12:56 PM
**App Version:** 1.0.8+8

## Goal
Automate the verification of layout changes across different fonts (Roboto, Rock Salt) and scaling modes (Standard, UI Scale ON) using ADB-driven navigation and screenshot capture.

## 1. Automation Infrastructure
We will use `adb shell` to drive the application state, ensuring reproducible test conditions.

### A. Device Configuration (Pre-Test)
To prevent the screen from turning off during the test run:
```bash
# Keep screen on while plugged in (USB/AC/Wireless)
adb shell svc power stayon true
# Ensure orientation is fixed (optional, app already locks to portrait)
adb shell settings put system accelerometer_rotation 0
```

### B. Deep Link Intents
We will implement/expand the following Deep Links to bypass manual navigation.

| Action | URI Scheme | Implementation Status |
| :--- | :--- | :--- |
| **Set Font** | `shakedown://font?name={font}` | ✅ Implemented |
| **Set UI Scale** | `shakedown://ui-scale?enabled={true/false}` | ✅ Implemented |
| **Navigate** | `shakedown://navigate?screen={screen_id}` | 🚧 **To Be Added** |
| **Reset App** | `shakedown://debug?action=reset_prefs` | 🚧 **To Be Added** |

**Navigation Targets:**
- `settings`: Opens `SettingsScreen`.
- `splash`: Replaces current stack with `SplashScreen` (for font check).
- `home`: Pop to `ShowListScreen`.

### C. Screenshot Automation Script
A Python script (`scripts/verify_fonts.py`) will:
1.  **Launch App:** `adb shell am start ...`
2.  **Configure Environment:**
    - Set Font: Rock Salt
    - Set UI Scale: OFF
3.  **Navigate & Capture:**
    - Go to Splash -> Screenshot (`splash_rock_salt_1x.png`)
    - Go to Home -> Screenshot (`home_rock_salt_1x.png`)
    - Go to Settings -> Screenshot (`settings_rock_salt_1x.png`)
4.  **Repeat with UI Scale ON.**

## 2. Test Scenarios (Before vs. After)

### Scenario 1: The "Rock Salt" Overflow
**Focus:** `SettingsScreen` Font Preview & `ShowListScreen` badges.
- **Before:** Text might be clipped vertically or overflow container width at 1.2x scale.
- **After:** Text should fit comfortable with the new 0.85 scaling factor applied in `FontLayoutConfig`.

### Scenario 2: Splash Screen Consistency
**Focus:** Checklist items on the Splash Screen.
- **Before:** "Checking Archives..." items are huge and may wrap when UI Scale is ON.
- **After:** Items respect the `FontLayoutConfig` constraints, remaining legible but compact.

### Scenario 3: Onboarding & First Run
**Focus:** Verify font scaling on the Onboarding screen.
- **Action:** Trigger `reset_prefs`, navigate to Root.
- **Capture:** `onboarding_{font}_{scale}.png`

### Scenario 4: Player & Sliding Panel
**Focus:** Track list readability and Player controls.
- **Action:** Open a show (to populate list), Expand Panel.
- **Capture:** `player_{font}_{scale}.png`

## 3. Implementation Plan for Test Tools

### Step 1: Update `main.dart`
- Add `onboarding` and `player` (expand panel) to deep link handlers.
- Ensure `reset_prefs` correctly forces a UI rebuild to Onboarding.

### Step 2: Update Test Script (`verify_fonts.py`)
- Add "Keep Awake" loop (simulated taps).
- Add steps for Onboarding and Player.
- **Verification Flow:**
    1. Reset -> Screenshot Onboarding.
    2. Complete Onboarding (skip to Home).
    3. Open a Show -> Screenshot Track List.
    4. Expand Player -> Screenshot Playback.
    5. Settings & Splash tests.

## 4. Execution Command
```bash
python3 scripts/verify_fonts.py --device {DEVICE_ID}
```
