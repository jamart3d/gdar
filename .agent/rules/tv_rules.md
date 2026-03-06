---
trigger: tv, screensaver, focus, flow, navigation
policy_domain: TV Platform
---
# TV Platform & UI Flow Directives

### 1. Focus & Navigation
* **Action:** Wrap every interactive TV element in `TvFocusWrapper` (1.05x scale + glow border).
* **Action:** Dim inactive panes or background elements to 0.2 opacity when focus is elsewhere.
* **Action:** Use optimized, minimal durations (e.g., <100ms) for transitions to ensure a premium feel without lag.
* **Constraint:** Never use tactile/haptic feedback on TV builds. Focus is purely visual.
* **Constraint:** Never use organic ripples or spring animations on TV; stick to direct linear or fast-out/slow-in transforms.

### 2. Optimization [CRITICAL]
* **Action:** Use a **Rasterized Glyph Cache** (`Map<String, ui.Image>`) for `StealBanner` neon glow effects. Rasterize glyph blurs to off-screen surfaces once to prevent GPU thrashing.

### 3. Screensaver
* **Action:** Always consult `.agent/specs/tv_screensaver_spec.md` before modifying screensaver logic.
* **Constraint:** TV exclusivity is absolute. Never implement screensaver triggers on mobile or web.
