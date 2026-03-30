# Audit: Overlap between AGENTS.md and GEMINI.md

This audit identifies redundant and complementary mandates between the primary identity and rules documents in the GDAR monorepo.

## 1. Identical Mandates (Redundant for Safety)
The following rules are duplicated across both documents to ensure compliance regardless of which context is triggered:
- **The Fruit Boundary**: "No Material 3 widgets, ripples, or FAB patterns on Fruit screens."
- **Performance Efficiency**: "Strict use of `const` constructors everywhere possible."
- **Code Style**: Adherence to the official Dart style guide and `flutter format`.
- **Tooling**: Melos is the entry point for `analyze`, `test`, and `format`.

## 2. Complementary Contexts
| Feature | AGENTS.md Context | GEMINI.md Context |
| :--- | :--- | :--- |
| **Architecture** | Focuses on monorepo layout (`apps/` vs `packages/`). | Focuses on layer separation (UI/Logic/Data). |
| **Provider** | Lists it as a key package dependency. | Mandates it as the primary state management solution. |
| **Platforms** | Defines the "UI Platform Contract" and dual-pane TV. | Defines the "Design System" and target-specific themes. |

## 3. Unique Mandates
### Unique to AGENTS.md (Agent Protocols)
- **Session Indexing**: Mandatory `ls -R` on first turn.
- **Fail-Fast Protocols**: Immediate self-correction over explanatory analogies.
- **Large Data Threading**: The 8MB JSON parsing must use `compute()`.
- **Infrastructure Safety**: Reserved `.agent/appdata` mapping.

### Unique to GEMINI.md (Release Management)
- **CHANGELOG Strategy**: Keep a Changelog format and stage notes in `pending_release.md`.
- **Play Store Prepend Rule**: Prepending new release blocks to `docs/PLAY_STORE_RELEASE.txt`.
- **Workflow Triggers**: Discrete steps for `/shipit`, `/verify`, and `/prod`.
- **Verification Status**: Recording commit SHAs in `verification_status.json` for smart-skipping.
