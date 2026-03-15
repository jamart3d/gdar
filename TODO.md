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
- [ ] **Multi-Logo Swarm Mode**: Implement a "Swarm" mode to instance the logo across the screen. Use `drawImageRect` or `SpriteBatch` for high performance on Google TV 2020, disabling expensive blurs for secondary instances to maintain 60fps.
- [x] **Neon Glow Optimization**: Implement Rasterized Glyph Cache for `StealBanner`. Real-time Gaussian blurs were replaced with optimized static rasterization.
- [x] **App Size Audit**: Initialized `size_guard` skill. Found 11.43MB assets; icons need optimization to WebP.

### Backlog / Low Priority
- [ ] **Default Screensaver Settings**: Fine-tune default visual style, speed, and performance mode for a premium out-of-the-box experience.
- [ ] **TV Safe Area**: Global setting to adjust margins for rare older panels with overscan/edge-cropping issues.
- [ ] **Screensaver Settings Polish**: Introduce an "Advanced Options" toggle in TV Settings to hide deep-tweak knobs and clean up D-pad navigation.
- [x] **Screensaver Text "Crawl" Investigation**: Individual letters in the show info text appear to crawl/jitter independently as they translate around with the logo. Investigate the cause (likely precision/rendering issue) and add a toggle to disable this behavior if desired.
- [ ] **Audio-Responsive Trails**: Tie Trail Intensity and Trail Blur directly to real-time audio `energy.overall` or `beatPulse` in the screensaver.
- [ ] **Audio-Driven Shader "Boiling"**: Tie `uOverall` to the `heatDrift`/`flowSpeed` uniforms in `steal.frag` so background dynamics match song intensity.
- [ ] **Screensaver Auto-Transition Delay**: Add a setting to control the elapsed time before automatically playing the next show when the screensaver is active.

### Debug
- [x] **Logo Position Jump**: Diagnose visual jolt/reset every few minutes with audio reactivity off. Resolved via position-reset mitigation.
- [x] **Premium TV Highlight Flow**: When `oilTvPremiumHighlight` is ON, the right-side track list has unstable D-pad navigation — focus can loop back to the currently playing track. 
    - *Result*: Resolved via "Surgical Stabilization" (stable widget tree in `TvFocusWrapper`) and Safe-Zone Scrolling in `PlaybackScreen`.

### Future Ideas
- [ ] **Voice & Modern Search UX**: Optimize search overlay for large screens/keyboard and add voice capabilities ("Play shows from Winterland 1973" via Google Assistant).
- [ ] **Analog VU Meters**: Add a visualization option to display the audio bar graph as vintage analog needle meters (old-school high-end HiFi style).
- [ ] **Flutter GPU Investigation**: Explore `flutter_gpu` for higher-fidelity fluid simulation in the lava lamp screensaver.
- [ ] **Live Playlist (Session History)**: Implement a *Persistent* "Live Playlist" (storing the last 50 shows). 
    - **Spec:** Referenced in `docs/live_playlist_spec.md`.
    - **Logic:** Enable "Reverse-Show" navigation: going back from the first track of a show takes you to the last track of the *previous* show played.
    - **UX:** Added "Undo/History" capability: allow users to jump back to a previous track/position if they accidentally block a show or skip a favorite track.
    - **Persistence:** The list survives app restarts, allowing for multi-day session continuity via `SharedPreferences`.

### Monorepo Transition Cleanup
- [ ] **Prune Shadowed UI Components**: Audit `apps/gdar_tv/lib/ui/` for duplicate widgets and screens (e.g., `OnboardingScreen`, `SettingsScreen`, `SplashScreen`) that now reside in `packages/shakedown_core/`. Ensure the app target uses the core package versions to avoid architectural drift.

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
- [ ] **HUD Improvements**: Improve readability for smaller displays with a multi-mode HUD (Full, Mini, Micro) that cycles on tap. [cc6f95db]
- [ ] **Mobile Preload Setting**: User setting to choose how many tracks to buffer/preload ahead (currently defaults to 1).
- [ ] **Playback Settings**: Investigate a short fade-in playback option (on start/resume) to reduce audio "popping".
- [ ] **Web Audio Engine Wiring Cleanup**: Route hybrid/background/handoff runtime updates through active `AudioProvider.audioPlayer` only (avoid creating ad-hoc `GaplessPlayer()` in settings flows).
- [ ] **Hybrid Background Sync**: In `AudioProvider.update()`, sync `hybridBackgroundMode` to active player along with handoff mode.
- [ ] **Transition/Crossfade Contract**: Unify Dart/JS method naming and fully wire `trackTransitionMode` + `crossfadeDurationSeconds`; hide unsupported UI paths until complete.
- [ ] **Adaptive PWA Engine Profile**: Add first-run profile selection for modern vs older phones (`hybrid balanced` vs `html5 stability`).
- [ ] **Long Background Soak Test Matrix**: Validate hidden playback longevity per preset (`stability`, `balanced`, `maxGapless`) across modern and older mobile browsers.
- [ ] **UI Technical Debt Cleanup**:
- [x] **UI Technical Debt Cleanup**: Continue the pattern from `PlaybackPanel` refactor to strip "ghost" theme logic (`isFruit`, `isTv`) from components that are only ever reached by a single platform/theme path.
  - [x] Audit `MiniPlayer` for leaked Fruit UI logic in the Material path.
  - [x] Audit `PlaybackControls` and `PlaybackProgressBar` for similar platform-specific gates that should be moved up to the screen level.
  - [ ] **Fruit Theme Gating Audit**: Verify `ElevatedButton` and `InkWell` in `playback_screen.dart` and `mini_player.dart` are correctly gated for Fruit theme. [v168]
  - [x] **Asset Optimization**: Build successfully tree-shook icons, reducing asset size. [v168]



---

## 📄 Spec & Documentation

- [x] **Centralize Theme Logic**: Documented that `kIsWeb` applies the "Fruit" theme, referencing `docs/fruit_theme_spec.md` as the styling source of truth. Logic is surgically gated in `ThemeProvider`.
 
 ---
 
 ## 🧪 Testing & Auditing
 
 - [x] **Consolidate Jules Audits**: Created [master_audit.md](file:///c:/Users/jeff/StudioProjects/gdar/test/prompts/master_audit.md) as the 100% comprehensive (Phases 1-7) pre-release standard.
 - [ ] **Port Widget Tests**: Convert remaining flakey unit tests into Jules E2E observation phases for 100% reliable coverage.
- [ ] **Politeness Policy**: Ensure all automated tests (Jules/Arlo) consistently use local mocks and never hit `archive.org` directly. Verify this isolation as part of the CI/CD pipeline.
- [ ] **TV Show List Widget Tests**: Verify TV cards always show stars + source badge and remain stable with multi-source shows. How: add a widget test in `test/ui/show_list/tv_show_list_card_test.dart` that pumps `ShowListCard` with `DeviceService(isTv: true)` and asserts `RatingControl` and `SrcBadge` render for single- and multi-source shows.
- [ ] **TV UI Smoke Pass**: Quick manual pass of the dual-pane layout. How: run the TV build, open the left show list, confirm stars/badges on several cards, scroll with D-pad, and ensure focus movement and scrollbar still work.

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
## Web Audio Engines
- [ ] **Review Report**: 2026-03-12 web audio engines issue report saved to `reports/2026-03-12_web_audio_engines_issue_report.md`.
- [ ] **Decision**: Confirm default web/PWA engine profile (HTML5 vs Hybrid Balanced) based on long background sessions priority.
- [ ] **Validation**: Run long background soak tests across `stability`, `balanced`, and `maxGapless` presets.
