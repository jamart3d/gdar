# Font Normalization & Standardization Plan
**Date:** 2026-01-25 12:48 PM
**App Version:** 1.0.8+8

## Goal
Eliminate ad-hoc font scaling and positioning logic (currently scattered in widgets) by centralizing it into a robust Theme-based system. Ensure all fonts feel "native" and consistent in size, weight, and vertical rhythm.

## 1. The "Font Personality" Matrix
We will map specific factors for each supported font to normalize their visual appearance relative to the default (Roboto).

| Font | Scale Factor | Height (Line Height) | Weight Adjustment | Letter Spacing |
| :--- | :--- | :--- | :--- | :--- |
| **Roboto (Default)** | 1.0 | 1.2 | None (w400/w500) | 0.0 |
| **Caveat** | 1.3 | 1.0 (Taller glyphs) | +100 (w500 -> w600) | 0.5 |
| **Rock Salt** | 0.85 | 1.6 (Large ascenders) | -100 (w500 -> w400) | 1.5 |
| **Permanent Marker** | 0.95 | 1.4 | None | 0.5 |

*   **Scale Factor:** Multiplier applied to the base font size to make X-heights visually equal.
*   **Height:** Forced `height` property to stabilize layout containers. Caveat needs less line height (tight), Rock Salt needs more (loose).
*   **Weight:** "Optical" weight adjustment. Caveat often looks too thin at standard weights; Rock Salt looks too bold.

## 2. Infrastructure: `FontProvider` vs. `AppTheme`
**Yes, a `FontProvider` (or a dedicated logic controller) is essential.**
Instead of widgets pulling separate settings (`uiScale`, `appFont`) and doing math, a centralized logic will produce a fully configured `TextTheme`.

### Proposed Architecture
1.  **`FontConfig` Class:** Data class holding the Matrix values above.
2.  **`AppTheme` Update:** Modify the `main.dart` theme builder to consume `SettingsProvider`.
3.  **No New Provider Needed (Optimization):** Since `SettingsProvider` already notifies on font changes, we can contain the logic in a new helper `AppTheme.buildTextTheme(String font, bool uiScale)` which `main.dart` calls.

## 3. Implementation Steps

### Phase 1: The Configuration Core
**Action:** Create `lib/ui/styles/font_config.dart`.
- Define a Map of `FontConfig` objects for each supported font.
- Implement the "Optical Weight" mapping logic.

### Phase 2: Theme Integration (Centralization)
**Action:** Update `lib/main.dart` / `AppTheme`.
- Instead of just setting `fontFamily`, use `TextTheme.apply()`:
  ```dart
  TextTheme buildTextTheme(String fontKey, bool uiScale) {
    final config = FontConfig.get(fontKey);
    final baseTheme = ThemeData.light().textTheme;
    
    return baseTheme.apply(
      fontFamily: config.fontFamily,
      fontSizeFactor: config.scaleFactor * (uiScale ? 1.2 : 1.0),
      bodyColor: ...,
      displayColor: ...,
    ).copyWith(
      // Enforce specific overrides that .apply() might miss or strict heights
      bodyMedium: baseTheme.bodyMedium?.copyWith(
         height: config.lineHeight,
         fontWeight: adjustWeight(FontWeight.normal, config),
      ),
      // ... repeat for critical styles
    );
  }
  ```

### Phase 3: Widget Refactoring (Cleanup)
**Action:** Remove `AppTypography.responsiveFontSize`.
- **Target:** `PlaybackScreen`, `OnboardingScreen`, `ShowListCard`.
- **Change:** Replace `fontSize: AppTypography.responsiveFontSize(...)` with:
  ```dart
  style: Theme.of(context).textTheme.titleLarge 
  // The Theme now ALREADY has the correct size, scale, and weight!
  ```
- **Benefit:** Widgets become dumb. They ask for "Title Large" and get the perfect Caveat size automatically.

### Phase 4: Cap & Constraints
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

## Verification
- **Visual Regression:** Verify Rock Salt doesn't clip (height fix). Verify Caveat isn't hairline thin (weight fix).
- **Scaling:** Toggle UI Scale. Verify entire app scales uniformly without ad-hoc `if (caveat)` checks in UI code.
