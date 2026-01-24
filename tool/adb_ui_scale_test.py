#!/usr/bin/env python3
"""
ADB UI Scale Test - 8-Look Audit

Tests ShowListCard spacing across 4 system font sizes × 2 UI scale states.
Generates screenshots for manual inspection of text collisions and spacing issues.

Usage:
    python3 tool/adb_ui_scale_test.py

Requirements:
    - ADB installed and in PATH
    - Device/emulator connected and authorized
    - Shakedown app installed and running
"""

import subprocess
import time
import os
from datetime import datetime

# Test matrix
FONT_SCALES = [0.85, 1.0, 1.15, 1.3]
UI_SCALES = [False, True]

# ADB commands
ADB_SET_FONT = "adb shell settings put system font_scale {}"
ADB_SET_UI_SCALE = 'adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled={}" com.jamart3d.shakedown'
ADB_SCREENSHOT = "adb exec-out screencap -p > {}"

# Output directory
SCREENSHOT_DIR = "screenshots/ui_scale_audit"
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
    command = ADB_SCREENSHOT.format(filepath)
    
    # Use shell redirection properly
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
    """Run the 8-Look audit test."""
    print("=" * 60)
    print("ADB UI Scale Test - 8-Look Audit")
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
    
    # Run test matrix
    total_tests = len(FONT_SCALES) * len(UI_SCALES)
    current_test = 0
    
    results = []
    
    for font_scale in FONT_SCALES:
        for ui_scale in UI_SCALES:
            current_test += 1
            ui_scale_str = "on" if ui_scale else "off"
            test_name = f"font_{font_scale}_scale_{ui_scale_str}"
            
            print(f"[{current_test}/{total_tests}] Testing: Font={font_scale}, UI Scale={ui_scale_str}")
            
            # Set font scale
            print(f"  📝 Setting font scale to {font_scale}...")
            if not run_adb_command(ADB_SET_FONT.format(font_scale)):
                print(f"  ❌ Failed to set font scale")
                results.append((test_name, "FAILED - Font Scale"))
                continue
            
            time.sleep(0.5)
            
            # Set UI scale
            ui_scale_value = "true" if ui_scale else "false"
            print(f"  📝 Setting UI scale to {ui_scale_value}...")
            if not run_adb_command(ADB_SET_UI_SCALE.format(ui_scale_value)):
                print(f"  ❌ Failed to set UI scale")
                results.append((test_name, "FAILED - UI Scale"))
                continue
            
            # Wait for UI to settle
            print(f"  ⏳ Waiting for UI to settle...")
            time.sleep(2)
            
            # Capture screenshot
            screenshot_name = f"{test_name}.png"
            print(f"  📸 Capturing screenshot: {screenshot_name}")
            if capture_screenshot(screenshot_name):
                print(f"  ✅ Screenshot saved")
                results.append((test_name, "SUCCESS"))
            else:
                print(f"  ❌ Screenshot failed")
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
    
    print("Detailed Results:")
    for test_name, status in results:
        status_icon = "✅" if status == "SUCCESS" else "❌"
        print(f"  {status_icon} {test_name}: {status}")
    
    print()
    print(f"📁 Screenshots saved to: {OUTPUT_DIR}")
    print()
    print("Next Steps:")
    print("1. Review screenshots for text collisions")
    print("2. Check vertical gaps between venue and date")
    print("3. Verify Marquee only activates horizontally")
    print()


if __name__ == "__main__":
    main()
