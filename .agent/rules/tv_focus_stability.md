# TV Focus Stability & Performance Rules

### 1. Surgical Stabilization
When creating focusable elements for TV (e.g., list items, buttons):
- **Constraint:** The widget tree structure MUST remain identical whether the item is focused or unfocused.
- **Action:** Do not conditionally mount/unmount padding, borders, or wrappers based on focus state. Instead, toggle the *properties* of those widgets (e.g., set border width to 0 or color to transparent when unfocused).
- **Reason:** Mounting/unmounting widgets during fast D-pad navigation causes layout shifts ("bounce scroll"), breaks internal focus tracking, and leads to infinite focus loops.

### 2. ValueKey Synchronization
When rendering dynamic lists (e.g., Show Lists, Track Lists):
- **Constraint:** Every item in a scrollable list MUST have a unique, stable `ValueKey`.
- **Action:** Use domain-specific IDs (e.g., `ValueKey(show.identifier)` or `ValueKey(track.id)`). Do not use index-based keys.
- **Reason:** Stable keys ensure Flutter's element tree correctly matches state to list items during rapid scrolling and dataset updates, preventing focus from becoming detached or jumping to the wrong item.
