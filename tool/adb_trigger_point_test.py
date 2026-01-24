#!/usr/bin/env python3
"""
ADB Trigger Point Test - Fine-Grained Font Size Analysis

Tests ShowListCard with fine-grained font size increments to identify
the exact point where Marquee triggers and text collisions occur.

Usage:
    python3 tool/adb_trigger_point_test.py

Requirements:
    - ADB installed and in PATH
    - Device/emulator connected and authorized
    - Shakedown app installed and running
"""

import subprocess
import time
import os
from datetime import datetime

# Fine-grained test range
FONT_SCALE_START = 1.0
FONT_SCALE_END = 1.5
FONT_SCALE_STEP = 0.05

UI_SCALES = [False, True]

# ADB commands
ADB_SET_FONT = "adb shell settings put system font_scale {}"
ADB_SET_UI_SCALE = 'adb shell am start -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled={}" com.jamart3d.shakedown'

# Output directory
SCREENSHOT_DIR = "screenshots/trigger_point_audit"
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
    """Run the trigger point analysis test."""
    print("=" * 60)
    print("ADB Trigger Point Test - Fine-Grained Font Analysis")
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
    
    # Generate font scale values
    font_scales = []
    current = FONT_SCALE_START
    while current <= FONT_SCALE_END:
        font_scales.append(round(current, 2))
        current += FONT_SCALE_STEP
    
    total_tests = len(font_scales) * len(UI_SCALES)
    current_test = 0
    
    results = []
    
    print(f"Testing {len(font_scales)} font sizes × {len(UI_SCALES)} UI scale states")
    print(f"Font range: {FONT_SCALE_START} to {FONT_SCALE_END} (step {FONT_SCALE_STEP})")
    print()
    
    for ui_scale in UI_SCALES:
        ui_scale_str = "on" if ui_scale else "off"
        ui_scale_value = "true" if ui_scale else "false"
        
        print(f"📊 Testing with UI Scale: {ui_scale_str}")
        print("-" * 60)
        
        # Set UI scale once per batch
        if not run_adb_command(ADB_SET_UI_SCALE.format(ui_scale_value)):
            print(f"❌ Failed to set UI scale to {ui_scale_str}")
            continue
        
        time.sleep(1)
        
        for font_scale in font_scales:
            current_test += 1
            test_name = f"font_{font_scale:.2f}_scale_{ui_scale_str}"
            
            print(f"  [{current_test}/{total_tests}] Font={font_scale:.2f}", end="")
            
            # Set font scale
            if not run_adb_command(ADB_SET_FONT.format(font_scale)):
                print(f" ❌ Failed")
                results.append((test_name, font_scale, ui_scale_str, "FAILED"))
                continue
            
            time.sleep(1.5)
            
            # Capture screenshot
            screenshot_name = f"{test_name}.png"
            if capture_screenshot(screenshot_name):
                print(f" ✅")
                results.append((test_name, font_scale, ui_scale_str, "SUCCESS"))
            else:
                print(f" ❌ Screenshot failed")
                results.append((test_name, font_scale, ui_scale_str, "FAILED"))
        
        print()
    
    # Generate summary report
    print("=" * 60)
    print("Test Summary")
    print("=" * 60)
    print()
    
    success_count = sum(1 for _, _, _, status in results if status == "SUCCESS")
    print(f"Total Tests: {total_tests}")
    print(f"Successful: {success_count}")
    print(f"Failed: {total_tests - success_count}")
    print()
    
    # Group by UI scale
    for ui_scale in UI_SCALES:
        ui_scale_str = "on" if ui_scale else "off"
        print(f"UI Scale {ui_scale_str.upper()}:")
        
        scale_results = [r for r in results if r[2] == ui_scale_str and r[3] == "SUCCESS"]
        if scale_results:
            font_values = [r[1] for r in scale_results]
            print(f"  Font range: {min(font_values):.2f} - {max(font_values):.2f}")
            print(f"  Tests: {len(scale_results)}")
        else:
            print(f"  No successful tests")
        print()
    
    print(f"📁 Screenshots saved to: {OUTPUT_DIR}")
    print()
    print("Next Steps:")
    print("1. Review screenshots sequentially to find trigger points")
    print("2. Identify exact font size where Marquee activates")
    print("3. Check for text collisions or vertical gap issues")
    print("4. Compare behavior between UI scale on/off")
    print()


if __name__ == "__main__":
    main()
