# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Docs / Planning
- Replaced the broader "Live Playlist" direction with a narrower approved
  `Navigation Undo` v1 focused on one-step accidental navigation recovery.
- Added the approved design spec:
  `docs/superpowers/specs/2026-04-07-navigation-undo-design.md`
- Added the implementation plan:
  `docs/superpowers/plans/2026-04-07-navigation-undo.md`
- Added session handoff notes for the next agent:
  `.agent/notes/session_handoff.md`

### Navigation Undo

**Task 1 - Scaffolding (commit `05ed21b` + `9154f32`)**
- Added `UndoCheckpoint` model
  (`packages/shakedown_core/lib/models/undo_checkpoint.dart`) - immutable,
  in-memory only, with a 10-second expiry helper
- Wired `WidgetsBindingObserver` into `AudioProvider` for lifecycle events
- Added undo state and helpers to `_AudioProviderState`:
  `captureUndoCheckpoint()`, `_replaceUndoCheckpoint()`,
  `_clearUndoCheckpoint()`, `undoCheckpointForTest` (@visibleForTesting)
- Checkpoint auto-expires via a 10-second `Timer` and clears on app background
  (`paused` / `hidden` / `detached` lifecycle states)
- Unified track index resolution: `currentTrack` now delegates to
  `currentLocalTrackIndex`, removing a stale ID-string fallback path

**Task 2 - Restore logic (commit `0a85795`)**
- `seekToPrevious()` now attempts checkpoint restore before normal player
  behavior when the current position is <= 5 seconds into a track
- Added `_restoreUndoCheckpointIfAvailable()` to `_AudioProviderControls`:
  validates checkpoint, resolves show/source from `allShows`, checks
  `isSourceAllowed`, restores via `playSource` with saved track index and
  position, then clears the checkpoint
- `_isRestoringUndo` guard prevents `captureUndoCheckpoint()` from overwriting
  the checkpoint during a restore

**Task 3 - UI capture sites + help text**
- Added `captureUndoCheckpoint()` before every user-initiated navigation:
  show list row tap, random show roll (all platforms), clipboard/share paste,
  search-submit, track list header, track row taps (3 locations), Fruit track
  row, rated shows long-press, and the TV dice button
- Added "Press Previous" plus the expiry note to the `Player Controls` section
  in `UsageInstructionsSection`
- Hardened failed random/share navigation so only the exact just-captured
  checkpoint is cleared when the action does not resolve

### Tests
- Added `packages/shakedown_core/test/models/undo_checkpoint_test.dart`
  (2 tests, expiry boundary coverage)
- Expanded the Navigation Undo group in
  `packages/shakedown_core/test/providers/audio_provider_test.dart`
  to cover capture, restore, above-threshold delegation, expiry, lifecycle
  clearing, failed-random cleanup, delayed failed-random cleanup, and failed
  share cleanup
- Added `packages/shakedown_core/test/ui/widgets/settings/usage_instructions_section_test.dart`
  (1 test: help text presence)
- Updated `packages/shakedown_core/test/ui/widgets/playback/track_list_view_test.dart`
  to assert representative checkpoint capture on manual track tap
- Focused verification passed:
  `audio_provider_test.dart`, `track_list_view_test.dart`,
  `usage_instructions_section_test.dart`, `settings_screen_test.dart`

### Notes
- Spec compliance review passed on the final Task 3 working tree.
- Code quality review passed on the final Task 3 working tree.
- Navigation Undo is now fully user-reachable because the UI capture sites are
  wired before manual navigation actions.
