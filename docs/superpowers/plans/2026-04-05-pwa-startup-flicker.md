# PWA Startup Flicker Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate visual jumps during PWA startup by syncing colors, replacing the icon with matching text, adding a progress bar, and fast-pathing returning users.

**Architecture:** Pure HTML/CSS/JS changes in `index.html` and `manifest.json`. No Dart changes. Phase 1 fixes the two visual seams; Phase 2 adds the returning-user fast path. All changes are inside `#loading-splash` so they fade out with it — no snap risk.

**Tech Stack:** Vanilla HTML/CSS/JS, RockSalt TTF (already in web build assets), `localStorage`

---

## File Map

| File | What changes |
|---|---|
| `apps/gdar_web/web/manifest.json` | `background_color` `#000000` → `#080808` |
| `apps/gdar_web/web/index.html` | Font preload, `@font-face`, remove `<img>`, add title + progress bar, fade timing, returning-user JS |

---

## Task 1: Sync background colors

**Files:**
- Modify: `apps/gdar_web/web/manifest.json`
- Modify: `apps/gdar_web/web/index.html`

The OS splash reads `background_color` from `manifest.json`. The HTML splash div uses `--splash-bg: #080808`. Currently `manifest.json` says `#000000` — a visible jump on first render.

- [ ] **Step 1: Update manifest.json**

In `apps/gdar_web/web/manifest.json`, change:
```json
"background_color": "#000000",
```
to:
```json
"background_color": "#080808",
```

- [ ] **Step 2: Update body background in index.html**

In `apps/gdar_web/web/index.html`, in the `<style>` block, change:
```css
body {
  background-color: #000000;
  margin: 0;
  padding: 0;
}
```
to:
```css
body {
  background-color: #080808;
  margin: 0;
  padding: 0;
}
```

- [ ] **Step 3: Verify**

Open `apps/gdar_web/web/index.html` in a browser (or `flutter run -d chrome` from `apps/gdar_web/`). In DevTools → Application → Manifest, confirm `background_color` shows `#080808`. Inspect `body` computed style and confirm `background-color: rgb(8, 8, 8)`.

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/manifest.json apps/gdar_web/web/index.html
git commit -m "fix(web): sync manifest and body background to #080808"
```

---

## Task 2: Replace icon with RockSalt title text

**Files:**
- Modify: `apps/gdar_web/web/index.html`

The HTML splash currently shows `Icon-512.png` at `clamp(80px, 20vmin, 160px)`. The OS splash scales the same icon to ~33% of viewport — visible size snap. Flutter's `SplashScreen` shows a "Shakedown" text title in RockSalt. Replace the icon with matching text to eliminate seam 2.

The font is already compiled into the web build at:
`assets/packages/gdar_design/assets/fonts/RockSalt-Regular.ttf`

- [ ] **Step 1: Add font preload link**

In `apps/gdar_web/web/index.html`, inside `<head>`, add this line immediately before `<title>Shakedown</title>`:
```html
<link rel="preload" href="assets/packages/gdar_design/assets/fonts/RockSalt-Regular.ttf" as="font" type="font/ttf" crossorigin>
```

- [ ] **Step 2: Add @font-face and title CSS**

In `apps/gdar_web/web/index.html`, inside the `<style>` block, add after the `body` rule:
```css
@font-face {
  font-family: 'RockSalt';
  src: url('assets/packages/gdar_design/assets/fonts/RockSalt-Regular.ttf') format('truetype');
  font-weight: bold;
  font-display: block;
}
#splash-title {
  font-family: 'RockSalt', cursive;
  font-weight: bold;
  font-size: 32px;
  letter-spacing: 1.2px;
  line-height: 1.4;
  color: #00E676;
  text-align: center;
  margin-bottom: 8px;
}
```

`font-display: block` prevents a flash of unstyled text — the font is preloaded so it will be available before the splash div renders.

- [ ] **Step 3: Remove old img CSS rule**

In the `<style>` block, delete this rule entirely:
```css
#loading-splash img {
  width: clamp(80px, 20vmin, 160px);
  height: clamp(80px, 20vmin, 160px);
  margin-bottom: 24px;
}
```

- [ ] **Step 4: Replace img element with title div**

In `<body>`, inside `<div id="loading-splash">`, replace:
```html
<img src="icons/Icon-512.png" alt="Shakedown" />
```
with:
```html
<div id="splash-title">Shakedown</div>
```

- [ ] **Step 5: Verify**

Run `flutter run -d chrome` from `apps/gdar_web/`. The splash should show "Shakedown" in the RockSalt handwritten font in green (`#00E676`), centered, above "Loading Shakedown". No icon should appear. DevTools → Network → Filter by font: confirm `RockSalt-Regular.ttf` loads with status 200 and is preloaded (initiator: `<link rel=preload>`).

- [ ] **Step 6: Commit**

```bash
git add apps/gdar_web/web/index.html
git commit -m "fix(web): replace splash icon with RockSalt title text to match Flutter SplashScreen"
```

---

## Task 3: Add indeterminate progress bar

**Files:**
- Modify: `apps/gdar_web/web/index.html`

Adds a sweeping green bar below the sub-label so the splash never looks frozen. Uses `transform: translateX()` (GPU-composited) rather than `width`/`margin-left` for smooth animation. The bar is inside `#loading-splash` and fades with it — no snap.

- [ ] **Step 1: Add progress bar CSS**

In `apps/gdar_web/web/index.html`, in the `<style>` block, add after the `#splash-title` rule:
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
  width: 40%;
  background: #00E676;
  border-radius: 3px;
  animation: splash-sweep 1.6s ease-in-out infinite;
}
@keyframes splash-sweep {
  0%   { transform: translateX(-250%); }
  100% { transform: translateX(350%); }
}
```

The fill starts off the left edge of the track (`-250%` of its own 40% width) and exits off the right (`350%`). The track's `overflow: hidden` clips it. Animation loops continuously.

- [ ] **Step 2: Add progress bar HTML**

Inside `<div id="loading-splash">`, add after `<div id="loading-text">Loading Shakedown</div>`:
```html
<div id="splash-progress-track">
  <div id="splash-progress-fill"></div>
</div>
```

The full `#loading-splash` body should now read:
```html
<div id="loading-splash">
  <div id="splash-title">Shakedown</div>
  <div id="loading-text">Loading Shakedown</div>
  <div id="splash-progress-track">
    <div id="splash-progress-fill"></div>
  </div>
</div>
```

- [ ] **Step 3: Verify**

Run `flutter run -d chrome`. The splash should show:
1. "Shakedown" in green RockSalt
2. "Loading Shakedown" sub-label
3. A slim green bar sweeping left-to-right continuously below

Throttle the network to Slow 3G in DevTools to keep the splash visible long enough to observe the sweep loop. Confirm the bar fades cleanly when Flutter paints (no lingering bar, no snap).

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/index.html
git commit -m "feat(web): add indeterminate progress bar to splash screen"
```

---

## Task 4: Tighten fade timing and add returning-user fast path

**Files:**
- Modify: `apps/gdar_web/web/index.html`

Two changes to the splash management IIFE:
1. Reduce fade from 600ms → 200ms, remove the 100ms pre-hide delay
2. On return visits (`localStorage.getItem('gdar_pwa_visited')`), use 100ms fade instead of 200ms

- [ ] **Step 1: Update CSS transition duration**

In `apps/gdar_web/web/index.html`, in the `<style>` block, change:
```css
#loading-splash {
  ...
  transition: opacity 0.6s ease-out;
}
```
to:
```css
#loading-splash {
  ...
  transition: opacity 0.2s ease-out;
}
```

(The JS will override this per-call for returning users — the CSS value is the first-visit default.)

- [ ] **Step 2: Replace the splash management IIFE**

In `apps/gdar_web/web/index.html`, replace the entire splash management `<script>` block:
```html
<script>
  // Splash Screen Management: Removes splash only when Flutter app element appears  
  (function() {
    const splash = document.getElementById('loading-splash');
    if (!splash) return;

    const hideSplash = () => {
      console.log('[Splash] Flutter pane detected, fading out splash...');
      splash.style.opacity = '0';
      splash.style.pointerEvents = 'none';
      setTimeout(() => { if (splash.parentNode) splash.remove(); }, 600);
    };

    // 1. Observe body for flt-glass-pane (Flutter's root element)
    const observer = new MutationObserver((mutations, obs) => {
      if (document.querySelector('flt-glass-pane')) {
        // Tiny delay ensures the glass pane has a moment to paint its first frame   
        setTimeout(hideSplash, 100);
        obs.disconnect();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });

    // 2. Watchdog: Safety backup (app crashed or took > 20s)
    setTimeout(() => {
      if (document.getElementById('loading-splash')) {
        console.warn('[Splash] Watchdog triggered after 20s.');
        hideSplash();
      }
    }, 20000);
  })();
</script>
```

with:
```html
<script>
  // Splash Screen Management: Removes splash only when Flutter app element appears
  (function() {
    const splash = document.getElementById('loading-splash');
    if (!splash) return;

    const isReturning = !!localStorage.getItem('gdar_pwa_visited');
    if (!isReturning) {
      localStorage.setItem('gdar_pwa_visited', '1');
    }

    const hideSplash = () => {
      console.log('[Splash] Flutter pane detected, fading out splash...');
      splash.style.transition = isReturning ? 'opacity 0.1s ease-out' : 'opacity 0.2s ease-out';
      splash.style.opacity = '0';
      splash.style.pointerEvents = 'none';
      setTimeout(() => { if (splash.parentNode) splash.remove(); }, isReturning ? 100 : 200);
    };

    // 1. Observe body for flt-glass-pane (Flutter's root element)
    const observer = new MutationObserver((mutations, obs) => {
      if (document.querySelector('flt-glass-pane')) {
        obs.disconnect();
        hideSplash();
      }
    });
    observer.observe(document.body, { childList: true, subtree: true });

    // 2. Watchdog: Safety backup (app crashed or took > 20s)
    setTimeout(() => {
      if (document.getElementById('loading-splash')) {
        console.warn('[Splash] Watchdog triggered after 20s.');
        hideSplash();
      }
    }, 20000);
  })();
</script>
```

Key changes from original:
- `isReturning` reads/sets `gdar_pwa_visited` in localStorage
- `hideSplash` sets `transition` inline (overrides CSS) — 0.1s for returning, 0.2s for first visit
- Removed the `setTimeout(hideSplash, 100)` wrapper — no pre-hide delay
- `splash.remove()` timeout: 100ms or 200ms (down from 600ms)

- [ ] **Step 3: Verify first-visit behaviour**

Open DevTools → Application → Local Storage → clear `gdar_pwa_visited`. Hard-reload. Confirm:
- Progress bar sweeps for the full init duration
- Splash fades in ~200ms once Flutter paints
- No snap or flicker when Flutter SplashScreen appears

- [ ] **Step 4: Verify returning-visit behaviour**

With `gdar_pwa_visited` set in localStorage, hard-reload with network throttling off. Confirm:
- Splash disappears in ~100ms (near-instant)
- No white flash, no frozen frame

- [ ] **Step 5: Commit**

```bash
git add apps/gdar_web/web/index.html
git commit -m "fix(web): tighten splash fade timing and fast-path returning users"
```
