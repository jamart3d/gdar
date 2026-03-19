# Session Handoff - Fruit UI Refinement and TV Regression Cleanup
**Date:** 2026-03-18  
**Status:** In progress. Fruit web UI has been substantially refined. Several
TV regressions caused by shared styling were corrected. Local validation has
been partial and mostly file-targeted.

---

## Scope Rule

- Visible behavior changes should stay Fruit-only unless the task is explicitly
  about TV.
- Shared fixes are acceptable only for neutral safety/plumbing work.
- Diagnostic HUD remains out of scope as a visual design target.

---

## Fruit Work Completed

### Core Liquid Direction

- Updated the working spec in
  `.agent/specs/fruit_theme_spec.md`.
- Updated the working plan in `docs/fruit_theme_refactor_plan.md`.
- Introduced a more canonical Fruit surface in:
  - `packages/shakedown_core/lib/ui/widgets/theme/liquid_glass_wrapper.dart`
  - `packages/shakedown_core/lib/ui/widgets/theme/fruit_ui.dart`
- Strengthened top-edge lensing and reduced the generic fogged-glass feel.

### Playback / Now Playing

- Reworked Fruit now-playing chrome in:
  - `packages/shakedown_core/lib/ui/widgets/playback/fruit_now_playing_card.dart`
  - `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
  - `packages/shakedown_core/lib/ui/widgets/playback/fruit_track_list.dart`
- Removed conflicting Fruit neumorphic/plastic stacking in the main now-playing
  card path.
- Added a liquid pending/loading glyph for Fruit transport controls.
- Improved Fruit press feedback so controls sink/rebound instead of relying on
  opacity alone.
- Reworked the HUD-visible playback card layout:
  - play/pause button moved into the progress row
  - playback message moved under the progress bar
  - compact message sizing supported via `PlaybackMessages(fontScale: ...)`

### Fruit Navigation / Settings / Lists

- Fixed Fruit tab bar on web so enabling liquid glass no longer creates a
  full-screen/top-of-screen blur artifact:
  - `packages/shakedown_core/lib/ui/widgets/fruit_tab_bar.dart`
- Adjusted large Fruit settings sections to avoid turning the whole screen into
  a fogged slab:
  - `packages/shakedown_core/lib/ui/widgets/section_card.dart`
- Hid non-Fruit controls in Fruit Appearance:
  - Glow Border hidden in Fruit
  - RGB active highlight hidden in Fruit
  - Fruit now uses a single `Liquid Glass` toggle instead of competing liquid +
    simple toggles
- Updated:
  - `packages/shakedown_core/lib/ui/widgets/settings/appearance_section.dart`
  - `packages/shakedown_core/lib/providers/settings_provider.dart`

### Fruit Track List / Show List

- Reworked Fruit track list header to better match Playback:
  - non-transparent header surface
  - extra top spacing
  - inline play button by venue row
  - `...` menu instead of theme button
  - tighter alignment with playback metadata layout
- Track list menu now removes `Sticky Now Playing` and keeps only:
  - Track Numbers
  - Track Duration
- Updated:
  - `packages/shakedown_core/lib/ui/screens/track_list_screen.dart`
- Fruit show list app bar buttons were constrained back to compact controls:
  - `packages/shakedown_core/lib/ui/widgets/show_list/show_list_app_bar.dart`
- Fruit show list title now supports `Rock Salt` override:
  - `packages/shakedown_core/lib/ui/widgets/shakedown_title.dart`

---

## TV Fixes Completed

These were not planned as TV feature work, but were necessary regression
cleanup after shared changes bled into TV styling.

- TV current-show cards restored to black fills:
  - `packages/shakedown_core/lib/ui/widgets/show_list/card_style_utils.dart`
- TV settings scaffold and left pane restored to black:
  - `packages/shakedown_core/lib/ui/screens/tv_settings_screen.dart`
- TV stepper rows restored to black cards:
  - `packages/shakedown_core/lib/ui/widgets/tv/tv_stepper_row.dart`
- TV Collection Statistics layout made roomier:
  - `packages/shakedown_core/lib/ui/widgets/settings/collection_statistics.dart`
- TV Source Filtering chips upgraded to a proper 10-foot chip treatment:
  - `packages/shakedown_core/lib/ui/widgets/settings/source_filter_settings.dart`
- TV defaults changed so new/unset installs start with:
  - `Hide TV Scrollbars = on`
  - `TV Highlight = on`
  - files:
    - `packages/shakedown_core/lib/config/default_settings.dart`
    - `packages/shakedown_core/lib/providers/settings_provider.dart`

---

## Shared Safety / Plumbing Changes Kept

These are intentionally shared because they are neutral fixes, not platform
style changes.

- Added safer scroll helpers to avoid detached controller crashes:
  - `packages/shakedown_core/lib/ui/screens/playback_screen.dart`
  - `packages/shakedown_core/lib/ui/screens/tv_playback_screen.dart`
- Fixed fast-scroll edge-case crash:
  - `packages/shakedown_core/lib/ui/widgets/show_list/fast_scrollbar.dart`
- Added shared extension points:
  - `PlaybackMessages.fontScale`
  - `ShakedownTitle.fontKeyOverride`

---

## Verification Done

- Ran targeted `dart format` / `dart analyze` on several touched files during
  the session.
- Not all touched files were re-analyzed together at the end.
- Many visual fixes were confirmed by screenshot iteration rather than full app
  regression passes.

---

## Recommended Next Steps

1. Run a focused Fruit web smoke pass:
   - Playback
   - Track List
   - Show List
   - Settings / Appearance
2. Verify Fruit-only scope:
   - no non-Fruit visual regressions remain
3. Decide whether Show List should preserve scroll position on return in Fruit
   only
4. Consider one-time migration behavior for existing TV users if the new
   defaults for `Hide TV Scrollbars` and `TV Highlight` should apply beyond
   fresh/unset installs
5. If stable, do a broader format/analyze pass before save
