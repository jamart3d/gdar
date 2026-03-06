# Pending Release Notes

### Added
- **UI/UX (TV)**: Implemented "Switch Pane" shortcut (Tab/S), Back-to-master navigation, and dimming visual indicators for inactive panes.
- **UI/UX (Web/PWA)**: Created `docs/fruit_theme_spec.md` to formally define the "Fruit" (Liquid Glass) aesthetic for Web/PWA platforms.
- **Testing**: Added "Phase 4: CPU Throttling & Timer Drift" to `jules_audit.md` for stress-testing the JS audio scheduler on Web/PWA.
- **Infrastructure**: Initialized `size_guard` skill for ongoing app size and asset optimization audits.

### Changed
- **UI/UX (TV)**: Relocated "TV Safe Area" and "Default Screensaver Settings" to Backlog/Low Priority to focus on core performance.
- **UI/UX (TV)**: Dimmed inactive headers in the TV dual-pane layout for clearer focus indication.

### Fixed
- **UI/UX (TV)**: Synchronized list keying with `ValueKey(currentSource.id)` and updated alignment to fully eliminate "bounce scroll" glitches.
- **Theme**: Surgically gated "Fruit" theme logic to ensure it only applies to Web/PWA, strictly enforcing Material 3 on Native and TV.
