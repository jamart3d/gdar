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

### Navigation Undo (Task 1 of 3 complete)
- Added `UndoCheckpoint` model
  (`packages/shakedown_core/lib/models/undo_checkpoint.dart`) — immutable,
  in-memory only, with a 10-second expiry helper
- Wired `WidgetsBindingObserver` into `AudioProvider` for lifecycle events
- Added undo state and helpers to `_AudioProviderState`:
  `captureUndoCheckpoint()`, `_replaceUndoCheckpoint()`,
  `_clearUndoCheckpoint()`, `undoCheckpointForTest` (@visibleForTesting)
- Checkpoint auto-expires via a 10-second `Timer` and clears on app background
  (`paused` / `hidden` / `detached` lifecycle states)
- Unified track index resolution: `currentTrack` now delegates to
  `currentLocalTrackIndex`, removing a stale ID-string fallback path

### Tests
- Added `packages/shakedown_core/test/models/undo_checkpoint_test.dart`
  (2 tests, expiry boundary coverage)
- Full suite: 361/361 passing

### Notes
- Navigation Undo restore logic (Task 2) and UI capture sites (Task 3) are
  not yet implemented.
- No UI visible to the user from this work yet.
