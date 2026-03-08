# 🛰 ANTIGRAVITY_SETUP (v1.20.4)

This document is the Atomic Source of Truth for the **gdar** (shakedown) project. It defines the specialized environment, architectural standards, and deep technical pipelines required for high-performance development.

---

## 🏗 The `.agent/` Directory Structure
The `.agent` directory contains the specialized configurations, automation scripts, and domain knowledge that power the AI agent.

### 1. Rules (`.agent/rules/`)
*   **architecture_context.md**: Domain-specific architecture rules (Flame, Audio, Routing).
*   **audio_architecture.md**: Rules for audio engine design.
*   **auto_approve.md**: Allow-list of safe, read-only commands for background execution.
*   **efficiency_guardrails.md**: Token and quota management rules (The "Stop and Ask" rule).
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
*   **audio_engine_diagnostics**: Debugging tools for hybrid audio engines.
*   **dev_tools**: Utilities for interacting with connected devices.
*   **focus_trap_protection**: Audit for focus-safe TV patterns.
*   **mock_alignment_audit**: UI auditing against provided mocks.
*   **ripple_control**: Detection and management of dependency ripples.
*   **shipit**: Production release and deployment pipeline.
*   **size_guard**: CI/CD-style check for bundle size regressions.
*   **test_mocking_templates**: Standardized templates for mocking services.
*   **test_run_guard**: Poll and bail-out logic for background test runners.
*   **web_debug_suite**: Complex web-state and audio debugging tools.

### 4. Specs (`.agent/specs/`)
Detailed architectural and design specifications.
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
*   **[GLOSSARY.md](file:///home/jam/StudioProjects/gdar/docs/GLOSSARY.md)**: Glossary of agentic terms & patterns.

---

## 🔊 Audio Engine Matrix (Native Target)
The gdar project utilizes a complex hybrid audio stack:

| Target | Engine | Primary Intent |
| :--- | :--- | :--- |
| **Android (Phone/TV)** | Native C++ | High-performance playback via `just_audio`. |
| **PWA / Web** | Hybrid (JS) | Orchestrated transition for 0ms gaps inside the browser. |
| **Gapless Strategy** | Vapor Transitions | Pre-queueing the next track *inside* the current playback loop. |

---

## 💻 Platform Development Setup

### 🪟 Windows 10/11 (PowerShell)
*   **Required CLI Tools**: `ripgrep`, `fd`, `jq`, `fzf`, `bat`, `gh`.
*   **Shell Syntax**: Chained commands MUST use `;` for separation. Never use `&&`.
*   **Brain Location**: `%USERPROFILE%\.gemini\antigravity\brain`

### 💻 ChromeOS / Linux (bash)
*   **Required CLI Tools**: `ripgrep`, `fd-find`, `jq`, `fzf`, `bat`, `gh`, `avahi-utils`.
*   **Shell Syntax**: Standard `&&` or `;` can be used for chaining.
*   **Brain Location**: `~/.gemini/antigravity/brain`
*   **Optimal Web Development**:
    Running via `web-server` is preferred over the `chrome` device for PWA testing and engine stability.
    ```bash
    alias flub="flutter run -d web-server --web-port=8080"
    ```

---

## 📱 Device Testing & ADB Pairing

### 1. `phone_pair` (Initial Pairing)
```bash
#!/bin/bash
# Detects _adb-tls-pairing._tcp for local Android 11+ pairing.
echo "Searching for Android Pairing service..."
LINE=$(avahi-browse -rtp _adb-tls-pairing._tcp | grep "^=" | grep "IPv4" | head -n 1)
if [ -z "$LINE" ]; then echo "ERROR: Pairing service not found."; exit 1; fi
IP=$(echo "$LINE" | cut -d';' -f8); PORT=$(echo "$LINE" | cut -d';' -f9)
read -p "Enter pairing code: " CODE
adb pair "$IP:$PORT" "$CODE"
```

### 2. `phone_soft` (Quick Re-connect)
```bash
#!/bin/bash
adb disconnect 
avahi-browse -rtp _adb-tls-connect._tcp | grep "^=" | head -n 1 | awk -F';' '{print $8":"$9}' | xargs adb connect
```

---

## 🎨 Area 1: Impeller Shader & Aesthetic Debugging
gdar uses high-fidelity fragment shaders (`shaders/steal.frag`) for the screensaver visualizer.

### 1. Unified Debugging
To debug shaders in real-time, the application must be run using the **Impeller** rendering engine:
*   **Android (Vulkan)**: `flutter run --enable-impeller`
*   **iOS (Metal)**: Enabled by default on latest Flutter versions.

### 2. Shader Logic (Uniforms)
The `steal.frag` file relies on real-time uniform injections from the `OilSlideVisualizer`:
*   `uTime`: Continuous float for fluid oscillation.
*   `uOverall`: Dynamic audio energy intensity (0.0 to 1.0).
*   `uBeat`: Pulsed trigger (0.0 or 1.0) synced with beat detection.

---

## 📦 Area 2: The Asset Catalog Pipeline
The show library is stored in `assets/data/output.optimized_src.json`. This 12MB file is the compiled "Source of Truth" for all show/track metadata.

### 1. The Handoff Mode
The application uses a **Late-Binding** approach to show data:
1.  **CatalogService** loads the JSON into memory via `compute()` (Isolates).
2.  **Hive** stores only user-generated diffs (Ratings, Play Counts).
3.  **Optimization**: Track titles and venue names are tokenized in the JSON to save storage.

### 2. Updating the Catalog
> [!WARNING]
> Manual edits to the `output.optimized_src.json` are strictly forbidden. Use the specialized Python pipeline (if available in `tools/`) to re-generate the catalog from the Archive.org scraper output.

---

## 📺 Area 3: Google TV "10ft" Focus Mechanics
Focus on TV is a high-risk area for "Focus Ghosting" and interactive stalls.

### 1. Safe-Zone Scrolling
The `TvFocusWrapper` and `ScrollablePositionedList` are configured to keep focused items in a **30% Viewport Margin**.
*   **Logic**: When a user moves focus (D-pad), the list scrolls only if the focused item is within 3 items of the viewport edge.
*   **Persistence**: Focus state is anchored to the `trackID` or `showDate`, not the list index, to ensure stability during background updates.

### 2. Focus Pruning
Every `Overlay` and `Screen` change triggers a proactive focus prune to clear stale nodes, preventing the "Focus Trap" where navigation keys stop responding.

---

## 🔊 Area 4: The Hybrid Engine Handoff Map (Web)
The Hybrid engine orchestrates a complex state-switch between HTML5 and Web Audio contexts.

### 1. The 3-Phase Lifecycle
1.  **Instant Hit (Phase 1)**: `hybrid_html5_engine.js` starts playback immediately. This bypasses the long "Decode" wait time of the Web Audio API. 
2.  **Decoding (Phase 2)**: In the background, the Web Audio engine (`gapless_audio_engine.js`) fetches and decodes the full track.
3.  **The Vapor Handoff (Phase 3)**: Once decoded, the engine performs a **zero-latency cross-fade** (0ms duration) from HTML5 to Web Audio. This ensures that the remainder of the session is sample-accurate and background-stable.

### 2. Survival Policy
*   If the tab is hidden, the engine injects a **Silent Video Loop** to prevent the browser from suspending the high-performance Web Audio context.

---

## 🤖 Working with Arlo (Antigravity)
**Arlo** is your local pair-programming persona, powered by the **Antigravity** engine.

### How Arlo Processes Context
1.  **Automatic Context**: Injected every prompt (Active Doc, cursor position, open tabs, core rules).
2.  **Proactive Discovery**: Pulls from Root, `.agent/`, and manifests (`pubspec.yaml`, `CHANGELOG.md`).
3.  **Persistent Knowledge**: Knowledge Items (KIs) are reviewed at the start of every session.
4.  **Selective Research**: Arlo does **not** broad-scan `lib/` unless identifying a cross-file "ripple."

---

## 🛡 Security & Guardrails
*   **No Hallucinations**: Agents must state if a solution is unknown.
*   **Secrets**: Hardcoding keys or secrets is strictly forbidden.
*   **Negative Constraint Integrity**: Purge rejected terminology (e.g., "no marquee") from all artifacts immediately.

---

## 📅 Maintenance & Debriefing
Use **`/session_debrief`** at the end of every development session. This is mandatory for the **shipit** workflow to prevent technical drift.

*Standard Release: March 2026*
