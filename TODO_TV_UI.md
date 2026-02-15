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
- [ ] **Atmospheric TV Backgrounds**: 
  - [ ] Implement dynamic background gradients that adapt to the currently selected/playing show.
- [ ] **Display Typography**:
  - [ ] Audit and upgrade headers to `DisplayMedium` or `DisplayLarge` on the right (Playback) pane.
- [ ] **Glassmorphism Expansion**:
  - [ ] Add `BackdropFilter` blur to the show list background for a more premium "Glass" look.

## Performance & Optimization
- [ ] **App Size Audit**:
  - [ ] Run the optimization audit workflow specifically looking for TV-only assets that could be optimized.
- [ ] **Overscan Margins**:
  - [ ] Add a global "TV Safe Area" setting to adjust margins for older TV panels that crop edges.

## Future Ideas
- [ ] **Voice Search**: "Play shows from Winterland 1973" via Google Assistant.
- [ ] **Leanback Screensaver**: A dedicated high-art playback view with scrolling credits and atmospheric glow for when the app is left idle during music.
