# Implementation Plan: Rule Consolidation

GDAR has grown into many fragmented rule files in `.agent/rules/`. To improve efficiency and reduce redundant context loading, we will consolidate them into a smaller set of high-impact, theme-based rule files.

## 1. Agent Autonomy & Efficiency
**New File:** `.agent/rules/agent_autonomy.md`
**Source Files:**
- `autonomy_policy.md`
- `efficiency_guardrails.md`

## 2. Monorepo & Maintenance Standards
**New File:** `.agent/rules/monorepo_hygiene.md`
**Source Files:**
- `workspace_hygiene.md`
- `monorepo_builds.md`
- `dependency_hygiene.md`
- `version_sync_guard.md`
- `platform_shell.md`

## 3. Google TV Platform Rules
**New File:** `.agent/rules/tv_platform.md` (Overwriting existing)
**Source Files:**
- `tv_rules.md` (current)
- `tv_focus_stability.md`
- `beat_detection_calibration.md`

## 4. Web & PWA Platform Rules
**New File:** `.agent/rules/web_platform.md`
**Source Files:**
- `pwa_branding_sync.md`
- `localstorage_hygiene.md`
- `wasm_handling.md`
- `performance_mode_gates.md`

## 5. Fruit Theme Rules
**New File:** `.agent/rules/fruit_theme.md`
**Source Files:**
- `fruit_design_system.md`

## 6. Testing & Verification Standards
**New File:** `.agent/rules/testing_standards.md`
**Source Files:**
- `testing_stubs.md`
- `widget_test_surfaces.md`

## 7. Audio Engine & Technical Calibration
**New File:** `.agent/rules/audio_engine.md` (Overwriting existing)
**Source Files:**
- `audio_engine_rules.md` (current)
- `canvas_rendering.md`

## 8. Core Architecture & Mobile
**Revised File:** `.agent/rules/architecture_context.md`
**Merged content:**
- `mobile_rules.md`
- General architecture from root `AGENTS.md` where appropriate.

## Cleanup
Delete the original files after merging and verification.

---
**Approval Needed:** Should I proceed with this consolidation?
