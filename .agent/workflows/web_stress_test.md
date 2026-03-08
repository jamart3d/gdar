---
description: Test PWA rendering performance and Simple Theme gates.
---
# Web Stress Test Workflow

This workflow is designed to verify that the application remains performant and follows the "Simple Theme" rules in the browser.

1.  **Environment Check**:
    - Ensure you are running on the `web-server` device:
    ```bash
    flutter run -d web-server --web-port=8080
    ```

2.  **Performance Mode Audit**:
    - Navigate through the Library, Track List, and Playback screens with `performanceMode` (Simple Theme) toggled **ON**.
    - **Verify**: No blurs (BackdropFilters) are visible.
    - **Verify**: No shadows are rendered under headers or buttons.
    - **Verify**: Smooth scrolling in the Track List (no RenderFlex or repaint lag).

3.  **Engine Switching**:
    - Toggle between **HTML5** and **Web Audio** engines.
    - **Verify**: No UI stalls during the switch.
    - **Verify**: Metadata remains in sync after engine handoff.

4.  **Reporting**:
    - If jank is detected (>16ms frames), identify the offending Widget (usually a nested `Stack` with `Opacity` or `Blur`).
    - Use the `/clean` workflow if build artifacts are stale.
