# Splash Theme Sync Design
**Date:** 2026-04-07  
**Scope:** `apps/gdar_web/web/index.html` only — no Dart changes

---

## Problem

The HTML pre-Flutter splash (`#loading-splash`) hardcodes `color: #00E676` for the Shakedown title and progress bar. This matches only the Fruit "sophisticate dark" palette. Users on any other palette or light mode see a visible color flash when the HTML splash transitions to the Flutter `SplashScreen`.

The background color is already partially handled via `prefers-color-scheme` but does not account for per-palette scaffold backgrounds.

---

## Goal

Eliminate the color flash on the Shakedown title and progress bar, and the background color jump, for all Fruit palettes and dark/light modes. Works on every visit including first return (not first-ever, where no prefs are stored yet).

---

## Approach

Read the three Flutter preference keys from `localStorage` synchronously at splash creation time. Map to the correct primary and background colors. Apply inline. Fall back to sophisticate dark defaults when no prefs exist (first-ever visit — same as current behavior).

**No Dart changes. No new localStorage keys.**

---

## Color Map

Sourced directly from `packages/styles/gdar_fruit/lib/fruit_theme.dart`.

| palette index | dark primary | dark bg   | light primary | light bg   |
|---------------|-------------|-----------|---------------|------------|
| 0 — sophisticate | `#00E676` | `#0F172A` | `#5C6BC0`   | `#E0E5EC`  |
| 1 — minimalist   | `#30D158` | `#1C1C1E` | `#34C759`   | `#FFFFFF`  |
| 2 — creative     | `#FF375F` | `#1A1A1A` | `#FF2D55`   | `#FFF9F9`  |
| android theme    | `#00E676` | `#080808` | `#00E676`   | `#F5F5F5`  |

---

## localStorage Keys (Flutter `shared_preferences` web prefix)

| Key | Values | Meaning |
|-----|--------|---------|
| `flutter.theme_style_preference` | `0` = android, `1` = fruit | Which theme family |
| `flutter.fruit_color_option_preference` | `0` = sophisticate, `1` = minimalist, `2` = creative | Fruit palette |
| `flutter.theme_mode_preference` | `0` = system, `1` = light, `2` = dark | Brightness |

For `theme_mode = 0` (system), resolve dark/light via `window.matchMedia('(prefers-color-scheme: dark)').matches`.

---

## Implementation

**Single inline `<script>` block** added to `index.html`, placed immediately before the `#loading-splash` div in `<body>`. Runs synchronously so no flash before the div is painted.

```
function getSplashColors() {
  try {
    const themeStyle = parseInt(localStorage.getItem('flutter.theme_style_preference') ?? '1');
    const colorOption = parseInt(localStorage.getItem('flutter.fruit_color_option_preference') ?? '0');
    const themeMode = parseInt(localStorage.getItem('flutter.theme_mode_preference') ?? '0');

    const prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
    const isDark = themeMode === 2 || (themeMode === 0 && prefersDark);

    if (themeStyle !== 1) {
      // Android theme
      return { primary: '#00E676', bg: isDark ? '#080808' : '#F5F5F5' };
    }

    const darkMap = ['#00E676','#30D158','#FF375F'];
    const darkBgMap = ['#0F172A','#1C1C1E','#1A1A1A'];
    const lightMap = ['#5C6BC0','#34C759','#FF2D55'];
    const lightBgMap = ['#E0E5EC','#FFFFFF','#FFF9F9'];

    const idx = Math.min(colorOption, 2);
    return isDark
      ? { primary: darkMap[idx], bg: darkBgMap[idx] }
      : { primary: lightMap[idx], bg: lightBgMap[idx] };
  } catch (_) {
    // localStorage unavailable (e.g. private browsing write-blocked on read? No — reads are safe. This catches unexpected errors.)
    return { primary: '#00E676', bg: '#080808' };
  }
}
```

Apply the resolved colors to:
- `document.body.style.backgroundColor`
- `#loading-splash` background
- `--splash-bg` CSS variable (covers `flt-glass-pane` too)
- `#splash-title` color
- `#splash-progress-fill` background

Leave the existing `@media (prefers-color-scheme: light)` CSS block as a no-JS fallback. The JS values override it when prefs are available.

---

## Out of Scope

- PWA `manifest.json` `background_color` — static, OS-native splash before HTML loads; not addressable
- Shakedown text color precision: `colorScheme.primary` from `ColorScheme.fromSeed` may produce a slightly different tonal value than the seed. The seed colors are used here (same as the existing `#00E676` hardcode), which is an accepted approximation.

---

## Files Changed

| File | Change |
|------|--------|
| `apps/gdar_web/web/index.html` | Add `getSplashColors()` JS block; apply colors inline; update CSS defaults |
