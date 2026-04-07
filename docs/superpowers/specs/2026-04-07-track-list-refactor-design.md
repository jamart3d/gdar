# Track List Refactor Design

## Summary

Refactor the track-list feature around
`track_list_screen_build.dart` and `track_list_view.dart` to follow better
Flutter and Dart structure without preserving the current file shape as a
constraint. The refactor should reduce duplicated list-shaping logic, separate
screen coordination from presentational widgets, localize reactive rebuilds,
and add focused tests around the new seams.

## Scope

This change applies to the track-list feature area in
`packages/shakedown_core/lib/ui/screens/` and
`packages/shakedown_core/lib/ui/widgets/playback/`.

In scope:
- Refactor `track_list_screen_build.dart`.
- Refactor `track_list_view.dart`.
- Extract adjacent private or feature-local helpers/widgets where they improve
  clarity.
- Replace untyped `List<dynamic>` track-list composition with typed models.
- Consolidate duplicated section-building and track-index mapping logic.
- Add focused widget and unit tests for the extracted seams.

Out of scope:
- Global theme-system rewrites.
- Navigation redesigns.
- Behavior changes outside the track-list feature area.
- Large-scale playback architecture changes.

## Current Problems

The current implementation has three structural issues:

1. Track-list data shaping is duplicated.
   Both files rebuild grouped sections and flattened list items independently,
   which creates multiple sources of truth for ordering and index mapping.
2. Screen and row responsibilities are mixed.
   `track_list_screen_build.dart` owns screen composition, list shaping,
   navigation, theme branching, and row interaction details in one place.
   `track_list_view.dart` similarly mixes scroll/focus behavior with tile
   rendering and per-platform visual logic.
3. Reactive dependencies are broader than necessary.
   Several nested builders call `context.watch()` repeatedly, which makes the
   rebuild surface larger and hides which widgets actually depend on which
   provider values.

## Chosen Approach

Use a feature decomposition refactor with shared typed list models.

This keeps the existing feature ownership intact while improving boundaries:

- `TrackListScreen` remains the coordinator for navigation, playback actions,
  and screen-level theme decisions.
- `TrackListView` remains responsible for scrollable track rendering and TV
  focus behavior.
- Shared typed helpers build ordered track sections and list items once.
- Reusable presentational widgets render set headers and track tiles with
  smaller, more testable responsibilities.

This is preferred over a minimal in-file cleanup because the current duplicate
data shaping is a real structural problem. It is preferred over a fully split
platform-renderer architecture because that would add more abstraction than the
feature currently needs.

## Target Structure

The refactor stays local to the track-list feature area. It can add adjacent
feature files such as:

- `packages/shakedown_core/lib/ui/widgets/playback/track_list_items.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/track_list_sections.dart`
- `packages/shakedown_core/lib/ui/widgets/playback/track_list_tile.dart`

Exact filenames may vary, but the structure should preserve these boundaries:

- Screen coordinator:
  `TrackListScreen` and its `part` files own screen assembly and navigation.
- Shared list modeling:
  one helper owns grouping tracks by set and flattening them into ordered list
  items plus any index lookups needed by `TrackListView`.
- Presentational widgets:
  extracted widgets own set-header and track-row rendering.
- Interaction adapters:
  TV wrap-around, mobile tap handling, and long-press safety-reset behavior stay
  explicit and close to the widgets that consume them.

## Data Model And Flow

Replace the current string sentinel and `List<dynamic>` pattern with typed
feature-local models.

Recommended model shape:

- `TrackListSection`
  Contains a `setName` and the ordered tracks in that section.
- `TrackListItem`
  A typed item hierarchy for flattened rendering.
- `TrackListIndexMap`
  Encapsulates `trackIndex -> listIndex` and `listIndex -> trackIndex` lookups
  where scroll or focus behavior needs them.

The helper should:

- Build ordered sections from `Source.tracks`.
- Flatten those sections into ordered list items.
- Preserve track ordering exactly as it exists in `source.tracks`.
- Provide stable mapping information for `ScrollablePositionedList` and TV
  wrap-around behavior.

This removes runtime type branching based on unrelated meanings such as:

- string as set header
- string sentinel as show header
- track object as row item

## Widget Responsibilities

### `track_list_screen_build.dart`

After refactor, this file should:

- Build the scaffold and top-level body selection.
- Own screen-only concerns such as app bar, Fruit header overlay, bottom tab
  navigation, and playback-screen navigation.
- Use shared typed track-list data instead of rebuilding grouped data inline.

It should no longer own large inline implementations for every set header and
every track tile variant.

### `track_list_view.dart`

After refactor, this file should:

- Own `ScrollablePositionedList` setup.
- Own TV focus traversal and wrap-around plumbing.
- Consume typed list items and index mappings from the shared helper.
- Delegate tile/header rendering to extracted widgets.

It should no longer build list-shaping data independently from the screen.

### Extracted Widgets

Extracted widgets should be small and explicit.

Expected examples:

- a set-header widget
- a non-Fruit track tile widget
- a Fruit track tile widget or a track-tile shell with theme-specific branches
- a small widget for current-track leading state if that logic is still complex

The goal is not maximum abstraction. The goal is to move rendering code into
clear widget boundaries that are easy to read and test.

## Provider And Rebuild Strategy

Prefer reading provider values at the narrowest widget that actually depends on
them.

Guidelines for this refactor:

- Read screen-level flags once near the scaffold when they affect only layout
  branching.
- Pass simple derived values into presentational widgets when possible.
- Keep playback-stream listeners localized to widgets that render live state.
- Avoid nested `Builder` plus repeated `context.watch()` when a focused widget
  can express the dependency more clearly.

This should reduce rebuild scope without introducing premature memoization or
custom state layers.

## Consistency Rules

The refactor should align with repo conventions:

- Use package imports across library boundaries.
- Keep Flutter UI code readable with focused helper methods or widgets instead
  of very large monolithic build methods.
- Prefer typed feature-local models over `dynamic`.
- Preserve current platform contracts for TV and Fruit behavior unless a small
  cleanup is behaviorally equivalent.
- Keep comments sparse and only where they explain non-obvious behavior.

## Testing

Add focused coverage around the seams created by the refactor.

Required coverage:

- unit tests for section-building and index-mapping logic
- widget tests that verify ordered set headers and track rows from a sample
  `Source`
- targeted widget tests for tap behavior and current-track visual state
  selection where the new widget boundaries make that practical

Not required in this pass:

- exhaustive cross-platform golden coverage
- broad snapshot tests for every theme permutation

## Risks

- Small visual regressions can occur if extracted widgets subtly change spacing
  or typography defaults.
- TV focus behavior can regress if list-index mapping and rendered-item order
  diverge.
- A cleanup that over-normalizes Fruit and non-Fruit rendering could erase
  intentional platform-specific differences.

## Implementation Notes

- Prefer incremental extraction over a total rewrite.
- Establish the shared typed list helper first, then migrate both screen and
  list view to it.
- Move presentational code into extracted widgets only after the shared data
  model exists so the widget APIs remain stable.
- Add tests alongside the extracted seams before finishing the refactor.
