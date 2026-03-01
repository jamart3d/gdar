# Playback UI Scaling Fix - 2026-02-24 19:30

## Goal
Fix the shriveled playback controls in the sliding panel on small phones with high scaling factors.

## Proposed Changes

### [Component] Playback Screen

#### [MODIFY] [playback_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/screens/playback_screen.dart)
- Adjust `maxPanelHeight` to be more flexible. Instead of a fixed 40-42% of screen height, it should ensure a minimum amount of space for the expanded controls column, while still respecting a reasonable maximum limit (e.g. 70-80% of screen).
- Ensure `maxPanelHeight` accounts for `scaleFactor`.

### [Component] Playback Panel

#### [MODIFY] [playback_panel.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/widgets/playback/playback_panel.dart)
- Refine the `FittedBox` usage. If possible, avoid scaling the whole column at once, or provide more granular scaling for non-essential elements (like large venue text) to preserve the size of controls (buttons, progress bar).
- Adjust vertical spacing and paddings to be more compact when space is tight.

## Verification Plan

### Automated Tests
- Run existing playback screen tests to ensure no regressions in layout logic.
- Add a widget test that simulates a small screen with high text scaling to verify that controls maintain a minimum readable size.

### Manual Verification
- Verify on a small phone device/emulator with "UI Scale" ON.
- Verify that no scrollbars appear as requested by the user.
