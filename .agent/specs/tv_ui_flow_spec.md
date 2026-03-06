# TV UI Flow Specification: GDAR Audio Player

This document defines the interaction model, focus management, and sequential logic for the **Google TV / Android TV** implementation of GDAR.

## 1. Core Architecture: Dual-Pane Layout
The TV UI utilizes a persistent dual-pane layout within `TvDualPaneLayout`. 

*   **Left Pane (60%):** `ShowListScreen` (Browse & Search).
*   **Right Pane (40%):** `PlaybackScreen` (Active Track List & Details).
*   **Divider:** A vertical Translucent Material divider with linear transparency.
*   **Dimming:** The inactive pane is dimmed to **0.2 opacity** to clearly indicate focus.

## 2. D-Pad Navigation Truth Table

| From (Component) | Direction | Action / Destination |
| :--- | :--- | :--- |
| **TvHeader (Dice)** | Left | Wrap-around: Focus **Track List** (Right Pane) |
| **TvHeader (Dice)** | Down | Focus **Search Bar** or **First Show Item** |
| **Show List Item** | Right | Focus **Show List Scrollbar** |
| **Show List Scrollbar**| Left | Focus **Show List Item** (Visible/Middle item) |
| **Show List Scrollbar**| Right | Focus **Track List** (Right Pane) |
| **Track List Item** | Left | Focus **Show List Scrollbar** (Return to Browse) |
| **Track List Item** | Right | Focus **Playback Scrollbar** |
| **Playback Scrollbar** | Right | Wrap-around: Focus **Dice** (TvHeader) |
| **Playback Scrollbar** | Left | Focus **Track List Item** (Visible/Middle item) |

## 3. Interaction Flows

## Interactive Navigation Logic

### Pane Switching
- **Shortcut**: `Tab` or `S` keys (mapped globally when `TvDualPaneLayout` is active).
- **Behavior**: Toggles `_activePane` state. Focus is immediately shifted to the most recently focused item in the target pane to prevent "lost focus" on entry.
- **Visuals**: Inactive panes are dimmed to `0.3` opacity. Inactive headers are dimmed to `0.4` or `0.5` based on state.

### Detail Dismissal (Back-to-Master)
- **Constraint**: Pressing `Back` (Remote/Escape) while focus is in the **Playback Pane** (Detail) must shift focus back to the **Show List** (Master).
- **Goal**: Prevents the exit confirmation dialog from appearing prematurely. The user must feel that the Master-Detail layout is a single, navigable space.

### 3.1 Clicking an "Active" Show
When a show that is already playing is selected in the Show List:
1.  **If Multi-Source:** The show expands in the left pane to reveal SHNIDs. Focus remains in the list.
2.  **If Single-Source / Selected SHNID:** Shifts focus to the **Right Pane** (Track List). **NO** full-screen navigation occurs.
3.  **Focus:** Visual focus is communicated via a static high-contrast border. **NO** haptic feedback.

### 3.2 Clicking an "Inactive" Show
1.  **Selection:** Starts playback of the show.
2.  **Flow:** Automatically shifts focus to the **Right Pane** (Track List) to maintain a consistent dual-pane experience.

### 3.2 Show Expansion Logic
*   **Expansion:** Clicking a non-playing show with $>1$ source expands the card.
*   **Auto-Scroll:** The list automatically scrolls to align the expanded card (alignment varies: 0.05 for large sets, 0.4 for small sets).
*   **Collapsing:** Clicking the same show again collapses it. Focusing out does NOT auto-collapse.

### 3.3 The "Random Roll" Sequence (Dice)
Triggered by the Dice icon or "play-random" deep link. This is a multi-stage orchestrated sequence:

1.  **Stage 1 (1.2s):** Dice pulse animation only. Logic generates a selection.
2.  **Stage 2 (2.0s):** Show List scrolls to the selected show. Focus is force-shifted to the Show Card.
3.  **Stage 3 (2.0s):** Focus shifts to the Right Pane (Track List). `PlaybackScreen` syncs to the current track.
4.  **Playback Start:** Audio begins after focus has stabilized in the track list.

### 4. Modal Interactions (Long-Press)
*   **Show/Source (Non-Playing):** Triggers `TvInteractionModal` (legacy v135 behavior).
    *   **Primary:** Starts playback.
    *   **Secondary:** Opens `RatingDialog`.
*   **Active Track (Right Pane):** Triggers `TvReloadDialog`.
    *   **Reload:** Force-retries the current source stream.
    *   **Safe Button (Hard Reset):** Emergency Stop & Clear Playlist (for unrecoverable buffer stalls).
*   **TV Context:** `RatingDialog` buttons are specifically scaled for TV visibility ($1.2\times$ multiplier).

### Navigation Actions (TV)

| Trigger | Item Status | Action | View |
| :--- | :--- | :--- | :--- |
| **Select (Tap)** | **Active Show** | Shift focus to right pane (track list) | Dual-Pane |
| **Select (Tap)** | **Inactive Show** | Navigate to dedicated `TrackListScreen` | Full-Screen |
| **Long-Press** | **Any Show** | Play immediately (highest rated source) | Dual-Pane / Target |
| **Select (Tap)** | **Inactive Source** | Navigate to dedicated `TrackListScreen` | Full-Screen |
| **Long-Press** | **Any Source** | Play immediately | Dual-Pane / Target |

### Flow Philosophy: v135 Context
The TV UI uses a hybrid navigation model:
1. **Browse Mode**: Persistent dual-pane for the current show context.
2. **Dive Mode**: Navigation to a dedicated `TrackListScreen` for non-current shows to allow deep browsing without interrupting active playback state.
3. **Power Actions**: Long-press bypasses modals for immediate "lean-back" playback.

## 5. Performance & Physics
- **Transitions**: All TV transitions are instantaneous (`Duration.zero`) to match the Translucent Material aesthetic.
- **Physics**: No organic ripples or "breathing" animations; focus is communicated via static high-contrast borders.
- **Interaction Feedback**: All haptic feedback is **STRICTLY PROHIBITED** on TV builds. Focus is purely visual.
*   **Focus Scale:** Focused items scale by $1.05\times$ (managed by `TvFocusWrapper`).
*   **Wakelock:** The `WakelockService` is active during any playback state on TV to prevent the screen from dimming.

---
*Version: 1.2*  
*Last Updated: 2026-03-02*
