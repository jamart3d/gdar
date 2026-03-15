"""
GDAR Project Setup Script v3.5.2
──────────────────────────────────
APPLY (default)
    Backs up any existing file as <file>.bak, then writes the new version.

        python setup_gdar.py           # apply
        python setup_gdar.py --dry-run # preview without touching disk

SNAPSHOT
    Scans the live project and prints an updated PROJECT_FILES dict
    to stdout so this script stays in sync with reality.
    NOTE: Only captures .md files. JSON/config assets are static and excluded.

        python setup_gdar.py --snapshot [--root /path/to/gdar]
"""

import argparse
import shutil
import sys
import textwrap
from datetime import datetime
from pathlib import Path

__version__ = "3.5.2"

# ─────────────────────────────────────────────────────────────────────────────
# Real file contents — updated 2026-03-03
# ─────────────────────────────────────────────────────────────────────────────

PROJECT_FILES: dict[str, str] = {

    # ══════════════════════════════════════════════════════════════════════
    # ROOT FILES
    # ══════════════════════════════════════════════════════════════════════

    "todo.md": """\
# GDAR Project TODO

## Immediate Priorities
* [ ] Transition release notes from `docs/RELEASE_NOTES.txt` to `CHANGELOG.md` (Automated via script).
* [ ] Update Shipit Workflow to use `CHANGELOG.md` and `pending_release.md`.
* [ ] Initialize project structure with Clean Architecture folders (`lib/core`, `lib/features`, `lib/data`).
* [ ] Implement local JSON repository to read `output.optimized_src.json`.
* [ ] Create `AudioProvider` using `just_audio` + `just_audio_background`.
* [ ] Set up the `ShowListScreen` with sub-listing logic for multiple `shnid` entries.

## Feature Backlog
* [ ] Implement **TV Standard** UI (D-Pad navigation and OLED black theme).
* [ ] Implement **Mobile Standard** UI (Material 3 Expressive and Sliding Up Panel).
* [ ] Implement **Web/Fruit** Theme (Backdrop blurs and Liquid Glass).
* [ ] Add the "Dice Roll" random show logic.""",

    "CHANGELOG.md": """\
<!-- Path: CHANGELOG.md -->
# Changelog

All notable changes to the GDAR project will be documented in this file.
The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]
### Added
- Multi-platform design system architecture (TV, Mobile, Web).
- Agent-first development environment with specialized rules and technical blueprints.
- Dual-theme support system (Material 3 Expressive and Fruit/Liquid Glass).

## [0.9.1] - 2026-03-03
### Changed
- **Architecture Migration:** Officially transitioned release note tracking to this root `CHANGELOG.md`.
- **Workflow Update:** Integrated `pending_release.md` staging into the `shipit` automation skill.

---
### Legacy History
""",

    # ══════════════════════════════════════════════════════════════════════
    # CROSS-PLATFORM CONFIG (root) — static assets, not snapshotted
    # ══════════════════════════════════════════════════════════════════════

    ".editorconfig": """\
# .editorconfig — enforces consistent formatting across Windows and ChromeOS
# editors automatically respect this (VS Code, Android Studio, IntelliJ).
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
# NOTE: If Git sync between your machines is already working cleanly,
# this file will not disrupt it. It only governs future commits.
# Do NOT run 'git add --renormalize' unless you have an active CRLF
# problem — it is unnecessary if things are already working.

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

# Windows scripts — keep CRLF only for .bat/.cmd so they run natively
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

    # ── .vscode/ ─────────────────────────────────────────────────────────
    # launch.json: matches existing file exactly.
    # settings.json: tuned for Git + Crostini Linux + VS Code native.
    # Both are static assets — not snapshotted.
    # ─────────────────────────────────────────────────────────────────────

    ".vscode/launch.json": """\
{
    // Use IntelliSense to learn about possible attributes.
    // Hover to view descriptions of existing attributes.
    // For more information, visit: https://go.microsoft.com/fwlink/?linkid=830387
    "version": "0.2.0",
    "configurations": [
        {
            "name": "gdar",
            "request": "launch",
            "type": "dart"
        },
        {
            "name": "gdar (profile mode)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "profile"
        },
        {
            "name": "gdar (release mode)",
            "request": "launch",
            "type": "dart",
            "flutterMode": "release"
        }
    ]
}""",

    ".vscode/settings.json": """\
{
  // ── Dart / Flutter ────────────────────────────────────────────────────
  "editor.formatOnSave": true,
  "editor.defaultFormatter": "Dart-Code.dart-code",
  "editor.rulers": [80],
  "dart.lineLength": 80,
  // null = auto-detect Flutter SDK from PATH on both Windows and Crostini.
  // Never hardcode a machine-specific path here.
  "dart.flutterSdkPath": null,
  "[dart]": {
    "editor.tabSize": 2,
    "editor.insertSpaces": true
  },

  // ── Line endings & whitespace ─────────────────────────────────────────
  // Belt-and-suspenders alongside .editorconfig and .gitattributes.
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
  // Note: git.autofetch is disabled to save battery/bandwidth on ChromeOS.
  // Manual fetch/pull is required.
  "git.autofetch": false,

  // ── Terminal (Crostini: VS Code runs natively in Linux container) ─────
  // Dart and Flutter extensions install directly — no Remote SSH needed.
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

    # ══════════════════════════════════════════════════════════════════════
    # DOCUMENTATION (docs/)
    # ══════════════════════════════════════════════════════════════════════

    "docs/guide.md": """\
<!-- Path: docs/guide.md -->
# GDAR: Development Guide & Usage
## 1. Environment Setup
* **App name:** shakedown (package: `name: shakedown`)
* **Flutter SDK:** Latest Stable Channel (sdk: >=3.4.0 <4.0.0)
* **Architecture:** Clean Architecture (UI, Logic, Data)
* **Testing:** mockito ^5.4.4 + build_runner ^2.4.8
* **Design:** Material 3 Expressive
## 2. Core Requirements
* Data: Local `assets/data/output.optimized_src.json`.
* Playback: Gapless MP3 URL streaming.
* Visuals: No album art.""",

    "docs/agents.md": """\
<!-- Path: docs/agents.md -->
# Persona
Senior Flutter developer and expert in mobile architecture.
# Goal
Assist in developing "gdar". Act as a pair programmer and mentor.""",

    "docs/dev_environment.md": """\
<!-- Path: docs/dev_environment.md -->

# Dev Environment: Windows 10 + ChromeOS Setup

This project is actively developed across **Windows 10** and a **Chromebook
(ChromeOS Linux container / Crostini)**, synced via Git. This document covers
setup, gotchas, and the guardrails baked into the repo to keep both in sync.

---

## 1. Line Endings

Windows uses CRLF (`\\r\\n`). Linux/ChromeOS uses LF (`\\n`). Dart and
Flutter tooling are LF-native.

**Three safeguards are in place — all automatic and non-destructive:**

| File | What it does |
| `.editorconfig` | Tells your editor to always write LF, indent Dart with 2 spaces. |
| `.gitattributes` | Tells Git to store everything as LF for future commits. |
| `.vscode/settings.json` | `"files.eol": "\\n"` enforces LF at the VS Code buffer level. |

> **Important:** If Git sync between your machines is already working
> cleanly, these files will not disrupt it. They only govern future
> commits — no history is rewritten. Do **NOT** run
> `git add --renormalize` unless you have an active CRLF problem.
> It is unnecessary if things are already working.

---

## 2. Flutter SDK Paths

**Windows 10**
* Recommended install: `C:\\flutter` (no spaces — avoids Gradle issues).
* Add to PATH: `C:\\flutter\\bin`.
* Android SDK: `C:\\Users\\<you>\\AppData\\Local\\Android\\Sdk`.

**ChromeOS — Crostini Linux container**
* VS Code runs **natively inside the Linux container** — no Remote SSH
  extension or container bridging needed. Install the Dart and Flutter
  extensions as you normally would and they connect directly.
* Recommended install: `~/flutter` inside the container.
* Add to `~/.bashrc` or `~/.zshrc`:
  ```bash
  export PATH="$HOME/flutter/bin:$PATH"
  export ANDROID_HOME="$HOME/Android/Sdk"
  export PATH="$ANDROID_HOME/platform-tools:$PATH"
  ```
* Run after setup: `sudo apt install libglu1-mesa` (required for Flutter
  web tooling on Crostini).
* `dart.flutterSdkPath` in `.vscode/settings.json` is intentionally
  `null` — VS Code auto-detects from PATH on both machines. No
  machine-specific path is ever committed to the repo.

---

## 3. Android Device

**Windows:** USB debugging works normally. Emulator via Android Studio.

**ChromeOS:** Use a physical Android device via USB — most reliable path.
Enable USB debugging on the device, then inside the Linux container:
```bash
adb devices          # confirm device is listed
flutter devices      # confirm Flutter sees it
flutter run
```
> ChromeOS has its own Android container (ARC++) but targeting it
> directly for Flutter dev is not recommended. Use a real device.

---

## 4. Git Sync Workflow

`git.autofetch` is disabled in `.vscode/settings.json` to preserve resources
on ChromeOS. You must manually fetch and pull before starting work.

After pulling on the other machine, `flutter pub get` is usually
sufficient:
```bash
flutter pub get
```

Key files:
* `.dart_tool/` — machine-specific, gitignored. Never commit it.
* `pubspec.lock` — IS committed. Keeps dependency versions identical.

---

## 5. `flutter clean` on Crostini — Last Resort Only

⚠️ **Avoid `flutter clean` on the Chromebook unless absolutely necessary.**

The Crostini Linux container has slow disk I/O compared to a native Linux
or Windows install. A `flutter clean` forces Gradle to re-download and
rebuild everything from scratch, which can take many minutes and puts
unnecessary load on the container.

**`flutter pub get` is almost always enough** after a pull.

Only reach for `flutter clean` if you are experiencing:
* Corrupted build cache causing inexplicable compile errors.
* A package upgrade that requires a full rebuild.
* Build artifacts from a different Flutter SDK version causing conflicts.

In all other cases — dependency changes, switching branches, pulling
updates — `flutter pub get` is the correct tool.

---

## 6. Performance Notes (Crostini)

* Allocate **4 GB+ RAM** to the Linux container in ChromeOS Settings →
  Linux → Disk & Memory.
* If `Running Gradle task 'assembleDebug'...` hangs, RAM is the usual cause.
* `.vscode/settings.json` excludes `.dart_tool/`, `build/`, and `.gradle/`
  from the file watcher to reduce Crostini I/O overhead.

---

*Version: 1.2* *Last Updated: 2026-03-03*""",

    "docs/data_schema.md": """\
<!-- Path: docs/data_schema.md -->

# Data Schema: output.optimized_src.json

This document defines the finalized structure for the local JSON data source based on the Concert Archive Schema.

## 1. Key Mapping Reference

To keep the JSON file compact, the following shorthand keys are used:

| Key | Description | Data Type |
| ----- | ----- | ----- |
| **`l`** | Location / Venue | String |
| **`sources`** | List of recordings for the date | Array<Object> |
| **`id`** | Unique Identifier (SHNID) | String |
| **`_d`** | Internal Directory ID | String |
| **`src`** | Source Type (sbd, aud, etc.) | String |
| **`sets`** | List of sets in the recording | Array<Object> |
| **`n`** | Name of Set (in Sets) or Track Number (in Tracks) | String / Integer |
| **`t`** | Track List (in Sets) or Track Title (in Tracks) | Array / String |
| **`d`** | Duration in seconds | Integer |
| **`u`** | Audio URL / Path | String |

## 2. Representative Example

```json
[
  {
    "name": "Grateful Dead",
    "date": "1977-05-08",
    "l": "Barton Hall, Cornell University, Ithaca, NY",
    "sources": [
      {
        "id": "gd1977-05-08.shnid.12345",
        "_d": "gd77-05-08",
        "src": "sbd",
        "sets": [
          {
            "n": "Set 1",
            "t": [
              {
                "n": 1,
                "t": "New Minglewood Blues",
                "d": 312,
                "u": "https://archive.org/download/.../d1t01.mp3"
              }
            ]
          }
        ]
      }
    ]
  }
]
```

## 3. UI Logic Note

* **Primary List:** Grouped by `date` and `l`.
* **Sub-listing:** If `sources.length > 1`, display the `id` (SHNID) and `src` as selection options before entering the player.

*Version: 2.0 (Finalized Schema)* *Last Updated: 2026-03-03*""",

    "docs/tv_screensaver_spec.md": """\
<!-- Path: docs/tv_screensaver_spec.md -->

# TV Screensaver UI Specification: GDAR Audio Player

This document outlines the current state, architecture, specifications, and constraints specifically for the **TV Screensaver** feature within the GDAR application. The screensaver uses a fully custom generative visualizer ("Steal Your Face") to prevent screen burn-in while providing a highly aesthetic, audio-reactive experience tailored for Google TV and Android TV hardware.

## Key Files & Components

  * **UI Settings:** `lib/ui/tv/tv_screensaver_section.dart`
  * **Trigger Service:** `lib/services/inactivity_service.dart`
  * **Visualizer Shader:** `shaders/steal.frag`
  * **Main Screen Route:** `lib/ui/tv/screensaver_screen.dart`

-----

## 1. Current State & Architecture

### 1.1 Core Trigger Mechanism

  - **Service:** `InactivityService` monitors user interaction across the TV application.
  - **Trigger:** Activates automatically after a default period (e.g., 5 minutes) of remote inactivity if the `useOilScreensaver` setting is enabled.
  - **Guardrails:** When triggered, the screensaver (`ScreensaverScreen.show`) explicitly stops the `InactivityService` to prevent multiple hardware key events from stacking overlapping routes. Once dismissed, the service restarts.
  - **Dismissal:** Any `KeyDownEvent` captured by a global `HardwareKeyboard` handler pops the screensaver route and returns the user to the underlying application state.

### 1.2 Visuals & Audio Reactivity (`StealVisualizer`)

  - **Configuration:** Driven by `StealConfig`, providing parameters controlling flow speed, palettes, film grain, and audio sensitivity.
  - **Audio Reactor:** Integrates via `AudioReactorFactory`. When enabled (`oilEnableAudioReactivity`), it hooks into the native Android Audio Session ID.
      - **Source Agnostic:** Reacts to *any* audio being output by the application's `AudioProvider`.
      - Maps decibel and frequency bands directly to the visualizer's pulse rate and heat drift.

### 1.3 Beat Detection & Audio Graph Visualization

  - **Graph Modes (`oilAudioGraphMode`)**: Operates in two modes:
      - **Corner Mode**: A traditional 8-band EQ anchored to the bottom-left, featuring a distinct **9th bar specifically for Beat Detection**.
      - **Circular Mode**: An 8-band radial EQ that dynamically calculates its center point based on `game.smoothedLogoPos`, sprouting from the floating logo.

### 1.4 Performance Tuning & Shader Scalability

  - **Performance Levels (`oilPerformanceLevel`)**:
      - **High (Level 2):** Full fidelity blur loops and rendering passes.
      - **Balanced (Level 1) - Default:** Reduces sampling fidelity slightly to maintain 60fps on standard Google TV hardware.
      - **Fast (Level 0):** Severely limits blur samples and rendering overhead for low-end panels.

-----

## 2. Screensaver Settings Reference

### 2.1 General & Performance

1.  **Use Generative Screensaver** (`useOilScreensaver`): Master toggle.
2.  **Screensaver Time** (`idleTimeout`): Inactivity duration before triggering.
3.  **Performance Mode** (`oilPerformanceLevel`): 0 = Fast, 1 = Balanced, 2 = High.

### 2.2 Visuals & Motion

4.  **Color Palette** (`oilPalette`): Active base color range.
5.  **Cycle Palettes** (`oilPaletteCycle`): Auto-transitions between color palettes.
6.  **Cycle Duration** (`oilPaletteTransitionSpeed`): Speed of palette morphing.
7.  **Flow Speed** (`oilFlowSpeed`): Multiplier for the Lissajous path sweeping the logo.
8.  **Pulse Intensity** (`oilPulseIntensity`): Aggressiveness of glow scaling over time.
9.  **Heat Drift** (`oilHeatDrift`): Wavy distortion on the UV coordinates.
10. **Translation Smoothing** (`oilTranslationSmoothing`): Orbit tracking drag (0.0 to 1.0).
11. **Orbit Drift** (`oilOrbitDrift`): Multiplier for the Lissajous curve amplitude.
12. **Logo Scale** (`oilLogoScale`): Center graphic sizing multiplier.
13. **Blur Amount** (`oilBlurAmount`): Initial fragment shader blur factor.
14. **Logo Trail Slices** (`oilLogoTrailSlices`): Ghost copies rendered behind the logo.
15. **Logo Trail Length** (`oilLogoTrailLength`): Distance offset between ghosts.
16. **Logo Trail Intensity** (`oilLogoTrailIntensity`): Blend strength of the ghosting trail.

### 2.3 Audio Reactivity

17. **Enable Audio Reactivity** (`oilEnableAudioReactivity`): Hooks into Android Visualizer.
18. **Audio Graph Mode** (`oilAudioGraphMode`): `off`, `corner`, or `circular`.
19. **Audio Graph Sensitivity** (`oilBeatSensitivity`): Threshold to trigger a "BEAT" spike.

### 2.4 Typography & HUD Information (`StealBanner`)

20. **Enable HUD** (`oilShowInfoBanner`): Toggles the textual track information.
21. **HUD Display Mode** (`oilBannerDisplayMode`): `ring` (orbiting) or `flat` (stacked block).
22. **Font Family** (`oilBannerFont`): Selects the typeface (e.g., Rock Salt, Roboto).
23. **Track Word Spacing** (`oilTrackWordSpacing`): HUD word spacing control.
24. **Track Letter Spacing** (`oilTrackLetterSpacing`): HUD letter kerning control.
25. **Flat Text Proximity** (`oilFlatTextProximity`): Distance of block text from the image in `flat` mode.
26. **Line Spacing** (`oilFlatLineSpacing`): Line height multiplier in `flat` mode.

-----

## 3. Platform Exclusivity & Restrictions

  - 🚫 **Strict TV Exclusivity:** Exclusively available on the TV UI. Will not trigger, and settings are hidden, on native mobile apps or the web PWA.
  - **Hardware WakeLock:** Invokes `wakelock_plus` when launched to prevent deep sleep.
  - 🚫 **Haptics Disabled:** Hard-disabled through `AppHaptics`.
  - **Keyboard Handling:** D-pad and OK button inputs are treated as standard keyboard events to pop the overlay.

-----

## 4. Known Limitations & Constraints

  - **Graphical Overhead:** Real-time Flame game loop + GLSL shader (`shaders/steal.frag`) is computationally heavy. On cheaper hardware stacks, "High" mode can cause thermal throttling.
  - **Audio Permission Boundaries:** Audio reactivity requires permission to record/capture the global audio mix.

-----

## 5. Future Plans & Roadmap

  - **TV-Specific Optimization Pass:** Establish a strict "TV Safe Frame" border. Implement adaptive downgrading for FPS drops.
  - **Enhanced Media Controls Overlay:** Intercept media keys to show a temporary HUD over the visualizer.
  - **Screensaver "Daydream" OS Integration:** Register `StealVisualizer` as a system-wide Android TV Daydream target.""",

    "docs/phone_ui_flow_spec.md": """\
<!-- Path: docs/phone_ui_flow_spec.md -->

# Phone UI Flow Specification: GDAR Audio Player

This document defines the interaction model, navigation stack, and core user flows for the **Mobile (Android/iOS)** implementation of GDAR. It relies on the `docs/android_theme_spec.md` (Look) and the `docs/phone_platform_spec.md` (Feel/Hardware).

## Key Files & Components

* **Primary Screens:** `lib/ui/mobile/screens/show_list_screen.dart`, `lib/ui/mobile/screens/track_list_screen.dart`
* **Playback & Overlay:** `lib/ui/mobile/components/sliding_up_panel.dart`, `lib/ui/mobile/screens/playback_screen.dart`
* **Utility Screens:** `lib/ui/mobile/screens/settings_screen.dart`, `lib/ui/mobile/screens/rated_shows_screen.dart`
* **Routing/Navigation:** `lib/routes/mobile_router.dart`

## 1. Interaction Architecture

The Phone UI is strictly **Walled Off** from the Fruit (Liquid Glass) theme. It utilizes the **Material 3 Expressive** baseline to ensure high-performance native navigation.
The Phone UI follows a standard linear navigation stack using Flutter's `Navigator`.

* **Primary Screen:** `ShowListScreen` (The catalog/browsing hub).
* **Expansion Point:** `TrackListScreen` (Detailed track browsing for a specific show).
* **Context Layer:** `PlaybackScreen` (A persistent `SlidingUpPanel (sliding_up_panel ^2.0.0)` overlay for active controls).

## 2. Core Interaction Flows

### 2.1 Browsing & Playback

1. **Selection:** Tapping a show in the `ShowListScreen` initiates one of two actions:
   * **Direct Play:** If the show has a single source, it starts playback immediately.
   * **Expand:** If the show has multiple sources, it expands the card to show available versions.
2. **Immersive Browser:** Tapping an already expanded show card (or a specific source) navigates the user to the `TrackListScreen` for that show.
3. **Active Control:** Once playback begins, the **Mini-Player** becomes visible at the bottom of the screen.

### 2.2 Playback Control (The Slide-Up Panel)

* **Expansion:** A vertical upward swipe or a tap on the Mini-Player expands the `SlidingUpPanel (sliding_up_panel ^2.0.0)` to reveal the `PlaybackScreen`.
* **Deep Navigation:** Tapping the venue/date text in the expanded player scrolls the internal track list to the currently playing track.
* **Dismissal:** A vertical downward swipe or tapping the "down" arrow icon collapses the player back to the Mini-Player state.

### 2.3 Clipboard & Deep Links

GDAR includes specialized logic for handling external show references:

* **Search Bar Detection:** Pasting a SHNID (e.g., `gd1977-05-08.shnid...`) or an `archive.org/details/gd...` URL into the search bar triggers an automatic playback search.
* **Auto-Play:** If a valid show is parsed from the clipboard, the app will automatically start playback and navigate to the playback controls.

## 3. Gesture & Haptic Mapping

| **Action** | **Gesture** | **Feedback** |
| **Play Random Show** | Tap (Dice Icon) | `mediumImpact` Haptics + Dice Animation |
| **Open Settings** | Tap (Title/Logo) | `selectionClick` Haptics |
| **Expand Player** | Swipe Up / Tap | Smooth panel slide |
| **Seek Track** | Horizontal Slide | Visual time update |
| **Rate Show** | Long-Press | `vibrate` (if blocked) / `selectionClick` |

## 4. UI Transition Philosophy

* **Consistency:** Transitions between screens use the platform-standard page route transitions (Material for Android, Cupertino for iOS).
* **Context Preservation:** The `SlidingUpPanel (sliding_up_panel ^2.0.0)` ensures that the user never loses access to playback controls, regardless of where they are in the navigation stack.
* **Loading States:** High-performance "Skeletons" or "Slightly Opacity" pulses are used during metadata fetching to maintain a feeling of responsiveness.

*Version: 1.0.1* *Last Updated: 2026-03-03*""",

    "docs/tv_ui_flow_spec.md": """\
<!-- Path: docs/tv_ui_flow_spec.md -->

# TV UI Flow Specification: GDAR Audio Player

This document defines the interaction model, focus management, and sequential logic for the **Google TV / Android TV** implementation of GDAR.

## Key Files & Components

* **Layout & Focus:** `lib/ui/tv/tv_dual_pane_layout.dart`, `lib/ui/tv/tv_focus_wrapper.dart`
* **TV Screens:** `lib/ui/tv/screens/show_list_screen.dart`, `lib/ui/tv/screens/track_list_screen.dart`
* **Modals & Dialogs:** `lib/ui/tv/components/tv_interaction_modal.dart`, `lib/ui/tv/components/tv_reload_dialog.dart`
* **Services:** `lib/services/wakelock_plus.dart`

## 1. Core Architecture: Dual-Pane Layout

The TV UI utilizes a persistent dual-pane layout within `TvDualPaneLayout`.

* **Left Pane (60%):** `ShowListScreen` (Browse & Search).
* **Right Pane (40%):** `PlaybackScreen` (Active Track List & Details).
* **Divider:** A vertical Translucent Material divider with linear transparency.
* **Dimming:** The inactive pane is dimmed to **0.2 opacity** to clearly indicate focus.

## 2. D-Pad Navigation Truth Table

| **From (Component)** | **Direction** | **Action / Destination** |
| **TvHeader (Dice)** | Left | Wrap-around: Focus **Track List** (Right Pane) |
| **TvHeader (Dice)** | Down | Focus **Search Bar** or **First Show Item** |
| **Show List Item** | Right | Focus **Show List Scrollbar** |
| **Show List Scrollbar** | Left | Focus **Show List Item** (Visible/Middle item) |
| **Show List Scrollbar** | Right | Focus **Track List** (Right Pane) |
| **Track List Item** | Left | Focus **Show List Scrollbar** (Return to Browse) |
| **Track List Item** | Right | Focus **Playback Scrollbar** |
| **Playback Scrollbar** | Right | Wrap-around: Focus **Dice** (TvHeader) |
| **Playback Scrollbar** | Left | Focus **Track List Item** (Visible/Middle item) |

## 3. Interaction Flows

### 3.1 Clicking an "Active" Show

When a show that is already playing is selected in the Show List:
1. **If Multi-Source:** The show expands in the left pane to reveal SHNIDs. Focus remains in the list.
2. **If Single-Source / Selected SHNID:** Shifts focus to the **Right Pane** (Track List). **NO** full-screen navigation occurs.
3. **Focus:** Visual focus is communicated via a static high-contrast border. **NO** haptic feedback.

### 3.2 Clicking an "Inactive" Show

1. **Selection:** Starts playback of the show.
2. **Flow:** Automatically shifts focus to the **Right Pane** (Track List) to maintain a consistent dual-pane experience.

### 3.3 Show Expansion Logic

* **Expansion:** Clicking a non-playing show with >1 source expands the card.
* **Auto-Scroll:** The list automatically scrolls to align the expanded card.
* **Collapsing:** Clicking the same show again collapses it. Focusing out does NOT auto-collapse.

### 3.4 The "Random Roll" Sequence (Dice)

Triggered by the Dice icon or "play-random" deep link. This is a multi-stage orchestrated sequence:
1. **Stage 1 (1.2s):** Dice pulse animation only. Logic generates a selection.
2. **Stage 2 (2.0s):** Show List scrolls to the selected show. Focus is force-shifted to the Show Card.
3. **Stage 3 (2.0s):** Focus shifts to the Right Pane (Track List). `PlaybackScreen` syncs to the current track.
4. **Playback Start:** Audio begins after focus has stabilized in the track list.

## 4. Modal Interactions (Long-Press)

* **Show/Source (Non-Playing):** Triggers `TvInteractionModal` (legacy v135 behavior).
* **Active Track (Right Pane):** Triggers `TvReloadDialog`.
* **TV Context:** `RatingDialog` buttons are specifically scaled for TV visibility (1.2x multiplier).

## 5. Flow Philosophy: v135 Context & Navigation Actions

The TV UI uses a hybrid navigation model:
1. **Browse Mode**: Persistent dual-pane for the current show context.
2. **Dive Mode**: Navigation to a dedicated `TrackListScreen` for non-current shows.
3. **Power Actions**: Long-press bypasses modals for immediate "lean-back" playback.

| **Trigger** | **Item Status** | **Action** | **View** |
| **Select (Tap)** | **Active Show** | Shift focus to right pane (track list) | Dual-Pane |
| **Select (Tap)** | **Inactive Show** | Navigate to dedicated `TrackListScreen` | Full-Screen |
| **Long-Press** | **Any Show** | Play immediately (highest rated source) | Dual-Pane / Target |
| **Select (Tap)** | **Inactive Source** | Navigate to dedicated `TrackListScreen` | Full-Screen |
| **Long-Press** | **Any Source** | Play immediately | Dual-Pane / Target |

## 6. Performance & Physics

* **Transitions**: All TV transitions are instantaneous (`Duration.zero`).
* **Physics**: No organic ripples; focus is communicated via static high-contrast borders.
* 🚫 **Interaction Feedback**: All haptic feedback is **STRICTLY PROHIBITED** on TV builds.

*Version: 1.2.1* *Last Updated: 2026-03-03*""",

    "docs/fruit_theme_spec.md": """\
<!-- Path: docs/fruit_theme_spec.md -->

# Fruit Theme Specification: GDAR Audio Player

This document defines the **Fruit** (Liquid Glass) theme, a premium, tactile, and immersive aesthetic developed for the GDAR ecosystem.

## 1. Aesthetic Philosophy

The "Fruit" look centers on depth, translucency, and physical responsiveness. It moves away from Material's elevation-based shadow model towards a model of blurred surfaces and tactile feedback.

## 2. Visual Tokens

### 2.1 Translucency (Liquid Glass)

  * **Backdrop Blur:** Surfaces use `BackdropFilter` with `sigma: 15.0`.
  * **Opacity:** Background alpha is typically `0.7`.
  * **Availability:** Specifically enabled on **Web** platforms when the Fruit theme is active.

### 2.2 Tactility (Neumorphism)

  * **Shadow System:** Interactive elements use dual-shadow light/dark offsets.
  * **Convex (Pop):** Standard buttons and active cards.
  * **Concave (Depressed):** Search fields, inactive inputs.

### 2.3 Symbology & Typography

  * **Font Family:** **Inter** (Hard-enforced).
  * **Icon Set:** **Lucide Icons** exclusively.

## 3. Dynamic Effects

### 3.1 RGB Active Track

  * Rotating `SweepGradient` border for playing track or selected show.

### 3.2 Motion & Easing

  * **Spring Physics:** Rely on Apple-style spring physics for transitions.
  * **Tactile Feedback:** Use scale-down/bounce-back animations instead of ripples.

## 4. Platform Application (The "Walled" Policy)

The Fruit theme is architecturally **walled off** as a **Web and PWA Exclusive**.

  * **Web / PWA (Exclusive Domain):** Full implementation permitted.
  * 🚫 **Native Mobile (Phone/Tablet):** **STRICTLY FORBIDDEN**.
  * 🚫 **TV:** **STRICTLY FORBIDDEN**.

---

*Version: 1.1 (Walled Architecture)* *Last Updated: 2026-03-02*""",

    "docs/phone_platform_spec.md": """\
<!-- Path: docs/phone_platform_spec.md -->

# Phone Platform Specification: GDAR Audio Player

This document defines the **Hardware Interactivity** and **Native OS Integration** standards for the Phone (Android/iOS).

## 1. Physical Layout & Constraint Management

### 1.1 The "Thumb Zone" Constraint

  * **Active Area:** Primary interactive elements MUST be positioned within the bottom 40% of the screen.

### 1.2 Display & Safe Areas

  * **Sensor Housing:** Deep integration with `SafeArea`.
  * **OLED Optimization:** Default to **True Black** backgrounds.

## 2. Hardware Feedback (Haptics)

  * **Selection:** Subtle click (Light) on every selection.
  * **Action Success:** Medium vibration for success.
  * **Dice Roll (Random):** Multi-stage "rumble" sequence.
  * **Warning:** Heavy vibration for blocks or errors.

## 3. Native Integration

### 3.1 Background & Energy

  * **Background Audio:** Maintain stable foreground service.
  * **Wakelock:** Enable `wakelock_plus` during active playback ONLY.

### 3.2 Lock Screen & Media Controls

  * **Service Integration:** Sync current track metadata to system media controller.

## 4. Input & Sensors

  * **Gestures:** Vertical swipe-to-dismiss for playback panel.
  * **Connectivity:** Monitor `connectivity_plus`.

---

*Version: 1.0 (Hardware & Integration)* *Last Updated: 2026-03-02*""",

    "docs/android_theme_spec.md": """\
<!-- Path: docs/android_theme_spec.md -->
# Mobile Standard Design Tokens
* Theme: Material 3 Expressive.
* Tokens: Standard M3 elevation, organic ripples, and dynamic color seeding.
* Restrictions: No blurs or neumorphism.""",

    "docs/tv_ui_design_spec.md": """\
<!-- Path: docs/tv_ui_design_spec.md -->
# TV UI Design Tokens
* Theme: Material Dark (OLED Black).
* Tokens: 1.35x scale boost, high-contrast borders, no blurs.
* Restrictions: Visual focus only, no haptics.""",

    "docs/native_audio_architecture_spec.md": """\
<!-- Path: docs/native_audio_architecture_spec.md -->
# Native Audio Architecture
* Engine: `just_audio ^0.10.5` + `just_audio_background ^0.0.1-beta.11`.
* Session: `audio_session ^0.1.21` for audio focus management.
* Queue: Flattened `AudioSource` sequence. NO ConcatenatingAudioSource.
* Storage: Show metadata cached in Hive boxes (`hive` + `hive_flutter`).
* Data source: `assets/data/output.optimized_src.json` — read-once on first run, loaded into Hive.
* Platform note: Hive runs on all native targets (Android phone + Android TV). No platform split needed.""",

    "docs/web_audio_architecture_spec.md": """\
<!-- Path: docs/web_audio_architecture_spec.md -->
# Web Audio Architecture
* Engines: Web Audio (Gapless) and Relisten (HTML5).
* Orchestrator: Hybrid handoff for instant-start latency-free playback.""",

    "docs/agent_architecture.md": """\
<!-- Path: docs/agent_architecture.md -->
# Antigravity Agent Architecture: GDAR Setup
* .agent/rules/: Behavioral triggers (How).
* .agent/specs/: Technical Blueprints (What).
* docs/: High-level guides (Why).
* .agent/notes/: Transient logs (Now).""",

    "docs/project_structure_map.md": """\
<!-- Path: docs/project_structure_map.md -->

# GDAR Project Structure & Directory Map

## 1. Documentation (`docs/`)
* `docs/agents.md`: Senior Developer persona.
* `docs/guide.md`: General setup guides.
* `docs/dev_environment.md`: Windows 10 + ChromeOS (Crostini) setup and cross-platform gotchas.
* `docs/data_schema.md`: `output.optimized_src.json` structure.
* `docs/shows.schema.json`: JSON Schema for the data file (static, not snapshotted).
* `docs/project_structure_map.md`: (This file)

## 2. Cross-Platform Config (root + .vscode/, static — not snapshotted)
* `.editorconfig`: LF line endings, 2-space indent for Dart/YAML.
* `.gitattributes`: Future-commits LF safety. Non-destructive if Git already works.
* `.vscode/launch.json`: Debug configurations (gdar, profile, release).
* `.vscode/settings.json`: Format on save, ruler at 80, LF, git.autofetch, Crostini terminal, excludes build dirs.

## 3. Agent Blueprints (.agent/specs/)
* `.agent/specs/mobile_standard.md`
* `.agent/specs/tv_standard.md`
* `.agent/specs/web_fruit_standard.md`
* `.agent/specs/audio_native.md`
* `.agent/specs/audio_web.md`

## 4. Agent Guardrails (.agent/rules/)
* `.agent/rules/gemini.md`
* `.agent/rules/global_guardrails.md`
* `.agent/rules/screensaver.md`
* `.agent/rules/android_theme.md`
* `.agent/rules/fruit_theme.md`
* `.agent/rules/phone_platform.md`
* `.agent/rules/tv_ui_flow.md`
* `.agent/rules/phone_ui_flow.md`
* `.agent/rules/native_audio.md`
* `.agent/rules/web_audio.md`

## 5. Agent Skills (.agent/skills/)
* `.agent/skills/shipit.md`

## 6. Active Workspace & Root Files
* `todo.md`: (Primary Task List - Root)
* `CHANGELOG.md`: (Project History - Root)
* `.agent/notes/progress_log.md`
* `.agent/notes/scratchpad.md`
* `.agent/notes/pending_release.md`

---
*Version: 1.7* *Last Updated: 2026-03-03*""",

    "docs/final_manifest.md": """\
<!-- Path: docs/final_manifest.md -->
# Final Project Manifest
Master list of the agentic environment setup for GDAR.""",

    # JSON schema — static doc asset, excluded from snapshot
    "docs/shows.schema.json": """{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "title": "Concert Archive Schema",
  "description": "Schema for output.optimized_src.json — read-once, loaded into Hive on first run.",
  "type": "array",
  "items": {
    "type": "object",
    "properties": {
      "name": {"type": "string", "description": "Artist or event name."},
      "date": {"type": "string", "format": "date", "description": "Concert date YYYY-MM-DD."},
      "l":    {"type": "string", "description": "Location of the concert."},
      "sources": {
        "type": "array",
        "description": "Audio sources/recordings for this concert.",
        "items": {
          "type": "object",
          "properties": {
            "id":  {"type": "string", "description": "Unique recording identifier (SHNID)."},
            "_d":  {"type": "string", "description": "Internal directory ID."},
            "src": {"type": "string", "description": "Source type e.g. sbd, aud."},
            "sets": {
              "type": "array",
              "description": "Sets played during the concert.",
              "items": {
                "type": "object",
                "properties": {
                  "n": {"type": "string",  "description": "Set name e.g. Set 1."},
                  "t": {
                    "type": "array",
                    "description": "Tracks in this set.",
                    "items": {
                      "type": "object",
                      "properties": {
                        "n": {"type": "integer", "description": "Track number."},
                        "t": {"type": "string",  "description": "Track title."},
                        "d": {"type": "integer", "description": "Duration in seconds."},
                        "u": {"type": "string",  "description": "Audio filename or URL."}
                      },
                      "required": ["n", "t", "d", "u"]
                    }
                  }
                },
                "required": ["n", "t"]
              }
            }
          },
          "required": ["id", "_d", "src", "sets"]
        }
      }
    },
    "required": ["name", "date", "l", "sources"]
  }
}""",

    # ══════════════════════════════════════════════════════════════════════
    # AGENT SPECS (.agent/specs/) — on-demand technical blueprints
    # ══════════════════════════════════════════════════════════════════════

    ".agent/specs/mobile_standard.md": """\
<!-- Path: .agent/specs/mobile_standard.md -->

# Technical Blueprint: Mobile Standard (Native Phone/Tablet)

## 1. Visual Standard: Material 3 Expressive
* **Core:** Material 3 baseline, organic ripples.
* **Surfaces:** Elevation shadows only. 🚫 NO blurs or neumorphism.

## 2. Hardware & OS Constraints
* **Thumb Zone:** Primary controls in bottom 40%.
* **Haptics:** Required. Light click/Medium/Vibrate.

## 3. Navigation & Interaction Flow
* **Stack:** ShowList -> TrackList.
* **Context:** Persistent `SlidingUpPanel (sliding_up_panel ^2.0.0)`.

*Version: 1.0* *Last Updated: 2026-03-03*""",

    ".agent/specs/tv_standard.md": """\
<!-- Path: .agent/specs/tv_standard.md -->

# Technical Blueprint: TV Standard (Google TV / Android TV)

## 1. Visual Standard: Material Dark (OLED Optimized)
* **Colors:** True Black background, Blue accents.
* **Scaling:** 1.35x Global boost.

## 2. D-Pad & Focus Management
* **Focus Wrapper:** 1.05x scale + glow border.
* **Inactive State:** Unfocused panes dimmed to 0.2.
* **Feedback:** 🚫 NO haptics or organic ripples.

## 3. Persistent Layout (Dual-Pane)
* **Architecture:** Persistent 60/40 split.

*Version: 1.0* *Last Updated: 2026-03-03*""",

    ".agent/specs/web_fruit_standard.md": """\
<!-- Path: .agent/specs/web_fruit_standard.md -->

# Technical Blueprint: Web & Fruit Standard (PWA/Desktop)

## 1. Visual Standard: Fruit (Liquid Glass)
* **Translucency:** `BackdropFilter` (sigma 15.0).
* **Tactility:** Neumorphic shadow offsets.
* **Motion:** Apple-style spring physics.

## 2. Web Layout & Responsiveness
* **Breakpoint:** 768px.
* **Desktop:** 1.01x hover scale, click cursors.

## 3. Audio Engine Orchestration (Hybrid)
* **Startup:** Relisten (HTML5).
* **Handoff:** Transitions to Web Audio once decoded.

*Version: 1.0* *Last Updated: 2026-03-03*""",

    ".agent/specs/audio_native.md": """\
<!-- Path: .agent/specs/audio_native.md -->

# Technical Blueprint: Native Audio Architecture

## 1. Engine Core
* **Provider:** `AudioProvider` wrapping `just_audio` + `just_audio_background`.
* **Queue:** Flattened `AudioSource` sequence. 🚫 NO `ConcatenatingAudioSource`.

## 2. Configuration & Logic
* **Gapless:** Default 'gapless' (0ms handoff).
* **Buffer Agent:** Monitors stall conditions.
* **Offline Buffering:** Optional 5-track pre-fetch.
* **Storage:** Hive — shared across phone and TV (same Android target, no split needed).

*Version: 1.0* *Last Updated: 2026-03-03*""",

    ".agent/specs/audio_web.md": """\
<!-- Path: .agent/specs/audio_web.md -->

# Technical Blueprint: Web Audio Engine Architecture

## 1. The Isolation Doctrine
* Engines [1]-[4] independent of Hybrid orchestrator.

## 2. Engine Specifications
* **[1] Web Audio:** 0ms gapless, crossfade support.
* **[2] Relisten:** 🚫 NO refactor to ReadableStream.
* **[5] Hybrid:** Orchestrator with isolated background processor.

*Version: 1.0* *Last Updated: 2026-03-03*""",

    # ══════════════════════════════════════════════════════════════════════
    # AGENT RULES (.agent/rules/) — always-loaded behavioral guardrails
    # ══════════════════════════════════════════════════════════════════════

    ".agent/rules/gemini.md": """\
---
trigger: always_on
policy_domain: Global Standards
---
# Project Rules: GDAR Audio Player

### Coding & Architecture
* **Action:** Use Latest Stable Flutter / Dart SDK at all times.
* **Action:** Enforce Clean Architecture — UI → Logic → Data. No layer bleeding.
* **Action:** Use `.withValues()` for all color APIs. Format to line length 80.
* **Constraint:** Never let the UI layer import directly from the Data layer.

### Release Management
* **Action:** Write all release history to root `CHANGELOG.md` using Keep a Changelog format.
* **Action:** Stage pending notes in `.agent/notes/pending_release.md` before running shipit.
* **Constraint:** Never write to `docs/RELEASE_NOTES.txt`. That file is legacy and retired.""",

    ".agent/rules/global_guardrails.md": """\
---
trigger: always_on
policy_domain: Efficiency & Safety
---
# Efficiency Guardrails

### File Modification Safety
* **Action:** Stop and ask the user before modifying any existing file.
* **Action:** Output complete files only — no partial diffs, no placeholders.
* **Constraint:** Never bundle unrelated changes in a single response.

### Autonomous Exception
* **Action:** When the `shipit` keyword is detected, proceed autonomously through the full release workflow.""",

    ".agent/rules/screensaver.md": """\
---
trigger: tv, screensaver, focus
policy_domain: TV Screensaver
---
# TV Screensaver Directives

### Implementation
* **Action:** Always read `docs/tv_screensaver_spec.md` before touching screensaver code — all variable names are defined there.
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
* **Constraint:** Never apply Fruit theme to mobile or TV. Web and PWA only — this wall is absolute.""",

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

    ".agent/rules/phone_ui_flow.md": """\
---
trigger: mobile, phone, flow, navigation
policy_domain: Mobile Navigation
---
# Phone UI Flow Directives

### Navigation
* **Action:** Use a linear Navigator stack: ShowListScreen → TrackListScreen.
* **Action:** Use SlidingUpPanel (sliding_up_panel ^2.0.0) as the persistent playback overlay.
* **Constraint:** Never use nested navigators on mobile.
* **Constraint:** Never apply Fruit/Liquid Glass theme on any mobile screen.""",

    ".agent/rules/native_audio.md": """\
---
trigger: audio, native, background, queue
policy_domain: Native Audio
---
# Native Audio Directives

### Engine & Queue
* **Action:** Use a flattened AudioSource list for all queue management.
* **Action:** Implement just_audio_background for background awareness and foreground service on Android.
* **Action:** Sync track metadata to the OS media controller on every track change.
* **Action:** Use Hive for show metadata cache on all native targets (phone and TV share the same build).
* **Constraint:** Never use ConcatenatingAudioSource under any circumstances.""",

    ".agent/rules/web_audio.md": """\
---
trigger: audio, web, worker, engine
policy_domain: Web Audio
---
# Web Audio Directives

### Engine Architecture
* **Action:** Use an isolated AudioWorklet worker for the Web Audio engine — never on the main thread.
* **Action:** Implement HybridAudioOrchestrator for seamless Engine 1 → Engine 2 handoff.
* **Constraint:** Never refactor the Relisten engine to use ReadableStream.
* **Constraint:** Never share an AudioContext across tracks.""",

    # ══════════════════════════════════════════════════════════════════════
    # AGENT SKILLS (.agent/skills/)
    # ══════════════════════════════════════════════════════════════════════

    ".agent/skills/shipit.md": """\
<!-- Path: .agent/skills/shipit.md -->
# Shipit Skill: GDAR Production Release
**TRIGGERS:** shipit, release, prod, deploy
1. Bump version in `pubspec.yaml`.
2. Finalize Changelog from `pending_release.md` to `CHANGELOG.md`.
3. Build release and push to git.""",

    # ══════════════════════════════════════════════════════════════════════
    # NOTES — transient workspace files (generated with live timestamps)
    # ══════════════════════════════════════════════════════════════════════

    ".agent/notes/pending_release.md": """\
<!-- Path: .agent/notes/pending_release.md -->
# Pending Release Notes
### Added
-
### Changed
-
### Fixed
- """,

    ".agent/notes/scratchpad.md": """\
<!-- Path: .agent/notes/scratchpad.md -->
# Scratchpad & Ideas""",
}


# ── Transient files: generated with live timestamp ────────────────────────────

def _transient_files() -> dict[str, str]:
    now = datetime.now().isoformat()
    return {
        ".agent/notes/progress_log.md": (
            f"<!-- Path: .agent/notes/progress_log.md -->\n"
            f"# Progress Log\n"
            f"* {now}: Setup script v{__version__} applied.\n"
        ),
        ".agent/notes/shipit_workflow.md": (
            "<!-- Path: .agent/notes/shipit_workflow.md -->\n"
            "# Shipit Workflow (Updated v1.1)\n"
            "* Automation protocol for versioning and changelog finalization.\n"
        ),
    }


# ── Scaffold Clean Architecture dirs ──────────────────────────────────────────

def _scaffold_dirs() -> None:
    """Create lib/ Clean Architecture folders if absent. Safe to re-run."""
    dirs = ["lib/core", "lib/features", "lib/data", "lib/ui"]
    created = []
    for d in dirs:
        path = Path(d)
        path.mkdir(parents=True, exist_ok=True)
        gitkeep = path / ".gitkeep"
        if not gitkeep.exists():
            gitkeep.touch()
            created.append(d)
    if created:
        print(f"  🏗️  Scaffolded : {', '.join(created)}")


# ── Snapshot mode: read disk → print updated PROJECT_FILES ────────────────────

def _snapshot(root: Path) -> None:
    SKIP_DIRS = {
        ".dart_tool", ".firebase", ".idea", ".vscode",
        "build", ".git", "android", "ios", "fonts", "assets",
    }
    # Only snapshot .md files. All other assets (JSON, .editorconfig,
    # .gitattributes, .vscode/) are static and managed in PROJECT_FILES directly.
    collected: dict[str, str] = {}
    for path in sorted(root.rglob("*.md")):
        if set(path.parts) & SKIP_DIRS:
            continue
        key = str(path.relative_to(root))
        collected[key] = path.read_text(encoding="utf-8")

    print('PROJECT_FILES: dict[str, str] = {')
    for key, content in collected.items():
        safe = content.replace('"""', "'''")
        print(f'\n    "{key}": """\\\n{textwrap.indent(safe.rstrip(), "")}\n""",')
    print("}")
    print(f"\n# {len(collected)} .md files captured from {root}", file=sys.stderr)
    print(
        "# Static assets excluded from snapshot:\n"
        "#   docs/shows.schema.json, .editorconfig, .gitattributes,\n"
        "#   .vscode/launch.json, .vscode/settings.json\n"
        "# Edit these directly in PROJECT_FILES.",
        file=sys.stderr,
    )


# ── Legacy migration: RELEASE_NOTES.txt → CHANGELOG.md ───────────────────────

def _migrate_legacy(root: Path) -> str | None:
    """
    One-time migration tasks run before writing new files.
    Returns legacy RELEASE_NOTES content if found, else None.
    Caller is responsible for merging into CHANGELOG — no global mutation.
    Safe to re-run: each guard checks for existence first.
    """
    legacy_notes = root / "docs" / "RELEASE_NOTES.txt"
    root_guide   = root / "guide.md"
    timestamp    = datetime.now().strftime("%Y%m%d%H%M%S")
    legacy_content: str | None = None

    if legacy_notes.exists():
        bak = legacy_notes.with_name(f"{legacy_notes.stem}_{timestamp}.bak")
        shutil.copy2(legacy_notes, bak)
        print(f"  📦 Backed up  : {legacy_notes.relative_to(root)} → {bak.name}")

        legacy_content = legacy_notes.read_text(encoding="utf-8")
        line_count = len(legacy_content.splitlines())
        migrated = legacy_notes.with_suffix(".migrated")
        legacy_notes.rename(migrated)
        print(f"  🚀 Migrated   : {line_count} lines captured for CHANGELOG.md")
        print(f"  💾 Archived   : {legacy_notes.name} → {migrated.name}")

    if root_guide.exists():
        bak = root_guide.with_name(f"guide_{timestamp}.md.bak")
        root_guide.rename(bak)
        print(f"  📦 Backed up  : {root_guide.name} → {bak.name}")

    return legacy_content


# ── Apply mode: backup existing → write new ───────────────────────────────────

def _apply(*, dry_run: bool, scaffold: bool = False) -> None:
    # Build a local working copy — PROJECT_FILES is never mutated
    all_files = {**PROJECT_FILES, **_transient_files()}
    written:   list[str] = []
    backed_up: list[str] = []
    errors:    list[str] = []

    label = "[DRY RUN] " if dry_run else ""
    print(f"🚀 {label}GDAR Setup v{__version__} — {len(all_files)} files\n")

    if not dry_run:
        legacy_content = _migrate_legacy(Path("."))
        # Merge legacy notes into local copy only — PROJECT_FILES stays pure
        if legacy_content:
            all_files["CHANGELOG.md"] += f"\n```text\n{legacy_content}\n```\n"
        print()

    for filepath, content in all_files.items():
        path = Path(filepath)

        if dry_run:
            note = " (would backup first)" if path.exists() else ""
            print(f"  [DRY RUN] {filepath}{note}")
            written.append(filepath)
            continue

        try:
            path.parent.mkdir(parents=True, exist_ok=True)
            if path.exists():
                timestamp = datetime.now().strftime("%Y%m%d%H%M%S")
                bak = path.with_name(f"{path.stem}_{timestamp}.bak")
                path.rename(bak)
                print(f"  💾 {filepath} → {bak.name}")
                backed_up.append(filepath)
            path.write_text(content.strip() + "\n", encoding="utf-8")
            print(f"  ✅ {filepath}")
            written.append(filepath)
        except OSError as exc:
            print(f"  ❌ {filepath} — {exc}")
            errors.append(filepath)

    if scaffold and not dry_run:
        _scaffold_dirs()

    print(f"\n{'─' * 50}")
    print(f"  Written   : {len(written)}")
    if backed_up:
        print(f"  Backed up : {len(backed_up)}")
    if errors:
        print(f"  Errors    : {len(errors)}")
    print(f"\n{'✨ Done.' if not errors else '⚠️  Completed with errors.'}")
    if errors:
        sys.exit(1)


# ── CLI ───────────────────────────────────────────────────────────────────────

def _parse() -> argparse.Namespace:
    p = argparse.ArgumentParser(description=f"GDAR workspace setup v{__version__}")
    p.add_argument("--dry-run", action="store_true",
                   help="Preview what would be written without touching disk.")
    p.add_argument("--snapshot", action="store_true",
                   help="Scan live project and print updated PROJECT_FILES (.md only).")
    p.add_argument("--root", default=".", metavar="DIR",
                   help="Project root for --snapshot (default: current dir).")
    p.add_argument("--scaffold", "--init", action="store_true",
                   help="Scaffold lib/ Clean Architecture dirs.")
    return p.parse_args()


if __name__ == "__main__":
    args = _parse()
    if args.snapshot:
        _snapshot(Path(args.root))
    else:
        _apply(dry_run=args.dry_run, scaffold=args.scaffold)