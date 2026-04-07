# Fruit Car Mode And Steal Graph Refactor Design

## Summary

Refactor
`packages/shakedown_core/lib/ui/screens/playback_screen_fruit_car_mode.dart`
and
`packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart`
to follow better Dart and Flutter structure without intentionally changing user
behavior. The refactor should reduce method size, remove repeated inline style
and paint construction, clarify ownership boundaries, and expose a few small
pure helpers where that improves readability or testability.

## Scope

This change applies only to the Fruit car-mode playback screen extension and
the corner/scope/VU rendering helpers used by `StealGraph`.

In scope:
- Refactor `playback_screen_fruit_car_mode.dart`.
- Refactor `steal_graph_render_corner.dart`.
- Extract feature-local private helpers, small internal data objects, and
  focused widgets or methods where they reduce complexity.
- Add or update focused tests only for any newly extracted pure logic.

Out of scope:
- Theme-system redesigns.
- Navigation changes.
- New playback features.
- Changing graph modes, animation tuning, or Fruit interaction patterns unless
  the change is behaviorally equivalent.

## Current Problems

The current implementation has two structural issues:

1. Large methods hide responsibility boundaries.
   The Fruit car-mode file contains several long builders that mix layout,
   provider wiring, gesture handling, progress math, and text styling in one
   place.
2. Rendering helpers repeat low-level setup.
   The Steal graph renderer repeatedly rebuilds text spans, paints, panel
   chrome, and glow variants inline, which makes the frame logic harder to
   scan and harder to change safely.

## Chosen Approach

Use a behavior-preserving internal decomposition refactor.

This keeps the current feature boundaries intact while improving readability:

- `PlaybackScreenState` continues to own Fruit car-mode coordination and state.
- `StealGraph` continues to own rendering and timing behavior.
- Repeated style, geometry, and paint setup move into narrow private helpers.
- Pure decision logic is extracted only where it creates a clear seam.

This is preferred over a minimal formatting-only cleanup because the current
files are carrying too much inline responsibility. It is preferred over a
full widget or renderer architecture rewrite because that would increase churn
and regression risk for limited practical gain.

## Target Structure

### Fruit Car Mode

`playback_screen_fruit_car_mode.dart` should read as section composition rather
than one long stream of inline decisions.

Expected boundaries:

- scaffold/background assembly
- HUD mode toggle and rating dialog plumbing
- hero text block
- progress-track math and drag/tap seeking
- transport controls
- upcoming-track list typography

Implementation details:

- Keep the current `part` file structure and extension ownership.
- Extract repeated `Inter` text-style setup into feature-local helpers.
- Keep stream subscriptions localized to the sections that need them.
- Prefer tiny private helper types only if they replace repeated derived values
  cleanly, for example progress percentages or thumb geometry.

### Steal Graph Corner Rendering

`steal_graph_render_corner.dart` should keep render orchestration visible while
moving repeated low-level setup into private helpers.

Expected boundaries:

- panel chrome drawing
- mono-label text painting
- EQ bar glow/core/cap paint creation
- scope telemetry labels
- stereo lane label painting

Implementation details:

- Keep all helpers feature-local to `StealGraph`.
- Do not move rendering into a separate public painter API.
- Preserve current graph-mode output, alpha tuning, and panel placement unless
  a small cleanup is mathematically equivalent.

## Data Flow And State

No new app-level state is needed.

The refactor should preserve:

- current provider usage and navigation flow in Fruit car mode
- current HUD freeze behavior while paused
- current seeking behavior from the progress track
- current beat-flash, scope, VU, and corner-bar rendering decisions

If pure helper methods are extracted, they should take explicit inputs and
return derived values without reading hidden mutable state where practical.

## Consistency Rules

The refactor should align with repo conventions:

- Use package imports across library boundaries.
- Keep Fruit structure and controls intact and avoid Material-style fallbacks.
- Prefer small, explicit private helpers over large monolithic methods.
- Keep comments sparse and only where behavior is not obvious.
- Prefer immutable local values and `const` constructors where possible.

## Testing

Testing should stay targeted.

Required:

- retain existing tests that cover Fruit playback inset math and Steal graph
  behavior
- add focused unit coverage only for any newly extracted pure helper with
  non-trivial branching

Not required:

- broad golden coverage
- re-testing unchanged visual details that remain internal-only

## Risks

- Small spacing or typography regressions can slip in if extracted helpers
  change defaults.
- Rendering cleanup can accidentally alter alpha or blur behavior if helper
  inputs are normalized incorrectly.
- Over-extraction can make internal APIs harder to follow than the current
  inline code.

## Implementation Notes

- Refactor incrementally inside each file instead of rewriting both at once.
- Start by extracting pure or repeated logic with the lowest behavior risk.
- Keep the final call flow readable at the top level of each method.
- Only widen the file footprint with new helpers if the resulting ownership is
  clearer than the original inline code.
