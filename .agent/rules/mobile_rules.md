---
trigger: mobile, android, theme, phone, layout
policy_domain: Mobile Platform
---
# Mobile Platform & Theme Directives

### 1. Visuals & Theme
* **Action:** Use Material 3 (Expressive) dynamic color tokens exclusively.
* **Action:** Apply ink ripples on every tappable surface.
* **Constraint:** Never use `BackdropFilter`, horizontal/vertical blurs, or neumorphic shadows on mobile native builds.

### 2. Layout & Interactions
* **Action:** Place all primary interactive controls (Play/Pause, Seek, Skip) within the bottom 40% of screen height for one-handed use.
* **Action:** Implement haptic feedback on every significant interaction: `selectionClick`, `mediumImpact`, or `vibrate`.
* **Action:** Respect `SafeArea` on all edges. Use True Black (`Colors.black`) for OLED backgrounds in dark mode.
* **Constraint:** Never place primary navigation or playback controls in the top half of the screen.
