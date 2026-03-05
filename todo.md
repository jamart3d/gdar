# GDAR — Open TODO Items

> Consolidated from `todo.md`, `TODO_TV_UI.md`, `WEB_GAPLESS_TODO.md`, and `TODO_position_jump_debug.md`.
> Originals archived to `reports/archive/`.

---

## 🖥️ Google TV

### High Priority
- [ ] **Default Screensaver Settings**: Set default visual style, speed, etc. for a premium out-of-the-box experience.
- [ ] **Search UX**: Optimize search overlay for large screens; ensure on-screen keyboard doesn't obscure results.
- [ ] **Pane Navigation Polish**: "Switch Pane" shortcut and visual indicator for inactive pane focus state.
- [ ] **Settings Two-Pane Layout**: Redesign Settings screen for 16:9 using a Master-Detail pattern.

### Visual & Motion
- [ ] **Display Typography**: Audit and upgrade headers to `DisplayMedium` / `DisplayLarge` on the playback pane.

### Performance
- [ ] **Neon Glow Optimization** *(CRITICAL)*: Implement Rasterized Glyph Cache for `StealBanner`. Real-time Gaussian blurs are too expensive for TV SOCs.
- [ ] **App Size Audit**: Run optimization audit looking for TV-only assets that could be trimmed.
- [ ] **TV Safe Area**: Global setting to adjust margins for older panels that crop edges.

### Debug
- [ ] **Logo Position Jump**: Diagnose visual jolt/reset every few minutes with audio reactivity off. See `reports/archive/TODO_position_jump_debug.md` for full investigation notes.

### Future Ideas
- [ ] **Voice Search**: "Play shows from Winterland 1973" via Google Assistant.
- [ ] **Flutter GPU Investigation**: Explore `flutter_gpu` for higher-fidelity fluid simulation in the lava lamp screensaver.

---

## 🌐 Web / PWA

- [ ] **Background Longevity**: Extend playback when tab is backgrounded/throttled.
  - [ ] Explore Silent Video looping or Web Workers for timer consistency.
  - [ ] Audit `gapless_audio_engine.js` for timer drift during CPU throttling.
- [ ] **Bug — Track Skip on Buffer**: Engine skips next track if it isn't fully buffered when current track ends.
- [ ] **Mobile Preload Setting**: User setting to choose how many tracks to buffer/preload ahead (currently defaults to 1).

---

## 📄 Spec & Documentation

- [ ] **Merge Platform Specs into Feature Specs**: Consolidate `web_ui_design_spec.md` and `phone_ui_design_spec.md` into unified cross-platform specs.
  - [ ] Create `spec_browse_flow.md` (routing, layout, logic for Years/Shows/Tracks).
  - [ ] Create `spec_music_player.md` (sliding panel, playback controls, animations, audio service).
  - [ ] Create `spec_settings.md` (configuration options and theme toggles).
- [ ] **Centralize Theme Logic**: Document that `kIsWeb` applies the "Fruit" theme, referencing `fruit_theme_spec.md` as the styling source of truth.
