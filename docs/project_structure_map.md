<!-- Path: docs/project_structure_map.md -->
# GDAR Project Structure & Directory Map

## 1. Human-Facing Docs (`docs/`)
* `docs/guide.md` — Development guide & quick start.
* `docs/dev_environment.md` — Windows/ChromeOS setup & gotchas.
* `docs/data_schema.md` — `output.optimized_src.json` structure.
* `docs/agents.md` — Agent persona & goals.
* `docs/project_structure_map.md` — This file.

## 2. Agent Specs (`.agent/specs/`)
Technical blueprints read on-demand by the agent:
* `android_theme_spec.md`, `fruit_theme_spec.md`
* `native_audio_spec.md`, `web_ui_audio_engines.md`
* `phone_ui_design_spec.md`, `phone_ui_flow_spec.md`
* `tv_ui_design_spec.md`, `tv_ui_flow_spec.md`, `tv_screensaver_spec.md`
* `web_ui_design_spec.md`

## 3. Agent Rules (`.agent/rules/`)
Always-loaded + trigger-based behavioral guardrails:
* `gemini.md` — Global coding & design standards.
* `architecture_context.md` — Domain constraints (audio, game, async).
* `efficiency_guardrails.md` — Quota & safety rules.
* `screensaver.md`, `android_theme.md`, `fruit_theme.md` — Theme guards.
* `phone_platform.md`, `tv_ui_flow.md` — Platform-specific guards.
* `native_audio.md`, `web_audio.md` — Audio engine guards.

## 4. Agent Workflows (`.agent/workflows/`)
Slash-command automation:
`/checkup` (Local Sanity), `/save`, `/fruit_audit`, `/audit`,
`/issue_report`, `/screenshot_audit`, `/mock_regen`, `/image_to_code`, `/session_debrief`.

## 5. Agent Skills (`.agent/skills/`)
* `shipit/` — Autonomous release pipeline (version, build, deploy).
* `test_run_guard/` — Safety logic for background test runners.
* `test_mocking_templates/` — Mockito stubs & MultiProvider setup.
* `web_debug_suite/` — Web audio engine debug tools.
* `dev_tools/` — ADB wrappers for screenshots and logs.
* `ripple_control/` — Dependency ripple detection.

## 6. Static Configs (root + `.vscode/`)
* `.editorconfig`, `.gitattributes` — Cross-platform formatting.
* `.vscode/launch.json`, `.vscode/settings.json` — Editor config.

## 7. Root Files
* `todo.md` — Active task list.
* `CHANGELOG.md` — Project history (Keep a Changelog format).
* `pubspec.yaml` — Flutter project definition.

---
*Last Updated: 2026-03-04*
