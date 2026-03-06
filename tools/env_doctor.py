"""
GDAR Environment Doctor v4.1
─────────────────────────────
One-shot project bootstrap and health checker.

MODES:
    python tools/env_doctor.py               # apply (creates missing files/dirs)
    python tools/env_doctor.py --dry-run      # preview without touching disk
    python tools/env_doctor.py --check        # read-only health report
    python tools/env_doctor.py --force        # overwrite existing static configs

WHAT IT DOES:
    1. Creates missing static configs (.editorconfig, .gitattributes, .vscode/)
    2. Ensures the .agent/ directory structure is complete
    3. Revives docs/ with human-facing guides if missing
    4. Migrates docs/RELEASE_NOTES.txt → CHANGELOG.md (one-time)
    5. Reports on project health

DIRECTORY PHILOSOPHY:
    docs/          → Human-facing guides (setup, schema, structure)
    .agent/specs/  → Agent-facing technical blueprints
    .agent/rules/  → Always-loaded behavioral guardrails
    .agent/workflows/ → Slash-command workflow definitions
    .agent/skills/ → Specialized skill folders
    .agent/notes/  → Transient working files
"""

import argparse
import shutil
import sys
from datetime import datetime
from pathlib import Path

__version__ = "4.1.0"

# ─────────────────────────────────────────────────────────────────────────────
# 1. STATIC CONFIGS — rarely change, safe to write if missing
# ─────────────────────────────────────────────────────────────────────────────

STATIC_CONFIGS: dict[str, str] = {

    ".editorconfig": """\
# .editorconfig — enforces consistent formatting across editors
root = true

[*]
end_of_line = lf
charset = utf-8
trim_trailing_whitespace = true
insert_final_newline = true

[*.dart]
indent_style = space
indent_size = 2

[*.{yaml,yml}]
indent_style = space
indent_size = 2

[*.md]
trim_trailing_whitespace = false

[*.{json,jsonc}]
indent_style = space
indent_size = 2""",

    ".gitattributes": """\
# .gitattributes — forces LF line endings in the repo regardless of OS.
# Prevents CRLF/LF conflicts when committing from Windows 10.

* text=auto eol=lf

# Dart and Flutter source
*.dart text eol=lf
*.yaml text eol=lf
*.yml  text eol=lf
*.json text eol=lf
*.jsonc text eol=lf
*.md   text eol=lf
*.sh   text eol=lf

# Shader source
*.frag text eol=lf
*.vert text eol=lf

# Windows scripts — keep CRLF so they run natively
*.bat  text eol=crlf
*.cmd  text eol=crlf

# Binary assets — never mangle
*.png  binary
*.jpg  binary
*.jpeg binary
*.gif  binary
*.webp binary
*.ttf  binary
*.otf  binary
*.woff binary
*.woff2 binary""",

    ".vscode/settings.json": """\
{
  // ── Dart / Flutter ────────────────────────────────────────────────────
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "Dart-Code.dart-code",
  "editor.rulers": [80],
  "dart.lineLength": 80,
  "dart.flutterSdkPath": null,
  "[dart]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },

  // ── Line endings & whitespace ─────────────────────────────────────────
  "files.eol": "\\n",
  "files.trimTrailingWhitespace": true,
  "files.insertFinalNewline": true,
  "[markdown]": {
    "files.trimTrailingWhitespace": false
  },

  // ── YAML ──────────────────────────────────────────────────────────────
  "[yaml]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },

  // ── Git ───────────────────────────────────────────────────────────────
  "git.autofetch": false,

  // ── Terminal ──────────────────────────────────────────────────────────
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.defaultProfile.windows": "PowerShell",

  // ── Performance — exclude heavy Flutter build dirs ────────────────────
  "search.exclude": {
    "**/.dart_tool": true,
    "**/build": true,
    "**/.gradle": true,
    "**/android/.gradle": true
  },
  "files.watcherExclude": {
    "**/.dart_tool/**": true,
    "**/build/**": true,
    "**/.gradle/**": true
  }
}""",

    ".vscode/launch.json": """\
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "gdar",
            "request": "launch",
            "type": "dart"
        },
        {
            "name": "gdar (Chrome)",
            "request": "launch",
            "type": "dart",
            "args": ["-d", "chrome"]
        },
        {
            "name": "gdar (TV Mode)",
            "request": "launch",
            "type": "dart",
            "args": ["--dart-define=FORCE_TV=true"]
        },
        {
            "name": "gdar (profile)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile"
        },
        {
            "name": "gdar (release)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release"
        }
    ]
}""",
}

# ─────────────────────────────────────────────────────────────────────────────
# 2. STARTER FILES — created only if missing
# ─────────────────────────────────────────────────────────────────────────────

STARTER_FILES: dict[str, str] = {

    # ── Agent Notes (transient workspace) ────────────────────────────────
    ".agent/notes/pending_release.md": """\
<!-- Path: .agent/notes/pending_release.md -->
# Pending Release Notes
### Added
-
### Changed
-
### Fixed
-""",

    ".agent/notes/scratchpad.md": """\
<!-- Path: .agent/notes/scratchpad.md -->
# Scratchpad & Ideas""",

    ".agent/notes/progress_log.md": """\
<!-- Path: .agent/notes/progress_log.md -->
# Progress Log""",

    # ── Human-Facing Docs ────────────────────────────────────────────────
    "docs/dev_environment.md": """\

<!-- Path: docs/dev_environment.md -->
# Dev Environment: Windows 10 + ChromeOS Setup

This project is developed across **Windows 10** and a **Chromebook
(ChromeOS / Crostini)**, synced via Git.

---

## 1. Line Endings
Windows = CRLF. Linux/ChromeOS = LF. Flutter tooling is LF-native.

Three safeguards are in place (all automatic and non-destructive):

| File               | Purpose                                        |
|--------------------|------------------------------------------------|
| `.editorconfig`    | Editor writes LF, indents Dart with 2 spaces.  |
| `.gitattributes`   | Git stores everything as LF for future commits. |
| `.vscode/settings` | `"files.eol": "\\n"` enforces LF in VS Code.    |

> Do **NOT** run `git add --renormalize` unless you have an active
> CRLF problem — it is unnecessary if things are already working.

---

## 2. Flutter SDK Paths
* **Windows 10:** `C:\\flutter` (no spaces). Add `C:\\flutter\\bin` to PATH.
* **ChromeOS (Crostini):** `~/flutter`. Add to `~/.bashrc`:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH"
  ```
* `dart.flutterSdkPath` in `.vscode/settings.json` is `null` —
  auto-detects from PATH on both machines. No machine-specific path
  is ever committed.

---

## 3. Git Sync Workflow
`git.autofetch` is disabled to preserve resources on ChromeOS.
Manual fetch/pull required before starting work.

After pulling: `flutter pub get` is almost always sufficient.

---

## 4. Performance Notes (Crostini)
* Allocate **4 GB+ RAM** to the Linux container.
* `.vscode/settings.json` excludes `.dart_tool/`, `build/`, `.gradle/`
  from the file watcher to reduce I/O overhead.
* Avoid `flutter clean` on Crostini — slow disk I/O makes full
  rebuilds painful. Use `flutter pub get` instead.

---
*Last Updated: 2026-03-04*""",

    "docs/project_structure_map.md": """\
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
*Last Updated: 2026-03-06*""",

    # ── Workflows (Slash Commands) ───────────────────────────────────────
    ".agent/workflows/screenshot_audit.md": """\
---
description: Context-aware UI audit against platform design rules
---
# Screenshot Audit Workflow

**When to use:** To verify UI implementation against platform rules.

1.  **Identify Target Platform:** The user provides an image and specifies the target platform (TV, Mobile Web, Desktop Web, Phone, or Tablet).
2.  **Load Rules:** Automatically read the corresponding `.agent/rules/` file (e.g., `tv_ui_flow.md` or `fruit_theme.md`).
3.  **Analyze Image:** Evaluate the provided screenshot against the loaded rules.
    *   **Check for Fruit Theme leakage:** Ensure no Material 3 ripples or hard shadows are present if evaluating Fruit Theme.
    *   **Check for TV Flow:** Verify 1.05x scale focus wrappers, glow borders, and dimmed inactive panes (0.2 opacity).
    *   **Check alignment and spacing:** Look for visual overflow (e.g., the 2.0px overflow previously fixed on TV).
4.  **Report Findings:** Generate a concise list of pass/fail items based *only* on the active ruleset.
5.  **Suggest Fixes:** If failures are found, propose the specific Flutter code changes needed to resolve them based on `.agent/specs/`.
""",

    ".agent/workflows/mock_regen.md": """\
---
description: Standardized Mockito test stub regeneration
---
# Mock Regeneration Workflow

**When to use:** When tests fail with `ProviderNotFoundException` or `MissingStubError` after modifying core providers or services.

1.  **Analyze Failure:** Read the `flutter test` output to identify the exact failing test file and the missing stub or provider.
2.  **Locate Test Setup:** Open the corresponding `_test.dart` file and locate the mock initialization block (usually `setUp()`).
3.  **Update Mocks:**
    *   If using `build_runner`, ensure the `@GenerateMocks` annotation includes the modified class.
    *   Run `flutter pub run build_runner build --delete-conflicting-outputs`.
4.  **Inject Stubs:** Inject the required `when().thenReturn()` or `when().thenAnswer()` logic based on the new service signature.
    *   *Reference:* Consult `.agent/skills/test_mocking_templates/SKILL.md` (if it exists) for standardized MultiProvider setups.
5.  **Verify:** Run the specific failing test file `flutter test test/path/to/file_test.dart`.
6.  **Report:** Confirm pass rate.
""",

    ".agent/workflows/image_to_code.md": """\
---
description: Generate Flutter UI code or new image assets using Stitch MCP and Banana.
---
# Image to Code (Design Generation) Workflow

**When to use:** When translating a UI mockup/screenshot into Flutter code, or generating new visual assets.

1.  **Analyze Source:** Review the provided image layout, typography, and styling.
2.  **Determine Target:**
    *   **Generate Code:** Use Stitch MCP (or equivalent transpiler) to convert the image elements into Flutter Widget structures.
    *   **Generate Image:** Use Banana (or the agent's image generation tools) to create new derivative assets based on prompts.
3.  **Apply Local Rules:**
    *   Once code is generated by Stitch, it *must* be refined against GDAR's `.agent/rules/`.
    *   For example: Ensure it uses `LucideIcons` instead of `Icons`, applies `BackdropFilter` (for Fruit theme), or implements `TvFocusWrapper` (for TV).
4.  **Integrate:** Format the resulting Dart code and present it to the user or save the new image to `assets/`.
""",

    ".agent/workflows/session_debrief.md": """\
---
description: Analyze the day's work and suggest new agent tools/docs.
---
# Session Debrief Workflow

**When to use:** At the end of a coding session to extract reusable knowledge and improve the agent's environment.

1.  **Analyze Activity:** Review the recent git commits, completed tasks in `todo.md`, and the conversation history of the current session.
2.  **Identify Patterns:** Look for:
    *   Repeated commands or debugging steps.
    *   Newly discovered architectural constraints or UI gotchas.
    *   Successful multi-step processes.
    *   Missing documentation that caused confusion.
3.  **Propose Enhancements:** Generate a concise list of suggestions categorized into:
    *   **Rules (`.agent/rules`):** E.g., "Add rule to always check X before Y."
    *   **Skills (`.agent/skills`):** E.g., "Create skill for testing WebSockets."
    *   **Workflows (`.agent/workflows`):** E.g., "Create a `/deploy_staging` workflow."
    *   **Specs/Docs:** E.g., "Document the new caching layer."
4.  **Execute:** Ask the user which suggestions they approve, and immediately generate the selected `.md` files.
""",

    # ── Shipit Skill (autonomous release pipeline) ────────────────────────
    ".agent/skills/shipit/SKILL.md": """\
---
name: shipit
description: Autonomous production release pipeline for GDAR.
---

# Shipit Skill: GDAR Production Release

**TRIGGERS:** shipit, release, prod, deploy

This skill runs the full release cycle autonomously. The agent proceeds
through all steps without asking for confirmation (per the Autonomous
Exception in `gemini.md` rules).

## Prerequisites
- All changes committed and tests passing.
- `CHANGELOG.md` has an `[Unreleased]` section with pending entries.
- `.agent/notes/pending_release.md` has staged notes (optional — will
  be merged into CHANGELOG if present).

## Steps

### 1. Version Bump
1. Read current `version` from `pubspec.yaml`.
2. Increment build number (e.g., `1.0.3+3` → `1.0.3+4`).
3. If the user specified a version type (major/minor/patch), bump accordingly.

### 2. Finalize Changelog
1. Read `.agent/notes/pending_release.md`.
2. Move entries from `[Unreleased]` to a new version heading in `CHANGELOG.md`.
3. Clear `pending_release.md` back to its template.

### 3. Build
1. Run `flutter build appbundle --release` (Android).
2. Run `flutter build web --release` (Web).

### 4. Deploy Web
1. Run `firebase deploy --only hosting`.

### 5. Git Sync
1. `git add .`
2. `git commit -m "Release vX.X.X+N"`
3. `git push`

### 6. Notify
1. Inform user the build is ready.
2. Remind to upload AAB to [Google Play Console](https://play.google.com/console).
3. Provide release summary from CHANGELOG.

### 7. Post-Launch Debrief
1. Run the `/session_debrief` workflow to evaluate the work that went into this release.
2. Suggest to the user any new `.agent/rules/`, `.agent/skills/`, or `.agent/workflows/` that we should create based on lessons learned during this sprint.

> **IMPORTANT:** Never write to `docs/RELEASE_NOTES.txt`. That file is
> legacy and retired. All release history goes to root `CHANGELOG.md`.
""",

    # ── Diagnostic Skills (Specialized Tools) ────────────────────────────
    ".agent/skills/audio_engine_diagnostics/SKILL.md": """\
---
name: audio_engine_diagnostics
description: Specialized tools for debugging native, web, and hybrid audio engines.
---
# Audio Engine Diagnostics Skill

**TRIGGERS:** audio debug, gapless stall, buffer, audio stutter

This skill provides strategies for isolating and debugging audio playback issues across GDAR's multiple engine implementations.

## 1. Web / Hybrid Engine (Relisten dual-<audio>)
*   **Context:** Mobile web uses a dual `<audio>` element swap to bypass autoplay restrictions and save memory.
*   **Diagnostic Action:** Inject the `BufferWatchdog` visualizer.
    *   To do this, instruct the user to set `debugBufferWatchdog = true` in `relisten_audio_engine.js` (or propose the edit if permitted).
    *   This will expose the inner `readyState`, `currentTime`, and `buffered.length` of the hidden audio elements.
*   **Common Issue:** If transition stalls, check if `prefetchAhead` duration is shorter than the network latency.

## 2. Native Engine (just_audio_background)
*   **Context:** Android/iOS wrapper using ExoPlayer/AVPlayer.
*   **Diagnostic Action:** Check OS media controller sync.
    *   Ensure `MediaItem` ID is a unique String representing the URI, not just the index, to prevent caching collisions.
    *   If background playback dies, verify WakelockPlus is initialized *before* the AudioService.

## 3. General Cache Flow
*   **Context:** Cached files (SHA-256 named) vs Remote Streaming.
*   **Diagnostic Action:** Force cache bypass. Suggest commenting out the local file check in `AudioProvider` to isolate network vs I/O jitter.
""",

    ".agent/skills/dev_tools/SKILL.md": """\
---
name: dev_tools
description: ADB wrappers and utilities for interacting with connected Android/TV devices.
---
# Dev Tools Skill

**TRIGGERS:** adb, screenshot, screencap, logcat, pull

This skill provides the standard commands for interacting with a connected physical device or emulator.

## 1. Screenshots (UI Auditing)
*   **Action:** Capture the screen and pull it to the local temp directory for analysis.
*   **Command 1:** `adb shell screencap -p /sdcard/gdar_screen.png`
*   **Command 2:** `adb pull /sdcard/gdar_screen.png ./temp/gdar_screen.png`
*   **Note:** Once pulled, the agent can use the path `./temp/gdar_screen.png` to analyze the UI against specific design rules (e.g., via the `/screenshot_audit` workflow).

## 2. Live Logs (Crash Isolation)
*   **Action:** Dump the recent device logcat, filtering for GDAR or Flutter errors.
*   **Command:** `adb logcat -d -v time flutter:V "*:S"`
*   *(Note: Add `> ./temp/device_log.txt` if the output is too large for context).*

## 3. Permissions Testing
*   **Action:** Force-grant or revoke permissions via ADB to test app resilience (e.g., testing the screensaver visualizer without Microphone permission).
*   **Command (Grant):** `adb shell pm grant com.jamart3d.gdar android.permission.RECORD_AUDIO`
*   **Command (Revoke):** `adb shell pm revoke com.jamart3d.gdar android.permission.RECORD_AUDIO`
""",

    # ── Granular Agent Rules (trigger-based) ─────────────────────────────
    ".agent/rules/screensaver.md": """\
---
trigger: tv, screensaver, focus
policy_domain: TV Screensaver
---
# TV Screensaver Directives

### Implementation
* **Action:** Always read `.agent/specs/tv_screensaver_spec.md` before touching screensaver code.
* **Constraint:** Never implement screensaver logic on mobile or web. TV exclusivity is absolute.
* **Constraint:** Never add haptic feedback anywhere in the screensaver flow.""",

    ".agent/rules/android_theme.md": """\
---
trigger: mobile, android, theme, phone
policy_domain: Mobile Theme
---
# Android / Mobile Theme Directives

### Visuals
* **Action:** Use M3 Expressive dynamic color tokens exclusively.
* **Action:** Apply ink ripples on every tappable surface.
* **Constraint:** Never use BackdropFilter, blurs, or neumorphic shadows on mobile.""",

    ".agent/rules/fruit_theme.md": """\
---
trigger: web, fruit, glass, theme
policy_domain: Web / Fruit Theme
---
# Fruit Theme Directives

### Visuals & Motion
* **Action:** Use BackdropFilter sigma 15.0 on all glass surfaces.
* **Action:** Use Lucide Icons exclusively. Typography: Inter variable font only.
* **Action:** Use spring physics for all transitions — no MD ripples.
* **Constraint:** Never apply Fruit theme to mobile or TV. Web and PWA only.""",

    ".agent/rules/phone_platform.md": """\
---
trigger: mobile, phone, layout
policy_domain: Mobile Platform
---
# Phone Platform Directives

### Layout & Hardware
* **Action:** Place all primary interactive controls within the bottom 40% of screen height.
* **Action:** Implement haptic feedback on every interaction: selectionClick / mediumImpact / vibrate.
* **Action:** Respect SafeArea on all edges. Use True Black for OLED backgrounds.
* **Constraint:** Never place primary controls in the top half of the screen.""",

    ".agent/rules/tv_ui_flow.md": """\
---
trigger: tv, flow, navigation, focus
policy_domain: TV Navigation
---
# TV UI Flow Directives

### Focus & Navigation
* **Action:** Wrap every interactive TV element in TvFocusWrapper (1.05x scale + glow border).
* **Action:** Dim inactive panes to 0.2 opacity.
* **Action:** Use Duration.zero for all TV transitions — instant only.
* **Constraint:** Never use haptic feedback on TV builds. Focus is purely visual.
* **Constraint:** Never use organic ripples or spring animations on TV.""",

    ".agent/rules/native_audio.md": """\
---
trigger: audio, native, background, queue
policy_domain: Native Audio
---
# Native Audio Directives

### Engine & Queue
* **Action:** Use a flattened AudioSource list for all queue management.
* **Action:** Implement just_audio_background for background awareness and foreground service.
* **Action:** Sync track metadata to the OS media controller on every track change.
* **Action:** Use Hive for show metadata cache on all native targets.
* **Constraint:** Never use ConcatenatingAudioSource under any circumstances.""",

    ".agent/rules/web_audio.md": """\
---
trigger: audio, web, worker, engine
policy_domain: Web Audio
---
# Web Audio Directives

### Engine Architecture
* **Action:** Use an isolated AudioWorklet worker for the Web Audio engine.
* **Action:** Implement HybridAudioOrchestrator for seamless Engine 1 → Engine 2 handoff.
* **Constraint:** Never refactor the Relisten engine to use ReadableStream.
* **Constraint:** Never share an AudioContext across tracks.""",
}

# ─────────────────────────────────────────────────────────────────────────────
# 3. EXPECTED PROJECT STRUCTURE — used by --check
# ─────────────────────────────────────────────────────────────────────────────

REQUIRED_DIRS = [
    ".agent/rules",
    ".agent/specs",
    ".agent/workflows",
    ".agent/skills",
    ".agent/notes",
    "docs",
    ".vscode",
]

EXPECTED_AGENT_FILES = {
    # Rules (always-on)
    ".agent/rules/gemini.md":                "Project-wide coding & design rules",
    ".agent/rules/architecture_context.md":  "Domain-specific architecture constraints",
    ".agent/rules/efficiency_guardrails.md": "Agent efficiency & quota guardrails",
    # Rules (trigger-based)
    ".agent/rules/screensaver.md":           "TV screensaver guardrails",
    ".agent/rules/android_theme.md":         "Mobile M3 theme guardrails",
    ".agent/rules/fruit_theme.md":           "Web Liquid Glass theme guardrails",
    ".agent/rules/phone_platform.md":        "Phone hardware & layout guardrails",
    ".agent/rules/tv_ui_flow.md":            "TV navigation & focus guardrails",
    ".agent/rules/native_audio.md":          "Native audio engine guardrails",
    ".agent/rules/web_audio.md":             "Web audio engine guardrails",
    # Specs
    ".agent/specs/android_theme_spec.md":    "Mobile Material 3 design tokens",
    ".agent/specs/fruit_theme_spec.md":      "Web Liquid Glass theme spec",
    ".agent/specs/native_audio_spec.md":     "Native audio engine architecture",
    ".agent/specs/phone_ui_design_spec.md":  "Phone UI design tokens",
    ".agent/specs/phone_ui_flow_spec.md":    "Phone navigation & interaction flows",
    ".agent/specs/tv_screensaver_spec.md":   "TV screensaver visualizer spec",
    ".agent/specs/tv_ui_design_spec.md":     "TV UI design tokens",
    ".agent/specs/tv_ui_flow_spec.md":       "TV navigation & focus management",
    ".agent/specs/web_ui_audio_engines.md":  "Web audio engine architecture",
    ".agent/specs/web_ui_design_spec.md":    "Web UI design tokens",
    # Workflows
    ".agent/workflows/checkup.md":           "Health check with auto-fixes",
    ".agent/workflows/dev_tools.md":         "Device interaction utilities",
    ".agent/workflows/git_sync.md":          "Version control operations",
    ".agent/workflows/glass_audit.md":       "Liquid Glass design audit",
    ".agent/workflows/improve_liquid.md":    "Liquid Glass improvement suggestions",
    ".agent/workflows/inject_debug_tools.md":"Debug tool injection",
    ".agent/workflows/issue_report.md":      "Issue investigation & reporting",
    ".agent/workflows/quality_audit.md":     "Code quality & performance audit",
    ".agent/workflows/release_manager.md":   "Build & deployment management",
    ".agent/workflows/save.md":              "Quick-save commit & push",
    ".agent/workflows/spec_audit.md":        "Spec compliance audit",
    ".agent/workflows/test_fixer.md":        "Auto-fix test stub errors",
    ".agent/workflows/tv_flow_audit.md":     "TV UI layout & navigation audit",
    ".agent/workflows/screenshot_audit.md":  "Context-aware UI audit",
    ".agent/workflows/mock_regen.md":        "Mockito test stub regeneration",
    ".agent/workflows/image_to_code.md":     "UI mockup to Flutter code",
    ".agent/workflows/session_debrief.md":   "End-of-session knowledge extraction",
    # Skills
    ".agent/skills/shipit/SKILL.md":                    "Autonomous release pipeline",
    ".agent/skills/audio_engine_diagnostics/SKILL.md":  "Audio engine debugging",
    ".agent/skills/dev_tools/SKILL.md":                 "ADB wrappers & device utils",
    ".agent/skills/test_mocking_templates/SKILL.md":    "Mockito stubs & providers",
    ".agent/skills/web_debug_suite/SKILL.md":           "Web audio debug tools",
}

EXPECTED_DOC_FILES = {
    "docs/agents.md":                  "Agent persona, goals & project overview",
    "docs/dev_environment.md":         "Windows/ChromeOS setup guide",
    "docs/json_schema_reference.md":   "JSON data schema reference",
    "docs/project_structure_map.md":   "Project directory map",
}

EXPECTED_ROOT_FILES = {
    "todo.md":       "Project task list",
    "CHANGELOG.md":  "Project changelog (Keep a Changelog format)",
    "pubspec.yaml":  "Flutter project definition",
}


# ─────────────────────────────────────────────────────────────────────────────
# CHECK MODE — read-only health report
# ─────────────────────────────────────────────────────────────────────────────

def _check(root: Path) -> None:
    """Read-only audit of the project environment."""
    print(f"🔍 GDAR Environment Health Check v{__version__}\n")
    issues = 0

    # Directories
    print("── Directories ──")
    for d in REQUIRED_DIRS:
        path = root / d
        if path.is_dir():
            count = sum(1 for _ in path.iterdir())
            print(f"  ✅ {d}/ ({count} items)")
        else:
            print(f"  ❌ {d}/ — MISSING")
            issues += 1

    # Static configs
    print("\n── Static Configs ──")
    for filepath in STATIC_CONFIGS:
        path = root / filepath
        if path.exists():
            print(f"  ✅ {filepath}")
        else:
            print(f"  ❌ {filepath} — MISSING (run --apply to create)")
            issues += 1

    # Human-facing docs
    print("\n── Human Docs (docs/) ──")
    for filepath, desc in EXPECTED_DOC_FILES.items():
        path = root / filepath
        if path.exists():
            size = path.stat().st_size
            print(f"  ✅ {filepath} ({size:,} bytes)")
        else:
            print(f"  ❌ {filepath} — MISSING — {desc}")
            issues += 1

    # Agent files
    print("\n── Agent Files (.agent/) ──")
    for filepath, desc in EXPECTED_AGENT_FILES.items():
        path = root / filepath
        if path.exists():
            size = path.stat().st_size
            print(f"  ✅ {filepath} ({size:,} bytes)")
        else:
            print(f"  ❌ {filepath} — MISSING — {desc}")
            issues += 1

    # Root files
    print("\n── Root Files ──")
    for filepath, desc in EXPECTED_ROOT_FILES.items():
        path = root / filepath
        if path.exists():
            size = path.stat().st_size
            print(f"  ✅ {filepath} ({size:,} bytes)")
        else:
            print(f"  ❌ {filepath} — MISSING — {desc}")
            issues += 1

    # Legacy migration check
    print("\n── Legacy / Migration ──")
    legacy_notes = root / "docs" / "RELEASE_NOTES.txt"
    changelog = root / "CHANGELOG.md"
    if legacy_notes.exists() and not changelog.exists():
        size = legacy_notes.stat().st_size
        print(f"  ⚠️  docs/RELEASE_NOTES.txt ({size:,} bytes) → should migrate to CHANGELOG.md")
        print(f"     Run --apply to migrate automatically.")
        issues += 1
    elif legacy_notes.exists() and changelog.exists():
        print(f"  ⚠️  docs/RELEASE_NOTES.txt still exists alongside CHANGELOG.md")
        print(f"     Consider deleting the legacy file manually.")
    elif changelog.exists():
        print(f"  ✅ CHANGELOG.md (migration complete)")
    else:
        print(f"  ❌ Neither CHANGELOG.md nor docs/RELEASE_NOTES.txt found")
        issues += 1

    # Duplication / stale check
    print("\n── Duplication & Stale Check ──")
    wrong_location = [
        "docs/tv_ui_flow_spec.md", "docs/fruit_theme_spec.md",
        "docs/phone_ui_flow_spec.md", "docs/phone_platform_spec.md",
        "docs/tv_screensaver_spec.md", "docs/android_theme_spec.md",
        "docs/tv_ui_design_spec.md", "docs/native_audio_architecture_spec.md",
        "docs/web_audio_architecture_spec.md",
    ]
    found_dups = False
    for filepath in wrong_location:
        path = root / filepath
        if path.exists():
            print(f"  ⚠️  {filepath} — spec belongs in .agent/specs/, not docs/")
            found_dups = True
            issues += 1
    if not found_dups:
        print(f"  ✅ No duplicate specs in wrong locations")

    # Check for stale shipit workflow (should be a skill now)
    stale_shipit = root / ".agent" / "workflows" / "shipit.md"
    if stale_shipit.exists():
        print(f"  ⚠️  .agent/workflows/shipit.md — should be .agent/skills/shipit/SKILL.md")
        print(f"     Run --apply to migrate automatically.")
        found_dups = True
        issues += 1

    # Check for duplicate guide.md (should be merged into agents.md)
    guide = root / "docs" / "guide.md"
    if guide.exists() and (root / "docs" / "agents.md").exists():
        print(f"  ⚠️  docs/guide.md — should be merged into docs/agents.md")
        print(f"     Run --apply to merge automatically.")
        issues += 1

    # Check gemini.md for Liquid Glass content (belongs in fruit_theme.md)
    gemini = root / ".agent" / "rules" / "gemini.md"
    if gemini.exists():
        gc = gemini.read_text(encoding="utf-8")
        if "LIQUID GLASS" in gc or "BackdropFilter" in gc:
            print(f"  ⚠️  .agent/rules/gemini.md has Liquid Glass rules (web-only, belongs in fruit_theme.md)")
            print(f"     Run --apply to fix automatically.")
            issues += 1

    # Check release_manager for stale RELEASE_NOTES reference
    release_mgr = root / ".agent" / "workflows" / "release_manager.md"
    if release_mgr.exists():
        rm_content = release_mgr.read_text(encoding="utf-8")
        if "RELEASE_NOTES.txt" in rm_content:
            print(f"  ⚠️  .agent/workflows/release_manager.md still references RELEASE_NOTES.txt")
            print(f"     Run --apply to patch automatically.")
            issues += 1

    # Summary
    print(f"\n{'─' * 50}")
    if issues == 0:
        print("✨ Environment is healthy — no issues found.")
    else:
        print(f"⚠️  {issues} issue(s) found. Run --apply to fix what can be auto-fixed.")


# ─────────────────────────────────────────────────────────────────────────────
# MIGRATIONS
# ─────────────────────────────────────────────────────────────────────────────

MERGED_AGENTS_CONTENT = """\
# Persona
You are a senior Flutter developer and expert in mobile application architecture.
You have extensive experience with the latest versions of Flutter and Dart,
particularly with audio playback and multi-platform UI.

## Goal
Assist in developing the Flutter MP3 player application "gdar" by providing
high-quality code, architectural guidance, and clear explanations. Act as a
pair programmer and mentor.

## Project Overview
* **App name:** gdar (package: `name: shakedown`)
* **Flutter SDK:** Latest Stable Channel
* **Architecture:** Clean Architecture — UI (Widgets), Logic (Provider), Data (Repository)
* **State Management:** Provider (`ChangeNotifier` / `ProxyProvider`)
* **Repo:** https://github.com/jamart3d/gdar

## Core Features
* Reads show/track data from local `assets/data/output.optimized_src.json`.
* Lists shows, sublists by shnid if multiple sources.
* Focuses on gapless MP3 URL streaming via `just_audio`.
* No album art — all imagery is generated (shaders, gradients).

## Multi-Platform Targets
* **Android Phone/Tablet:** Material 3 Expressive theme.
* **Google TV / Android TV:** Material Dark (OLED), D-Pad focus, dual-pane.
* **Web / PWA:** Fruit (Liquid Glass) theme with BackdropFilter.

## Key Packages
* `just_audio`, `just_audio_background`, `provider`
* `shared_preferences`, `logger`, `hive`, `hive_flutter`
* `sliding_up_panel`, `scrollable_positioned_list`
* `lucide_icons`, `wakelock_plus`

## Coding Standards
* Use latest stable Dart with sound null safety.
* Strictly follow official Dart style guide, `flutter format`, line length 80.
* Use `const` constructors everywhere possible.
* Provide widget and unit tests for generated code.
* If unsure about something, ask for clarification rather than guessing.
"""

FIXED_GEMINI_CONTENT = """\
---
trigger: always_on
---

# Project Rules: GDAR Audio Player

### 1. CODING STANDARDS & ARCHITECTURE
* **Stack:** Latest Stable Flutter / Dart SDK. Strictly follow modern syntax
  (e.g., favoring `.withValues()` over `withOpacity()`) and proactively resolve
  deprecation warnings.
* **Architecture:** Clean Architecture. Strictly separate UI (Widgets),
  Business Logic (Provider/State), and Data (Repository).
* **State Management:** Provider is primary. Use `ChangeNotifier` or `ProxyProvider`.
* **Style & Performance:** Adhere strictly to the official Dart style guide,
  use `flutter format`, and use `const` constructors everywhere possible to
  prevent unnecessary rebuilds.

### 2. RELEASE MANAGEMENT
* **Action:** Write all release history to root `CHANGELOG.md` using
  Keep a Changelog format.
* **Action:** Stage pending notes in `.agent/notes/pending_release.md`
  before running shipit.
* **Constraint:** Never write to `docs/RELEASE_NOTES.txt`. That file is
  legacy and retired.

### 3. VERIFICATION & OUTPUT
* **Task Artifacts:** When completing a significant feature or fix, provide
  a brief Task List, Implementation Plan, Testing suggestions (unit/widget),
  and a Walkthrough of the results.
"""


def _merge_agent_docs(root: Path, *, dry_run: bool) -> bool:
    """Merge agents.md + guide.md into a single clean agents.md."""
    agents = root / "docs" / "agents.md"
    guide = root / "docs" / "guide.md"
    changed = False

    # Only merge if guide.md still exists
    if guide.exists():
        if dry_run:
            print(f"  [DRY RUN] Would merge docs/guide.md into docs/agents.md")
            print(f"  [DRY RUN] Would delete docs/guide.md")
        else:
            # Backup both
            if agents.exists():
                shutil.copy2(agents, agents.with_suffix(".md.bak"))
                print(f"  💾 Backed up: docs/agents.md → agents.md.bak")
            shutil.copy2(guide, guide.with_suffix(".md.bak"))
            print(f"  💾 Backed up: docs/guide.md → guide.md.bak")

            # Write merged content
            agents.write_text(MERGED_AGENTS_CONTENT.strip() + "\n", encoding="utf-8")
            print(f"  🔀 Merged: docs/agents.md + docs/guide.md → docs/agents.md")

            # Remove guide.md
            guide.unlink()
            print(f"  🗑️  Removed: docs/guide.md (backup preserved)")
        changed = True

    return changed


def _fix_gemini_rules(root: Path, *, dry_run: bool) -> bool:
    """Remove Liquid Glass section from gemini.md (belongs in fruit_theme.md)."""
    gemini = root / ".agent" / "rules" / "gemini.md"
    if not gemini.exists():
        return False

    content = gemini.read_text(encoding="utf-8")

    # Check if it still has the Liquid Glass section
    if "LIQUID GLASS" not in content and "BackdropFilter" not in content:
        return False

    if dry_run:
        print(f"  [DRY RUN] Would fix .agent/rules/gemini.md")
        print(f"            (remove Liquid Glass section → belongs in fruit_theme.md)")
        return True

    shutil.copy2(gemini, gemini.with_suffix(".md.bak"))
    print(f"  💾 Backed up: .agent/rules/gemini.md → gemini.md.bak")

    gemini.write_text(FIXED_GEMINI_CONTENT.strip() + "\n", encoding="utf-8")
    print(f"  ✏️  Fixed: .agent/rules/gemini.md")
    print(f"     (Liquid Glass section moved to .agent/rules/fruit_theme.md)")

    return True


def _migrate_shipit_to_skill(root: Path, *, dry_run: bool) -> bool:
    """Move shipit from workflows/ to skills/ and patch release_manager."""
    old_wf = root / ".agent" / "workflows" / "shipit.md"
    new_skill = root / ".agent" / "skills" / "shipit" / "SKILL.md"
    release_mgr = root / ".agent" / "workflows" / "release_manager.md"
    changed = False

    # Move workflow → skill (if old exists and new doesn't)
    if old_wf.exists() and not new_skill.exists():
        if dry_run:
            print(f"  [DRY RUN] Would move .agent/workflows/shipit.md → .agent/skills/shipit/SKILL.md")
            print(f"  [DRY RUN] Would delete .agent/workflows/shipit.md")
        else:
            new_skill.parent.mkdir(parents=True, exist_ok=True)
            # Don't copy the old content — the STARTER_FILES has the updated version
            old_wf.unlink()
            print(f"  🚀 Removed: .agent/workflows/shipit.md (replaced by skill)")
        changed = True
    elif old_wf.exists() and new_skill.exists():
        if dry_run:
            print(f"  [DRY RUN] Would delete stale .agent/workflows/shipit.md")
        else:
            old_wf.unlink()
            print(f"  🗑️  Removed stale: .agent/workflows/shipit.md")
        changed = True

    # Patch release_manager.md to reference CHANGELOG.md
    if release_mgr.exists():
        content = release_mgr.read_text(encoding="utf-8")
        if "RELEASE_NOTES.txt" in content:
            if dry_run:
                print(f"  [DRY RUN] Would patch .agent/workflows/release_manager.md")
                print(f"            (RELEASE_NOTES.txt → CHANGELOG.md)")
            else:
                patched = content.replace(
                    "docs/RELEASE_NOTES.txt", "CHANGELOG.md"
                ).replace(
                    "copy to Play Console", "copy summary to Play Console"
                )
                release_mgr.write_text(patched, encoding="utf-8")
                print(f"  ✏️  Patched: .agent/workflows/release_manager.md")
                print(f"     (RELEASE_NOTES.txt → CHANGELOG.md)")
            changed = True

    return changed


def _migrate_release_notes(root: Path, *, dry_run: bool) -> bool:
    """Migrate docs/RELEASE_NOTES.txt to root CHANGELOG.md."""
    legacy = root / "docs" / "RELEASE_NOTES.txt"
    changelog = root / "CHANGELOG.md"

    if not legacy.exists():
        return False

    if changelog.exists():
        print(f"  ⏩ CHANGELOG.md already exists — skipping migration")
        print(f"     Delete docs/RELEASE_NOTES.txt manually if complete.")
        return False

    content = legacy.read_text(encoding="utf-8")
    line_count = len(content.splitlines())
    timestamp = datetime.now().strftime("%Y-%m-%d")

    changelog_content = f"""\
# Changelog

All notable changes to the GDAR project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

---

### Legacy History (migrated {timestamp} from docs/RELEASE_NOTES.txt)

```text
{content.rstrip()}
```
"""

    if dry_run:
        print(f"  [DRY RUN] Would migrate docs/RELEASE_NOTES.txt ({line_count} lines) → CHANGELOG.md")
        print(f"  [DRY RUN] Would backup docs/RELEASE_NOTES.txt → RELEASE_NOTES.txt.bak")
        return True

    bak = legacy.with_suffix(".txt.bak")
    shutil.copy2(legacy, bak)
    print(f"  📦 Backed up: docs/RELEASE_NOTES.txt → {bak.name}")

    changelog.write_text(changelog_content, encoding="utf-8")
    print(f"  🚀 Migrated: {line_count} lines → CHANGELOG.md")

    legacy.unlink()
    print(f"  🗑️  Removed: docs/RELEASE_NOTES.txt (backup preserved)")

    return True


# ─────────────────────────────────────────────────────────────────────────────
# APPLY MODE — create missing files, never overwrite without --force
# ─────────────────────────────────────────────────────────────────────────────

def _write_files(
    root: Path,
    files: dict[str, str],
    label: str,
    *,
    dry_run: bool,
    force: bool,
    created: list[str],
    skipped: list[str],
    errors: list[str],
) -> None:
    """Write a dict of {relative_path: content} to disk."""
    print(f"\n── {label} ──")
    for filepath, content in files.items():
        path = root / filepath
        if path.exists() and not force:
            print(f"  ⏩ {filepath} (exists)")
            skipped.append(filepath)
            continue

        if dry_run:
            action = "overwrite" if path.exists() else "create"
            print(f"  [DRY RUN] Would {action} {filepath}")
            created.append(filepath)
            continue

        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists() and force:
                bak = path.with_suffix(path.suffix + ".bak")
                shutil.copy2(path, bak)
                print(f"  💾 Backed up: {filepath} → {bak.name}")
            path.write_text(content.strip() + "\n", encoding="utf-8")
            print(f"  ✅ {filepath}")
            created.append(filepath)
        except OSError as exc:
            print(f"  ❌ {filepath} — {exc}")
            errors.append(filepath)


def _apply(root: Path, *, dry_run: bool, force: bool) -> None:
    """Create missing static configs, docs, and agent infrastructure."""
    created: list[str] = []
    skipped: list[str] = []
    errors: list[str] = []

    tag = "[DRY RUN] " if dry_run else ""
    print(f"🚀 {tag}GDAR Environment Setup v{__version__}\n")

    # Step 1: Ensure required directories exist
    print("── Directories ──")
    for d in REQUIRED_DIRS:
        path = root / d
        if path.is_dir():
            print(f"  ✅ {d}/ (exists)")
        else:
            if dry_run:
                print(f"  [DRY RUN] Would create {d}/")
            else:
                path.mkdir(parents=True, exist_ok=True)
                print(f"  📁 Created {d}/")

    # Step 2: Write static configs
    _write_files(root, STATIC_CONFIGS, "Static configs",
                 dry_run=dry_run, force=force,
                 created=created, skipped=skipped, errors=errors)

    # Step 3: Write starter files (human docs + agent notes)
    _write_files(root, STARTER_FILES, "Starter files (docs + notes)",
                 dry_run=dry_run, force=False,  # Never force-overwrite docs
                 created=created, skipped=skipped, errors=errors)

    # Step 4: Migrations
    print("\n── Migrations ──")
    any_migration = False
    any_migration |= _merge_agent_docs(root, dry_run=dry_run)
    any_migration |= _fix_gemini_rules(root, dry_run=dry_run)
    any_migration |= _migrate_shipit_to_skill(root, dry_run=dry_run)
    any_migration |= _migrate_release_notes(root, dry_run=dry_run)
    if not any_migration:
        print(f"  ⏩ No migrations needed")

    # Summary
    print(f"\n{'─' * 50}")
    print(f"  Created : {len(created)}")
    print(f"  Skipped : {len(skipped)} (already exist)")
    if errors:
        print(f"  Errors  : {len(errors)}")
    print(f"\n{'✨ Done.' if not errors else '⚠️  Completed with errors.'}")

    if not dry_run and not errors:
        print("\n💡 Run with --check to verify full environment health.")

    if errors:
        sys.exit(1)


# ─────────────────────────────────────────────────────────────────────────────
# CLI
# ─────────────────────────────────────────────────────────────────────────────

def _parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(
        description=f"GDAR environment doctor v{__version__}",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""\
examples:
  python tools/env_doctor.py --check     # health report
  python tools/env_doctor.py --dry-run   # preview changes
  python tools/env_doctor.py             # create missing files
  python tools/env_doctor.py --force     # reset static configs
""",
    )
    p.add_argument("--check", action="store_true",
                   help="Read-only health report.")
    p.add_argument("--dry-run", action="store_true",
                   help="Preview without touching disk.")
    p.add_argument("--force", action="store_true",
                   help="Overwrite static configs (backs up first).")
    p.add_argument("--root", default=".", metavar="DIR",
                   help="Project root (default: current dir).")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse()
    root = Path(args.root).resolve()

    if not (root / "pubspec.yaml").exists():
        print(f"❌ No pubspec.yaml found in {root}")
        print(f"   Run this script from the GDAR project root.")
        sys.exit(1)

    if args.check:
        _check(root)
    else:
        _apply(root, dry_run=args.dry_run, force=args.force)
