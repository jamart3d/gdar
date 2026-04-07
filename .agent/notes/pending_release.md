# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### TV Screensaver — Audio Graph & Preview Panel
- **Preview panel now updates live** — settings changes reflect in the preview
  immediately without navigating away and back (removed LayoutBuilder deferral).
- **Audio graph scales to fit preview** — all graph modes (corner, EKG, circular,
  VU, scope, beat debug) now scale correctly inside the small settings preview
  panel using a 512px reference for preview-sized containers.
- **Logo hidden when audio graph preview is active** — fixed shader clamp that
  kept the logo at 5% opacity; logo and trail are now fully suppressed when
  graph preview is on.

### TV Screensaver — VU Meters
- Removed peak-hold indicator dots from VU needle meters.
- VU needles no longer bleed through the spindle hub — needle now starts at the
  spindle edge rather than the pivot centre.

### TV Screensaver — Beat Debug Graph
- Added live `● BEAT` indicator next to the FINAL PCM meter label.
- Removed flash-burst and winning-algo indicator dots from the algorithm bars.

### TV Screensaver — Enhanced Beat Detector Settings
- Reduced info tiles from 4 to 2 (merged redundant descriptions).
- Status tile is now colour-coded: green (active), orange (stale/fallback),
  red (permission missing).
