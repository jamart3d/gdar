# Identity & Architecture Data Sources

This document defines the authoritative files used to establish the Antigravity agent's identity and architectural understanding at session launch.

## 1. Identity Source: AGENTS.md
The primary persona and monorepo coordinator file.
- **Persona**: Antigravity, Senior Flutter / Expert Architect.
- **Workspace Logic**: Monorepo layout (`apps/`, `packages/`) and path conventions.
- **Command Set**: Primary Melos orchestration triggers.
- **Data Guard**: Isolate-based threading rules for large JSON files.

## 2. Architecture Context Source: .agent/rules/architecture_context.md
The primary source for internal system resolution and technical gating.
- **Core Providers**: Mandates for `SettingsProvider`, `AudioProvider`, and `ThemeProvider`.
- **Platform Resolution**: Mapping the "Resolved Engine Mode" (`auto` vs. `standard`).
- **Visual Gating**: "True Black" depth rules and Fruit theme boundary constraints.

## 3. Standards Enforcement: .agent/rules/GEMINI.md
The primary source for project-wide coding and engineering standards.
- **Stack Definition**: Flutter/Dart Stable, sound null safety, Proactive deprecation resolution.
- **Layering**: UI (Widgets) -> Logic (Provider) -> Data (Repository).
- **Verification Suite**: Pre-release preflight suite requirements.
