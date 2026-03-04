---
trigger: tv, flow, navigation, focus
policy_domain: TV Navigation
---
# TV UI Flow Directives

### Focus & Navigation
* **Action:** Wrap every interactive TV element in TvFocusWrapper (1.05x scale + glow border).
* **Action:** Dim inactive panes to 0.2 opacity.
* **Action:** Use Duration.zero for all TV transitions — instant only.
* **Constraint:** Never use haptic feedback on TV builds. Focus is purely visual.
* **Constraint:** Never use organic ripples or spring animations on TV.
