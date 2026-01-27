import subprocess
import time
import argparse
import sys
import os
import threading

# Configuration
PACKAGE_NAME = "com.jamart3d.shakedown"
DEVICE_DIR = "/sdcard/shakedown_tests"
LOCAL_DIR = "./screenshots/font_verification"

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
        
    # print(f"Executing: {' '.join(adb_cmd)}")
    result = subprocess.run(adb_cmd, capture_output=True, text=True)
    if result.returncode != 0:
        print(f"Error ({' '.join(adb_cmd)}): {result.stderr}")
    return result.stdout.strip()

def stay_awake_loop(device_id):
    """Periodically taps a safe corner of the screen to prevent sleep."""
    while keep_awake:
        # Tap coordinates (1,1) - minimal impact
        run_adb(["shell", "input", "tap", "1", "1"], device_id)
        time.sleep(10)

def open_deep_link(uri, device_id=None):
    """Opens a deep link using adb shell am start."""
    print(f"  -> Deep Link: {uri}")
    cmd = ["shell", "am", "start", "-a", "android.intent.action.VIEW", "-d", f"\"{uri}\""]
    run_adb(cmd, device_id)
    time.sleep(0.5) # Wait for intent to fire and UI to settle

def take_screenshot(filename, device_id=None):
    """Captures a screenshot and pulls it to local machine."""
    print(f"  -> Capture: {filename}")
    run_adb(["shell", "screencap", "-p", f"{DEVICE_DIR}/{filename}"], device_id)
    run_adb(["pull", f"{DEVICE_DIR}/{filename}", f"{LOCAL_DIR}/{filename}"], device_id)

def get_screen_width(device_id=None):
    """Gets the screen width in pixels."""
    output = run_adb(["shell", "wm", "size"], device_id)
    # Output format: Physical size: 1080x2400
    if "Physical size:" in output:
        try:
            dims = output.split(":")[1].strip().split("x")
            return int(dims[0])
        except:
             return 1080
    return 1080

def swipe_left(device_id=None):
    """Swipes from right to left (Next Page)."""
    width = get_screen_width(device_id)
    start_x = int(width * 0.9)
    end_x = int(width * 0.1)
    y = 1000 # Middle-ish vertically
    run_adb(["shell", "input", "swipe", str(start_x), str(y), str(end_x), str(y), "300"], device_id)
    time.sleep(1.0) # Wait for animation


def main():
    global keep_awake
    parser = argparse.ArgumentParser(description="Automated Font Verification")
    parser.add_argument("--device", help="ADB Device ID")
    parser.add_argument("--slow", action="store_true", help="Run slowly for visual verification")
    parser.add_argument("--tag", default="latest", help="Tag for this test run (e.g., 'before_fix', 'after_fix')")
    parser.add_argument("-df", "--default-only", action="store_true", help="Run only with the default font (skips others)")
    parser.add_argument("-sc", "--single-scale", action="store_true", help="Run only with 1x scale (skips 1.2x)")
    parser.add_argument("--stay-awake", action="store_true", help="Keep device awake during test (svc power stayon)")
    args = parser.parse_args()

    device_id = args.device
    run_tag = args.tag

    # update global LOCAL_DIR for this run
    global LOCAL_DIR
    LOCAL_DIR = f"./screenshots/font_verification/{run_tag}"

    # Pre-flight
    if not os.path.exists(LOCAL_DIR):
        os.makedirs(LOCAL_DIR)
    
    # Setup Device
    print(f"Setting up device: {device_id}")
    run_adb(["shell", "mkdir", "-p", DEVICE_DIR], device_id)
    
    if args.stay_awake:
        print("  -> Enabling Stay Awake (svc power stayon)")
        run_adb(["shell", "svc", "power", "stayon", "true"], device_id)
        
    # Start Keep Awake Thread (Always runs to handle battery/wifi cases)
    wake_thread = threading.Thread(target=stay_awake_loop, args=(device_id,))
    wake_thread.start()

    delay = 3 if args.slow else 1.5
    
    try:
        print("\n=== [Phase 1] Test Setup & Execution ===")
        if args.default_only:
            fonts = ["default"]
        else:
            fonts = ["default", "rock_salt", "permanent_marker", "caveat"]
            
        if args.single_scale:
            scales = [("false", "1x")]
        else:
            scales = [("false", "1x"), ("true", "1.2x")]

        combinations = []
        for font in fonts:
            for scale_val, scale_name in scales:
                combinations.append((font, scale_val, scale_name))

        total_tests = len(combinations)

        for i, (font, scale_val, scale_name) in enumerate(combinations):
            progress_pct = int(((i) / total_tests) * 100)
            print(f"\n\n>>> [{progress_pct}%] Testing Configuration: Font={font}, Scale={scale_name} ({i+1}/{total_tests}) <<<")
            
            # 1. Reset App & Configure
            print(f"  [Setup] Resetting prefs and applying config...")
            # Stop any existing playback first
            open_deep_link("shakedown://player?action=stop", device_id)
            time.sleep(0.5)
            
            open_deep_link("shakedown://debug?action=reset_prefs", device_id)
            time.sleep(1.0)
            
            # Set Font & Scale
            open_deep_link(f"shakedown://font?name={font}", device_id)
            time.sleep(0.5)
            open_deep_link(f"shakedown://ui-scale?enabled={scale_val}", device_id)
            time.sleep(0.5)

            # 2. Verify Onboarding Flow
            print(f"  [Verify] Onboarding Flow...")
            
            # 2a. Onboarding (Navigate explicitly to Onboarding)
            open_deep_link("shakedown://navigate?screen=onboarding", device_id) 
            time.sleep(delay)
            take_screenshot(f"onboarding_p1_{font}_{scale_name}.png", device_id)
            
            # Swipe to Page 2
            swipe_left(device_id)
            time.sleep(delay)
            take_screenshot(f"onboarding_p2_{font}_{scale_name}.png", device_id)

            # Swipe to Page 3
            swipe_left(device_id)
            time.sleep(delay)
            take_screenshot(f"onboarding_p3_{font}_{scale_name}.png", device_id)

            # 2b. Splash Screen
            open_deep_link("shakedown://navigate?screen=splash", device_id)
            time.sleep(1.0) 
            take_screenshot(f"splash_{font}_{scale_name}.png", device_id)
            
            # Disable Splash Screen to prevent it from showing when we complete onboarding (or via play-random logic)
            open_deep_link("shakedown://settings?key=show_splash_screen&value=false", device_id)
            time.sleep(0.5)

            # 3. Complete Onboarding
            print(f"  [Setup] Completing Onboarding...")
            open_deep_link("shakedown://debug?action=complete_onboarding", device_id)
            
            # Force stop playback first to ensure state is clean
            open_deep_link("shakedown://player?action=stop", device_id)
            time.sleep(0.5)

            # Navigate to Home explicitly to clear Splash Screen and ensure fresh UI
            open_deep_link("shakedown://navigate?screen=home", device_id)
            time.sleep(1.0)
            
            # Capture Home Initial (Empty State / No Player)
            take_screenshot(f"home_initial_{font}_{scale_name}.png", device_id)

            # 4. Start Playback (Ensure Player is active for subsequent tests)
            # Note: This might trigger a splash screen briefly if the app cold starts or resets
            open_deep_link("shakedown://play-random", device_id)
            time.sleep(delay + 3.0) # Extended wait to allow splash screen/buffering to clear

            # 5. Verify Main App UI
            print(f"  [Verify] Main Application UI...")

            # A. Show List (Home) - Verifies Closed Panel (MiniPlayer)
            # Ensure search is closed for the baseline home screenshot
            open_deep_link("shakedown://navigate?screen=home&action=close_search", device_id)
            time.sleep(delay)
            take_screenshot(f"home_{font}_{scale_name}.png", device_id)

            # A.2 Show List (Search Expanded)
            open_deep_link("shakedown://navigate?screen=home&action=search", device_id)
            time.sleep(delay - 0.5) 
            take_screenshot(f"home_search_open_{font}_{scale_name}.png", device_id)

            # Close Search to reset UI state
            open_deep_link("shakedown://navigate?screen=home&action=close_search", device_id)
            time.sleep(1.0)

            # A.4 Track List (Consistent Show Selection)
            # Select show at index 10 to ensure same show across all runs
            open_deep_link("shakedown://navigate?screen=track_list&index=10", device_id)
            time.sleep(delay)
            take_screenshot(f"track_list_{font}_{scale_name}.png", device_id)

            # B. Settings (Expanded Sections)
            sections = [
                "usage_instructions", 
                "appearance", 
                "interface", 
                "random_playback", 
                "playback",
                "collection_statistics"
            ]
            
            for section in sections:
                # Reset to home to ensure fresh navigation stack/scroll state
                open_deep_link("shakedown://navigate?screen=home", device_id) 
                time.sleep(delay - 1.0) # Fast reset

                open_deep_link(f"shakedown://navigate?screen=settings&highlight={section}", device_id)
                time.sleep(delay)
                take_screenshot(f"settings_{section}_{font}_{scale_name}.png", device_id)
            
            # C. Player & Controls
            
            # 1. Player Panel OPEN (Baseline - Messages OFF)
            # Reset to home first to ensure we aren't stacking player screens weirdly
            open_deep_link("shakedown://navigate?screen=home", device_id)
            time.sleep(1.0)
            
            # Ensure messages are OFF for baseline
            open_deep_link("shakedown://settings?key=show_playback_messages&value=false", device_id)
            open_deep_link("shakedown://navigate?screen=player&panel=open", device_id)
            time.sleep(delay + 1.0) # Extra time for panel animation
            take_screenshot(f"player_panel_open_{font}_{scale_name}.png", device_id)

            # 2. Messages ON
            open_deep_link("shakedown://settings?key=show_playback_messages&value=true", device_id)
            # Ensure checking same screen state
            open_deep_link("shakedown://navigate?screen=player&panel=open", device_id)
            time.sleep(delay)
            take_screenshot(f"player_msg_on_{font}_{scale_name}.png", device_id)
            
            # Cleanup: Turn messages off for next run cleanliness (but don't screenshot)
            open_deep_link("shakedown://settings?key=show_playback_messages&value=false", device_id)
            
            # 3. Paused State - (Removed as per user request)
            
            # Resume for next loop (though next loop resets app, so maybe not strictly needed, but good practice)
            open_deep_link("shakedown://player?action=play", device_id)
            time.sleep(0.5)

    finally:
        keep_awake = False
        if wake_thread and wake_thread.is_alive():
            wake_thread.join()
        
        if args.stay_awake:
            run_adb(["shell", "svc", "power", "stayon", "false"], device_id)
            
        print("  [Cleanup] Resetting preferences (Restore Onboarding)...")
        open_deep_link("shakedown://debug?action=reset_prefs", device_id)
        
        generate_html_report()
        print("\n=== Test Complete ===")

def generate_html_report():
    """Generates an HTML contact sheet and slideshow for captured screenshots, grouped by feature."""
    print(f"\nGenering HTML Report in {LOCAL_DIR}...")
    
    html_path = os.path.join(LOCAL_DIR, "verification_report.html")
    
    # Get all PNG files
    files = [f for f in os.listdir(LOCAL_DIR) if f.endswith(".png")]
    files.sort() # Ensure consistent order
    
    if not files:
        print("No screenshots found to generate report.")
        return

    # Group files by Feature (Base Name)
    # Filename format: {base_name}_{font}_{scale}.png
    # Regex: ^(.*?)_([a-z_]+)_([0-9.]+x)\.png$
    import re
    # Updated regex to handle potential extra underscores in font names correctly
    # We assume scale is always at the end (e.g., 1x, 1.2x)
    # And font is immediately before scale.
    # However, to be robust, we can just look for known suffixes or use a greedy match for base name
    # knowing that font and scale specific formats.
    
    # Let's try to deduce groups dynamically
    groups = {} 
    
    for f in files:
        match = re.match(r"^(.*)_([a-z_]+)_([0-9.]+x)\.png$", f)
        if match:
            base_name, font, scale = match.groups()
            if base_name not in groups:
               groups[base_name] = []
            groups[base_name].append({'file': f, 'font': font, 'scale': scale})
        else:
            # Fallback for unexpected names (e.g. splash_default.png which lacks scale/font in standard way logic?)
            # Actually splash_default.png -> base=splash, font=default, scale=? NO.
            # standard loop uses: f"{base}_{font}_{scale_name}.png"
            # splash/onboarding use: "splash_default.png" (hardcoded). 
            # We should probably treat them as "Misc" or their own group if they don't match pattern.
            misc_key = "Startup / Onboarding"
            if misc_key not in groups:
                groups[misc_key] = []
            groups[misc_key].append({'file': f, 'font': 'N/A', 'scale': 'N/A'})

    # Custom Sort Order
    sort_order = [
         "onboarding_p1", "onboarding_p2", "onboarding_p3",
         "splash",
         "home_initial", "home", "home_search_open",
         "track_list",
         "settings_usage_instructions", "settings_appearance", "settings_interface", "settings_random_playback", "settings_playback", "settings_collection_statistics",
         "player_msg_on", "player_panel_open"
    ]
    
    # Helper to find index in sort_order, else append at end sorted alphabetically
    def get_sort_key(name):
        try:
            return sort_order.index(name)
        except ValueError:
            return 999 

    sorted_group_keys = sorted(groups.keys(), key=lambda x: (get_sort_key(x), x))

    # Generate Group HTML
    groups_html = ""
    for base_name in sorted_group_keys:
        items = groups[base_name]
        cards_html = ""
        for item in items:
            cards_html += f"""
                <div class="card" onclick="openLightbox('{item['file']}')">
                    <img src="{item['file']}" loading="lazy" alt="{item['file']}">
                    <div class="card-info">
                        <strong>{item.get('font','-').title()}</strong>
                        {item.get('scale','-')}
                    </div>
                </div>"""
        
        groups_html += f"""
        <div class="group-container">
            <h2>{base_name.replace('_', ' ').replace('/', ' / ').title()} <span style="font-size: 12px; color: #555; margin-left:10px;">({len(items)} variants)</span></h2>
            <div class="group-grid">
                {cards_html}
            </div>
        </div>"""

    html_content = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Shakedown Verification Report</title>
    <style>
        body {{ font-family: 'Segoe UI', system-ui, sans-serif; background: #121212; color: #e0e0e0; margin: 0; padding: 20px; }}
        header {{ text-align: center; margin-bottom: 30px; border-bottom: 1px solid #333; padding-bottom: 20px; }}
        h1 {{ margin: 0; font-weight: 300; letter-spacing: 1px; color: #fff; }}
        h2 {{ margin-top: 40px; border-bottom: 1px solid #333; padding-bottom: 10px; font-weight: 400; color: #81d4fa; }}
        
        .controls {{ text-align: center; margin-bottom: 30px; position: sticky; top: 0; background: #121212; padding: 15px 0; z-index: 100; border-bottom: 1px solid #222; }}
        button {{ 
            padding: 8px 16px; cursor: pointer; background: #333; color: #ccc; 
            border: 1px solid #555; border-radius: 4px; margin: 0 5px; font-size: 14px; 
        }}
        button:hover {{ background: #444; color: #fff; }}
        button.active {{ background: #0288d1; color: #fff; border-color: #0288d1; }}

        /* Group Grid */
        .group-container {{ margin-bottom: 40px; }}
        .group-grid {{ 
            display: grid; 
            grid-template-columns: repeat(auto-fill, minmax(200px, 1fr)); 
            gap: 15px; 
        }}
        
        .card {{ 
            background: #1e1e1e; border-radius: 8px; overflow: hidden; 
            box-shadow: 0 4px 6px rgba(0,0,0,0.3); transition: transform 0.2s;
            cursor: pointer;
        }}
        .card:hover {{ transform: scale(1.02); z-index: 10; ring: 2px solid #0288d1; }}
        .card img {{ width: 100%; height: auto; display: block; }}
        .card-info {{ padding: 10px; font-size: 12px; color: #aaa; background: #252525; }}
        .card-info strong {{ color: #eee; display: block; margin-bottom: 2px; }}

        /* Slideshow / Lightbox */
        #lightbox {{ 
            display: none; position: fixed; top: 0; left: 0; width: 100%; height: 100%; 
            background: rgba(0,0,0,0.95); z-index: 2000; flex-direction: column; justify-content: center; align-items: center; 
        }}
        #lightbox img {{ max-width: 95%; max-height: 85vh; border-radius: 4px; box-shadow: 0 0 20px rgba(0,0,0,0.8); }}
        #lightbox-caption {{ margin-top: 15px; color: #fff; font-size: 16px; font-family: monospace; }}
        .lb-nav {{ 
            position: absolute; top: 50%; transform: translateY(-50%); 
            background: rgba(255,255,255,0.1); border: none; color: white; 
            font-size: 40px; padding: 20px; cursor: pointer; user-select: none; border-radius: 50%;
        }}
        .lb-nav:hover {{ background: rgba(255,255,255,0.2); }}
        .prev {{ left: 30px; }}
        .next {{ right: 30px; }}
        .close-btn {{ 
            position: absolute; top: 20px; right: 30px; font-size: 40px; cursor: pointer; color: #888; 
        }}
        .close-btn:hover {{ color: #fff; }}

    </style>
</head>
<body>
    <header>
        <h1>Shakedown Visual Verification</h1>
        <p style="color: #666; font-size: 12px;">Generated: {time.strftime("%Y-%m-%d %H:%M:%S")} | Tag: {LOCAL_DIR.split('/')[-1]}</p>
    </header>

    <div class="controls">
        <button onclick="collapseAll()">Collapse All Groups</button>
        <button onclick="expandAll()">Expand All Groups</button>
    </div>

    <div id="main-content">
        <!-- Render Groups -->
        {groups_html}
    </div>

    <!-- Lightbox -->
    <div id="lightbox" onclick="if(event.target === this) closeLightbox()">
        <span class="close-btn" onclick="closeLightbox()">&times;</span>
        <button class="lb-nav prev" onclick="changeSlide(-1)">&#10094;</button>
        <button class="lb-nav next" onclick="changeSlide(1)">&#10095;</button>
        <img id="lb-img" src="" alt="">
        <div id="lb-caption"></div>
    </div>

    <script>
        const allFiles = {str([f for f in files])}; 
        let currentIndex = 0;
        const lb = document.getElementById('lightbox');
        const lbImg = document.getElementById('lb-img');
        const lbCap = document.getElementById('lb-caption');

        function openLightbox(filename) {{
            currentIndex = allFiles.indexOf(filename);
            updateLightbox();
            lb.style.display = 'flex';
            document.body.style.overflow = 'hidden';
        }}

        function closeLightbox() {{
            lb.style.display = 'none';
            document.body.style.overflow = 'auto';
        }}

        function changeSlide(dir) {{
            currentIndex += dir;
            if (currentIndex < 0) currentIndex = allFiles.length - 1;
            if (currentIndex >= allFiles.length) currentIndex = 0;
            updateLightbox();
        }}

        function updateLightbox() {{
            const file = allFiles[currentIndex];
            lbImg.src = file;
            lbCap.textContent = file;
        }}

        document.addEventListener('keydown', (e) => {{
            if (lb.style.display === 'flex') {{
                if (e.key === 'ArrowLeft') changeSlide(-1);
                if (e.key === 'ArrowRight') changeSlide(1);
                if (e.key === 'Escape') closeLightbox();
            }}
        }});
        
        function collapseAll() {{
            document.querySelectorAll('.group-grid').forEach(el => el.style.display = 'none');
        }}
        function expandAll() {{
            document.querySelectorAll('.group-grid').forEach(el => el.style.display = 'grid');
        }}
    </script>
</body>
</html>"""
    
    with open(html_path, "w") as f:
        f.write(html_content)
    
    print(f"Report generated: {html_path}")

if __name__ == "__main__":
    main()
