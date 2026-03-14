# Jules Fruit UI & Liquid Glass Audit

**Mission:** Run this in a headless Chrome instance and show me the logs. Audit the GDAR Web UI to ensure it strictly adheres to the **Fruit (Liquid Glass)** theme spec. We are checking for "Apple-kosher" feel and the total exclusion of Material 3 design expressive leaks.

---

### Phase 0: Environment Check
1.  **Navigate** to the app URL.
2.  Enable **Fruit Theme** in settings if not active by default.
3.  Ensure **Liquid Glass** is toggled ON.

### Phase 1: Architectural "Apple-Kosher" Audit
1.  **Corner Radii**: Inspect the main cards and buttons. They MUST have exactly **14px** corner radii. 
2.  **Typography**: Verify the font-family. It MUST be **Inter**. Check that it is a variable font weight if possible.
3.  **Iconography**: Inspect icons in the sidebar and player controls. They MUST be **Lucide Icons** (SVG/Line-based). Any Material symbols or icons are a Fail.
4.  **Liquid Glass**: Inspect the **Playback Panel** backdrop. It MUST use a `BackdropFilter` with a blur (`sigma`) of **15.0**. The background alpha should be around **0.7**.

### Phase 2: Neumorphism vs Material 3
1.  **Elevation check**: Select a button or card. Ensure it does NOT use standard CSS `box-shadow` elevation or M3 elevation levels.
2.  **Dual Shadows**: Verify that interactive elements use **dual-shadow** Neumorphism (light/dark offsets).
3.  **Interaction Feedback**: Tap a button. Verify there is a **Spring/Scale** animation. There MUST be **0 ink-ripples** or Material 3 splash effects.

### Phase 3: Uniformity & Toggle Stress
1.  **Navigation**: Traverse between **Home**, **Playback Screen**, and **Settings**. Does the style remain uniform? 
2.  **Simple Mode Toggle**: 
    - Toggle "Simple Mode" / "Liquid Glass" OFF.
    - Verify the backdrop blur is removed but the "Fruit" structure (Radii, Font) remains.
3.  **Color Sync**:
    - Change the **Seed Color** / Theme.
    - Verify that all glass surfaces and Neumorphic highlights adapt correctly to the new tint.

### Phase 4: M3 Leak Detection
1.  Check for any un-themed **Material 3 Floating Action Buttons (FABs)** or standard M3 BottomNavigationBars. 
2.  Ensure the **Settings** list is NOT using standard M3 list tiles with large gaps and standard M3 iconography.

**Report:** Provide a detailed report of any M3 leaks, incorrect radii, or icon inconsistencies. Take a screenshot of the Playback Panel with Liquid Glass active.
