# Pending Release Notes

### Added
- **UI/UX (TV)**: Implemented "Surgical Stabilization" for Premium Highlights. The widget tree now remains structurally identical whether highlights are on or off, preventing focus loops and "wacky flow" during navigation.
- **UI/UX (TV)**: Added "Safe-Zone Scrolling" to the track list. Intelligent visibility checks now prevent unnecessary list movement, only scrolling when the focused item reaches the viewport edges.

### Fixed
- **UI/UX (TV)**: Resolved "leftover highlights" bug by implementing an explicit unfocus broadcast across all track nodes before a new focus is granted.
- **UI/UX (TV)**: Fixed layout shifting caused by mounting/unmounting `AnimatedGradientBorder` by ensuring it stays mounted and uses zero-padding when features are disabled.
- **UI/UX (TV)**: Added a zero-cost performance short-circuit to the RGB border painter when the border width is zero.
