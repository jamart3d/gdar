---
trigger: mobile, android, phone, theme, layout
policy_domain: Mobile Platform
---
# Mobile Platform & Theme Directives

### 1. Visuals & Theme
* **Action:** Use Material 3 Expressive dynamic color tokens exclusively.
* **Action:** Apply ink ripples on every tappable surface.
* **Constraint:** Never use `BackdropFilter`, blurs, or neumorphic shadows on mobile. Use True Black for OLED backgrounds where applicable.

### 2. Layout & Hardware
* **Action:** Place all primary interactive controls within the bottom 40% of screen height.
* **Action:** Implement haptic feedback on every interaction: `selectionClick` / `mediumImpact` / `vibrate`.
* **Action:** Respect `SafeArea` on all edges.
* **Constraint:** Never place primary controls in the top half of the screen.
