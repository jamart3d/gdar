# Master Release Audit (v1.2.x)

This is the comprehensive pre-release checklist for GDAR.

## Phase 1: Infrastructure & Health
- [ ] Run `/verify` to check formatting and static analysis across all packages.
- [ ] Ensure all app targets have `publish_to: none`.

## Phase 2: TV UI & Navigation
- [ ] **Dual-Pane Layout**: Verify master-detail navigation works via D-pad.
- [ ] **Focus Management**: Ensure focus doesn't get stuck in inactive panes.
- [ ] **Font Override**: Confirm "Rock Salt" is used globally on TV platforms.

## Phase 3: Web & PWA Performance
- [ ] **Fruit Theme**: Verify Liquid Glass and Neumorphic effects render correctly.
- [ ] **Audio Engines**: Test Hybrid, Web Audio, and HTML5 modes.
- [ ] **Web Drag & Drop (NEW)**: 
    - Open `ShowListScreen` on Web.
    - Drag the `FastScrollbar` thumb rapidly.
    - **Pass Criteria**: The year chip overlay must remain perfectly aligned with the pointer/thumb even under 4x CPU throttling.

## Phase 4: Audio Engine Soak Test
- [ ] 30-minute background playback test with screen locked.
- [ ] Verify gapless transitions between tracks.

## Phase 5: Persistence & State
- [ ] Verify ratings and blocked shows survive an app restart.
- [ ] Confirm "Show List" scroll position is restored.
