# Scroll Behavior Diagnosis: Foreground vs. Background

## The Issue
Random show selection works perfectly when triggered by a tap (foreground) but scrolls to the wrong position when triggered by "End of Playlist" auto-advance (background).

## Diagnosis
The difference lies in the **timing of the Layout Pass** relative to the **Scroll Command**.

### 1. Foreground Selection (Normal Tap)
When the app is visible, the sequence is synchronous and visual:
1.  **State Change**: Show marked as `expanded`.
2.  **Animation/Layout**: The UI framework immediately runs a layout pass. The item grows from **Small** to **Large**.
3.  **Scroll Calculation**: The `ItemScrollController` runs *after* the layout update. It sees the **Large** item and calculates the center position based on its full expanded height.
4.  **Result**: Correct alignment.

### 2. Background Selection (Auto-Advance)
When the app is backgrounded, the OS pauses rendering to save battery.
1.  **State Change**: The code marks the show as `expanded` and requests a scroll.
2.  **Animation Paused**: Because the app is not visible, the **Layout Pass does not run**. The logical state is "Expanded", but the *calculated visual size* remains **Small** (collapsed).
3.  **Scroll Calculation**: The `ItemScrollController` attempts to calculate the target immediately. It queries the list state and sees the **Small** (collapsed) item dimensions. It sets the scroll offset for that small size.
4.  **Resume (App Visible)**: The user opens the app.
5.  **Visual Jump**: The app resumes painting. The item instantly "pops" to its **Large** state.
6.  **Result**: The scroll position stays at the coordinate calculated for the small item. Since the item is now much larger, the "Top" alignment is usually pushed up and out of view.

## Conclusion
The bug is caused by calculating scroll offsets based on stale layout data while the application is paused in the background.
