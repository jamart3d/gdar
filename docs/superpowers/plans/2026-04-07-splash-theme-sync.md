# Splash Theme Sync Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Eliminate the Shakedown title color flash and background color jump when the HTML pre-Flutter splash transitions to the Flutter SplashScreen.

**Architecture:** A single synchronous inline `<script>` block in `<head>` reads three `flutter.*` localStorage keys, resolves the correct primary and background colors, and overrides CSS custom properties on the root element before the splash div is painted. CSS rules are updated to consume these vars instead of hardcoded hex values.

**Tech Stack:** Vanilla JS, CSS custom properties, `localStorage`, `window.matchMedia`

**Spec:** `docs/superpowers/specs/2026-04-07-splash-theme-sync-design.md`

---

## Files

| File | Change |
|------|--------|
| `apps/gdar_web/web/index.html` | Add `--splash-primary` CSS var; wire `#splash-title` and `#splash-progress-fill` to it; add inline JS color-resolver in `<head>` |

---

### Task 1: Wire CSS to use `--splash-primary` variable

**Files:**
- Modify: `apps/gdar_web/web/index.html` (the `<style>` block in `<head>`)

- [ ] **Step 1: Add `--splash-primary` to the `:root` defaults and light-mode media query**

In the existing `<style>` block, update `:root` and the `@media` block:

```css
:root {
  --splash-bg: #080808;
  --splash-primary: #00E676;
  --splash-text: #333;
}
@media (prefers-color-scheme: light) {
  :root {
    --splash-bg: #f5f5f5;
    --splash-primary: #5C6BC0;
    --splash-text: #888;
  }
}
```

- [ ] **Step 2: Update `body` background to use the var**

Change:
```css
body {
  background-color: #080808;
  margin: 0;
  padding: 0;
}
```
To:
```css
body {
  background-color: var(--splash-bg);
  margin: 0;
  padding: 0;
}
```

- [ ] **Step 3: Update `#splash-title` color to use the var**

Change:
```css
#splash-title {
  font-family: 'RockSalt', cursive;
  font-weight: 400;
  font-size: 24px;
  letter-spacing: 1.2px;
  line-height: 1.4;
  color: #00E676; /* default sophisticate palette primary — alternate palette users see brief mismatch */
  text-align: center;
  margin-bottom: 8px;
}
```
To:
```css
#splash-title {
  font-family: 'RockSalt', cursive;
  font-weight: 400;
  font-size: 24px;
  letter-spacing: 1.2px;
  line-height: 1.4;
  color: var(--splash-primary);
  text-align: center;
  margin-bottom: 8px;
}
```

- [ ] **Step 4: Update `#splash-progress-fill` background to use the var**

Change:
```css
#splash-progress-fill {
  height: 100%;
  width: 40%;
  background: #00E676;
  border-radius: 3px;
  animation: splash-sweep 1.6s ease-in-out infinite;
}
```
To:
```css
#splash-progress-fill {
  height: 100%;
  width: 40%;
  background: var(--splash-primary);
  border-radius: 3px;
  animation: splash-sweep 1.6s ease-in-out infinite;
}
```

- [ ] **Step 5: Verify CSS vars render correctly with no JS**

Open `apps/gdar_web/web/index.html` directly in a browser (file://) with DevTools open. Confirm:
- Dark OS: Shakedown title is `#00E676`, background is `#080808`
- Light OS: Shakedown title is `#5C6BC0`, background is `#f5f5f5`

(No JS runs at this point — these are the CSS-only defaults.)

---

### Task 2: Add inline JS color resolver to `<head>`

**Files:**
- Modify: `apps/gdar_web/web/index.html` (add `<script>` block in `<head>`, immediately after the closing `</style>` tag)

- [ ] **Step 1: Add the resolver script**

Insert this block immediately after `</style>` and before `</head>`:

```html
<script>
  // Splash color sync: reads stored Flutter theme prefs from localStorage and
  // overrides CSS vars before the splash div is painted — eliminates color
  // flash on the Shakedown title during the HTML→Flutter transition.
  // Keys use Flutter's web SharedPreferences prefix ("flutter.").
  // Falls back to CSS defaults (sophisticate dark/light) when no prefs stored.
  (function () {
    try {
      var colorOption = parseInt(
        localStorage.getItem('flutter.fruit_color_option_preference') || '0', 10);
      var themeMode = parseInt(
        localStorage.getItem('flutter.theme_mode_preference') || '0', 10);
      var themeStyle = parseInt(
        localStorage.getItem('flutter.theme_style_preference') || '1', 10);

      var prefersDark = window.matchMedia('(prefers-color-scheme: dark)').matches;
      // themeMode: 0=system, 1=light, 2=dark
      var isDark = themeMode === 2 || (themeMode === 0 && prefersDark);
      var idx = Math.min(Math.max(colorOption, 0), 2);

      var primary, bg;
      if (themeStyle !== 1) {
        // Android theme — no per-palette variants
        primary = '#00E676';
        bg = isDark ? '#080808' : '#F5F5F5';
      } else if (isDark) {
        // Fruit dark: sophisticate / minimalist / creative
        var dp = ['#00E676', '#30D158', '#FF375F'];
        var db = ['#0F172A', '#1C1C1E', '#1A1A1A'];
        primary = dp[idx];
        bg = db[idx];
      } else {
        // Fruit light: sophisticate / minimalist / creative
        var lp = ['#5C6BC0', '#34C759', '#FF2D55'];
        var lb = ['#E0E5EC', '#FFFFFF', '#FFF9F9'];
        primary = lp[idx];
        bg = lb[idx];
      }

      var root = document.documentElement;
      root.style.setProperty('--splash-primary', primary);
      root.style.setProperty('--splash-bg', bg);
    } catch (_) {
      // localStorage unavailable — CSS defaults remain active
    }
  })();
</script>
```

- [ ] **Step 2: Verify JS overrides fire before paint**

In Chrome DevTools → Elements → `<html>` element → Styles pane. Confirm `--splash-primary` and `--splash-bg` appear as inline style overrides on the `<html>` element when localStorage has values set.

To set test values in DevTools Console:
```js
localStorage.setItem('flutter.fruit_color_option_preference', '1'); // minimalist
localStorage.setItem('flutter.theme_mode_preference', '2');          // dark
localStorage.setItem('flutter.theme_style_preference', '1');         // fruit
```
Reload. Expected: `--splash-primary: #30D158`, `--splash-bg: #1C1C1E`. Shakedown title and progress bar should be green (`#30D158`), background dark gray (`#1C1C1E`).

- [ ] **Step 3: Test creative dark palette**

```js
localStorage.setItem('flutter.fruit_color_option_preference', '2'); // creative
localStorage.setItem('flutter.theme_mode_preference', '2');          // dark
localStorage.setItem('flutter.theme_style_preference', '1');         // fruit
```
Reload. Expected: `--splash-primary: #FF375F` (pink-red), `--splash-bg: #1A1A1A`.

- [ ] **Step 4: Test sophisticate light palette**

```js
localStorage.setItem('flutter.fruit_color_option_preference', '0'); // sophisticate
localStorage.setItem('flutter.theme_mode_preference', '1');          // light
localStorage.setItem('flutter.theme_style_preference', '1');         // fruit
```
Reload. Expected: `--splash-primary: #5C6BC0` (indigo), `--splash-bg: #E0E5EC`.

- [ ] **Step 5: Test first-visit fallback (no prefs)**

```js
localStorage.removeItem('flutter.fruit_color_option_preference');
localStorage.removeItem('flutter.theme_mode_preference');
localStorage.removeItem('flutter.theme_style_preference');
```
Reload. Expected: JS reads no keys → falls back to CSS defaults. Dark OS: `#00E676` / `#080808`. Light OS: `#5C6BC0` / `#f5f5f5`.

- [ ] **Step 6: Test localStorage-unavailable fallback**

In DevTools Console, override localStorage to throw:
```js
Object.defineProperty(window, 'localStorage', { get() { throw new Error('blocked'); }});
```
Reload. Expected: no JS error in console, CSS defaults apply (no crash from the `catch` block).

---

### Task 3: Commit

- [ ] **Step 1: Verify the full file looks correct**

Confirm `apps/gdar_web/web/index.html`:
- `<style>` block has `--splash-primary` in `:root` and media query
- `body { background-color: var(--splash-bg) }`
- `#splash-title { color: var(--splash-primary) }` (no hardcoded `#00E676`)
- `#splash-progress-fill { background: var(--splash-primary) }` (no hardcoded `#00E676`)
- Resolver `<script>` block present in `<head>`, immediately after `</style>`

- [ ] **Step 2: Commit**

```bash
git add apps/gdar_web/web/index.html
git commit -m "feat(web): sync HTML splash colors to stored theme palette

Reads flutter.* localStorage keys before painting the splash div.
Eliminates Shakedown title color flash and bg jump on HTML→Flutter
transition for all Fruit palettes and dark/light modes.
Falls back to sophisticate defaults on first visit."
```
