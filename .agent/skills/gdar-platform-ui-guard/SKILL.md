---
name: gdar-platform-ui-guard
description: Use when editing GDAR UI files where Fruit web, mobile Material, and TV patterns may leak across boundaries; especially during screen/widget refactors, import changes, feature parity work, fruit_audit follow-up, and pre-commit gating checks.
---

# GDAR Platform UI Guard

Enforce UI boundary rules before and after any UI edit.

## Core Rules
- Keep Fruit (web/PWA) UI language isolated from Material 3.
- Never leak Fruit-only components into mobile/TV targets.
- Preserve Fruit structure when glass effects are disabled.
- Use package imports across package boundaries; avoid relative library imports.

## Audit Scope
1. Scan changed files first.
2. If shared UI files changed, include:
   - `packages/shakedown_core/lib/`
   - `apps/gdar_web/lib/`
   - `apps/gdar_mobile/lib/`
   - `apps/gdar_tv/lib/`
3. Check for Fruit symbols (`LiquidGlassWrapper`, `FruitTabBar`, Fruit-only widgets) and verify gating.

## Required Checks
1. Fruit components are only used behind explicit web/Fruit gating.
2. Mobile/TV apps do not directly import Fruit-only web UI.
3. No Material 3 visual language is introduced on Fruit screens.
4. Fallback mode keeps Fruit structure and controls.

## Validation Commands
- `dart run scripts/scan_diffs.dart`
- `dart run scripts/verify.dart`

## Done Checklist
- Fruit-only widgets are gated to web/Fruit contexts.
- Mobile/TV targets import no Fruit-only web UI.
- Fruit fallback preserves Fruit structure (no Material substitution).
- Package imports are used across package boundaries.
- Validation commands pass or failures are reported with file-level fixes.

If a violation is found, stop and propose surgical file-level fixes.
