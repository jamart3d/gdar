# myapp Agent Environment & Setup Guide

## Overview
This document outlines the specialized agentic environment used for developing myapp. It describes the `.agent` directory structure, necessary tools for Windows, Linux, and Chromebook-based development, and the integration of the **Arlo (Antigravity)** agent.

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
*   **fruit_theme_boundaries.md**: Rules for ensuring theme isolation.
*   **Gemini.md**: Primary coding and architecture standards (Clean Architecture).
*   **mobile_rules.md**: Platform-specific rules for mobile.
*   **platform_shell.md**: Environment-specific shell rules (Windows/Linux).
*   **root_hygiene.md**: Rules for maintaining a clean project root.
*   **screensaver.md**: Specific rules for screensaver/animation logic.
*   **testing_stubs.md**: Rules for mocking and test architecture.
*   **tv_focus_stability.md**: Advanced focus management rules for TV.
*   **tv_rules.md**: Focus management and UI rules for Android TV / Google TV.
*   **web_audio_scheduling.md**: Deep specs for the web audio engine.

### 2. Workflows (`.agent/workflows/`)
Standardized slash commands that trigger complex, multi-step actions.
*   **/audit**: Full quality, design, and conformance check.
*   **/checkup**: Rapid health check, formatting, linting, and tests.
*   **/clean**: Automated project root hygiene and cleanup.
*   **/fruit_audit**: Scans UI for correct theme gating.
*   **/image_to_code**: UI or asset generation via Stitch MCP.
*   **/issue_report**: Investigation and standardized report generation.
*   **/jules**: Formalized handoff to Jules for full verification.
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

### 4. Specs (`.agent/specs/`)
Detailed architectural and design specifications that define the "Single Source of Truth" for the project.
*   **android_theme_spec.md**: Specifications for the Android system theme.
*   **fruit_theme_spec.md**: Deep design specifications for the "Fruit" aesthetic.
*   **native_audio_spec.md**: Specs for the high-performance native audio engines.
*   **phone_ui_design_spec.md**: Visual guidelines for the mobile interface.
*   **phone_ui_flow_spec.md**: Interaction flow and navigation logic for mobile.
*   **tv_screensaver_spec.md**: Specialized specs for the TV screensaver engine.
*   **tv_ui_design_spec.md**: Visual guidelines for the 10ft TV interface.
*   **tv_ui_flow_spec.md**: Interaction flow and focus logic for Android TV.
*   **web_ui_audio_engines.md**: Matrix of audio engine behaviors (Web Audio vs. HTML5).
*   **web_ui_design_spec.md**: Visual guidelines for the web/PWA interface.

---

## 💻 Platform Development Setup
To ensure the agent can perform efficiently, specific command-line utilities and shell configurations are required based on your operating system.

### 🪟 Windows 10/11 (PowerShell)
The agent relies on high-performance tools and specific PowerShell syntax.
*   **Required CLI Tools**:
    *   **ripgrep (`rg`)**: `choco install ripgrep` or `scoop install ripgrep`.
    *   **fd**: `choco install fd` or `scoop install fd`.
    *   **jq**: `choco install jq` or `scoop install jq`.
    *   **fzf**: `choco install fzf` or `scoop install fzf`.
    *   **bat**: `choco install bat` or `scoop install bat`.
*   **Shell Syntax**: Chained commands MUST use `;` for separation (e.g., `cd path ; ls`). Never use `&&`.
*   **Brain Location**: `%USERPROFILE%\.gemini\antigravity\brain`

### 💻 ChromeOS / Linux (bash)
The agent uses standard Linux utilities and bash syntax.
*   **Required CLI Tools**:
    *   **ripgrep (`rg`)**: `sudo apt install ripgrep`.
    *   **fd-find (`fdfind`)**: `sudo apt install fd-find`. 
        *   *(Tip: Add `alias fd='fdfind'` to your `.bashrc` or `.zshrc` for speed).*
    *   **jq**: `sudo apt install jq` (High-performance JSON processor).
    *   **fzf**: `sudo apt install fzf` (Fuzzy finder for files and history).
    *   **bat**: `sudo apt install bat` (Syntax-highlighted `cat`).
        *   *(Tip: Add `alias bat='batcat'` to your `.bashrc` for speed).*
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
    > [!WARNING]
    > **Storage Ballooning**: On Windows, the brain directory has been observed to balloon significantly (700MB+). Routine inspection is required to prevent storage exhaustion.
*   **ChromeOS/Linux (bash)**:
    ```bash
    du -sh ~/.gemini/antigravity/brain
    ```
    > [!NOTE]
    > While storage ballooning is confirmed on Windows, similar investigative monitoring is required on ChromeOS/Linux to see if those environments experience the same growth pattern.

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

## 🚀 Development Execution & Device Setup
To run and debug **myapp** across its primary targets, use the following specialized execution flows and ADB configurations.

### 1. Web & PWA (Chrome)
For the most accurate "Fruit" theme and Liquid Glass testing, use the Chrome device target:
*   **Command**: `flutter run -d chrome`
*   **Requirements**: 
    *   Chrome browser installed.
    *   `flutter config --enable-web` must be active.

### 2. Windows 10/11 (Android Emulator)
When debugging the Material 3 Expressive UI or TV dual-pane layouts on a Windows host:
*   **Command**: `flutter run` (selecting the emulator from the list or specifying `-d <device_id>`).
*   **ADB Setup**: 
    *   Ensure `platform-tools` is in your Windows `%PATH%`.
    *   Emulator must have **Developer Options** and **USB Debugging** enabled.
    *   **Tip**: Use `adb devices` in PowerShell to verify the tether before running.

### 3. ChromeOS / Linux (WiFi ADB)
For high-performance testing on Chromebooks or remote development:
*   **Command**: `flutter run -d <ip_address>:5555`
*   **Helper Scripts**: Use the following scripts in `~/bin/` to automate the tether:
    *   `phone_pair`: Initial pairing and setup (automates `adb tcpip`).
        ```bash
        #!/bin/bash
        # 1. Look for the Android Pairing service
        echo "Searching for Android Pairing service (ensure 'Pair device with pairing code' is open)..."
        LINE=$(avahi-browse -rtp _adb-tls-pairing._tcp | grep "^=" | grep "IPv4" | head -n 1)

        if [ -z "$LINE" ]; then
            echo "ERROR: Pairing service not found."
            echo "Make sure you are on the 'Pair device with pairing code' screen on your phone."
            exit 1
        fi

        # 2. Extract IP and Port
        IP=$(echo "$LINE" | cut -d';' -f8)
        PORT=$(echo "$LINE" | cut -d';' -f9)
        echo "Found Pairing Service at $IP:$PORT"

        # 3. Ask for the code
        read -p "Enter the 6-digit pairing code: " CODE

        # 4. Execute pair
        /home/jam/Android/Sdk/platform-tools/adb pair "$IP:$PORT" "$CODE"
        ```
    *   `phone_soft`: Re-connects to a soft-rebooted or disconnected device via WiFi.
        ```bash
        #!/bin/bash
        # Soft reset: only drops current connections instead of killing the whole server
        /home/jam/Android/Sdk/platform-tools/adb disconnect 

        # Search for the Android 16 mDNS broadcast
        LINE=$(avahi-browse -rtp _adb-tls-connect._tcp | grep "^=")

        if [ -z "$LINE" ]; then
            echo "Phone not found. Is Wireless Debugging ON?"
        else
            IP=$(echo "$LINE" | cut -d';' -f8)
            PORT=$(echo "$LINE" | cut -d';' -f9)
            echo "Syncing with Android 16 at $IP:$PORT"
            /home/jam/Android/Sdk/platform-tools/adb connect "$IP:$PORT"
        fi
        ```
*   **ADB WiFi Configuration (Modern/Pairing)**:
    1.  Enable **Developer Options** and **Wireless Debugging** on the target Android device.
    2.  Open the **"Pair device with pairing code"** screen on the phone to broadcast the `_adb-tls-pairing._tcp` service.
    3.  Run the helper script: `~/bin/phone_pair`.
    4.  Enter the 6-digit pairing code when prompted. The script uses `avahi-browse` to auto-detect the IP/Port and executes `adb pair`.
    5.  Once paired, use `~/bin/phone_soft` to complete the connection (or `adb connect <device_ip>:5555`).
*   **Requirements**: 
    *   Linux development environment (Crostini) enabled.
    *   `android-sdk-platform-tools` installed.
    *   `avahi-utils` installed (for `avahi-browse` service discovery).

---

## 🧠 How Arlo Processes Context
To maintain architectural alignment and project state, **Arlo** (Antigravity) performs a multi-layered analysis of the environment during every interaction.

### 1. Automatic Context (Injected Every Prompt)
With every message, the following is automatically provided to the agent:
*   **Active Document**: The file currently focused in the editor, including the exact cursor position.
*   **Open Tabs**: A list of other files currently open in the IDE.
*   **Core Rules**: The contents of `.agent/rules/` (specifically `Gemini.md`, `architecture_context.md`, and `efficiency_guardrails.md`).

### 2. Proactive Discovery (Task-Start Analysis)
At the beginning of a new task or conversation, Arlo proactively "pulls" information from:
*   **Project Root (`/`)**: A directory listing to understand high-level structure.
*   **Agent Directory (`.agent/`)**:
    *   `rules/` & `specs/`: Checked for domain-specific constraints (e.g., `audio_architecture.md`).
    *   `workflows/`: Consulted when a slash command (e.g., `/audit`) is triggered.
*   **Project Manifests**: 
    *   `pubspec.yaml`: To confirm Flutter/Dart versions and active dependencies.
    *   `CHANGELOG.md`: To review the recent history of changes and versioning.

### 3. Persistent Knowledge (Long-term Memory)
*   **Knowledge Items (KIs)**: Distilled summaries of past architectural decisions and patterns are reviewed at the start of every session to ensure consistency without "re-learning" the codebase.

### 4. Selective Research (On-Demand)
To conserve token quota, Arlo does **not** perform broad scans of the entire `lib/` or `test/` tree unless specifically searching for a symbol or verifying a cross-file "ripple" effect.

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
2.  **Contextual Awareness**: Arlo has access to `lib/`, `test/`, and the entire `.agent/` directory. For specialized logic, Arlo also consults the following:
    *   **`docs/`**: Consulted *on-demand* when researching specific features (e.g., `TV_DISPLAY_PATTERNS.md` or `SCREENSAVER_MANUAL.md`). These are considered the project's extended manual.
    *   **`reports/`**: Consulted *after* automated workflows (like `/audit` or `/checkup`) or during deep debugging to review historical logs and analysis results.
3.  **Turbo Execution**: Steps in workflows marked with `// turbo` can be executed automatically by Arlo (if configured with `SafeToAutoRun: true`). This accelerates routine tasks like formatting and linting.
4.  **Verification**: Always run `/checkup` for a rapid local sanity check. For **significant refactors**, follow it up with a full **Jules Audit** to ensure comprehensive regression coverage.

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
*   **The "Why"**: These are for binary, deterministic logic. If a function returns `X` but expected `Y`, it fails. This is the first line of defense against logic, syntax, and structural regressions. **Jules is REQUIRED for high-volume or full suites (> 5 files)** to protect Arlo's token quota and context stability.

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

## 📸 Screenshot & Deep Link Testing
Use these ADB shell commands for capturing UI state and testing intent-based features.

### 1. Capturing Screenshots
To capture a high-quality screenshot from a connected device/emulator:
*   **Capture**: `adb shell screencap -p /sdcard/screen.png`
*   **Pull to Host**: `adb pull /sdcard/screen.png .`
*   **Cleanup**: `adb shell rm /sdcard/screen.png`

### 2. Testing Deep Links
The application uses a custom URI scheme (e.g., `myapp://`). You can trigger specific routes or actions via ADB:
*   **Command**: 
    ```bash
    adb shell am start -a android.intent.action.VIEW \
        -c android.intent.category.BROWSABLE \
        -d "myapp://path/to/action" \
        com.user.myapp
    ```

### 3. Testing Media Search (Assistant/Gemini)
To simulate a "Play [X] on MyApp" voice command:
*   **Command**:
    ```bash
    adb shell am start -a android.media.action.MEDIA_PLAY_FROM_SEARCH \
        -e query "ARTIST OR SONG" \
        com.user.myapp
    ```

### 4. Automated Python Utilities
You can automate complex UI verification (like font rendering or static screen grabs) by combining ADB shell commands and Deep Links in Python. 

*   **Helper Scripts**: See `tools/` for automated verification utilities (e.g., `verify_fonts.py`).

---

## 📅 Maintenance
The agent environment is self-documenting. Use `@[/session_debrief]` at the end of a workday or after a significant milestone to have Arlo analyze the day's progress and suggest updates to the rules or skills based on new patterns discovered. Note that **session_debrief** is a mandatory post-completion step for the **shipit** workflow to ensure all release-related knowledge is captured.



