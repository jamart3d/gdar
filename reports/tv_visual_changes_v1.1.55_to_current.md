# TV UI Visual Changes Report (v1.1.55 to Current)

This report details the specific *visual* and layout changes made to the TV UI environment between version v1.1.55 and the current HEAD (v1.1.64), focusing on the dual panel, gaps, show list cards, stars, and badges.

## 1. Dual Pane Layout & Screen Gap
* **Top-Right Playback Messages:** The floating playback messages (Buffered / Next) in the top-right corner of the TV screen were refactored from a strict `Positioned(top: 0, right: 3)` to an `Align(Alignment.topRight)` wrapped in a `Padding` of the same 3 pixels. While the absolute gap distance remains similar, switching to `Align` and `Padding` allows the layout to breathe better and prevents flex-box overflow errors when the text lengths change dramatically.
* **Focus Stealing Prevention (Visual Stability):** Although largely architectural, new logic was added to prevent the left/right panes from stealing focus while a dialog or settings page is active in the foreground. This stops the TV UI from visually "jumping" or flashing the active highlight when a new song starts while you're in a menu.

## 2. Show List Cards & Constraints
* **Fitted Shrink-Wrapping:** The right side of the show list card (where the rating stars and badges live) was previously a vertical `Column` that would overflow or clip if the items inside grew too large. This entire column is now wrapped in a `FittedBox` configured to `BoxFit.scaleDown`. 
* **Result:** No matter how many badges or how large the TV font setting is, the right-side elements will smoothly shrink to fit the available space without ever breaking the visual boundaries of the card.

## 3. Stars (Rating Controls)
The visual presence of rating stars on TV was dramatically increased for distance legibility.
* **Significant Size Bump:** Previously, the rating stars inside the list cards were scaled using a base size of `19` (or `14/15` in denser areas). 
* **TV Override:** They now explicitly trigger a TV-specific size override of `28` pixels (`isTv ? 28`). This makes the stars substantially larger and much easier to read and interact with from 10 feet away.
* **Tap Targets:** Alongside the visual size increase, `enforceMinTapTarget: true` was added, guaranteeing the hit-box is always accessible for D-Pad controllers.

# 4. Badges (ShnidBadge)
The metadata badges (like the `Shnid` text) were identified as an "Interactive Link" leak from the Web/Fruit layout.
* **Restored Static Parity:** To match the version `v1.1.55` behavior and prevent the TV D-Pad from trapping focus on external Archive.org links, the `ShnidBadge` is now entirely hidden on the TV UI.
* **Interactivity Removal:** The visual underline and URL launching behavior are strictly gated to Web, Mobile, and PWA platforms. TV users no longer see or interact with these badges.
