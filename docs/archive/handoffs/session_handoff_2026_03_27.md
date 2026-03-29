# Session Handoff - Fruit Font Enforcement, Mark Played on Start, UI Polish
**Date:** 2026-03-27
**Status:** ✅ COMPLETE. All features implemented, checkup passed: 0 analyzer issues, 256/256 tests passing.

---

## Scope Rule

- Fruit font enforcement is Fruit-only — no non-Fruit visual regressions expected.
- `markPlayedOnStart` rename is cross-platform plumbing — TV, web, and mobile all share the new key.
- All mock/test file renames are mechanical — no logic changed.
- `ThemeProvider` reads in `ShakedownTitle` and `EmbeddedMiniPlayer` use nullable `ThemeProvider?` — safe for all test trees.

---

## Feature: Mark Played on Start (replaces Sequence Run Detection)

Renamed and repurposed the old "Sequence Run Detection" toggle.

### Files changed

| File | Change |
|---|---|
| `packages/shakedown_core/lib/config/default_settings.dart` | `enableRunDetection = false` → `markPlayedOnStart = true` (default ON) |
| `packages/shakedown_core/lib/providers/settings_provider_core.dart` | Key, field, getter, toggle all renamed to `markPlayedOnStart` |
| `packages/shakedown_core/lib/providers/settings_provider_initialization.dart` | Load from `mark_played_on_start` SharedPrefs key |
| `packages/shakedown_core/lib/services/random_show_selector.dart` | Removed `_suggestFromRun` method and all run-detection logic |
| `packages/shakedown_core/lib/providers/audio_provider_playback.dart` | On `playSource`: mark show as played + increment play count immediately if `markPlayedOnStart == true` and not yet played |
| `packages/shakedown_core/lib/ui/widgets/settings/playback_section_build.dart` | Removed HUD abbreviation legend call; renamed tile; moved "Mark Played on Start" to below `RandomProbabilityCard` |

### Mock/test files updated (mechanical rename only)

- `packages/shakedown_core/test/helpers/fake_settings_provider.dart`
- `packages/shakedown_core/test/providers/audio_provider_regression_test.mocks.dart`
- `packages/shakedown_core/test/providers/audio_provider_test.mocks.dart`
- `packages/shakedown_core/test/providers/show_list_provider_test.mocks.dart`
- `packages/shakedown_core/test/screens/splash_screen_test.mocks.dart`
- `packages/shakedown_core/test/ui/widgets/playback/playback_messages_test.mocks.dart`
- `packages/shakedown_core/test/ui/widgets/mini_player_test.mocks.dart`
- `apps/gdar_tv/test/tv_regression_test.dart`

---

## Feature: Fruit Font Enforcement (Inter everywhere except "Shakedown" branding)

Per Fruit spec section 5: Inter is the only font in Fruit UI. "Shakedown" title text stays Rock Salt.

### Files changed

| File | Change |
|---|---|
| `packages/shakedown_core/lib/ui/screens/settings_screen.dart` | Inject `textTheme.apply(fontFamily: 'Inter')` into `effectiveTheme` when `isFruit` |
| `packages/shakedown_core/lib/ui/screens/playback_screen_build.dart` | 9 instances: popup menu labels, status text, show date/venue/location — all use `isFruit ? 'Inter' : FontConfig.resolve('RockSalt')` or `fontFamily: isFruit ? 'Inter' : null`; added `isFruit` to `_buildFruitTopBar` scope |
| `packages/shakedown_core/lib/ui/widgets/shakedown_title.dart` | Force `FontConfig.resolve('RockSalt')` when `isFruit`; uses `ThemeProvider?` (nullable) for test safety |
| `packages/shakedown_core/lib/ui/screens/about_screen.dart` | `AboutBody`: added `isFruit` local; "Shakedown" text uses Rock Salt when `isFruit` or TV |
| `packages/shakedown_core/lib/ui/widgets/show_list/card_style_utils.dart` | `venueStyle`/`dateStyle`: force `fontFamily: 'Inter'` in Fruit; Fruit desktop multiplier applied after font guard |

---

## Feature: Fruit Show List Card Text Size / Gap

- Date and venue text proportionally larger on Fruit desktop (unstacked layout).
- Gap between date and venue reduced: `const Spacer()` → `SizedBox(width: 24)` for Fruit.

### Files changed

| File | Change |
|---|---|
| `packages/shakedown_core/lib/ui/widgets/show_list/card_style_utils.dart` | `topSize *= 1.1`, `bottomSize *= 1.3` for Fruit desktop |
| `packages/shakedown_core/lib/ui/widgets/show_list/show_list_card_build.dart` | `Spacer` → `SizedBox(width: 24)` for Fruit; non-Fruit keeps `Spacer` |

---

## Feature: Mini Player Polish (Fruit)

- Track title larger in compact Fruit mode (22px vs 18px).
- Time text right-aligned.
- Progress bar width matches time text width via `IntrinsicWidth` + `CrossAxisAlignment.stretch`.

### Files changed

| File | Change |
|---|---|
| `packages/shakedown_core/lib/ui/widgets/show_list/embedded_mini_player.dart` | `titleSize` uses `isFruit ? 22.0 : 18.0` in compact; time text `textAlign: TextAlign.end`; `IntrinsicWidth` wraps compact time+progress column; `ThemeProvider?` nullable read |

---

## Cleanup

- Removed `_buildDevHudAbbreviationLegend` method from `playback_section_web.dart` (was already uncalled, now deleted).

---

## Test Fixes (this session — checkup)

Three test regressions introduced by this session's changes, all fixed during checkup:

| File | Fix |
|---|---|
| `packages/shakedown_core/test/ui/widgets/fruit/fruit_tab_bar_platform_contract_test.dart` | Added `bool get fruitDenseList => false` to `_FakeSettings` |
| `packages/shakedown_core/lib/ui/widgets/shakedown_title.dart` | Changed `context.read<ThemeProvider>()` → `context.read<ThemeProvider?>()` (nullable) |
| `packages/shakedown_core/lib/ui/widgets/show_list/embedded_mini_player.dart` | Same nullable ThemeProvider read |
| `packages/shakedown_core/test/ui/widgets/show_list/embedded_mini_player_test.dart` | Replaced `Flexible(flex: 0)` + unbounded ConstrainedBox with `SizedBox(width: 350)` to prevent infinite-width overflow in test |

---

## Verification Status

- ✅ `dart fix --apply` — nothing to fix
- ✅ `melos run format` — 0 files changed (302 formatted)
- ✅ `melos run analyze` — 0 issues across all 7 packages
- ✅ `melos run test` — 256/256 passing (4 packages: gdar_mobile ✅, gdar_tv ✅, shakedown_core ✅, + skipped suites)
- ✅ Visual scan — no `withOpacity` usage; hardcoded colors are all pre-existing contextual (screensaver, TV black bg, status dots)
- Last commit: pending (not yet saved this session)

---

## Recommended Smoke Tests (manual, web Fruit)

1. Show list (unstacked): date/venue text size, reduced gap, Inter font
2. Mini player: title size, time right-aligned, progress bar matches time width
3. Playback screen: all text Inter except "Shakedown" popup/header
4. Settings: all text Inter
5. About screen: "Shakedown" in Rock Salt
6. `markPlayedOnStart` behavior: play a show → check it's immediately marked as played
7. "Mark Played on Start" toggle appears below the Selection Probability chart in Settings > Playback
