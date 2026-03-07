# myapp — Open TODO Items

> Consolidated from `todo.md`, `TODO_TV_UI.md`, `WEB_GAPLESS_TODO.md`, and `TODO_position_jump_debug.md`.
> Originals archived to `reports/archive/`.

---

## 🖥️ Google TV

### High Priority
- [x] **Pane Navigation Polish**: "Switch Pane" shortcut (Tab/S), Back-to-master navigation, and dimming visual indicators for inactive panes.
- [x] **Track List Entry Transition**: Fix the "bounce scroll" glitch when entering the track list; ensure the initial scroll to the currently playing track is anchored and doesn't visually jitter.
- [x] **Settings Two-Pane Layout**: Redesign Settings screen for 16:9 using a Master-Detail pattern.

### Performance & Optimization
- [x] **Neon Glow Optimization**: Implement Rasterized Glyph Cache for `StealBanner`. Real-time Gaussian blurs were replaced with optimized static rasterization.
- [x] **App Size Audit**: Initialized `size_guard` skill. Found 11.43MB assets; icons need optimization to WebP.

### Backlog / Low Priority
- [ ] **Default Screensaver Settings**: Fine-tune default visual style, speed, and performance mode for a premium out-of-the-box experience.
- [ ] **TV Safe Area**: Global setting to adjust margins for rare older panels with overscan/edge-cropping issues.
- [ ] **Screensaver Settings Polish**: Introduce an "Advanced Options" toggle in TV Settings to hide deep-tweak knobs and clean up D-pad navigation.
- [x] **Screensaver Text "Crawl" Investigation**: Individual letters in the show info text appear to crawl/jitter independently as they translate around with the logo. Investigate the cause (likely precision/rendering issue) and add a toggle to disable this behavior if desired.
- [ ] **Audio-Responsive Trails**: Tie Trail Intensity and Trail Blur directly to real-time audio `energy.overall` or `beatPulse` in the screensaver.
- [ ] **Audio-Driven Shader "Boiling"**: Tie `uOverall` to the `heatDrift`/`flowSpeed` uniforms in `steal.frag` so background dynamics match song intensity.

### Debug
- [x] **Logo Position Jump**: Diagnose visual jolt/reset every few minutes with audio reactivity off. Resolved via position-reset mitigation.
- [x] **Premium TV Highlight Flow**: When `oilTvPremiumHighlight` is ON, the right-side track list has unstable D-pad navigation — focus can loop back to the currently playing track. 
    - *Result*: Resolved via "Surgical Stabilization" (stable widget tree in `TvFocusWrapper`) and Safe-Zone Scrolling in `PlaybackScreen`.

### Future Ideas
- [ ] **Voice & Modern Search UX**: Optimize search overlay for large screens/keyboard and add voice capabilities ("Play shows from Winterland 1973" via Google Assistant).
- [ ] **Analog VU Meters**: Add a visualization option to display the audio bar graph as vintage analog needle meters (old-school high-end HiFi style).
- [ ] **Flutter GPU Investigation**: Explore `flutter_gpu` for higher-fidelity fluid simulation in the lava lamp screensaver.

---

## 🌐 Web / PWA

- [ ] **Fruit Style Settings**: Ensure first-time activation defaults to: Dense OFF, Glass ON, Simple OFF, Glow OFF, RGB OFF.
- [ ] **Fruit Style Playback Screen**: 
  - [ ] Lower the top header metadata info.
  - [ ] Implement marquee with horizontal fade for long Venue/Location text (Apple Glass style).
  - [ ] Implement regular glass list with play controls in the current track (no fancy sticking).
  - [ ] Now button on bottom tab bar should scroll current track back into view if offscreen.
- [ ] **Fruit Style Show List**: When not stacked, the current show should have the player to the left of the stars.
- [ ] **Fruit Style Rate Show Dialog**: Refresh dialog with glass style and themed stars; ensure compatibility with Simple Theme.
- [ ] **Fruit Style Glass SnackBar**: Implement floating "glass-morphic" notification pill with support for "Restart" and other actions.
- [ ] **Background Longevity**: Extend playback when tab is backgrounded/throttled.
  - [ ] Explore Silent Video looping or Web Workers for timer consistency.
  - [x] **Timer Drift Audit**: Added Phase 4 to `test/prompts/jules_audit.md` to audit `gapless_audio_engine.js` under 6x CPU throttling.
- [ ] **Bug — Track Skip on Buffer**: Engine skips next track if it isn't fully buffered when current track ends.
- [ ] **Mobile Preload Setting**: User setting to choose how many tracks to buffer/preload ahead (currently defaults to 1).
- [ ] **Playback Settings**: Investigate a short fade-in playback option (on start/resume) to reduce audio "popping".

---

## 📄 Spec & Documentation

- [x] **Centralize Theme Logic**: Documented that `kIsWeb` applies the "Fruit" theme, referencing `docs/fruit_theme_spec.md` as the styling source of truth. Logic is surgically gated in `ThemeProvider`.
 
 ---
 
 ## 🧪 Testing & Auditing
 
 - [x] **Consolidate Jules Audits**: Created [master_audit.md](file:///c:/Users/jeff/StudioProjects/gdar/test/prompts/master_audit.md) as the 100% comprehensive (Phases 1-7) pre-release standard.
 - [ ] **Port Widget Tests**: Convert remaining flakey unit tests into Jules E2E observation phases for 100% reliable coverage.
- [ ] **Politeness Policy**: Ensure all automated tests (Jules/Arlo) consistently use local mocks and never hit `archive.org` directly. Verify this isolation as part of the CI/CD pipeline.

---

## 🤖 Agent Tooling & Workflows

- [x] **PowerShell Pipe Workaround**: For Windows PowerShell agent execution, look into changing commands that use a pipe (`|`) to instead write output to a temporary file in `%TEMP%` and then read it, bypassing the shell's restricted pipe features.

---

## 🛠️ Generic Template Transformation

- [/] **Generalize Project Metadata**: Rename `gdar` → `myapp` in `pubspec.yaml`, `README.md`, and documentation.
- [ ] **Prune Domain Logic**: Remove project-specific audio engines, models, and heavy JSON datasets.
- [ ] **Preserve Agentic Core**: Extract and keep the "Single Source of Truth" rules (`.agent/rules`) and automation workflows.
- [ ] **Generalize Theme specs**: Update `fruit_theme_spec.md` and related UI specs to be project-agnostic while keeping the "Liquid Glass" experimentation layer.
- [ ] **Verify Multi-Target Baseline**: Ensure the generic template builds and runs on Chrome (Web), Android (Phone), and Android TV (10ft UI).
