# Code Hygiene Report
Date: 2026-04-11

## Scope
- apps/
- packages/

## Analyzer Findings (Confirmed)
**No issues found.** Zero `unused_import`, `unused_local_variable`, `unused_field`, `unused_element`, or `dead_code` warnings across the entire monorepo.

## Duplicate-Risk Candidates (Rated)

### DUP-1: Onboarding Screen — Full File Copy (9/10)
| | Web | Core |
|---|---|---|
| File | `apps/gdar_web/lib/ui/screens/onboarding_screen.dart` | `packages/shakedown_core/lib/ui/screens/onboarding_screen.dart` |
| Lines | 367 | 369 |

**Diff:** Only 3 meaningful differences — web conditionally routes through `SplashScreen`, core uses named routes via `ShakedownRouteNames`, and core adds `RouteSettings`. Everything else is line-for-line identical (imports, state, build, helper methods — all 360+ lines).

**Risk:** Bug fixes or UI changes must be applied in both files. The `about_screen.dart` in web already uses the correct pattern (a single `export` line). This is the most clear-cut deduplication target in the repo.

---

### DUP-2: Mobile/TV App Lifecycle Methods (7/10)
| Method | Mobile (`apps/gdar_mobile/lib/main.dart`) | TV (`apps/gdar_tv/lib/main.dart`) | Similarity |
|---|---|---|---|
| `_setScreensaverActive` | L118-126 | L101-109 | **Exact copy** |
| `_handleInactivityTimeout` | L191-193 | L213-215 | **Exact copy** |
| `_launchScreensaver` | L162-189 | L159-211 | Near-identical (TV adds double-launch guard, mounted check, enhanced logging, event-loop yield) |
| `_syncInactivityService` | L195-210 | L217-232 | Near-identical (TV adds route-blocking logic) |
| `_initDeepLinks` | L212-241 | L234-252 | Structurally similar (mobile handles `settings` deep links; TV handles `automate` via both host and path) |
| `_handleAutomation` | L243-299 | L254-304 | Near-identical (same step parsing, same settings dispatch) |

**Total duplicated surface:** ~180 lines across 6 methods.

**Risk:** Bug fixes or new automation steps need dual-apply. TV versions have legitimately richer behavior (route blocking, double-launch guard, enhanced logging) that a naive merge would flatten. A shared mixin with platform hooks would be the right extraction pattern.

---

### DUP-3: Widget Forks — show_list_item_details, source_list_item (6/10)
| Widget | Web | Core | Delta |
|---|---|---|---|
| `show_list_item_details.dart` | 167 lines | 163 lines | Web wraps in `SizedBox` with height; core uses `shrinkWrap: true` |
| `source_list_item.dart` | 299 lines | 300 lines | Core has `allowInPerformanceMode: useRgb` parameter; web omits it |

**Risk:** ~460 lines of near-identical widget code across 2 files. Differences are small enough to parameterize (e.g., an optional `height` constraint, a `bool allowInPerformanceMode` flag with a default).

---

### DUP-4: Provider Setup Trees (5/10)
| App | Location | Lines |
|---|---|---|
| Mobile | `apps/gdar_mobile/lib/main.dart:303-351` | ~48 |
| TV | `apps/gdar_tv/lib/main.dart:308-356` | ~48 |
| Web | `apps/gdar_web/lib/main.dart:139-172` | ~33 |

The `MultiProvider` tree is nearly identical across all three apps. Differences: mobile has conditional `ScreensaverLaunchDelegate`; TV always includes it + `navigatorObservers`; web omits screensaver/inactivity. `DeviceService` constructor args differ slightly.

**Risk:** Adding a new provider requires touching 3 files. A `buildCommonProviders()` factory in `shakedown_core` could reduce this to a single source of truth with platform-specific overrides passed in.

---

### DUP-5: TV Notification Guard in utils.dart (3/10)
File: `packages/shakedown_core/lib/utils/utils.dart:76-84, 118-121, 162-165`

The 6-line TV-notification-and-return pattern repeats verbatim in `showMessage()`, `showRestartMessage()`, and `showIssueMessage()`:
```dart
final isTv = context.read<DeviceService>().isTv;
if (isTv) {
  context.read<AudioProvider>().showNotification(message);
  return;
}
```

**Risk:** Low — all in one file, unlikely to drift independently. Extracting a `_handleTvNotification()` helper would save ~12 lines but adds indirection for a very small gain.

---

### DUP-6: Playback Screen TV/Mobile Variants (4/10)
Files: `playback_screen_layout_build.dart` vs `tv_playback_screen_layout_build.dart`, `playback_screen_helpers.dart` vs `tv_playback_screen_helpers.dart`, `playback_screen_fruit_build.dart` vs `tv_playback_screen_fruit_build.dart`, `playback_screen_controls.dart` vs `tv_playback_screen_controls.dart`.

**Assessment:** These are architecturally separated by design — TV needs D-pad focus handling, `TvFocusWrapper`, RGB borders, route-aware guards, and enhanced logging that mobile doesn't. The overlap (empty state builders, track focus logic) is a natural consequence of the multi-platform split, not accidental copy-paste. Forcing unification here would couple the platforms.

**Risk:** Low. The separation is intentional and provides independent velocity for each platform.

## Architecture Hotspots

| File | Lines | Concern |
|---|---|---|
| `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart` | 976 | Only non-test source file over 800 lines. Canvas rendering + text layout. Cohesive responsibility (rendering), but could split text painting vs graph drawing if it keeps growing. |
| `packages/shakedown_core/test/screens/playback_screen_test.dart` | 1342 | Large test file — acceptable for a complex screen. |
| `packages/shakedown_core/test/widgets/show_list_card_test.dart` | 1154 | Large test file — acceptable. |
| `packages/shakedown_core/test/providers/audio_provider_test.dart` | 1124 | Large test file — acceptable. |
| `apps/gdar_tv/test/tv_regression_test.dart` | 936 | Skipped during monorepo transition — may be dead weight if never re-enabled. |

## Suggested Cuts

- **delete:** `apps/gdar_web/lib/ui/screens/onboarding_screen.dart` — replace with `export 'package:shakedown_core/ui/screens/onboarding_screen.dart';` after reconciling the 3-line diff (DUP-1)
- **merge:** Web widget forks (`show_list_item_details.dart`, `source_list_item.dart`) into core versions with optional params (DUP-3)
- **extract:** Shared app lifecycle mixin from mobile/TV `main.dart` (DUP-2)
- **extract:** `buildCommonProviders()` factory into `shakedown_core` (DUP-4)

## Notes / False Positives
- **DUP-6 (playback screen variants):** Intentional platform separation, not a cleanup target.
- **DUP-5 (TV notification guard):** Too small to justify extraction — cosmetic only.
- **`tv_regression_test.dart`:** Marked as skipped for monorepo transition. Worth verifying if it will ever be re-enabled or if it should be removed.
- **`steal_graph_render_corner.dart`:** At 976 lines it's close to the threshold but internally cohesive. Monitor, don't split yet.
