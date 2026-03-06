import time
import os
import shutil
from playwright.sync_api import sync_playwright

def test_full_audit():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--autoplay-policy=no-user-gesture-required'])
        context = browser.new_context(viewport={'width': 1280, 'height': 800})
        page = context.new_page()

        logs = []
        page.on("console", lambda msg: logs.append(f"[{msg.type}] {msg.text}"))

        # Phase 0: Environment Check & Version
        print("Phase 0: Navigating and setting up environment...")
        page.goto("http://localhost:8080/?flush=true")
        time.sleep(15)

        page.evaluate("""() => {
            // Setup Phase 2 (Audio Persistence) + Phase 0 (Fruit Theme)
            localStorage.setItem('flutter.theme_style', '"fruit"');
            localStorage.setItem('flutter.use_liquid_glass', 'true');
            localStorage.setItem('flutter.fruit_color_option', '"blue"');

            localStorage.setItem('flutter.audio_engine_mode', '"hybrid"');
            localStorage.setItem('flutter.crossfade_duration', '8.0');
            localStorage.setItem('flutter.hybrid_handoff_mode', '"instant"');
        }""")

        print("Refreshing for Phase 0 applied settings...")
        page.reload(wait_until="networkidle")
        time.sleep(15)

        # Audio Survival & Persistence checks
        print("Phase 2 (Audio): Verifying persistence...")
        engine_mode = page.evaluate("localStorage.getItem('flutter.audio_engine_mode')")
        print(f"Engine Mode in DB: {engine_mode}")

        # Screenshot Home
        page.screenshot(path="audit_reports/01_home_fruit_theme.png")

        # Try to trigger playback. Because it's flutter canvas we have to click around.
        # Let's use tab navigation or just click the middle.
        # By default the first item in the list is a show.
        print("Phase 1 (Audio): Starting playback...")
        # click show
        page.mouse.click(640, 200)
        time.sleep(2)
        # click play all
        page.mouse.click(640, 300)
        time.sleep(5)

        page.screenshot(path="audit_reports/02_playback_started.png")

        # Rapid resize
        print("Phase 3 (Audio & UI): Visual & Thread Stress")
        for i in range(5):
            page.set_viewport_size({"width": 900, "height": 800})
            time.sleep(0.5)
            page.set_viewport_size({"width": 1280, "height": 800})
            time.sleep(0.5)

        page.screenshot(path="audit_reports/03_after_resize.png")

        print("Writing logs to audit_reports/console_logs.txt")
        with open("audit_reports/console_logs.txt", "w") as f:
            f.write("\n".join(logs))

        browser.close()

if __name__ == "__main__":
    os.makedirs("audit_reports", exist_ok=True)
    test_full_audit()
