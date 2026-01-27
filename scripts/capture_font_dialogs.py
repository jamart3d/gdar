import subprocess
import time
import argparse
import sys
import os

# Configuration
PACKAGE_NAME = "com.jamart3d.shakedown"
USER_ID = "0"  # Assuming default user
LOCAL_DIR = "./screenshots/font_dialogs"
DEVICE_ID = None # Will be set dynamically

# Fonts and Scales to Test
FONTS = [
    ("Default (Roboto)", "default"),
    ("Caveat", "caveat"),
    ("Permanent Marker", "permanent_marker"),
    ("Rock Salt", "rock_salt"),
]

SCALES = [
    (1.0, "1x", "false"),   # (scale_val, name, deep_link_val)
    (1.2, "1.2x", "true"),
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
        print(f"Error running ADB command: {' '.join(adb_cmd)}\n{e.stderr}")
        return None

def open_deep_link(url, device_id):
    """Opens a deep link using adb shell am start."""
    print(f"  -> Opening: {url}")
    run_adb_command([
        "shell", "am", "start",
        "-W", # Wait for launch
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

def wake_device(device_id):
    """Sends a wake key event."""
    run_adb_command(["shell", "input", "keyevent", "82"], device_id)

def main():
    global DEVICE_ID, LOCAL_DIR
    
    parser = argparse.ArgumentParser(description="Capture Font Selection Dialogs")
    parser.add_argument("--device", help="Specific ADB device ID")
    parser.add_argument("--report-only", action="store_true", help="Generate HTML report from existing screenshots without capturing")
    parser.add_argument("--tag", help="Subdirectory tag for organizing captures (e.g., 'baseline', 'v2')")
    args = parser.parse_args()
    
    # Update LOCAL_DIR if tag is provided
    if args.tag:
        LOCAL_DIR = os.path.join("./screenshots/font_dialogs", args.tag)
    
    # 0. Report Only Mode
    if getattr(args, 'report_only', False):
         generate_html_report(args.tag)
         return

    # 1. Device Setup
    if args.device:
        DEVICE_ID = args.device
    else:
        devices_output = run_adb_command(["devices"])
        lines = devices_output.splitlines()
        devices = [line.split()[0] for line in lines[1:] if line.strip()]
        
        if not devices:
            print("No devices found.")
            sys.exit(1)
        DEVICE_ID = devices[0]
        print(f"Using device: {DEVICE_ID}")

    if not os.path.exists(LOCAL_DIR):
        os.makedirs(LOCAL_DIR)

    try:
        print("\n=== Starting Font Dialog Capture ===\n")
        
        # Ensure screen is awake initially
        wake_device(DEVICE_ID)

        # Ensure App is Running / Onboarding Complete
        open_deep_link("shakedown://debug?action=complete_onboarding", DEVICE_ID)
        time.sleep(1.0)
        
        # Hide splash screen to avoid interference
        open_deep_link("shakedown://settings?key=show_splash_screen&value=false", DEVICE_ID)
        time.sleep(0.5)

        total_steps = len(FONTS) * len(SCALES)
        current_step = 0

        for font_cols, font_key in FONTS:
            for scale_val, scale_name, scale_bool in SCALES:
                current_step += 1
                percent = int((current_step / total_steps) * 100)
                print(f"\n>>> [{percent}%] Capturing: Font={font_key}, Scale={scale_name} ({current_step}/{total_steps}) <<<")

                # Keep device awake periodically
                wake_device(DEVICE_ID)

                # 1. Set Configuration (Font & Scale)
                open_deep_link(f"shakedown://font?name={font_key}", DEVICE_ID)
                time.sleep(0.3)
                
                open_deep_link(f"shakedown://ui-scale?enabled={scale_bool}", DEVICE_ID)
                time.sleep(0.3)
                
                # 2. Open Dialog
                # This PUSHES a new SettingsScreen instance
                open_deep_link("shakedown://debug?action=show_font_dialog", DEVICE_ID)
                # Wait longer for dialog to appear (SettingsScreen init + delay + showDialog anim)
                time.sleep(2.0) 

                # 3. Capture
                filename = f"dialog_{font_key}_{scale_name}.png"
                take_screenshot(filename, DEVICE_ID)

                # 4. cleanup / reset to home to clear stack
                open_deep_link("shakedown://navigate?screen=home", DEVICE_ID)
                time.sleep(0.5)

    finally:
        print("\n=== Capture Complete ===")
        generate_html_report(args.tag)
        print(f"Screenshots saved to: {LOCAL_DIR}")

def generate_html_report(tag=None):
    """Generates an HTML report for the captured font dialogs.
    
    Args:
        tag: Optional subdirectory tag used for organizing captures.
    """
    # Use LOCAL_DIR which may have been updated with tag
    report_dir = LOCAL_DIR
    print(f"\nGenerating HTML Report in {report_dir}...")
    
    html_path = os.path.join(report_dir, "font_dialogs_report.html")
    
    # Simple CSS for grid layout
    css = """
    body { font-family: sans-serif; background: #222; color: #eee; padding: 20px; }
    h1 { text-align: center; }
    .font-section { margin-bottom: 40px; border-bottom: 1px solid #444; padding-bottom: 20px; }
    .font-title { font-size: 1.5em; margin-bottom: 10px; color: #81d4fa; }
    .grid { display: flex; flex-wrap: wrap; gap: 20px; }
    .card { background: #333; padding: 10px; border-radius: 8px; text-align: center; }
    .card img { max-width: 300px; height: auto; border: 1px solid #555; display: block; margin-bottom: 8px; }
    .label { font-weight: bold; color: #bbb; }
    """

    tag_display = f" - {tag}" if tag else ""
    html_content = f"""
    <!DOCTYPE html>
    <html>
    <head>
        <title>Font Dialog Verification{tag_display}</title>
        <style>{css}</style>
    </head>
    <body>
        <h1>Font Selection Dialog Verification{tag_display}</h1>
    """

    for display_name, font_key in FONTS:
        html_content += f'<div class="font-section"><div class="font-title">{display_name}</div><div class="grid">'
        
        for scale_val, scale_name, scale_bool in SCALES:
            filename = f"dialog_{font_key}_{scale_name}.png"
            # specific fix for rock_salt key vs "Rock Salt" display name matching earlier logic if needed, 
            # but here we use the keys used in naming.
            
            # Check if file exists
            if os.path.exists(os.path.join(report_dir, filename)):
                 html_content += f"""
                 <div class="card">
                    <img src="{filename}" onclick="window.open(this.src)">
                    <div class="label">Scale: {scale_name}</div>
                 </div>
                 """
            else:
                 html_content += f"""
                 <div class="card">
                    <div style="width:300px; height:500px; display:flex; align-items:center; justify-content:center; background:#444;">
                        Missing: {filename}
                    </div>
                    <div class="label">Scale: {scale_name}</div>
                 </div>
                 """
        
        html_content += '</div></div>'

    html_content += "</body></html>"
    
    with open(html_path, "w") as f:
        f.write(html_content)
    
    print(f"Report generated: {html_path}")


if __name__ == "__main__":
    main()
