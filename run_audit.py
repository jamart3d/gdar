import time
import json
import base64
from playwright.sync_api import sync_playwright

def run_audit():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True, args=['--autoplay-policy=no-user-gesture-required'])
        context = browser.new_context(viewport={'width': 1280, 'height': 800})
        page = context.new_page()

        logs = []
        page.on("console", lambda msg: logs.append(f"[{msg.type}] {msg.text}"))

        print("Navigating to app...")
        page.goto("http://localhost:8080")

        print("Waiting for initial load (15 seconds)...")
        time.sleep(15)

        # Take a screenshot of the main screen
        page.screenshot(path="audit_reports/01_home_loaded.png")

        # Inject our settings via localStorage directly since it's hard to navigate flutter canvas
        print("Injecting settings to trigger Liquid Glass and Hybrid Engine...")
        page.evaluate("""() => {
            localStorage.setItem('flutter.theme_style', '"fruit"');
            localStorage.setItem('flutter.fruit_color_option', '"blue"');
            localStorage.setItem('flutter.use_liquid_glass', 'true');
            localStorage.setItem('flutter.audio_engine_mode', '"hybrid"');
            localStorage.setItem('flutter.crossfade_duration', '8.0');
            localStorage.setItem('flutter.hybrid_handoff_mode', '"instant"');
        }""")

        print("Refreshing to apply settings...")
        page.reload()
        time.sleep(10)

        page.screenshot(path="audit_reports/02_fruit_theme_loaded.png")

        # Evaluate settings
        engine_mode = page.evaluate("localStorage.getItem('flutter.audio_engine_mode')")
        print(f"Engine mode in localStorage: {engine_mode}")

        # Force playback via JS if possible, or try clicking in the center
        print("Attempting to start playback...")
        # Since it's a flutter app, clicking the middle of the screen might open the first show
        page.mouse.click(640, 300)
        time.sleep(2)
        page.screenshot(path="audit_reports/03_show_clicked.png")

        # Click the first track
        page.mouse.click(640, 400)
        time.sleep(5)
        page.screenshot(path="audit_reports/04_playback_started.png")

        # We can also call the GDAR Audio engine directly to start playing a track if we have to,
        # but the JS engine doesn't have play URL function exposed directly that works out of the box without flutter.
        # Let's interact with window._gdarAudio if it exists.

        has_audio = page.evaluate("!!window._gdarAudio")
        print(f"Has Audio Engine: {has_audio}")
        if has_audio:
            engine_type = page.evaluate("window._gdarAudio.engineType")
            print(f"Engine Type: {engine_type}")

        # Rapid resize
        print("Performing rapid resize...")
        for i in range(5):
            page.set_viewport_size({"width": 1000, "height": 800})
            time.sleep(0.5)
            page.set_viewport_size({"width": 1280, "height": 800})
            time.sleep(0.5)

        page.screenshot(path="audit_reports/05_after_resize.png")

        print("Writing logs...")
        with open("audit_reports/console_logs.txt", "w") as f:
            f.write("\n".join(logs))

        browser.close()

if __name__ == "__main__":
    import os
    os.makedirs("audit_reports", exist_ok=True)
    run_audit()
