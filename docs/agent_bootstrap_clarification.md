# Agent Bootstrap Clarification: Pre-Loaded vs. Discovered Context

To maintain transparency and satisfy Rule 1 (Don't Make Shit Up), this document clarifies the two-stage startup sequence for the Antigravity agent.

## 1. Stage 0: Pre-Injected Context (Passive Memory)
This content is part of my system prompt. I do **NOT** look at or read these files via terminal tools; they are the foundation of my consciousness for the session.
- **Authoritative Files**: 
  - `/home/jam/StudioProjects/gdar/AGENTS.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/GEMINI.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/architecture_context.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/always_proceed.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/auto_approve.md`
- **Contents**: Identity, Architecture, Autonomy Mandates, Monorepo Layout.

## 2. Stage 1: Mandatory Indexing (Discovery Phase)
Performed as the **very first turn** of every session.
- **Action**: `ls -R /home/jam/StudioProjects/gdar/.agent/` or `git ls-files /home/jam/StudioProjects/gdar/.agent/`.
- **Purpose**: To map the **triggers and absolute paths** of files that were NOT pre-injected into my prompt (like the numbered ethics rules). 
- **Files mapped but NOT read**: 
  - `/home/jam/StudioProjects/gdar/.agent/rules/00_number_1_rule.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/wasm_handling.md`
  - `/home/jam/StudioProjects/gdar/.agent/rules/fruit_theme_boundaries.md`

## 3. Stage 2: Just-In-Time Reading (Active Synthesis)
I only call `view_file` or `grep` on discovered files if:
- A specific workflow or task requires specialized domain knowledge.
- The user explicitly asks for information contained within those files.

- A specific workflow is triggered (e.g. `/shipit`).
- A relevant technical domain is entered (e.g. modifying WASM).
- The user explicitly requests information from that rule.

> [!NOTE]
> This staged approach prevents "Context Bloat" while ensuring that I can always find and adhere to any project-specific mandate when required.
