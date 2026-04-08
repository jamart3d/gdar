# Navigation Undo Design

## Summary

`Navigation Undo` is a small, behavior-only recovery feature for accidental user navigation. It is not a visible playlist/history feature in v1.

The app stores one in-memory undo checkpoint representing where playback was before an eligible user action changed context. If the user presses `Previous` within the first `5` seconds of the current track, and the checkpoint is still valid, playback restores to that earlier show/track/position. The checkpoint expires after `10` seconds of real time, clears on app background, and is consumed after one successful restore.

## Why This Replaces Live Playlist v1

The earlier `Live Playlist` plan assumed a broader session-history system with cross-show history traversal, persistence, boundary-state UI work, and optional visible management affordances.

The clarified product goal is narrower:

- recover from accidental manual navigation
- restore the exact playback point the user was at
- use the existing `Previous` control as the undo affordance
- avoid new visible UI surfaces in v1

That narrower goal is better modeled as one ephemeral undo checkpoint than as a persistent history timeline.

## Product Rules

### Eligible actions that create a checkpoint

Create or replace the single undo checkpoint immediately before these user-initiated actions:

- tapping a different track
- selecting a different show/source
- random/show-jump actions

Do not create a checkpoint for:

- transport `Next`
- transport `Previous`
- autoplay or random-next completion behavior
- passive engine transitions not directly initiated by the user

### Restore behavior

When the user presses `Previous`:

- if current playback position is greater than `5` seconds, do normal `Previous` behavior
- if current playback position is `<= 5` seconds, check whether a valid undo checkpoint exists
- if a valid checkpoint exists, restore its exact show/source, track index, and playback position
- after a successful restore, clear the checkpoint immediately
- if no valid checkpoint exists, do normal `Previous` behavior

### Checkpoint validity

A checkpoint is valid only if all of the following are true:

- it exists
- it is not older than `10` seconds of real time
- the app has not backgrounded since the checkpoint was created
- its target source is still allowed by existing filtering rules

For filtering, `isSourceAllowed(...)` is the correct gate. If the target is no longer allowed, the checkpoint is treated as invalid and normal `Previous` behavior continues.

### Scope boundaries

Out of scope for v1:

- visible history/session screen
- multi-step undo stack
- explicit undo pill, toast, or badge
- gesture-specific phone affordance
- persistence on any platform
- settings UI for managing history

Future TODO:

- optional read-only Session History screen, similar in spirit to Rated Shows, if the feature later grows beyond one-step undo

## Architecture

### Ownership

The undo checkpoint should live in `AudioProvider`, not `CatalogService`.

Reasons:

- this is transient playback state, not catalog data
- it is intentionally in-memory only on every platform
- the consumer is `seekToPrevious()`, which already belongs to playback control logic
- `CatalogService` should not absorb ephemeral UI/session behavior that has no persistence requirement

### Model

Add a lightweight `UndoCheckpoint` model under shared core logic. It should contain:

- `sourceId`
- `showDate`
- `trackIndex`
- `position`
- optional `title`
- `createdAt`

This can be a plain Dart model. It does not need Hive annotations.

### Provider seams

The feature should be implemented at these existing seams:

- `AudioProvider.playSource(...)` for show/source changes and random/show-jump flows
- track selection entry points in the track list / playback UI before they switch to another track
- `AudioProvider.seekToPrevious()` as the only consumer of the checkpoint
- an app lifecycle hook already present in the app to clear the checkpoint when backgrounded

`seekToPrevious()` becomes:

1. read current playback position
2. if position is `> 5s`, delegate to normal player previous behavior
3. if position is `<= 5s`, attempt undo restore
4. if restore succeeds, clear checkpoint and return
5. otherwise delegate to normal player previous behavior

### Restore mechanics

Restoring a checkpoint should:

1. resolve the target `Show` and `Source`
2. verify the target passes `isSourceAllowed(...)`
3. load the source with the stored `trackIndex`
4. seek to the stored `position`
5. clear the checkpoint only after restore succeeds

The restore path should not create a new checkpoint while replaying the older state. The implementation needs an internal guard so undo does not recursively overwrite itself.

## UI and UX

### Playback controls

No new visible control is required. The existing `Previous` control is the undo affordance when the current playback position is near the start of the track.

This keeps the behavior aligned across phone, TV, and other native surfaces without introducing new UI work in v1.

### Settings usage instructions

A short note should be added to the existing `Usage Instructions` section under player controls.

Recommended copy:

- `Press Previous within the first 5 seconds to undo an accidental track or show change and return to where you were.`
- `This undo is temporary and expires after 10 seconds.`

This belongs in usage/help text, not as a setting toggle.

## Edge Cases

- Same-show accidental track changes are restorable and should not be ignored.
- If the user presses `Previous` after `5` seconds, undo is ignored even if the checkpoint is still valid.
- If more than `10` seconds of real time pass, undo expires.
- If the app backgrounds, undo expires.
- If the restore target can no longer be resolved or is filtered out, undo is ignored and normal `Previous` behavior is used.
- If the user performs a second eligible navigation before consuming undo, the old checkpoint is replaced by the newer one.

## Testing Strategy

The primary tests should be provider-level tests around `AudioProvider`.

### Creation tests

Verify a checkpoint is created for:

- tapping a different track
- selecting a different show/source
- random/show-jump actions

Verify a checkpoint is not created for:

- transport `Next`
- transport `Previous`
- autoplay / completion transitions

### Restore tests

Verify:

- `Previous` at `<= 5s` restores exact `show/source + trackIndex + position`
- `Previous` at `> 5s` does normal behavior
- successful restore clears the checkpoint
- checkpoint older than `10s` is ignored
- checkpoint cleared on background is ignored
- same-show track change is restorable
- filtered-out target via `isSourceAllowed(...)` is ignored and falls back to normal behavior
- restore does not create a replacement checkpoint for itself

### UI/help tests

One lightweight widget test should confirm the usage instructions include the new undo note.

## Implementation Notes

- Keep this as a focused v1 behavior change, not a partial session-history system.
- Do not add persistence or settings management unless product intent changes.
- Reuse existing provider and playback entry points rather than adding a new service layer.
