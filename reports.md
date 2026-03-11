# TV UI Audit Report: Current Version vs. v1.1.55

This report outlines the key architectural and visual differences in the TV Main Screen, Show List Cards, Stars, and Badges between the current application version (v1.1.64) and v1.1.55.

## 1. Main Screen & Global TV Navigation
The main screen and TV global wrapper (`TvFocusWrapper`) underwent significant refinements targeted at eliminating layout thrashing and improving the "10-foot" lean-back experience.

* **Refined Premium Highlights**: The intense "Premium Glow" effect on active focused items was softened for better aesthetics. The `activeGlowOpacity` was reduced from `0.8` to `0.45`.
* **Clipped Focus Fix**: The active border width on focused TV components was reduced from `6.0` to `4.0`. This surgically resolves the layout shifting and "neighbor clipping" issues during rapid D-Pad scrolling.
* **Platform Constraints Enforced**: Gestures such as "Haptic Feedback" and "Swipe to Block" are strictly gated and hidden on TV hardware, ensuring compliance with TV D-Pad interaction models.
* **Playback Messages**: Addressed overflow glitches in the upper right screen area by explicitly gating web-only buffering indicators that were mistakenly being rendered on the TV main screen.

## 2. Show List Cards (TV)
The component architecture for `ShowListCard` was restructured to prioritize layout stability and metadata grouping on large displays.

* **Single-Row Metadata**: Instead of wrapping vertically, metadata badges (date, venue, shnid) are now unified into a single horizontal fitted layer, reducing vertical height and fitting more cards on the TV screen.
* **Embedded Player Injection**: Added logic to seamlessly integrate an `EmbeddedMiniPlayer` placeholder slot into the show list card layout.

## 3. Stars and Badges
Stars (Rating Controls) and Badges (`ShnidBadge`) were overhauled for greater interactivity and significantly improved legibility.

* **Larger Stars for 10-foot UI**: The sizing logic in `RatingControl` within the show list received a major bump. TV mode now triggers an explicit override setting the star size to a statically larger `28`. This dramatically improves visual clarity from the couch compared to the standard mobile layouts.
* **HTML-Style Badges**: The `ShnidBadge` component styling was unified. It now adopts an HTML-style link behavior across all platforms, including a distinct `onTap` tactile response and an explicit text underline.
* **Rating Dialog Integration**: Fixed a regression inside the show list card ratings. Rating stars now successfully pass the underlying `sourceUrl` back up through the tree, ensuring that the "Internet Archive" link inside the TV `RatingDialog` functions correctly when invoked from a show card.
