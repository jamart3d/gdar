# Google TV UI Refinements TODO

This list tracks the next steps for polishing the 10-foot experience of gdar.

## High Priority
- [ ] **Search UX for TV**: 
  - [ ] Optimize the search overlay for large screens (centered, larger input field).
  - [ ] Ensure the on-screen keyboard doesn't obscure search results.
- [ ] **Pane Navigation Polish**:
  - [ ] Implement a clear "Switch Pane" button shortcut (e.g., specific remote key or focused "tab" indicators).
  - [ ] Visual indicator for *why* a pane is inactive (e.g., subtle "Focused" badge).
- [ ] **Settings Two-Pane Layout**:
  - [ ] Redesign the Settings screen for 16:9 aspect ratios using a Master-Detail (Two-Pane) pattern.

## Visual & Motion
- [x] **Atmospheric TV Backgrounds**: 
  - [x] Implemented dynamic "Glass" vertical divider and inactive pane dimming (0.2 opacity) for a moody, focused experience.
- [ ] **Display Typography**:
  - [ ] Audit and upgrade headers to `DisplayMedium` or `DisplayLarge` on the right (Playback) pane.
- [x] **Glassmorphism Expansion**:
  - [x] Added translucent vertical gradient divider in `TvDualPaneLayout`.

## Performance & Optimization
- [ ] **App Size Audit**:
  - [ ] Run the optimization audit workflow specifically looking for TV-only assets that could be optimized.
- [ ] **Neon Glow Optimization**: [CRITICAL] Implement Rasterized Glyph Cache for `StealBanner` characters. Real-time Gaussian blurs are still way too expensive for standard Google TV SOCs.
- [ ] **TV Safe Area**:
  - [ ] Add a global "TV Safe Area" setting to adjust margins for older TV panels that crop edges.

## Future Ideas
- [ ] **Voice Search**: "Play shows from Winterland 1973" via Google Assistant.
- [x] **Leanback Screensaver**: High-art psychedelic oil lamp visualizer with audio reactivity and multiple visual styles (Lava Lamp, Silk).
- [ ] **Flutter GPU Investigation**: explore `flutter_gpu` for the lava lamp screensaver. Current Flame/Shader shading is too simple; need higher fidelity fluid simulation and advanced lighting/shading.
