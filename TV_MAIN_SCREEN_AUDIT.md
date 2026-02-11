# Google TV Main Screen Audit Report
**Version**: 1.0.43+43  
**Date**: February 11, 2026  
**Auditor**: Antigravity  
**AI Model**: Gemini 2.0 Pro (Advanced Agentic Coding)  
**Model Version**: v2.0-stable  
**Generated Via**: `write_to_file` (Agentic Analysis Tool)  
**Update Command**: `/audit_design` or manual request for "TV UI Audit Update"

---

## 1. Executive Summary
This report provides a technical breakdown of the "Leaning Back" experience in **Shakedown v1.0.43**. The UI has been optimized for Google TV (10-foot UI) using an adaptive dual-pane layout that prioritizes content legibility and D-pad navigation.

## 2. Global Scaling Logic
To ensure readability from a distance, the application employs a multi-layered scaling system:

| Layer | Factor | Source |
| :--- | :--- | :--- |
| **System Scale** | 1.0x - 1.2x | User's Android Accessibility Settings |
| **In-App Multiplier** | 1.2x | `DeviceService.isTv` detection |
| **Effective Scale** | **1.2x - 1.5x** | Compounded Result (`effectiveScale`) |

> [!NOTE]
> The TV multiplier was recently refined from 1.5x down to **1.2x** to improve information density while maintaining Material 3 readability standards.

---

## 3. Visual Layout Reference (ASCII)
```text
+------------------------------------+   +------------------------------------+
|  SHOW LIST (50%) / Opacity: 1.0    | | |  PLAYBACK AREA (50%) / Opacity: 0.6 |
|  [ Dice | Search | Settings ]      | | |  [ Date | SHNID | Src | Gear ]      |
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
+------------------------------------+   +------------------------------------+
```

## 4. Dual-Pane Architecture (`TvDualPaneLayout`)
The main screen is divided into two equal functional areas using a `Row` with flexible sizing.

### Layout Dimensions
- **Container**: Full-Screen Landscape (16:9)
- **Horizontal Padding**: `24.0 pt` (increased from 16.0 pt)
- **Structural Divider**: 1px Vertical Glass Line (linear gradient)
- **Presence**: Inactive Pane Dimming (0.6 opacity)
- **Show List Pane (Left)**: `flex: 1` (50% width)
- **Playback Pane (Right)**: `flex: 1` (50% width)

---

## 5. Component Breakdown: Show List

### Show List Shell (`ShowListShell`)
In TV mode (`isPane: true`), the shell adjusts its internal structure:
- **AppBar**: Embedded directly at the top of the `Column` in `Scaffold.body`.
- **MiniPlayer**: Automatically **hidden** (playback is always visible in the right pane).

### List Card Dimensions (`ShowListCard`)
- **Base Height**: `66.0 pt` (increased from 58.0 pt)
- **Effective TV Height**: `79.2 pt` (66.0 * 1.2)
- **Layout Model**: **Vertical 2-Line** (Date below Venue)
- **Scale Fit**: `FittedBox` scaling for both lines for perfect authoritative fit.
- **Vertical Spacing**: `8.0 pt` (increased from 6.0 pt)
- **Border**: `3.0 pt` selection stroke
- **Border Radius**: `28.0 pt`

| Element | Base Size | TV Size (1.2x) | Font | Alignment |
| :--- | :--- | :--- | :--- | :--- |
| **Venue Name** | 15.0 pt | **18.0 pt** | Default | Left (Marquee) |
| **Show Date** | 9.5 pt | **11.4 pt** | Default | Right |
| **Src Badge** | 7.0 pt | **8.4 pt** | Monospace | Right-Top |

---

## 6. Component Breakdown: Playback Screen

### Playback Header (`PlaybackAppBar`)
- **Height**: `56.0 pt` (`kToolbarHeight`)
- **Blur Effect**: `sigma: 15.0` (BackdropFilter) for a premium glassmorphic look.
- **Glass Opacity**: `0.7`
- **Elements**: Formatted Date, SHNID Badge, Src Badge, and Settings gear.

### Playback Panel (`PlaybackPanel`)
The bottom controls area is anchored and redesigned for the 70/30 vertical split:
- **Layout Model**: **Vertical Hierarchy**
- **Top 70%**: Dedicated Track List.
- **Bottom 30%**: Dedicated Now Playing area.
- **Hero Title**: Primary current track title (Bold / Hero).
- **Consolidated Metadata**: Venue, Location, and Date in single horizontal row.
- **Center Focus**: All elements are center-aligned on TV for cinematic impact.

---

## 7. Navigation & Focus Interaction
- **Focus Wrapper**: `TvFocusWrapper` wraps every interactive card.
- **Scaling Effect**: Focused items scale by **1.03x** with a smooth spring transition.
- **Glow Intensity**: Tied to `SettingsProvider.glowMode` (default 20%).
- **Long-Click**: Supported on remote control "Select" buttons for immediate Quick Play/Shuffle.

---

## 8. Improvement Roadmap & Suggestions
1. **App Bar Harmonization**: Align the vertical baseline of the Show List header icons (Dice/Search) with the Playback Area's title text to create a more stable horizontal scan line.
2. **Dynamic Backdrop Shifts**: Shift the focus of the background "Atmospheric Gradient" slightly toward the active pane (e.g., move the center of the glow when switching sides).
3. **Now Playing Detail Expansion**: Provide more detailed track metadata (Composer, Taper, Transferer) when the Playback Pane is focused.
