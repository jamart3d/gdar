# Google TV Main Screen Audit Report
**Version**: 1.0.50+50
**Date**: February 14, 2026
**Auditor**: Antigravity
**AI Model**: Gemini 2.0 Pro (Advanced Agentic Coding)
**Model Version**: v2.0-stable
**Generated Via**: `write_to_file` (Agentic Analysis Tool)
**Update Command**: `/audit_design` or manual request for "TV UI Audit Update"

---

## 1. Executive Summary
This report provides a technical breakdown of the "Leaning Back" experience in **Shakedown v1.0.50**. The UI has been heavily optimized for Google TV (10-foot UI) using an adaptive dual-pane layout that prioritizes content legibility, high information density, and ergonomic D-pad navigation.

## 2. Global Scaling Logic
To ensure readability from a distance, the application employs a multi-layered scaling system:

| Layer | Factor | Source |
| :--- | :--- | :--- |
| **System Scale** | 1.0x - 1.2x | User's Android Accessibility Settings |
| **In-App Multiplier** | 1.2x | `DeviceService.isTv` detection |
| **Effective Scale** | **1.2x - 1.5x** | Compounded Result (`effectiveScale`) |

> [!NOTE]
> Specific components (Track List) now opt-out of focus scaling (1.0x) to preserve layout stability and density.

---

## 3. Visual Layout Reference (ASCII)
```text
+------------------------------------+   +------------------------------------+
|  SHOW LIST (Left Pane)             | | |  PLAYBACK (Right Pane)             |
|  [ Dice | SHAKEDOWN | Gear ]       | | |  [ TRACK LIST ]                    |
|                                    | | |                                    |
|  +------------------------------+  | | |  +------------------------------+  |
|  | Venue (ScaleFit)             |  | |/|  |                              |  |
|  | Date (ScaleFit)              |  | |G|  |         TRACK LIST           |  |
|  +------------------------------+  | |L|  |           (70%)              |  |
|  | Venue (Focused)              |  | |A|  |                              |  |
|  | Date                         |  | |S|  +------------------------------+  |
|  +------------------------------+  | |S|  |                              |  |
|  | Venue                        |  | | |  |       CURRENT TRACK (Hero)   |  |
|  | Date                         |  | | |  |         Venue • Loc • Date   |  |
|  +------------------------------+  | | |  |  [=======|------------------] |  |
|                                    | | |  |    [Prev]   [PLAY]   [Next]  |  |
|                                    | | |  +------------------------------+  |
+------------------------------------+   +------------------------------------+
```

## 4. Dual-Pane Architecture (`TvDualPaneLayout`)
The main screen is divided into two equal functional areas using a `Row` with flexible sizing.

### Layout Dimensions
- **Container**: Full-Screen Landscape (16:9)
- **Horizontal Padding**: `24.0 pt`
- **Structural Divider**: 1px Vertical Glass Line (linear gradient)
- **Presence**: Inactive Pane Dimming (0.6 opacity)
- **Show List Pane (Left)**: `flex: 1` (50% width)
- **Playback Pane (Right)**: `flex: 1` (50% width)

---

## 5. Component Breakdown: Show List

### Show List Shell (`ShowListShell`)
In TV mode (`isPane: true`):
- **AppBar**: Embedded directly at the top of the `Column` in `Scaffold.body`.
- **MiniPlayer**: Hidden (redundant with right pane).

### Left Pane Header (`TvHeader`)
- **Elements**: [ Dice (Random) | SHAKEDOWN (Title) | Gear (Settings) ]
- **Search**: Hidden/Absent in TV mode to simplify navigation.
- **Focus**: Dice and Gear are focusable endpoints.

### List Card Dimensions (`ShowListCard`)
- **Base Height**: `48.0 pt` (Reduced for density)
- **Effective TV Height**: `57.6 pt` (48.0 * 1.2)
- **Layout Model**: **Vertical 2-Line** (Date below Venue)
- **Scale Fit**: `FittedBox` scaling for both lines.
- **Vertical Spacing**: `2.0 pt` (Minimal padding)
- **Border Radius**: `12.0 pt` (Matched to Track List)
- **Focus Behavior**: Standard focus scaling enabled.

| Element | Base Size | TV Size (1.2x) | Font | Alignment |
| :--- | :--- | :--- | :--- | :--- |
| **Venue Name** | 15.0 pt | **18.0 pt** | Default | Left (Marquee) |
| **Show Date** | 9.5 pt | **11.4 pt** | Default | Right |
| **Src Badge** | 7.0 pt | **8.4 pt** | Monospace | Right-Top |

---

## 6. Component Breakdown: Playback Screen

### Right Pane Header (Custom)
- **Type**: Simple Text Header (`Column` child)
- **Content**: "TRACK LIST"
- **Style**: Rock Salt, 24pt, Bold
- **Note**: The standard `PlaybackAppBar` is **hidden** in TV mode to reduce visual noise.

### Playback Panel (`PlaybackPanel`)
- **Layout Model**: **Vertical Hierarchy** (70% Track List / 30% Now Playing)
- **Track List**:
    - **Font Size**: `14.0 pt` (TV Optimized)
    - **Visual Density**: `Compact`
    - **Focus Scaling**: **Disabled (1.0x)** to prevent layout shifts.
    - **Focus Indicator**: High-contrast background (`onSurface`), transparent border.
    - **Items Visible**: ~8-9 tracks.

---

## 7. Navigation & Focus Interaction
- **Focus Wrapper**: `TvFocusWrapper` wraps every interactive card.
- **Smart Focus**:
    - **Right**: Jumps from `ShowList` to `Scrollbar` or `TrackList`.
    - **Left**: Jumps from `ShowList` to `Dice Icon` (Header).
- **Wrap-Around**: Track list navigation wraps from bottom to top.
- **Long-Click**: Supported for immediate Quick Play.

## 8. Improvement Roadmap & Suggestions
1. **App Bar Harmonization**: Align the vertical baseline of the Show List header icons (Dice/Search) with the Playback Area's title text to create a more stable horizontal scan line.
2. **Dynamic Backdrop Shifts**: Shift the focus of the background "Atmospheric Gradient" slightly toward the active pane.
3. **Now Playing Detail Expansion**: Provide more detailed track metadata (Composer, Taper) when focused.
