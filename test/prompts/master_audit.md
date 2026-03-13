# GDAR Master Release Audit (Universal)

**Mission:** Run this in a headless Chrome instance and provide a comprehensive pass/fail report for all phases. This is the final "Green Light" check before production deployment.

---

### Phase 1: High-Performance Audio Gauntlet
1.  **Seek Stress**: Seek to within 3s of track end 3 times. Verify 0ms transition.
2.  **CPU Throttling**: Enable **6x Slowdown** in Chrome DevTools. 
    - **Observe**: Track transition MUST remain gapless.
    - **Monitor**: Check console logs for "Aborted fetch" or timer drift > 50ms.
3.  **Survival**: Hard Refresh during playback. Audio MUST resume and Engine Mode (Hybrid/Web) must persist.

### Phase 2: Web/PWA "Fruit" Aesthetic (Walled Garden)
1.  **Radii/Font**: Verify **14px** corner radii on all cards and **Inter** typography.
2.  **Blur**: Verify `BackdropFilter` (sigma 15.0) on the Playback Panel.
3.  **M3 Leak Detection**: Search for standard Material 3 FABs (Circular) or Ripples. Any ripple in Fruit mode is a FAIL.
4.  **Lucide Sync**: Verify all icons are line-based Lucide SVG icons.

### Phase 3: TV UI Interaction & Focus
1.  **Dual-Pane Flow**:
    - Select a show in the Master (left) pane.
    - Press **Tab** or **S**. Focus MUST shift to the Detail (right) pane.
    - Verify Inactive Header dimming (opacity ~0.3-0.5).
2.  **Back-to-Master**: In the Playback pane, press **Back/Escape**. Focus MUST return to the Show List.
3.  **Visual Focus**: Verify **TvFocusWrapper** scaling (1.05x) and RGB glow border. No ripples!

### Phase 4: Mobile SIM & One-Handed Layout
1.  **Safe-Area**: Set viewport to 375x812. Verify interactive controls are in the **bottom 40%**.
2.  **Padding**: Verify Status Bar and Home Indicator areas are NOT obscured by UI elements.
3.  **Style**: Ensure NO "Fruit" glass effects are showing in Mobile sim (Mobile is strictly Material 3).

### Phase 5: Persistence & Data Integrity (Final Health)
1.  **Ratings**: Rate a show 3 stars. Block another show. 
    - **Verify**: Hard Refresh. Persistence MUST survive in `localStorage`.
2.  **Screensaver & Dynamic Trails**: 
    - Enable **Screensaver**.
    - **Audit**: Verify the Logo bounces correctly.
    - **Stress**: Change Logo Velocity/Speed Settings. If "Dynamic Trails" is ON, verify the number of trail slices increases/decreases dynamically based on logo speed.
3.  **App Version**: Verify `Version 1.1.68+168` is visible in Settings.

### Phase 6: Edge Cases & Known Issues (Regression)
1.  **Background Longevity**: 
    - Minimize the browser or switch tabs for 2 minutes during playback.
    - **Verify**: Does the audio continue smoothly? Restore the window—is the timer sync still accurate?
2.  **Buffering & Skip Bug**: 
    - Start a track and immediately seek to 98%. 
    - If the next track isn't fully buffered, verify the engine WAITS for buffering instead of skipping the track entirely (Regression check for "Track Skip on Buffer Bug").
3.  **Mobile Preload**: 
    - Change the "Tracks to Buffer Ahead" setting in Settings.
    - **Verify**: Verify the new value persists after a Hard Refresh.

### Phase 7: Architectural Code Scans (Off-Line)
1.  **Walled Garden**: Scan `lib/` for any `LiquidGlassWrapper` leakage into standard Mobile widgets (verify they are strictly `kIsWeb` gated).
2.  **TV Focus**: Verify every file in `lib/ui/widgets/tv/` uses `TvFocusWrapper` for interactive elements and identifies any `InkWell` (prohibited in TV widgets).
3.  **Rule Sync**: Scan `.agent/rules/` to ensure no conflicting directives exist between Mobile, TV, and Web audio specs.

**Reporting Format:**
Provide a summary table for Phases 1-7 (PASS/FAIL).
