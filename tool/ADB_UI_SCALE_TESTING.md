# ADB UI Scale Testing - Quick Reference

## Prerequisites

- ADB installed and in PATH
- Device/emulator connected: `adb devices`
- Shakedown app installed and running

## Deep Link Commands

### Toggle UI Scale

```bash
# Enable UI scale (1.5x)
adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown

# Disable UI scale (1.0x)
adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=false" com.jamart3d.shakedown
```

### Change Font

```bash
# Set to default font
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=default" com.jamart3d.shakedown

# Set to Caveat
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=caveat" com.jamart3d.shakedown

# Set to Permanent Marker
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=permanent_marker" com.jamart3d.shakedown

# Set to Lacquer
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=lacquer" com.jamart3d.shakedown

# Set to Rock Salt
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=rock_salt" com.jamart3d.shakedown
```

### Set System Font Size

```bash
# Small (0.85)
adb shell settings put system font_scale 0.85

# Normal (1.0)
adb shell settings put system font_scale 1.0

# Large (1.15)
adb shell settings put system font_scale 1.15

# Extra Large (1.3)
adb shell settings put system font_scale 1.3
```

### Combined Testing Examples

```bash
# Test worst-case scenario (largest text + UI scale)
adb shell settings put system font_scale 1.3
adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown

# Test Rock Salt font with UI scale
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=rock_salt" com.jamart3d.shakedown
adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown

# Reset to defaults
adb shell settings put system font_scale 1.0
adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name=default" com.jamart3d.shakedown
adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=false" com.jamart3d.shakedown
```

## Automated Scripts

### 8-Look Audit (8 screenshots)

```bash
cd /home/jam/StudioProjects/gdar
python3 tool/adb_ui_scale_test.py
```

Output: `screenshots/ui_scale_audit/<timestamp>/`

### Trigger Point Analysis (fine-grained)

```bash
python3 tool/adb_trigger_point_test.py
```

Output: `screenshots/trigger_point_audit/<timestamp>/`

## What to Look For

1. **Text Collisions**: Venue text overlapping date text
2. **Vertical Gap**: Should always have visible space between venue and date
3. **Marquee Behavior**: Should only scroll horizontally, not vertically
4. **Card Height**: Should scale proportionally with UI scale setting
5. **Badge Alignment**: Rating stars and SHNID badges should stay in corners
6. **Font Rendering**: Text should be legible and properly sized across all fonts
