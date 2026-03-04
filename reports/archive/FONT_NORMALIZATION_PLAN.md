# Font Normalization & Standardization Plan
**Date:** 2026-01-26 (Revised after Screenshot Analysis)
**App Version:** 1.0.8+8

## Goal
Eliminate ad-hoc font scaling and positioning logic (currently scattered in widgets) by centralizing it into a robust Theme-based system. Ensure all fonts feel "native" and consistent in size, weight, and vertical rhythm.

## 1. Visual Analysis (from Font Dialog Screenshots)

**Key Observations (2026-01-26):**
- **Caveat at 1.3x is TOO LARGE:** Appears ~30-40% bigger than Roboto. The tall x-height makes it dominate visually. Recommend reducing to **1.0-1.1x** for better balance.
- **Permanent Marker slightly oversized:** At 0.95x it still appears larger than Roboto due to bold strokes and wide letters. Recommend **0.88-0.90x**.
- **Rock Salt letter-spacing too loose:** At 1.5 spacing, words feel disconnected. Recommend **0.8-1.0** for tighter cohesion while maintaining character.
- **Line height issues at 1.2x UI Scale:** Caveat and Rock Salt show crowding/clipping. All fonts need consistent **1.3-1.4** height for breathing room.
- **Weight adjustments working well:** Caveat +100 prevents hairline appearance, Rock Salt -100 reduces boldness effectively.

## 2. The "Font Personality" Matrix (REVISED)

| Font | Scale Factor | Height (Line Height) | Weight Adjustment | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| **Roboto (Default)** | 1.0 | 1.3 | None (w400/w500) | 0.0 |
| **Caveat** | **1.05** *(was 1.3)* | **1.3** *(was 1.0)* | +100 (w500 -> w600) | 0.5 |
| **Rock Salt** | 0.85 | **1.5** *(was 1.6)* | -100 (w500 -> w400) | **1.0** *(was 1.5)* |
| **Permanent Marker** | **0.90** *(was 0.95)* | 1.4 | None | 0.5 |

**Rationale for Changes:**
- **Caveat Scale**: Reduced from 1.3 to 1.05 to match Roboto's visual weight. The previous value made it the dominant font in every UI context.
- **Caveat Height**: Increased from 1.0 to 1.3 to prevent descenders from clipping at larger UI scales.
- **Rock Salt Spacing**: Reduced from 1.5 to 1.0 for better word cohesion without sacrificing character.
- **Rock Salt Height**: Slightly reduced from 1.6 to 1.5 as the new spacing helps vertical rhythm.
- **Permanent Marker Scale**: Reduced from 0.95 to 0.90 to counteract its bold/wide appearance.
- **Default Height**: Increased from 1.2 to 1.3 as baseline for all fonts to ensure consistent vertical rhythm.

## 3. Infrastructure: `FontProvider` vs. `AppTheme`
**Status:** ✅ `FontConfig` class created, `AppThemes.buildTextTheme()` implemented.

Instead of widgets pulling separate settings (`uiScale`, `appFont`) and doing math, a centralized logic produces a fully configured `TextTheme`.

### Implemented Architecture
1.  ✅ **`FontConfig` Class:** Data class in `lib/ui/styles/font_config.dart` holding the Matrix values above.
2.  ✅ **`AppTheme` Update:** Modified `lib/utils/app_themes.dart` to use `buildTextTheme(String font, bool uiScale)`.
3.  ✅ **No New Provider Needed:** `SettingsProvider` already notifies on font changes. Theme rebuilds automatically.

## 4. Implementation Steps

### Phase 1: The Configuration Core ✅ COMPLETE
- ✅ Created `lib/ui/styles/font_config.dart`.
- ✅ Defined Map of `FontConfig` objects for each supported font.
- ✅ Implemented "Optical Weight" adjustment logic via `adjustWeight()` method.

### Phase 2: Theme Integration (Centralization) ✅ COMPLETE
- ✅ Updated `lib/utils/app_themes.dart` with `buildTextTheme()` method.
- ✅ Integrated `uiScale` parameter into theme generation.
- ✅ Updated `lib/main.dart` to pass `uiScale` to `AppThemes.buildTextTheme()`.
- ✅ Removed redundant `MediaQuery` text scaler wrapper (now handled by theme).

### Phase 3: Font Config Refinement (IN PROGRESS)
**Action:** Update `lib/ui/styles/font_config.dart` with REVISED matrix values.
- [ ] Update Caveat scale from 1.3 to 1.05
- [ ] Update Caveat height from 1.0 to 1.3
- [ ] Update Rock Salt spacing from 1.5 to 1.0
- [ ] Update Rock Salt height from 1.6 to 1.5
- [ ] Update Permanent Marker scale from 0.95 to 0.90
- [ ] Update Roboto height from 1.2 to 1.3

### Phase 4: Widget Refactoring (Cleanup) - FUTURE
**Action:** Remove `AppTypography.responsiveFontSize` (if still exists).
- **Target:** `PlaybackScreen`, `OnboardingScreen`, `ShowListCard`.
- **Change:** Replace `fontSize: AppTypography.responsiveFontSize(...)` with:
  ```dart
  style: Theme.of(context).textTheme.titleLarge 
  // The Theme now ALREADY has the correct size, scale, and weight!
  ```
- **Benefit:** Widgets become dumb. They ask for "Title Large" and get the perfect Caveat size automatically.

### Phase 5: Cap & Constraints - FUTURE
1.  **Text Scale Cap:** In `main.dart`, wrap the app in a `MediaQuery` that clamps `textScaler`:
    ```dart
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      final clampedScale = mediaQuery.textScaler.clamp(minScale: 1.0, maxScale: 1.5);
      return MediaQuery(data: mediaQuery.copyWith(textScaler: clampedScale), child: child!);
    }
    ```
2.  **`auto_size_text`:**
    - **Target:** Playback Control Buttons, Filter Badges.
    - **Implementation:** Replace `Text()` with `AutoSizeText()` for labels that *must* fit in a fixed button height (e.g., "Play Random").

## 5. Verification

### Visual Regression Testing
- **Rock Salt:** Verify tall ascenders/descenders don't clip at 1.2x UI Scale (height 1.5 fix).
- **Caveat:** Verify it doesn't overwhelm Roboto in size (1.05 scale fix) and weight isn't too light (+100 weight adjustment).
- **Permanent Marker:** Verify bold strokes don't overpower UI (0.90 scale fix).
- **All Fonts:** Check letter-spacing doesn't create disjointed words (especially Rock Salt at 1.0).

### Scaling Uniformity Test
- Toggle UI Scale ON/OFF across all fonts.
- Verify the entire app scales uniformly without font-specific conditional logic in widgets.
- Check critical screens: Show List, Playback Panel, Settings, Search.

### Iterative Refinement Workflow
1. **Run `scripts/capture_font_dialogs.py`** to capture fresh dialog screenshots.
2. **Visual Compare:** Review HTML report (`./screenshots/font_dialogs/font_dialogs_report.html`).
3. **Adjust `FontConfig`:** Update `lib/ui/styles/font_config.dart` matrix values.
4. **Hot Reload & Test:** Cycle through fonts in the app, toggle UI scale, verify ShowListCard, Playback, Settings.
5. **Repeat** until all fonts feel visually balanced and "native."

### Success Criteria
- All 4 fonts should appear roughly the same **visual size** in the font selection dialog.
- No font should dominate or feel cramped compared to Roboto.
- Line heights prevent clipping at 1.2x UI scale.
- Letter-spacing maintains readability without fragmenting words.
