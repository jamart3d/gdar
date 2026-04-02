# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Changed
- **Fruit web settings: Interface section spacing/grouping refined**
  The Fruit-style Interface section now reads as distinct groups instead of one
  dense stack. Added Fruit-specific group headers and spacing rhythm while
  keeping Android/TV behavior unchanged.

- **Fruit web settings: Swipe-to-Block control now uses the Fruit-aligned switch row**
  Replaced the mismatched Material `SwitchListTile` presentation in the Fruit
  Interface section with the existing custom switch-row treatment so the web UI
  stays within the Fruit interaction contract.

- **HUD: removed `V` (visibility) chip**
  Redundant with `SHD` (which already shows `VIS`/`OK`/`SOFT`/`RISK`/`DEAD`) and
  with `BGT` (which tracks accumulated hidden time). VIS duration display had no
  diagnostic value. Updated `BGT` tooltip to "Total playing time with tab hidden
  (not-visible time)."

- **HUD: `AE` chip now shows `--` when engine context is not yet reported**
  Previously fell back to `_shortMode(effectiveMode)`, mirroring `ENG` and showing
  a mode label (`WBA`, `HYB`, `AUT`) rather than an actual sub-engine. `--` is
  honest; tooltip already reads "not available yet" for that value.

- **HUD: `AE` chip handles `H5B` / `H5B+` sub-engine label**
  Hybrid engine can emit `(H5B)` in contextState for background HTML5. Added
  `isH5B` detection in `_shortActiveEngine`; returns `H5B` or `H5B+` (heartbeat
  active) to match the WA/H5 pattern.

- **LG chip: sub-10ms gaps now show one decimal place**
  Values under 10ms render as e.g. `1.2ms` instead of rounding to `1ms`, giving
  finer resolution for near-gapless transitions.

- **Monorepo scoring workflow: Chromebook/Crostini reruns now prefer serial validation**
  Added serial analyze/test guidance and matching workspace scripts for
  scorecard-quality reruns. This avoids noisy `-c 2` Melos behavior on
  constrained Chromebook environments and produces cleaner validation signals.

### Fixed
- **HUD test contract updated after `HPD` sparkline/chip removal**
  The failing HUD regression test still expected `HPD` in the hybrid H5B path
  even though the sparkline/chip had been intentionally removed. The test now
  asserts absence instead of treating the removal as a product regression.

- **TV dual-pane layout: removed async `BuildContext` analyzer violation**
  Cached `ShowListProvider` before delayed callbacks in the TV random-show flow
  so `setIsChoosingRandomShow()` no longer reads from `context` after async
  gaps.

- **LG chip: gap not reported on natural track transitions (h5, h5b engines)**
  `Queue.playNext()` in `html5_audio_engine.js` and `hybrid_html5_engine.js` called
  `resetCurrentTrack()` → `seek(0)` on the just-ended track before the next track's
  `play()` could measure the gap. `_trackEndedAtMs` was wiped to 0, so the
  `if (_trackEndedAtMs > 0)` guard always failed. Fix: capture `_trackEndedAtMs`
  before the resets and restore it immediately before `play()`.

- **LG chip: gap resets to `--` on show change or manual track selection**
  `html5_audio_engine.js:setPlaylist()`, `hybrid_html5_engine.js:Track.seek()`, and
  `gapless_audio_engine.js:_setPlaylist()` all reset `_lastGapMs = null`, causing the
  chip to blank out whenever the user picked a track from the list or a new show
  loaded. The last measured gap should persist until a new transition is measured.
  Fix: removed `_lastGapMs = null` from all three reset points; `_trackEndedAtMs = 0`
  remains to prevent false measurements. Dart-side `_lastKnownGapMs` was already
  sticky so no Dart changes needed.

### Docs
- **Added monorepo architecture planning and refreshed the scorecard**
  Added a monorepo architecture plan, linked it from the monorepo rules, and
  saved a new 2026-04-01 workspace-state scorecard rerun. The rerun records an
  8.7/10 score using serial workspace validation and documents that the earlier
  HUD failure was a stale expectation rather than a live product break.
