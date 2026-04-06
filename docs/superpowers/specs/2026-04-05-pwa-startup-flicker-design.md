# PWA Startup Flicker Fix — Design Spec

**Date:** 2026-04-05
**Report:** `reports/2026-04-05_15-56_v1.3.61+271_pwa_startup_flicker.md`
**Scope:** Web/PWA only (`apps/gdar_web/`)

---

## Problem

Three-layer startup sequence produces two visible jumps ("snaps"):

| Seam | From | To | Issue |
|---|---|---|---|
| 1 | OS splash | HTML splash | Background color mismatch (`#000000` → `#080808`); icon size snap |
| 2 | HTML splash | Flutter `SplashScreen` | Layout mismatch: centered icon → title text + checklist |
| 3 | Flutter `SplashScreen` | Home | Already smooth (2500ms FadeTransition) |

Additionally: the HTML splash shows no activity indicator, making long inits look frozen.

---

## Phase 1 — Flicker Fix

### 1. Color Unification

**Files:** `apps/gdar_web/web/manifest.json`, `apps/gdar_web/web/index.html`

- `manifest.json` `background_color`: `#000000` → `#080808`
- `index.html` `body { background-color }`: `#000000` → `#080808`

Aligns OS splash background with the HTML splash div (`--splash-bg: #080808`), eliminating seam 1's background jump.

### 2. HTML Splash Redesign

**File:** `apps/gdar_web/web/index.html`

Replace the `<img src="icons/Icon-512.png">` with a CSS-rendered title matching Flutter's `ShakedownTitle` widget.

**Font preload:**
```html
<link rel="preload"
  href="assets/packages/gdar_design/assets/fonts/RockSalt-Regular.ttf"
  as="font" type="font/ttf" crossorigin>
```

**`@font-face` rule (in `<style>`):**
```css
@font-face {
  font-family: 'RockSalt';
  src: url('assets/packages/gdar_design/assets/fonts/RockSalt-Regular.ttf') format('truetype');
  font-weight: bold;
  font-display: block;
}
```

**Title element** (replaces `<img>`):
```html
<div id="splash-title">Shakedown</div>
```

**CSS to match `ShakedownTitle` (Flutter: `fontSize: 24`, `fontWeight: bold`, `letterSpacing: 1.2`, `color: colorScheme.primary`):**
```css
#splash-title {
  font-family: 'RockSalt', cursive;
  font-weight: bold;
  font-size: 32px;        /* Slightly larger than Flutter's 24 logical px for visual weight */
  letter-spacing: 1.2px;
  line-height: 1.4;
  color: #00E676;          /* GDARFruitTheme.dark sophisticate primary */
  text-align: center;
  margin-bottom: 8px;
}
```

Remove the old `#loading-splash img { ... }` CSS rule.

**Sub-label** (`#loading-text`): keep as-is ("Loading Shakedown"), positioned below the title.

### 3. Progress Bar

**File:** `apps/gdar_web/web/index.html`

Add below `#loading-text` inside `#loading-splash`:
```html
<div id="splash-progress-track">
  <div id="splash-progress-fill"></div>
</div>
```

**CSS:**
```css
#splash-progress-track {
  width: clamp(200px, 50vw, 360px);
  height: 6px;
  background: rgba(255, 255, 255, 0.08);
  border-radius: 3px;
  margin-top: 24px;
  overflow: hidden;
}
#splash-progress-fill {
  height: 100%;
  background: #00E676;
  border-radius: 3px;
  animation: splash-sweep 1.8s ease-in-out infinite;
  transform-origin: left;
}
@keyframes splash-sweep {
  0%   { width: 0%;   margin-left: 0%; }
  60%  { width: 70%;  margin-left: 0%; }
  80%  { width: 20%;  margin-left: 75%; }
  100% { width: 0%;   margin-left: 100%; }
}
```

The bar sweeps left-to-right and loops — never reaches 100%, never appears stuck. Fades out with `#loading-splash` (no snap risk since it's a child of the splash div).

### 4. Fade Timing

**File:** `apps/gdar_web/web/index.html`

| Setting | Before | After |
|---|---|---|
| Pre-hide delay | 100ms `setTimeout` | Remove entirely |
| CSS transition | `opacity 0.6s ease-out` | `opacity 0.2s ease-out` |
| `splash.remove()` timeout | 600ms | 200ms |

---

## Phase 2 — Returning User Fast Path

**File:** `apps/gdar_web/web/index.html`

On repeat visits the app loads from cache quickly. The HTML splash should step aside fast rather than animate.

**Logic in the splash init IIFE:**
```js
const isReturning = !!localStorage.getItem('gdar_pwa_visited');
if (!isReturning) {
  localStorage.setItem('gdar_pwa_visited', '1');
}

const hideSplash = () => {
  splash.style.transition = isReturning
    ? 'opacity 0.1s ease-out'
    : 'opacity 0.2s ease-out';
  splash.style.opacity = '0';
  splash.style.pointerEvents = 'none';
  setTimeout(() => { if (splash.parentNode) splash.remove(); },
    isReturning ? 100 : 200);
};
```

- First visit: 200ms fade (standard, progress bar animates while Flutter inits)
- Return visit: 100ms fade (near-instant, app is cached and paints quickly)
- No PWA standalone guard — behaviour is correct in both browser tab and installed PWA

---

## Files Changed

| File | Changes |
|---|---|
| `apps/gdar_web/web/manifest.json` | `background_color` → `#080808` |
| `apps/gdar_web/web/index.html` | Font preload, `@font-face`, remove img, add title div + progress bar, fade timing, returning-user localStorage logic |

No Dart changes required.

---

## Non-Goals

- Matching the Flutter checklist items in HTML (too dynamic, not worth the complexity)
- Reading localStorage for glass toggle state (progress bar is always solid; flash duration is too short to matter)
- Changing Flutter's `SplashScreen` layout
