import subprocess
import time
import argparse
import sys
import os
import threading

# Configuration
PACKAGE_NAME = "com.jamart3d.shakedown"
DEVICE_DIR = "/sdcard/shakedown_tests_dice"
LOCAL_DIR = "./screenshots/dice_verification"

# Global state for "Stay Awake" thread
keep_awake = True

def run_adb(command, device_id=None):
    """Executes an ADB command."""
    adb_cmd = ["adb"]
    if device_id:
        adb_cmd.extend(["-s", device_id])
    
    if isinstance(command, str):
        adb_cmd.extend(command.split())
    else:
        adb_cmd.extend(command)
        
    result = subprocess.run(adb_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error ({' '.join(adb_cmd)}): {result.stderr}")
    return result.stdout.strip()

def stay_awake_loop(device_id):
    """Periodically taps a safe corner of the screen to prevent sleep."""
    while keep_awake:
        run_adb(["shell", "input", "tap", "1", "1"], device_id)
        time.sleep(10)

def open_deep_link(uri, device_id=None):
    """Opens a deep link using adb shell am start."""
    print(f"  -> Deep Link: {uri}")
    cmd = ["shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", f"\"{uri}\""]
    run_adb(cmd, device_id)
    time.sleep(0.5)

def take_screenshot(filename, device_id=None):
    """Captures a screenshot and pulls it to local machine."""
    print(f"  -> Capture: {filename}")
    run_adb(["shell", "screencap", "-p", f"{DEVICE_DIR}/{filename}"], device_id)
    run_adb(["pull", f"{DEVICE_DIR}/{filename}", f"{LOCAL_DIR}/{filename}"], device_id)

def main():
    global keep_awake
    parser = argparse.ArgumentParser(description="Dice Animation Verification")
    parser.add_argument("--device", help="ADB Device ID")
    parser.add_argument("--html-only", action="store_true", help="Generate HTML report only")
    args = parser.parse_args()

    device_id = args.device

    if args.html_only:
        generate_html_report()
        return

    # Pre-flight
    if not os.path.exists(LOCAL_DIR):
        os.makedirs(LOCAL_DIR)
    
    print(f"Setting up device: {device_id}")
    run_adb(["shell", "mkdir", "-p", DEVICE_DIR], device_id)
    
    # Stay Awake
    run_adb(["shell", "svc", "power", "stayon", "true"], device_id)
    wake_thread = threading.Thread(target=stay_awake_loop, args=(device_id,))
    wake_thread.start()

    try:
        print("\n=== Dice Animation Test ===")
        
        # 1. Reset
        print("  [Setup] Resetting app state...")
        open_deep_link("shakedown://debug?action=reset_prefs", device_id)
        time.sleep(1.0)
        open_deep_link("shakedown://navigate?screen=home", device_id)
        time.sleep(5.0) # Increased to 5.0s to ensure JSON load

        # 2. Trigger Animation Only
        print("  [Action] Triggering Random Dice (Animation Only)...")
        # Trigger the random show logic but with animation_only=true
        open_deep_link("shakedown://play-random?animation_only=true", device_id)
        time.sleep(0.5) # Wait for UI to react
        
        # 3. Capture Burst (High Speed)
        print("  [Capture] Burst capturing...")
        start_time = time.time()
        frame_count = 0
        
        # Capture for 13.0 seconds (Animation is 12.0s)
        while time.time() - start_time < 13.0:
            # Timestamp suffix for sorting
            ts = int((time.time() - start_time) * 1000)
            take_screenshot(f"dice_frame_{ts:04d}.png", device_id)
            frame_count += 1
            # Minimal delay for max frame rate capability of adb (usually slow, but best effort)
            # User Feedback: "frames not perceivable" -> check less frequently.
            # Enforce 1.0s interval to capture ~12 key frames instead of 21+.
            time.sleep(1.0)

        print(f"Captured {frame_count} frames.")

    finally:
        keep_awake = False
        if wake_thread and wake_thread.is_alive():
            wake_thread.join()
        
        run_adb(["shell", "svc", "power", "stayon", "false"], device_id)
        generate_html_report()
        print("\n=== Test Complete ===")

def generate_html_report():
    print(f"\nGenerating HTML Report in {LOCAL_DIR}...")
    html_path = os.path.join(LOCAL_DIR, "dice_report.html")
    files = [f for f in os.listdir(LOCAL_DIR) if f.endswith(".png")]
    files.sort()

    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <title>Dice Animation Report</title>
    <style>
        body {{ background: #222; color: #eee; font-family: sans-serif; text-align: center; }}
        .filmstrip {{ display: flex; flex-wrap: wrap; justify-content: center; gap: 10px; }}
        .frame {{ background: #333; padding: 5px; border-radius: 4px; }}
        img {{ max-width: 200px; height: auto; }} 
        h1 {{ color: #81d4fa; }}
    </style>
</head>
<body>
    <h1>Dice Animation Frames</h1>
    <div class="filmstrip">
"""
    for f in files:
        html_content += f"""
        <div class="frame">
            <img src="{f}" onclick="this.style.maxWidth='800px';">
            <div>{f}</div>
        </div>"""

    html_content += """
    </div>
</body>
</html>"""

    with open(html_path, "w") as f:
        f.write(html_content)
    
    print(f"Report generated: {html_path}")

if __name__ == "__main__":
    main()
