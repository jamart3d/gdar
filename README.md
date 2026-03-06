# Shakedown

A Flutter application for browsing and playing concert recordings of the Grateful Dead from archives.

## Features

- Browse a list of shows and their recordings.
- **Advanced Playback**:
  - Dedicated playback screen with set list support (Set 1, Set 2, Encore).
  - Persistent mini-player for audio controls while browsing.
  - Random playback options: Play random show on startup/completion, filter by unplayed or high-rated shows.
  - **Offline Buffering**: Pre-cache entire shows for uninterrupted playback during deep sleep or poor connectivity.
  - **Buffer Agent**: Intelligent playback recovery that automatically detects and recovers from network issues and buffering failures.
  - **Premium Web Gapless**: A custom JavaScript-based audio engine for Web and PWA platforms, ensuring precise 0ms transitions by bypassing browser limitations.

- **Multi-Platform Optimization**:
  - **Google TV & Android TV**: Optimized dual-pane layout for large screens with full D-pad navigation support.
  - **Premium Web UI**: Desktop-class interface with resizable panels, keyboard shortcuts, and intelligent state restoration.
  - **PWA (Progressive Web App)**: Installable on Mobile/Desktop browsers for a native-like experience with offline caching, background media session integration, and standalone window modes.
  - **Glassmorphism UI**: High-end translucent design language that adapts across mobile, web, and TV.

- **Clipboard Playback**:
  - **Instant Playback**: Paste an Archive.org share link into the **search field** to instantly trigger playback.
  - Seamlessly parses SHNIDs and track names to start playback instantly.
- **Collection Management**:
  - Rate shows (1-3 stars) or block them (Red star).
  - Block specific sources (SHNIDs) for multi-source shows by swiping left on the source item.
  - **Rated Shows Library**: View and manage shows filtered by rating (including blocked shows).
  - Track played/unplayed status.
  - Sort shows by date (Oldest First / Newest First).
- **Rich Details**:
  - View track details, sources, and SHNID badges.
  - Direct links to Archive.org for source details.
  - **Copy**: Copy show/track info to clipboard from the **open player** in the playback screen.
- **Customization**:
  - Light and Dark theme support with dynamic color options.
  - **True Black Mode**: Pitch black backgrounds for OLED screens.
  - **Glow Effects**: Adjustable glow intensity for the playback card, adding a premium feel.
  - **Oil Slide Screensaver**: 
    - A high-art, psychedelic visualizer that activates during inactivity. Detailed settings and reactivity logic can be found in the [Screensaver Manual](docs/SCREENSAVER_MANUAL.md).
    - **Visual Styles**: Choose between **Standard (Psychedelic)**, **Lava Lamp**, and **Silk** modes.
    - **Customization**: Adjust viscosity, flow speed, and palettes.
    - **Audio Reactivity**: The visualizer pulses and reacts to the music's frequency and intensity.

  - **Fruit Theme (Premium)**:
    - Dedicated Apple-inspired design for Web/PWA with **14px** architectural corner radii.
    - **Apple Liquid Glass**: High-precision backdrop blurring paired with a subtle internal highlight (inset glow) that simulates glassy refraction.
    - **Pervasive Neumorphism (Soft UI)**: A complete, non-Material 3 design language. UI elements adopt a soft, extruded look using light and shadow.
    - **Tactile Bottom Sheet**: The playback panel features soft, deep Neumorphic shadows at its top edge and a sunken "handle basin" carved into the glass for a premium tactile drag experience.
    - **Interactive Styles**: Choose between **Convex** (standard extrusion) and **Concave** (sunken look) via Appearance settings.
  - **Accessibility**: Semantic labels for screen readers.
  - **Hide Track Duration** option for a minimalist interface.
  - **Global UI Scale**: Consistent text scaling across all screens. Automatically synchronizes date abbreviations (Day/Month) for optimal space usage when toggled.
  - **Font Selection**: Choose from 3 curated handwriting fonts (Caveat, Permanent Marker, Rock Salt).
- **Enhanced UX**:
  - **Smart Rating Dialog**: Toggle "Played" status, confirmation dialogs for safety, and mutually exclusive rating/blocking logic.
  - **Expressive Swipe to Block**: Polished Material 3 design for blocking shows/sources.
  - **Single Source Cleanliness**: Simplified view for shows with only one source.
  - **Rated Shows Library**: Dynamic counts on tabs (e.g., "Played (5)") and easier navigation.
  - **Smart Random**: Manual triggers respect search filters; automated playback picks from the full library to keep music fresh.
  - **Refined Settings**: Dedicated "Random Playback" section and clearer usage instructions with improved typography.
  - **Source-Only Blocking**: Blocking now applies specifically to Source IDs rather than the entire Show, allowing for finer curation.
  - **Native-Level Gapless**: Playback engine rewritten to use `ConcatenatingAudioSource` for true, precise gapless transitions on Mobile.
  - **JS-Interoperability (Web)**: Custom integration bridge between Flutter and a high-performance JavaScript audio scheduler for the Web.
  - **Haptic Feedback**: Premium tactile feedback on all interactive elements for enhanced touch experience.
  - **Material 3 Transitions**: Expressive navigation animations with scale + fade effects for a polished, premium feel.

## Usage Guide

### **Player Controls**

- **Mini-Player**: Appears at the bottom of the screen while browsing. Tap to expand to the full Playback Screen.
- **Playback Screen**:
  - **Single Tap**: Toggle Play/Pause.
  - **Double Tap**: Like/Like+ (Cycle through ratings: 1 star → 2 stars → 3 stars).
  - **Long Press**: Show details/Expand specialized controls.
  - **Swipe Down**: Collapse to Mini-Player.
- **Show List**:
  - **Tap**: View track list (or expand show if multiple sources exist).
  - **Long Press**: Play randomly (or play specific source if expanded).
  - **Swipe Left**: Quick block (Red Star).

### **Settings**

Access settings via the gear icon in the top app bar.

- **Appearance**: Toggle **Dark Mode**, **True Black Mode** (for OLED), **Dynamic Color** (Material You), and **Handwriting Font**.
- **Playback**:
  - **Audio Engine (Web)**: Choose between Hybrid (Recommended), Web Audio (Pure Gapless), Relisten (HTML5), or Passive Streaming.
  - **Engine Subsettings**: Fine-tune crossfade durations (0-10s), transition modes (Gapless/Crossfade/Gap), and background survival strategies (Video/Heartbeat/Relisten).
  - **Offline Buffering**: Pre-cache shows for uninterrupted playback.
  - **Buffer Agent**: Automatic recovery from network issues.
  - **Random Playback**: Configure behavior for the random shuffle button.
- **Interface**:
  - **UI Scale**: Adjust text size globally.
  - **Show Single SHNID**: Toggle visibility of SHNID badges for single-source shows.
- **Source Filtering**:
  - **Categories**: Filter sources by type (Matrix, SBD, Betty Board, Audience, etc.).
  - **Solo Mode**: **Long press** a filter category chip to solo it (active) and disable all others.

### **Random Selection Logic**

- **Manual Random (Dice)**: Tap the **animated dice icon** in the app bar. It spins and changes faces to indicate selection, respecting your current search query and filters.
- **Auto-Play Random**: When a show finishes, the app creates a "radio" experience by picking a new random show. This mode **ignores** current search filters to select from your entire library, ensuring variety.
- **Non-Random (Chronological)**: Toggle this in Settings to play shows in sequential order (based on list sort) instead of randomly. Great for listening through a tour or year.
- **Exclusions**: Blocked shows (Red Star) are **never** selected.

## Project Structure

The project's code and documentation are organized as follows:

- **`lib/`**: Contains the core Dart application code.
  - **`models/`**: Defines the data structures for shows, sources, tracks, and ratings.
  - **`providers/`**: Manages the application's state (e.g., audio playback, show lists, settings).
  - **`services/`**: Core data services, including the **Hybrid Catalog Service** (JSON parsing + Hive storage).
  - **`ui/`**: Contains the user interface code, separated into `screens/` and `widgets/`.
  - **`utils/`**: Includes utility functions, theme definitions, and other shared resources.
- **`.agent/specs/`**: Contains detailed architectural and design specifications. **Note:** UI specifications are organized by feature (e.g., Player, Browse Flow) rather than platform to maintain consistency across Web, Phone, and TV. The "Fruit" theme overrides (`fruit_theme_spec.md`) serve as the single source of truth for Liquid Glass styling.
- **`todo.md`**: Centralized task tracking for upcoming refactors and spec consolidations.

## Technical Architecture

**Hybrid Data & Persistence**
To balance app size with performance and robust user data storage, Shakedown utilizes a hybrid approach:

- **Show Catalog (JSON)**: The concert database is loaded from stored compressed JSON (`assets/data/output.optimized_src.json`) into memory at startup. This avoids the overhead of a large pre-built database file, keeping the APK/AAB size small (~15MB). Background isolates (`compute()`) prevent UI jank during this loading process.
- **User Data (Hive)**: User-generated content like **Ratings**, **Blocked Shows/Sources**, and **Played Status** is stored in a dedicated **Hive** box (`ratings`). This ensures fast, persistent, and efficient local storage for your personal collection data without modifying the read-only catalog.
- **Service Layer**: A unified `CatalogService` orchestrates this split, providing synchronous access to the in-memory show list while managing asynchronous Hive operations for user state.

## Building & Release

To build a release-ready Android App Bundle (AAB) for the Google Play Store, use the following commands:

```bash
# 1. Clean the project
flutter clean

# 2. Build the signed App Bundle
flutter build appbundle --release
```

The output file will be located at:  
`build/app/outputs/bundle/release/app-release.aab`

## Testing & Debugging

### **Deep Link Reference**
The app supports a wide range of deep links for testing and automation. Use `adb shell am start -W -a android.intent.action.VIEW -d "URI" com.jamart3d.shakedown` to trigger them.

| Feature | URI Scheme (`shakedown://`) | Parameters | Description |
| :--- | :--- | :--- | :--- |
| **Play Random** | `play-random` | None | Immediately plays a random show (respects search filters). |
| **Navigation** | `navigate` | `screen` | Navigate to specific screens: `home`, `settings`, `splash`, `onboarding`, `player`, `track_list`. |
| | | `action` (for home) | `search` (opens search bar), `close_search`. |
| | | `highlight` (for settings) | Highlights a specific setting key (e.g., `offline_buffering`). |
| | | `panel` (for player) | `open` (starts with panel expanded). |
| | | `index` (for track_list) | Index of the show to open from the current list (e.g., `0`). |
| **Player Control** | `player` | `action` | `play`, `pause`, `resume`, `stop` (clears queue). |
| **Settings** | `settings` | `key`, `value` | Toggle settings directly. Keys: `show_playback_messages`, `show_splash_screen`. |
| **Debug Tools** | `debug` | `action` | `reset_prefs` (factory reset settings), `complete_onboarding`, `show_font_dialog`. |
| **Font Test** | `font` | `name` | Force switch font: `caveat`, `permanent_marker`, `rock_salt`, `default`. |
| **UI Scale** | `ui-scale` | `enabled` | `true`/`false` to toggle UI scaling. |
| **Debug Update** | `debug` | `action` | `simulate_update` (Test the Update Banner). |

#### **Example Commands**
```bash
# Play a random show
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://play-random" com.jamart3d.shakedown

# Open Settings and highlight 'Advanced Cache'
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://navigate?screen=settings&highlight=offline_buffering" com.jamart3d.shakedown

# Pause Playback
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://player?action=pause" com.jamart3d.shakedown

# Force UI Scale ON
adb shell am start -W -a android.intent.action.VIEW -d "shakedown://ui-scale?enabled=true" com.jamart3d.shakedown
```


## Background Playback Audit (Jan 2026)

The application is **correctly configured** for standard background audio playback on Android 14+.

- **Configuration**: Excellent (Manifest and Services are correct).
- **Gapless Playback**: Excellent (Handled natively on Mobile, high-performance JS scheduler on Web).
- **Deep Sleep Stability**: **Fixed**. Implemented "Native Pre-Queueing" where the next show is queued into the native player buffer at the start of the last track. This ensures continuous playback even if the Flutter UI isolate is suspended by Android's Doze mode.

## Web & PWA Optimization (Feb 2026)

The web version is now a full Progressive Web App (PWA) with a custom, high-performance audio engine suite.

- **Audio Engine Suite**: A selectable array of engines tailored for the web wrapper:
  - **Hybrid (Default)**: Orchestrates an isolated HTML5 fallback (`hybrid_html5_engine.js`) for 0ms initial latency (Instant Start) and seamlessly hands off to the Web Audio engine `immediate`ly upon decoding for strict gapless transitions.
  - **Web Audio**: Pure `AudioBufferSourceNode` scheduling bypassing browser decode latencies entirely.
  - **Relisten**: A robust, battery-friendly HTML5 port.
- **Background Survival**: Aggressive anti-suspension trickery (`video` looping, `heartbeat` workers) to ensure Web Audio contexts survive screen locks and backgrounding on iOS/Android browsers.
- **Media Session API**: Full integration with browser/OS media controls (Play/Pause/Skip) and "Now Playing" metadata.
- **Installable**: Full manifest support for "Add to Home Screen" on iOS, Android, and desktop Chrome/Edge/Safari.

## TV Experience (Feb 2026)

- **Focus Management**: Deeply customized D-pad navigation logic to ensure natural movement. Includes stale-node pruning and focus-persistence guards to prevent focus "ghosting" during rapid pane switching.
- **Premium TV Highlight**: A high-intensity RGB rainbow glow effect for the actively focused item, with specialized logic to prevent "glow theft" by the currently playing track.
- **Auto-Scrolling**: Intelligent visibility guards in the Show List and Track List that automatically scroll the view to keep the focused item comfortably within the viewport (30% margin).
- **Inactivity Handling**: Automatic screensaver activation with a "Ghost Menu" accessible via D-pad for quick visual adjustments.

## Developer Tooling

For maximum productivity, this repository is optimized for the following high-performance CLI tools:
- **ripgrep (`rg`)**: Lightning-fast code searching.
- **fd (`fdfind`)**: Rapid file finding that respects `.gitignore`.
- **jq**: Powerful JSON processor for inspecting large source data.
- **fzf**: Fuzzy finder for navigating files and shell history.
- **bat (`batcat`)**: Syntax-highlighted `cat` for clearer code reading.

Detailed setup instructions for both Windows and Linux can be found in [AGENT_ENVIRONMENT.md](docs/AGENT_ENVIRONMENT.md).

## Repository Auditing (Jules)
This repository is optimized for high-performance auditing via **Jules** (`jules.google.com`). These cloud-based audits are exploratory and visual, complementing our local deterministic tests. Specialized audit prompts are located in `test/prompts/`.

### **How to Run Audits**
Direct Jules to the following file for a 100% comprehensive system check:

1. **Universal Master Audit (Single Run)**:
   > "Perform the **Master Release Audit** located in `test/prompts/master_audit.md` and provide a detailed PASS/FAIL report."

---
*Legacy/Specialized Audits (Available if needed for isolated debugging):*
- `jules_audit.md` (Audio Only)
- `jules_fruit_audit.md` (Web Aesthetics Only)
- `jules_integrity_audit.md` (Persistence Only)
- `jules_platform_guard_audit.md` (Cross-platform Architecture Only)

> [!TIP]
> **Jules Token Efficiency**: Providing an **Auth Token** (via CLI, Web interface, or environment configuration) is the high-performance path for all auditing. It is significantly more efficient for managing high-frequency concurrent audits and is required for the "Headless Chrome" stress-tests defined in the Master Audit.

### **Automated Health & Unit Testing (`@[/checkup]`)**
**Arlo** (your local Antigravity agent) can autonomously maintain repository health by running the specialized `@[/checkup]` workflow. This covers:
- **Unit Testing**: Runs `flutter test` on relevant changed files. **(Arlo handles < 5 files locally; Larger runs or full suites are handed off to Jules to save tokens).**
- **Linting & Formatting**: Automatically fixes style violations and standardizes code.
- **Static Analysis**: Identifies potential runtime errors or deprecated API usage.

**To trigger a targeted local check (Small Tasks):**
> "Run the `@[/checkup]` workflow on the current branch."

**To trigger a Full High-Volume Test (Large Tasks):**
> "Run all tests via Jules (jules new 'Run all tests')."

