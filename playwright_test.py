import time
from playwright.sync_api import sync_playwright

def run_audit():
    with sync_playwright() as p:
        browser = p.chromium.launch(headless=True)
        context = browser.new_context()
        page = context.new_page()

        # Listen for console logs
        page.on("console", lambda msg: print(f"CONSOLE [{msg.type}]: {msg.text}"))

        print("Navigating to app...")
        page.goto("http://localhost:8080")

        print("Waiting for app to load...")
        time.sleep(10)

        # Take a screenshot
        page.screenshot(path="screenshot_loaded.png")

        # Check window.shakedownVersion
        try:
            version = page.evaluate("window.shakedownVersion")
            print(f"window.shakedownVersion: {version}")
        except Exception as e:
            print(f"Error getting version: {e}")

        print("Done.")
        browser.close()

if __name__ == "__main__":
    run_audit()
