import asyncio
import time
from playwright.async_api import async_playwright

async def run(playwright):
    browser = await playwright.chromium.launch(headless=True)
    context = await browser.new_context(viewport={'width': 1920, 'height': 1080})
    page = await context.new_page()

    logs = []
    page.on("console", lambda msg: logs.append(msg.text))

    print("Navigating to http://localhost:8080...")
    await page.goto("http://localhost:8080")

    # Wait for the app to load
    await asyncio.sleep(10)

    print("Initial logs captured:")
    for log in logs:
        print(f"LOG: {log}")

    print("Test finished.")
    await browser.close()

async def main():
    async with async_playwright() as playwright:
        await run(playwright)

if __name__ == '__main__':
    asyncio.run(main())