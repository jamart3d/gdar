---
trigger: tv, screensaver, focus
policy_domain: TV Screensaver
---
# TV Screensaver Directives

### Implementation
* **Action:** Always read `.agent/specs/tv_screensaver_spec.md` before touching screensaver code.
* **Constraint:** Never implement screensaver logic on mobile or web. TV exclusivity is absolute.
* **Constraint:** Never add haptic feedback anywhere in the screensaver flow.
