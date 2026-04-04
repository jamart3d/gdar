# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Web Fruit settings and car mode
- Added a persisted `car_mode` setting in `SettingsProvider`, defaulting to off.
- Added a Fruit web `Car Mode` toggle below `UI Scale` in Interface settings.
- Made `Car Mode` force `UI Scale` off, and hide the `UI Scale` toggle while `Car Mode` is enabled.
- Added targeted tests covering `carMode` persistence, `UI Scale` shutoff, settings visibility, and larger Fruit tab bar sizing in car mode.

### Web Fruit playback car mode
- Added a dedicated Fruit playback car-mode layout that activates only when `carMode` is enabled.
- Reworked the car-mode playback hierarchy to use a large metadata-first layout with venue, location, date, current track, progress, controls, and upcoming tracks in that order.
- Added a toggleable top chip row in car mode with two states:
  - playback stats: `DFT`, `HD`, `NXT`, `LG`
  - metadata: rating, `SRC`, and `SHNID`
- Made the top chip row always visible in car mode, even when Audio HUD is off.
- Removed labels from the metadata row, removed the card boundary around rating stars, and stabilized the right-side chip sizing across toggle states.
- Added a more visible buffered-progress rail inside the car-mode progress bar, changed the right readout from remaining time to total duration, and restored the pending prebuffer pulse cue.
- Enlarged car-mode metadata typography, moved the controls closer under the progress bar, and expanded the upcoming queue to show up to four tracks with stepped emphasis.
- Added optional passive floating spheres for Fruit playback car mode, with a settings toggle and performance safeguards:
  - reduced blur
  - stepped animation updates
  - static behavior in `performanceMode`
  - continuous drift motion without cycle resets
- Improved the car-mode play/pause button treatment when Fruit liquid glass is enabled.
- Replaced the car-mode metadata chip pair with a plain stacked text block so `SRC` sits above `SHNID` with no chip borders or backgrounds.
- Doubled the visible size of the car-mode rating stars and expanded the tappable rating zone so tapping anywhere around the star cluster opens the rating dialog.
- Added focused playback and tab-bar test coverage for the car-mode layout and behavior.

### Web Fruit library car mode
- Added a Fruit library/show-list car-mode treatment for web that activates when `carMode` is enabled.
- Gave the Fruit library header, spacing, and list density a larger car-mode presentation.
- Added a dedicated taller Fruit car-mode show-list card layout with larger venue, location, date, rating, and source/badge affordances so fewer shows are visible at once.
- Made Fruit library car-mode cards respect the existing `dateFirstInShowCard` setting.
- Reworked the car-mode show-list card footer so source metadata stacks under the rating area and the embedded mini player gets a wider right-aligned slot for larger duration/progress presentation.
- Added focused show-list test coverage for the Fruit car-mode card branch and kept the Fruit show-list contract tests passing.
