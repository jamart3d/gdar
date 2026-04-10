# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]
- Web Fruit car mode resilience: added a one-shot playback state resync when
  entering Fruit car mode to reduce stale progress/duration UI after tick stalls.
- Added `AudioProvider.resyncWebEngine({reason})` and `GaplessPlayer.resync({reason})`
  API surface; web implementation pulls fresh JS state, native remains a no-op.
- Preserved existing watchdog/visibility recovery and added an entry-trigger guard
  so resync runs once per car-mode entry cycle.
- Added widget regression coverage:
  `PlaybackScreen triggers one-shot engine resync on Fruit car mode entry`.
- Verified in-session:
  - `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart --plain-name "one-shot engine resync"`
  - `flutter test packages/shakedown_core/test/screens/playback_screen_fruit_car_mode_test.dart`
  - `flutter test packages/shakedown_core/test/services/web_tick_stall_policy_test.dart`
  - `flutter test packages/shakedown_core/test/screens/playback_screen_test.dart --plain-name "uses Fruit car mode layout"`
- Web Fruit show-list layout polish (stacked + non-stacked):
  - Fruit car-mode idle cards (`showDateFirst=false`) now allow wrapped venue
    headlines and compute extra card height so long venues no longer ellipsize.
  - Idle venue-first cards were visually lowered using asymmetric vertical padding
    (more top, less bottom) for better balance.
  - Fruit car-mode date row now supports `SRC + SHNID` together when
    `showSingleShnid` is enabled for single-source shows.
  - Fruit stacked mobile/web cards: removed duplicate top-right `SRC` badge when
    single-source SHNID mode is on (keep lower row `SRC` + SHNID only).
  - Fruit non-stacked desktop playing-row layout tuned iteratively:
    - moved inline mini player to appear after left venue/location text
    - tightened venue->player seam (reduced oversized gap)
    - restored right-edge anchoring for trailing date/venue text in playing rows
    - increased date->controls spacing in non-glass/single-SHNID states.
- Added widget regression coverage:
  - `ShowListCard Fruit car mode idle cards wrap venue when date-first is off`
  - `ShowListCard Fruit car mode shows src and shnid badges when single-source shnid is enabled`
- Verified in-session:
  - `flutter test packages/shakedown_core/test/widgets/show_list_card_test.dart`
- Follow-up Fruit show-list unstacked playing-row refinements:
  - Reworked desktop unstacked playing-row composition to place inline mini player
    after left `venue | location` text while keeping the trailing text lane
    right-aligned.
  - Iteratively tuned venue->player seam and date->controls spacing for a cleaner
    visual gap in non-glass/single-SHNID states.
  - Added canonical location resolver for show-list row rendering:
    `resolveInlineShowLocation(show, playingSource)` now prefers
    `show.location` and only falls back to `playingSource.location` when empty,
    preventing incorrect source-derived city/state in show list cards.
  - Added tests:
    - `resolveInlineShowLocation prefers canonical show location over playing source location`
    - `resolveInlineShowLocation falls back to playing source location`
  - Expanded inline player sizing controls by adding `compactMaxWidth` to
    `EmbeddedMiniPlayer` and rebalancing unstacked playing-row flex/width caps so
    track title has priority without over-clipping venue/location.
- Verified in-session:
  - `flutter test packages/shakedown_core/test/widgets/show_list_card_test.dart`
