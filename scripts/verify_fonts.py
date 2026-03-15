#!/usr/bin/env python3
"""
verify_fonts.py
Automates UI font verification using ADB and Deep Links.
Uses the 'shakedown://' scheme to trigger specific screens and captures screenshots
to verify font rendering (e.g., the 'Fruit' / 'Inter' font aesthetic).
"""

import subprocess
import time
import os

# Configuration
PACKAGE_NAME = "com.jamart3d.shakedown"
SCHEME = "shakedown://"
OUTPUT_DIR = "reports/font_verification"

def run_command(cmd):
    """Executes a shell command and returns the output."""
    print(f"Executing: {cmd}")
    result = subprocess.run(cmd, shell=True, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error: {result.stderr}")
    return result.stdout

def trigger_deep_link(path):
    """Triggers a deep link via ADB."""
    uri = f"{SCHEME}{path}"
    cmd = (
        f"adb shell am start -a android.intent.action.VIEW "
        f"-c android.intent.category.BROWSABLE "
        f"-d '{uri}' {PACKAGE_NAME}"
    )
    run_command(cmd)

def capture_screenshot(filename):
    """Captures a screenshot and pulls it to the host."""
    remote_path = "/sdcard/font_verify.png"
    local_path = os.path.join(OUTPUT_DIR, filename)
    
    os.makedirs(OUTPUT_DIR, exist_ok=True)
    
    run_command(f"adb shell screencap -p {remote_path}")
    run_command(f"adb pull {remote_path} {local_path}")
    run_command(f"adb shell rm {remote_path}")
    print(f"Screenshot saved to: {local_path}")

def main():
    print("--- Starting Font Verification ---")
    
    # 1. Test Home Screen
    print("\n[Step 1] Verifying Home Screen Fonts...")
    trigger_deep_link("home")
    time.sleep(3) # Wait for UI to settle
    capture_screenshot("home_fonts.png")
    
    # 2. Test Playback Screen (specific track)
    print("\n[Step 2] Verifying Playback Screen Fonts...")
    trigger_deep_link("play/verify_fonts_id")
    time.sleep(3)
    capture_screenshot("playback_fonts.png")
    
    print("\n--- Verification Complete ---")
    print(f"Please review screenshots in {OUTPUT_DIR}/")

if __name__ == "__main__":
    main()
