#!/usr/bin/env python3
"""
ADB Comprehensive Font & Scale Test

Tests ShowListCard spacing across ALL combinations:
- 4 system font sizes (0.85, 1.0, 1.15, 1.3)
- 2 UI scale states (off, on)
- 4 app fonts (default, caveat, permanent_marker, rock_salt)

Total: 40 screenshots

Usage:
    python3 tool/adb_comprehensive_test.py
    
    # Or test specific font only:
    python3 tool/adb_comprehensive_test.py --font rock_salt

Requirements:
    - ADB installed and in PATH
    - Device/emulator connected and authorized
    - Shakedown app installed and running
"""

import subprocess
import time
import os
import argparse
from datetime import datetime

# Test matrix
FONT_SCALES = [0.85, 1.0, 1.15, 1.3]
UI_SCALES = [False, True]
APP_FONTS = ['default', 'caveat', 'permanent_marker', 'rock_salt']

# ADB commands
ADB_SET_SYSTEM_FONT = "adb shell settings put system font_scale {}"
ADB_SET_UI_SCALE = 'adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled={}" com.jamart3d.shakedown'
ADB_SET_APP_FONT = 'adb shell am start -a android.intent.action.VIEW -d "shakedown://font?name={}" com.jamart3d.shakedown'

# Output directory
SCREENSHOT_DIR = "screenshots/comprehensive_test"
TIMESTAMP = datetime.now().strftime("%Y%m%d_%H%M%S")
OUTPUT_DIR = f"{SCREENSHOT_DIR}/{TIMESTAMP}"


def run_adb_command(command):
    """Execute ADB command and return result."""
    try:
        result = subprocess.run(
            command,
            shell=True,
            capture_output=True,
            text=True,
            timeout=10
        )
        return result.returncode == 0
    except subprocess.TimeoutExpired:
        print(f"  ⚠️  Command timed out: {command}")
        return False


def capture_screenshot(filename):
    """Capture screenshot from device."""
    filepath = os.path.join(OUTPUT_DIR, filename)
    
    try:
        with open(filepath, 'wb') as f:
            result = subprocess.run(
                "adb exec-out screencap -p",
                shell=True,
                stdout=f,
                timeout=10
            )
        return result.returncode == 0
    except Exception as e:
        print(f"  ⚠️  Screenshot failed: {e}")
        return False


def main():
    """Run the comprehensive test."""
    parser = argparse.ArgumentParser(description='Comprehensive font and scale testing')
    parser.add_argument('--font', type=str, help='Test specific font only (default, caveat, permanent_marker, rock_salt)')
    args = parser.parse_args()
    
    # Filter fonts if specified
    fonts_to_test = [args.font] if args.font else APP_FONTS
    
    if args.font and args.font not in APP_FONTS:
        print(f"❌ Invalid font: {args.font}")
        print(f"Valid fonts: {', '.join(APP_FONTS)}")
        return
    
    print("=" * 60)
    print("ADB Comprehensive Font & Scale Test")
    print("=" * 60)
    print()
    
    # Create output directory
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    print(f"📁 Output directory: {OUTPUT_DIR}")
    print()
    
    # Check ADB connection
    print("🔍 Checking ADB connection...")
    if not run_adb_command("adb devices"):
        print("❌ ADB not available or no device connected")
        return
    print("✅ ADB connected")
    print()
    
    # Calculate total tests
    total_tests = len(FONT_SCALES) * len(UI_SCALES) * len(fonts_to_test)
    current_test = 0
    
    print(f"📊 Test Matrix:")
    print(f"   System Font Scales: {len(FONT_SCALES)} ({', '.join(map(str, FONT_SCALES))})")
    print(f"   UI Scales: {len(UI_SCALES)} (off, on)")
    print(f"   App Fonts: {len(fonts_to_test)} ({', '.join(fonts_to_test)})")
    print(f"   Total Screenshots: {total_tests}")
    print()
    
    results = []
    
    for app_font in fonts_to_test:
        print(f"🎨 Testing Font: {app_font.upper()}")
        print("-" * 60)
        
        # Set app font once per batch
        if not run_adb_command(ADB_SET_APP_FONT.format(app_font)):
            print(f"❌ Failed to set app font to {app_font}")
            continue
        
        time.sleep(1)
        
        for system_font_scale in FONT_SCALES:
            for ui_scale in UI_SCALES:
                current_test += 1
                ui_scale_str = "on" if ui_scale else "off"
                test_name = f"{app_font}_sys{system_font_scale}_ui{ui_scale_str}"
                
                print(f"  [{current_test}/{total_tests}] System={system_font_scale}, UI={ui_scale_str}", end="")
                
                # Set system font scale
                if not run_adb_command(ADB_SET_SYSTEM_FONT.format(system_font_scale)):
                    print(f" ❌ Failed (system font)")
                    results.append((test_name, "FAILED - System Font"))
                    continue
                
                time.sleep(0.5)
                
                # Set UI scale
                ui_scale_value = "true" if ui_scale else "false"
                if not run_adb_command(ADB_SET_UI_SCALE.format(ui_scale_value)):
                    print(f" ❌ Failed (UI scale)")
                    results.append((test_name, "FAILED - UI Scale"))
                    continue
                
                # Wait for UI to settle
                time.sleep(1.5)
                
                # Capture screenshot
                screenshot_name = f"{test_name}.png"
                if capture_screenshot(screenshot_name):
                    print(f" ✅")
                    results.append((test_name, "SUCCESS"))
                else:
                    print(f" ❌ Failed (screenshot)")
                    results.append((test_name, "FAILED - Screenshot"))
        
        print()
    
    # Generate summary report
    print("=" * 60)
    print("Test Summary")
    print("=" * 60)
    print()
    
    success_count = sum(1 for _, status in results if status == "SUCCESS")
    print(f"Total Tests: {total_tests}")
    print(f"Successful: {success_count}")
    print(f"Failed: {total_tests - success_count}")
    print()
    
    # Group results by font
    for app_font in fonts_to_test:
        font_results = [r for r in results if r[0].startswith(app_font)]
        font_success = sum(1 for _, status in font_results if status == "SUCCESS")
        print(f"  {app_font}: {font_success}/{len(font_results)} successful")
    
    print()
    print(f"📁 Screenshots saved to: {OUTPUT_DIR}")
    print()
    print("Next Steps:")
    print("1. Review screenshots grouped by font")
    print("2. Look for font-specific spacing issues")
    print("3. Compare behavior across fonts at same scale settings")
    print()


if __name__ == "__main__":
    main()
