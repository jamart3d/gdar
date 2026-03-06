# Google TV Display & Navigation Patterns

This document defines the architectural standards for the 10-foot UI experience in GDAR.

## 1. Dual-Pane Layout Strategy
The standard TV view is a 50/50 or 30/70 split between a **Master List** (e.g., Show List) and a **Detail View** (e.g., Playback/Track List).
- **Visual hierarchy:** The inactive pane MUST be dimmed (e.g., `AnimatedOpacity` to 40-60%) to clearly indicate where the user's D-pad focus currently resides.
- **Navigation:** Use explicit input captures (like `HardwareKeyboard` listeners for `LogicalKeyboardKey.tab` or `LogicalKeyboardKey.keyS`) or transparent focus-wrapping to allow the user to easily switch panes.

## 2. Safe-Zone Scrolling
When managing long lists on TV:
- Do NOT jump the scroll position so that the focused item is always perfectly centered. This creates a disorienting "bouncing" effect.
- **Implementation:** Use a "Safe-Zone" or "Visibility-Only" scrolling strategy. The `ScrollController` should only adjust its offset when the newly focused item approaches the viewport boundaries (top or bottom edge). If the focused item is already fully visible, do nothing.

## 3. Surgical Stabilization (Anti-Bounce)
When an item gains or loses focus:
- The widget tree **structure** must remain exactly the same.
- Do not conditionally wrap an item in a border or padding only when focused.
- **Implementation:** Always render the border/padding, but use `Colors.transparent` or `width: 0` when unfocused. This prevents Flutter from rebuilding the element tree, which is the primary cause of layout jumps and focus loops on low-powered TV hardware.

## 4. Leak-Proof Focus Wrapping
- For horizontal navigation (like settings toggles), focus should wrap natively (pressing right on the last item jumps to the first item).
- **Implementation:** Group related interactive elements inside a `FocusTraversalGroup` with an explicit layout policy.
