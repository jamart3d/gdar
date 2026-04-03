# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

- Web UI / Fruit playback: fixed the floating now-playing inset so the track
  list can scroll to the end when the Audio HUD is on and sticky player is off.
- Web UI / Fruit curation: rating stars now use fixed curation yellow
  (`#FFC107`) instead of inheriting the active Fruit palette primary.
- Web UI / Fruit RGB: active playback RGB borders now continue to work when
  Liquid Glass is off and when Simple Theme / `performanceMode` is on.
- Web UI / Fruit playback player: the Fruit now-playing / player card now uses
  the animated RGB border when `Highlight Playing with RGB` is enabled.
- Specs and regression tests were updated for the Fruit playback inset, rating
  star color override, RGB-in-performance-mode behavior, and the RGB player
  border contract.
- Monorepo docs: added a scorecard-derived todo list, refreshed the 2026-04-02
  scorecard evidence, and updated the architecture plan to match the current
  style/core package graph while noting the incomplete `screensaver_tv`
  manifest verification.
- Validation: captured a fresh serial analyzer pass and standard web release
  verification, then fixed the `PlaybackScreen` Fruit inset analyzer warning by
  routing the measurement update through a private state method.
- TV screensaver settings maintainability: split the large TV screensaver
  settings builder into dedicated system, visual, track-info, and audio
  section part files without changing behavior.
- Screensaver banner maintainability: split `StealBanner` into dedicated flat
  render and ring render part files while keeping banner state/update flow in
  the main component file.
