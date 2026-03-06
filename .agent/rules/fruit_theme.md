---
trigger: web, fruit, glass, theme
policy_domain: Web / Fruit Theme
---
# Fruit Theme Directives

### Visuals & Motion
* **Action:** Use BackdropFilter sigma 15.0+ on all glass surfaces. Focus on "Vapor" transitions using ShaderMask.
* **Action:** Use Lucide Icons exclusively. Typography: Inter variable font only.
* **Action:** Use spring physics for all transitions — no MD ripples.
* **Constraint:** Never apply Fruit theme to mobile or TV. Web and PWA only.
* **Constraint:** **No Dynamic Tinting.** Strictly disable show-based background overrides; use the curated Slate/White/Charcoal base only.
* **Constraint:** **Borderless Glass.** Set `showBorder: false` on all Fruit glass components to ensure visual melt.
