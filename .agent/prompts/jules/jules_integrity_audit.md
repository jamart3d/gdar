# Jules Persistence & Platform Integrity Audit

**Mission:** Run this in a headless Chrome instance and show me the logs. Audit the GDAR application for architectural integrity, state persistence, and platform-specific layout consistency.

---

### Phase 1: Aesthetic Depth (True Black + Glow)
1.  Navigate to **Settings > Appearance**.
2.  Enable **True Black Mode**.
3.  Set **Glow Intensity** to a high value (e.g., 80%).
4.  **Audit**: Inspect the playback card or buttons. Even in True Black, there MUST be subtle shadows/glows to maintain UI depth. It should not look like a 2D flat shape against black.
5.  **Screenshot**: Capture the Playback Screen in True Black with high glow.

### Phase 2: Navigation & Panel Persistence
1.  Navigate to a specific **Year** -> Select a **Show**.
2.  Expand the **Playback Panel** (slide it up).
3.  **REFRESH** the page (`Cmd+R` / `Ctrl+R`).
4.  **Verify**:
    - Does the app return to the same Show?
    - Is the Playback Panel still expanded?
    - Does the URL reflect the correct state (if using deep links/routing)?

### Phase 3: Data Integrity Stress (Ratings & Blocks)
1.  Find a show and give it a **3-star rating**.
2.  Find another show and **Block** it (Red Star).
3.  **Hard Refresh** the browser.
4.  **Verify**:
    - Does the rated show still show 3 stars?
    - Is the blocked show still marked as blocked and filtered out of "Random" dice rolls?
    - Check `localStorage` for `flutter.ratings` and ensure it is updated.

### Phase 4: Mobile Layout Consistency (Simulation)
1.  Set the browser viewport to **375 x 812** (Standard Mobile).
2.  Open the **Playback Screen**.
3.  **Audit**:
    - Are the primary interactive controls (Play/Pause, Seek, Skip) located within the **bottom 40%** of the screen height?
    - Is there appropriate **SafeArea** padding at the top (status bar) and bottom (home indicator)?
    - Verify NO Neumorphic shadows or BackdropFilters are active in this mobile-simulated mode (per `mobile_rules.md`).

**Report:** Provide the Console log and screenshots of any depth issues or navigation failures.
