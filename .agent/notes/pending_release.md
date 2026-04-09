# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Fixed
- **PWA wake lock not released when "Keep Screen On" toggled off during playback** — ordering bug in `AudioProviderLifecycle.update()` where `_settingsProvider` was assigned *after* `_updateWakeLockState()` was called, causing it to read the stale (old) value. Fix: move `_settingsProvider = settingsProvider` to before the `preventSleep` change-detection block.
  - File: `packages/shakedown_core/lib/providers/audio_provider_lifecycle.dart`

- **Show list card bottom text too small** — bumped non-Fruit default `bottomSize` from `9.5` → `11.5` sp to better fill the `flex: 43` zone; bumped RockSalt `dateFirst=false` override from `7.0` → `10.0`. Applies to web Android-style and native phone. TV unaffected (explicit override).
  - File: `packages/shakedown_core/lib/ui/widgets/show_list/card_style_utils.dart`

- **SHNID badge not stacked under src badge (Fruit web mobile)** — when "Show SHNID badge (single source)" is on, SHNID badge was appearing in the bottom inline row instead of the right-zone controls column. Moved SrcBadge + ShnidBadge into the `Positioned` right-zone column (below stars); suppressed SHNID from inline row when `showSingleShnid=true`. Also changed Fruit mobile `_buildBalancedControls` badge layout from `Row` → `Column` (right-aligned, 4px gap). Removed `#` prefix from all SHNID badge text.
  - Files: `show_list_card_controls.dart`, `show_list_card_fruit_mobile.dart`

- **SHNID badge not stacked under src badge (Fruit car mode)** — same badge placement issue in car mode. Added `shnidInColumn`/`badgeInFooter` split: SHNID now appears in the top-right column below SrcBadge; footer row and card height no longer inflated for single-shnid cards.
  - File: `show_list_card_fruit_car_mode.dart`

### Changed
- **Non-current show cards shorter (Fruit mobile/PWA)** — mini-player gap + slot now collapse to zero height via `AnimatedSize` when the card is not playing, instead of always reserving the fixed 48px slot (hidden via opacity). Current/playing card is unchanged.
  - File: `packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_fruit_mobile.dart`

- **SHNID count badge taps toggle card expansion (Fruit, multi-source, `showSingleShnid` off)** — badge was a passive `Container` with no tap handler; tapping it did not reliably expand/collapse the card. Added `tappable` named param to `_buildBadge`; when true wraps with `GestureDetector(onTap: widget.onTap)` + `MouseRegion(click cursor)` on web. Enabled for: Fruit desktop controls zone (multi-source, `showSingleShnid` off, non-TV) and Fruit mobile card content row (same condition).
  - Files: `show_list_card_controls.dart`, `show_list_card_fruit_mobile.dart`

- **Expanded source sub-list gap now natural/consistent** — removed manual `_calculateExpandedHeight` calculation (`n × 59 + 16`) and fixed `SizedBox` height from `ShowListItemDetails`. Switched `ListView.builder` to `shrinkWrap: true` with `padding: vertical: 8` so the list sizes to actual content with 8px top/bottom breathing room. Both current (playing) and non-current expanded shows now use the same layout path.
  - Files: `packages/shakedown_core/lib/ui/widgets/show_list_item_details.dart`, `packages/shakedown_core/lib/ui/widgets/show_list/show_list_item.dart`

### Tests
- Added regression test `'releases wake lock when preventSleep toggled off during active playback'` to `packages/shakedown_core/test/providers/audio_provider_test.dart` (Wake Lock group). Verified red on buggy code, green on fix.
