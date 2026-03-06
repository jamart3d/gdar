# myapp Agent Environment & Setup Guide

## Overview
This document outlines the specialized agentic environment used for developing myapp. It describes the `.agent` directory structure, necessary tools for Windows-based development, and the integration of the **Arlo (Antigravity)** agent.

---

## 🏗 The `.agent` Directory
The `.agent` directory is the core of the agentic workflow, containing the specialized configurations, automation scripts, and domain knowledge that power the AI agent.

### 1. Rules (`.agent/rules/`)
These markdown files provide the strict operational boundaries for the agent.
*   **architecture_context.md**: Domain-specific architecture rules.
*   **audio_architecture.md**: Rules for audio engine design.
*   **auto_approve.md**: List of safe, read-only commands for auto-execution.
*   **efficiency_guardrails.md**: Token and quota management rules.
*   **fruit_theme.md**: Rules for the theme styles (if applicable).
*   **Gemini.md**: Primary coding and architecture standards (Clean Architecture).
*   **mobile_rules.md**: Platform-specific rules for mobile.
*   **platform_shell.md**: Environment-specific shell rules (Windows/Linux).
*   **root_hygiene.md**: Rules for maintaining a clean project root.
*   **screensaver.md**: Specific rules for screensaver/animation logic.
*   **testing_stubs.md**: Rules for mocking and test architecture.
*   **tv_rules.md**: Focus management and UI rules for Android TV / Google TV.
*   **web_audio_scheduling.md**: Deep specs for the web audio engine.

### 2. Workflows (`.agent/workflows/`)
Standardized slash commands that trigger complex, multi-step actions.
*   **/audit**: Full quality, design, and conformance check.
*   **/checkup**: Rapid health check, formatting, linting, and tests.
*   **/clean**: Automated project root hygiene and cleanup.
*   **/image_to_code**: UI or asset generation via Stitch MCP.
*   **/issue_report**: Investigation and standardized report generation.
*   **/mock_regen**: Automated regeneration of test stubs/mocks.
*   **/save**: Quick commit and push workflow.
*   **/screenshot_audit**: Context-aware UI audit from screenshots.
*   **/session_debrief**: End-of-day summary and rule refinement.
*   **/verify_settings_defaults**: Pre-release check for premium/experimental flags.

### 3. Skills (`.agent/skills/`)
Specialized toolsets and instructions for complex tasks.
*   **audio_engine_diagnostics**: Debugging tools for hybrid audio engines.
*   **dev_tools**: Utilities for interacting with connected devices.
*   **focus_trap_protection**: Audit for focus-safe TV patterns.
*   **mock_alignment_audit**: UI auditing against provided mocks.
*   **ripple_control**: Detection and management of dependency ripples.
*   **shipit**: Production release and deployment pipeline. (Automatically triggers `session_debrief` upon completion).
*   **size_guard**: CI/CD-style check for bundle size regressions.
*   **test_mocking_templates**: Standardized templates for mocking services.
*   **test_run_guard**: Poll and bail-out logic for background test runners.
*   **web_debug_suite**: Complex web-state and audio debugging tools.

---

## 💻 Platform Development Setup
To ensure the agent can perform efficiently, specific command-line utilities and shell configurations are required based on your operating system.

### 🪟 Windows 10/11 (PowerShell)
The agent relies on high-performance tools and specific PowerShell syntax.
*   **Required CLI Tools**:
    *   **ripgrep (`rg`)**: `choco install ripgrep` or `scoop install ripgrep`.
    *   **fd**: `choco install fd` or `scoop install fd`.
*   **Shell Syntax**: Chained commands MUST use `;` for separation (e.g., `cd path ; ls`). Never use `&&`.
*   **Brain Location**: `%USERPROFILE%\.gemini\antigravity\brain`

### 💻 ChromeOS / Linux (bash)
The agent uses standard Linux utilities and bash syntax.
*   **Required CLI Tools**:
    *   **ripgrep (`rg`)**: `sudo apt install ripgrep`.
    *   **fd-find (`fd`)**: `sudo apt install fd-find`.
*   **Shell Syntax**: Standard `&&` or `;` can be used for chaining.
*   **Brain Location**: `~/.gemini/antigravity/brain`

---

## 🧠 Brain Maintenance & Storage
The agent's local state and artifacts are stored in the user profile directory. Over time, this directory can grow significantly (700MB+) due to session logs and generated assets.

### 1. Monitoring Size
*   **Windows (PowerShell)**:
    ```powershell
    Get-ChildItem -Path "$HOME\.gemini\antigravity\brain" -Recurse | Measure-Object -Property Length -Sum
    ```
*   **ChromeOS/Linux (bash)**:
    ```bash
    du -sh ~/.gemini/antigravity/brain
    ```

### 2. Cleanup Strategy
*   **Manual Purge**: You can safely delete older subdirectories within `brain/` for closed or stale sessions.
*   **Workflow Cleanup**: Use the `@[/clean]` workflow to audit the project root, then manually deep-clean the global brain directory if storage is tight.
*   **OS Temp Directory**: As per `.agent/rules/root_hygiene.md`, **Arlo** stores temporary debug and test files in the OS temp directory (`/tmp/` on Linux/ChromeOS, `%TEMP%` on Windows). You should periodically flush this directory.

---

## 🔌 MCP Servers (Model Context Protocol)
MCP servers provide a standard way for Jules to interact with your local environment and external APIs.
*   **dart-mcp-server**: Connects Jules to the Dart Tooling Daemon (DTD). Provides:
    *   Interactive `hot_reload` and `hot_restart`.
    *   Live Widget Tree inspection and selection.
    *   Static analysis and `dart fix` automation.
*   **StitchMCP**: High-level UI understanding and generation.
    *   Used for generating Flutter code from prompts or screenshots.
    *   Used for pixel-perfect UI audits against mocks.
*   **github-mcp-server**: Direct repository management.
    *   Automating commits, PR creation, and issue tracking.

---

## 🤖 Working with Arlo (Antigravity)
**Arlo** is your local pair-programming persona, powered by the **Antigravity** agent engine and Gemini.

### Naming Convention Logic
While the underlying technology is **Antigravity**, assigning a personal name like **Arlo** helps maintain a consistent, human-centric pair-programming experience across different models and sessions. This "naming login" ensures that regardless of which Gemini model is active, the agent maintains its role as a dedicated collaborator for **myapp**.

> [!NOTE]
> **Antigravity vs. Jules**: 
> *   **Antigravity** is the local AI assistant (me) performing your terminal commands, edits, and local checkups.
> *   **Jules** (`jules.google.com`) is the external high-performance auditing platform used for cloud-based system checks and stress testing.

### Best Practices for Interaction:
1.  **Workflow First**: Instead of asking Arlo to "clean up the project," use the command `/clean`. This ensures the agent follows the pre-defined, safe procedure.
2.  **Contextual Awareness**: Arlo has access to `lib/`, `test/`, and `.agent/specs/`. When starting a feature, refer specifically to a spec file in `.agent/specs/` to ensure architectural alignment.
3.  **Turbo Execution**: Steps in workflows marked with `// turbo` can be executed automatically by Arlo (if configured with `SafeToAutoRun: true`). This accelerates routine tasks like formatting and linting.
4.  **Verification**: Always ask Arlo to run `/checkup` after a significant refactor to ensure no regressions were introduced.

### Arlo's Execution & Guardrails
To prevent accidental breakages, Arlo operates under strict quota and execution guardrails (`.agent/rules/efficiency_guardrails.md`). 
*   **The "Stop and Ask" Rule**: Arlo is forbidden from executing destructive file modifications, writing code, or running broad terminal commands without explicit user approval first.
*   **The Auto-Approve Allowlist**: To keep the workflow fast, Arlo is permitted to bypass the "Stop and Ask" rule *only* for commands explicitly listed in `.agent/rules/auto_approve.md`. This list consists of safe, read-only commands which run silently in the background (`SafeToAutoRun: true`).
    *   *Note on Platforms*: Arlo uses context-aware syntax depending on the host OS. On **Windows 10/11**, the following PowerShell commands are explicitly allowed:
        *   **File Reads**: `Get-Content`, `Get-Item`, `Get-ChildItem` (ls/dir), `Test-Path`, `Select-String`, `Get-Location` (pwd), `Measure-Object`.
        *   **Git State**: `git status`, `git log`, `git diff`, `git branch`, `git rev-parse HEAD`.
        *   **Tooling**: `flutter analyze`, `dart analyze`, `flutter format .`, `flutter --version`, `where.exe`.
        *   (For **ChromeOS/Linux**, standard bash equivalents like `cat`, `ls`, and `grep` are substituted).
*   **Cross-Platform Shell Mastery**: Arlo uses the `.agent/skills/cross_platform_shell` skill to intelligently switch between OS paradigms:
    *   **Command Chaining**: Semicolons (`;`) for PowerShell vs. `&&` for Bash.
    *   **Pipe Workarounds**: PowerShell pipes (`|`) can be brittle in automated wrappers. On Windows, Arlo avoids long piped commands by writing output out to `%TEMP%` and reading it sequentially, bypassing environment restrictions.

---

## 🌓 The Verification Stack: Tests vs. Audits
To maintain a high-performance codebase like **myapp**, we use a two-tiered verification system. Understanding the distinction between **Arlo's local tests** and **Jules's cloud audits** is critical.

### 1. Deterministic Tests (Code-Based)
*   **Primary Execution**: **Arlo** (Local Antigravity Agent) via `@[/checkup]` or `flutter test`.
*   **High-Volume Execution**: **Jules** (External Cloud Platform) via the CLI + Auth Token.
*   **Location**: `/test/`
*   **The "Why"**: These are for binary, deterministic logic. If a function returns `X` but expected `Y`, it fails. This is the first line of defense against logic, syntax, and structural regressions. **Jules is preferred for high-volume or final CI-style runs** as it offers a more stable and high-performance execution environment than local machines.

### 2. Cognitive Audits (Prompt-Based)
*   **Agent**: **Jules** (External Cloud Platform at `jules.google.com`)
*   **Stored in**: `test/prompts/`
*   **Execution**: Via Jules Web UI or CLI using the markdown prompt files.
*   **The "Why"**: Standard tests struggle to audit **"The Feel"**. Jules uses cognitive vision and deep logs to detect:
    *   **Perceptual Jitter**: Audio gapless-ness during CPU stress (Phase 1 of Master Audit).
    *   **Aesthetic Leaks**: Detecting Material Ripples in Fruit-style widgets.
    *   **Interaction Flow**: Verifying complex TV focus transitions across panes.
    *   **Flaky Test Mitigation**: Used as an escape hatch to convert timing-sensitive, flaky widget tests into reliable E2E observation phases.

---

## ⚡ High-Performance Auditing: Jules
The following specialized prompts (located in `test/prompts/`) are submitted to the Jules platform:

*   **master_audit.md**: The **Final "Green Light"**. A 7-phase run covering Audio stress, UI leaks, Focus flow, Persistence, and Architecture guards.
*   **jules_audit.md**: Targets the high-performance Web Audio engine (e.g., the "99% Seek" gauntlet).
*   **jules_fruit_audit.md**: Audits "Apple-kosher" feel, 14px radii, and the exclusion of M3 leaks.
*   **jules_integrity_audit.md**: Stress-tests Hive persistence and state restoration after hard refreshes.
*   **jules_platform_guard_audit.md**: Codestyle-level scans ensuring platform-specific logic stays in its "Walled Garden."

### Jules Workflow & Efficiency
1.  **Arlo Prep**: Run `@[/checkup]` to clear local lints/tests.
2.  **Jules Config**: Ensure your repo is configured & indexed at `jules.google.com` or via the CLI.
3.  **Submit Verification Task**: 
    You can submit prompts directly via the **Web UI**, or efficiently pipe them via the **CLI** from the project root.
    
    *   **Option A: Web UI (jules.google.com)**
        Copy and paste the following into the prompt box:
        > "Perform the **Master Release Audit** (`test/prompts/master_audit.md`) and report PASS/FAIL."

    *   **Option B: CLI via Windows (PowerShell)**: 
        ```powershell
        Get-Content .\test\prompts\master_audit.md | jules new
        ```
        
    *   **Option C: CLI via ChromeOS (Linux/bash)**: 
        ```bash
        cat test/prompts/master_audit.md | jules new
        ```
        
    *   **For Running Deterministic Tests (Any Interface)**: 
        > "Run the `flutter test` suite and report any failures."
        *(Via CLI: `jules new "Run the flutter test suite and report any failures."`)*

4.  **Feedback Loop**: Bring logs back to Arlo for implementation work.

> [!TIP]
> **Jules Token Efficiency**: Providing an **Auth Token** (via CLI, Web interface, or environment configuration) is the high-performance path for all auditing. It is significantly more efficient for managing high-frequency concurrent audits and is required for the "Headless Chrome" stress-tests defined in the Master Audit.

---

## 📅 Maintenance
The agent environment is self-documenting. Use `@[/session_debrief]` at the end of a workday or after a significant milestone to have Arlo analyze the day's progress and suggest updates to the rules or skills based on new patterns discovered. Note that **session_debrief** is a mandatory post-completion step for the **shipit** workflow to ensure all release-related knowledge is captured.

> [!NOTE]
> If you need to re-verify the structure of the `.agent/` directories or ensure static configs like `.editorconfig` are present, you can run the Python script `tools/env_doctor.py --check`. This is a read-only script that verifies the presence of required agent specs, skills, and documentation.

