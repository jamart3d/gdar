#!/usr/bin/env python3
"""
Automated Testing Script: Onboarding Page 3 Font Normalization

Tests all font and UI scale combinations on onboarding page 3
to verify font normalization consistency.

Usage:
    python3 scripts/test_onboarding_fonts.py
    python3 scripts/test_onboarding_fonts.py --report-only
    python3 scripts/test_onboarding_fonts.py --tag baseline
"""

import subprocess
import time
import argparse
import sys
import os

# Configuration
PACKAGE_NAME = "com.jamart3d.shakedown"
LOCAL_DIR = "./screenshots/onboarding_fonts"
DEVICE_ID = None

# Fonts and Scales to Test
FONTS = [
    ("Roboto", "default"),
    ("Caveat", "caveat"),
    ("Permanent Marker", "permanent_marker"),
    ("Rock Salt", "rock_salt"),
]

SCALES = [
    ("1.0x", "false"),
    ("1.2x", "true"),
]

def run_adb_command(command, device_id=None):
    """Runs an ADB command and returns the output."""
    adb_cmd = ["adb"]
    if device_id:
        adb_cmd.extend(["-s", device_id])
    adb_cmd.extend(command)

    try:
        result = subprocess.run(
            adb_cmd,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            check=True
        )
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        print(f"Error running ADB command: {' '.join(adb_cmd)}\\n{e.stderr}")
        return None

def open_deep_link(url, device_id):
    """Opens a deep link using adb shell am start."""
    print(f"  -> Opening: {url}")
    run_adb_command([
        "shell", "am", "start",
        "-W",
        "-a", "android.intent.action.VIEW",
        "-d", f'"{url}"',
        PACKAGE_NAME
    ], device_id)

def take_screenshot(filename, device_id):
    """Takes a screenshot and pulls it to the local directory."""
    remote_path = f"/sdcard/{filename}"
    local_path = os.path.join(LOCAL_DIR, filename)

    run_adb_command(["shell", "screencap", "-p", remote_path], device_id)
    run_adb_command(["pull", remote_path, local_path], device_id)
    run_adb_command(["shell", "rm", remote_path], device_id)
    print(f"  [Captured] {local_path}")

def get_screen_width(device_id):
    """Get device screen width dynamically."""
    output = run_adb_command(["shell", "wm", "size"], device_id)
    # Output format: Physical size: 1080x2400
    if output and "Physical size:" in output:
        try:
            dims = output.split(":")[1].strip().split("x")
            return int(dims[0])
        except:
            return 1080
    return 1080

def swipe_left(device_id):
    """Swipes from right to left (Next Page)."""
    width = get_screen_width(device_id)
    start_x = int(width * 0.9)
    end_x = int(width * 0.1)
    y = 1000  # Middle-ish vertically
    run_adb_command(["shell", "input", "swipe", str(start_x), str(y), str(end_x), str(y), "300"], device_id)
    time.sleep(1.0)  # Wait for animation

def navigate_to_onboarding_page_3(device_id):
    """Navigate to onboarding screen page 3."""
    # Reset onboarding to ensure we can access it
    open_deep_link("shakedown://debug?action=reset_onboarding", device_id)
    time.sleep(0.5)
    
    # Navigate to onboarding
    open_deep_link("shakedown://navigate?screen=onboarding", device_id)
    time.sleep(1.5)  # Increased wait for screen load
    
    # Swipe to page 2
    print("  -> Swiping to page 2...")
    swipe_left(device_id)
    
    # Swipe to page 3
    print("  -> Swiping to page 3...")
    swipe_left(device_id)

def generate_html_report(tag=None):
    """Generate an HTML report comparing all screenshots."""
    report_dir = LOCAL_DIR
    if tag:
        report_dir = os.path.join(LOCAL_DIR, tag)
    
    report_path = os.path.join(report_dir, "onboarding_fonts_report.html")
    
    html_content = f"""<!DOCTYPE html>
<html>
<head>
    <title>Onboarding Page 3 Font Normalization Test{' - ' + tag if tag else ''}</title>
    <style>
        body {{
            font-family: Arial, sans-serif;
            margin: 20px;
            background: #f5f5f5;
        }}
        h1 {{
            color: #333;
            border-bottom: 3px solid #4CAF50;
            padding-bottom: 10px;
        }}
        .grid {{
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(400px, 1fr));
            gap: 20px;
            margin-top: 20px;
        }}
        .card {{
            background: white;
            border-radius: 8px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            padding: 15px;
        }}
        .card h3 {{
            margin-top: 0;
            color: #4CAF50;
            font-size: 16px;
        }}
        .card img {{
            width: 100%;
            border: 1px solid #ddd;
            border-radius: 4px;
        }}
        .font-group {{
            margin-bottom: 40px;
        }}
        .font-group h2 {{
            color: #555;
            border-left: 4px solid #4CAF50;
            padding-left: 10px;
        }}
        .comparison {{
            display: flex;
            gap: 20px;
            flex-wrap: wrap;
        }}
        .comparison .card {{
            flex: 1;
            min-width: 350px;
        }}
    </style>
</head>
<body>
    <h1>Onboarding Page 3 Font Normalization Test{' - ' + tag if tag else ''}</h1>
    <p><strong>Purpose:</strong> Compare font rendering with normalization across different scales</p>
    <p><strong>Test Date:</strong> {time.strftime('%Y-%m-%d %H:%M:%S')}</p>
"""

    # Group by font
    for font_name, font_key in FONTS:
        html_content += f"""
    <div class="font-group">
        <h2>{font_name} Font</h2>
        <div class="comparison">
"""
        
        for scale_name, scale_val in SCALES:
            filename = f"onboarding_p3_{font_key}_{scale_name}.png"
            filepath = os.path.join(report_dir, filename)
            
            if os.path.exists(filepath):
                html_content += f"""
            <div class="card">
                <h3>UI Scale: {scale_name}</h3>
                <img src="{filename}" alt="{font_name} at {scale_name}">
            </div>
"""
        
        html_content += """
        </div>
    </div>
"""

    html_content += """
</body>
</html>
"""

    with open(report_path, 'w') as f:
        f.write(html_content)
    
    print(f"\\n[Report Generated] {report_path}")

def main():
    global DEVICE_ID, LOCAL_DIR
    
    parser = argparse.ArgumentParser(description="Test Onboarding Page 3 Font Normalization")
    parser.add_argument("--device", help="Specific ADB device ID")
    parser.add_argument("--report-only", action="store_true", help="Generate HTML report from existing screenshots")
    parser.add_argument("--tag", help="Subdirectory tag for organizing captures")
    args = parser.parse_args()
    
    # Update LOCAL_DIR if tag is provided
    if args.tag:
        LOCAL_DIR = os.path.join("./screenshots/onboarding_fonts", args.tag)
    
    # Report-only mode
    if args.report_only:
        generate_html_report(args.tag)
        return
    
    # Ensure screenshot directory exists
    os.makedirs(LOCAL_DIR, exist_ok=True)
    
    # Get device
    if args.device:
        DEVICE_ID = args.device
    else:
        devices_output = run_adb_command(["devices"])
        if not devices_output:
            print("No ADB devices found!")
            sys.exit(1)
            
        lines = devices_output.splitlines()
        devices = [line.split()[0] for line in lines[1:] if line.strip() and 'device' in line]
        
        if not devices:
            print("No ADB devices found!")
            sys.exit(1)
        
        DEVICE_ID = devices[0]
    
    print(f"Using device: {DEVICE_ID}")
    print(f"Screenshots will be saved to: {LOCAL_DIR}\\n")
    
    # Test each font × scale combination
    total_tests = len(FONTS) * len(SCALES)
    current_test = 0
    
    for font_name, font_key in FONTS:
        for scale_name, scale_val in SCALES:
            current_test += 1
            progress_pct = int((current_test / total_tests) * 100)
            
            print(f"\\n[{progress_pct}%] Testing: {font_name} @ {scale_name} ({current_test}/{total_tests})")
            
            # Reset and configure
            print("  [1/4] Resetting preferences...")
            open_deep_link("shakedown://debug?action=reset_prefs", DEVICE_ID)
            time.sleep(1.0)
            
            print(f"  [2/4] Setting font to {font_name}...")
            open_deep_link(f"shakedown://font?name={font_key}", DEVICE_ID)
            time.sleep(0.5)
            
            print(f"  [3/4] Setting UI scale to {scale_name}...")
            open_deep_link(f"shakedown://ui-scale?enabled={scale_val}", DEVICE_ID)
            time.sleep(0.5)
            
            print("  [4/4] Navigating to onboarding page 3...")
            navigate_to_onboarding_page_3(DEVICE_ID)
            
            # Capture screenshot
            filename = f"onboarding_p3_{font_key}_{scale_name}.png"
            take_screenshot(filename, DEVICE_ID)
            
            time.sleep(0.5)
    
    # Generate HTML report
    print("\\n" + "="*60)
    generate_html_report(args.tag)
    print("="*60)
    print(f"\\n✅ Test Complete! Screenshots saved to: {LOCAL_DIR}")

if __name__ == "__main__":
    main()
