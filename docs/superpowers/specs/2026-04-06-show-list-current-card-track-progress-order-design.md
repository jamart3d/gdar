# Show List Current Card Track Progress Order Design

## Summary

Adjust the Fruit web/PWA car-mode current-show card in the show list so the
track title appears above the progress indicator instead of below it. Tighten
the spacing between the date/metadata block and the track block so the current
card feels balanced without changing the idle-card layout or the right-edge
rating/src column.

## Scope

This change applies only to the current-show card in the Fruit car-mode show
list layout.

In scope:
- Move the current-show progress row below the track title.
- Rebalance vertical spacing between metadata and the track block.
- Preserve existing venue wrapping behavior in both date-first modes.
- Preserve rating and source-badge alignment.
- Update widget tests for the new layout order.

Out of scope:
- Changes to idle cards.
- Changes to non-Fruit or non-car-mode show cards.
- Full footer redesigns or new controls.

## Current Problem

The current-show card uses a compact footer row where the progress indicator
renders above the track title. That ordering makes the track area read backward
and leaves an awkward visual gap between the metadata block and the currently
playing track information.

## Chosen Approach

Keep the existing current-show card structure and right-side metadata controls,
but reorder the track column from:

1. progress row
2. gap
3. track title

to:

1. track title
2. small gap
3. progress row

This is the smallest layout change that addresses the readability issue while
avoiding collateral changes to badge placement, rating alignment, and card
height behavior.

## Layout Details

### Current-Show Track Column

Only the current-show track column changes.

- Keep the track title in the existing trailing content area.
- Render the track title first.
- Render the progress row directly beneath it with a smaller gap than the
  current progress-to-title gap.
- Keep the pulse indicator attached to the progress row.

### Metadata-to-Track Spacing

Reduce the bottom-heavy feel by tightening the space between the metadata block
and the track block.

- Keep a modest separation so the card still reads as two sections.
- Avoid collapsing the sections so much that wrapped venue text feels crowded.
- Favor a tuned vertical rhythm over the current hard-pushed footer feel.

### Stable Elements

The following elements should not move structurally:

- Rating stars
- Source badge
- Idle-card layout
- Existing venue/date ordering behavior
- Existing overflow safeguards for narrow cards

## Data Flow And State

No provider or model changes are needed. The change is isolated to widget
composition inside the Fruit car-mode show-list card.

## Testing

Update and keep passing the existing widget coverage in
`packages/shakedown_core/test/widgets/show_list_card_test.dart`.

Required coverage:
- Current-show card renders the progress row below the track title.
- Existing overflow tests remain green.
- Existing wrapped-venue tests remain green in both date-first modes.
- Existing Fruit car-mode smoke coverage remains green.

## Risks

- Tightening spacing too aggressively could reintroduce overflow on narrow web
  widths.
- Reordering the footer content could accidentally shift badge alignment if the
  row/column constraints change more than intended.

## Implementation Notes

Implement the change in the Fruit car-mode show-list card widget only. Prefer
minimal structural edits that preserve current sizing logic, especially the
height adjustments already added for wrapped venue text.
