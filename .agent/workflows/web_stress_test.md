---
description: Test PWA rendering performance, Simple Theme gates, and standard web UI responsiveness.
---
# Web Stress Test Workflow (Monorepo)

This workflow verifies web performance, Simple Theme constraints, and detects UI freezes during engine playback and track transitions.

> [!NOTE]
> **MONOREPO**: Web app lives in `apps/gdar_web/`. Build output is at `apps/gdar_web/build/web`.

## Manual Checklist

1.  **Environment Check**:
    - Launch the web server from the web app target (note: this is interactive, so launch it and do not wait for it):
    ```powershell
    cd apps/gdar_web; flutter run -d web-server --web-port=8080
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

## Automated Test

4.  **Web Runtime Smoke Test**:
    - Build the application from the web app target:
    ```powershell
    cd apps/gdar_web; flutter build web --release
    ```
    - Serve `apps/gdar_web/build/web` using the local server in `scripts/stress_test/hybrid_stress.js`.
    - **Verify**: App loads without console errors.
    - **Identify**: Specifically look for `Unsupported operation: _Namespace` or `dart:io` crashes during initialization.

5.  **Web UI Freeze Stress Test**:
    - Run the Puppeteer test:
    ```bash
    node scripts/stress_test/hybrid_stress.js
    ```
    - **Verify**: UI heartbeat remains active (no stalls > 1s).
    - **Verify**: No long tasks > 200ms appear during track transitions.
    - **Verify**: Track transitions do not freeze UI while audio continues.
    - **Artifacts**: If a freeze is detected, the script captures a screenshot in `scripts/stress_test`.

6.  **Reporting**:
    - If jank is detected (>16ms frames), identify the offending Widget (often nested `Stack` with `Opacity` or `BackdropFilter`).
    - If freezes occur, compare HTML5 vs WebAudio vs Hybrid using the stress test and capture logs.
    - Use the `/clean` workflow if build artifacts are stale.

