# TV UI & Flow Audit Report

**Date**: 2026-03-02
**Version**: 1.1.39+139
**Device Focus**: Google TV / Android TV (D-Pad Navigation)

## 1. Executive Summary
The application's TV experience is highly functional, leveraging a specialized `TvDualPaneLayout` and `deviceService.isTv` gating. Focus management is explicit and reliable across the main screen regions. Typography and scaling are properly gated with a 1.2x multiplier for TV devices.

## 2. Findings & Categorization

### 🔴 Critical: Focus & Navigation
*   **None Found**: No focus traps were identified. The "Back" button is correctly handled via a `PopScope` and a TV-friendly exit dialog.

### 🟡 UI Consistency: Layout & Scaling
*   **Snackbar Positioning**: Standard `ScaffoldMessenger` snackbars appear at the bottom of the screen. While functional, they can be obscured on some TV sets due to overscan or simply missed in the large UI.
    *   *Recommendation*: Pipe critical errors to `PlaybackMessages` (Top Right) or use a centered "Toast" style widget for TV.
*   **Overscan Safe Areas**: `TvDualPaneLayout` uses a 48px horizontal padding. This is generally sufficient for modern TVs but should be monitored.

### 🟢 Optimization: Remote Control Efficiency
*   **Global Media Keys**: The app lacks a global `Shortcuts` / `Actions` mapping for hardware remote buttons like `MediaPlayPause`, `MediaNext`, and `MediaPrevious`.
    *   *Current State*: Users must navigate focus to the Play/Pause button or the Progress bar to seek/toggle.
    *   *Recommendation*: Wrap `MaterialApp` or `TvDualPaneLayout` in a `Shortcuts` widget to map these keys directly to `AudioProvider` actions.
*   **D-Pad Rapid Seek**: While `TvPlaybackBar` handles Arrow Left/Right for 10s seeking, adding a visual "Seek Overlay" (e.g., `+10s` / `-10s` icon in the center) would improve UX.

---

## 3. Recommended Implementation (Global Shortcuts)

To resolve the remote button optimization, it is recommended to add the following mapping in `main.dart` or `TvDualPaneLayout`:

```dart
// Suggested Shortcut Mapping
Shortcuts(
  shortcuts: <LogicalKeySet, Intent>{
    LogicalKeySet(LogicalKeyboardKey.mediaPlayPause): const PlayPauseIntent(),
    LogicalKeySet(LogicalKeyboardKey.mediaNext): const NextTrackIntent(),
    LogicalKeySet(LogicalKeyboardKey.mediaPrevious): const PreviousTrackIntent(),
  },
  child: Actions(
    actions: <Type, Action<Intent>>{
      PlayPauseIntent: CallbackAction<PlayPauseIntent>(
        onInvoke: (_) => audioProvider.togglePlayPause(),
      ),
      // ... next/prev actions
    },
    child: child,
  ),
)
```

---

## 4. Checklist Verification
- [x] **TV Detection**: Uses `deviceService.isTv` correctly.
- [x] **Header Logic**: Playback header correctly shows Date/Venue instead of track list.
- [x] **Typography**: 1.2x scale confirmed in `AppTypography`.
- [x] **Focus Indicators**: Spring-based scale and glass borders confirmed in `TvFocusWrapper`.
- [x] **Safe Areas**: 48px padding present in dual-pane layout.
