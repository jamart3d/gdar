# Debug: Copy Show Detail — Web Clipboard Bug

## Symptom
Clicking the copy icon (LucideIcons.copy) on the Fruit web playback screen puts incorrect
data in the clipboard. Works correctly on phone (Material theme).

## Copy button locations
| Platform | File | Function | Format |
|---|---|---|---|
| Phone (Material) | `packages/shakedown_core/lib/ui/widgets/playback/playback_panel.dart` | `_buildCopyButton` | `AppDateUtils.formatDate(...)` |
| Web (Fruit) | `packages/shakedown_core/lib/ui/screens/playback_screen_fruit_build.dart` | `_buildFruitCopyButton` | `DateFormat('EEEE, MMMM d, y')` (hardcoded long format) |

## Expected format (both platforms)
```
{venue}{locationStr} - {formattedDate} - {sourceId}
{trackTitle}
[{archiveUrl}]     ← only if omitHttpPathInCopy = false
```

## Known difference
Phone uses `AppDateUtils.formatDate(currentShow.date, settings: settingsProvider)` which
respects user settings (`showDayOfWeek`, `abbreviateDayOfWeek`, `abbreviateMonth`).

Web uses `dateText = DateFormat('EEEE, MMMM d, y').format(dateTime)` — the **display**
date format for the top bar header — hardcoded to always include full day of week + full month.

**With default settings** (`showDayOfWeek=true`, full month, full day), output is identical:
`"Sunday, May 8, 1977"`. The discrepancy only shows if user changed date format settings.

## What I've ruled out
- Copy logic itself unchanged since `e1784ed` (v1.3.23+233) when `_buildFruitCopyButton` was introduced
- `currentShow`, `currentSource` captured at build time from `audioProvider.currentShow/currentSource`; the parent `_buildFruitTopBar` watches `AudioProvider` so should rebuild on show/source change
- `audioProvider.currentTrack` is always read at tap time (not stale)
- URL split logic (`sublist(0,5)`) produces correct archive.org/details URL
- `omitHttpPathInCopy` default is `true` so URL not included by default — same on both platforms
- No breaking change to copy logic in recent commits (`cc50f33` → `bb1073d` → ... → current uncommitted changes)

## What I have NOT verified
1. **Whether `audioProvider.currentTrack` returns correct data on web** — the JsAudioPlayer's
   `currentIndex` and `sequence` need to be correct for `currentTrack` to return the right
   `Track` object. If wrong, `track.title` and `track.url` could be from the wrong track.
   → Check: `packages/shakedown_core/lib/providers/audio_provider_state.dart` `currentTrack` getter,
     and how `JsAudioPlayer` (web) implements `currentIndex` and `sequence`.

2. **Whether `currentSource` could be null at tap time** — if `currentSource` is null when
   the button is built, the closure returns early and nothing is copied. User sees empty
   clipboard or stale clipboard.
   → Check: confirm `audioProvider.currentSource` is never null while a track is playing.

3. **Whether there's a stale-closure scenario** — if the Fruit playback screen doesn't
   rebuild when show/source changes (e.g. if `context.watch<AudioProvider>()` in
   `_buildFruitTopBar` isn't triggering), `currentShow` / `currentSource` in the closure
   could be from a previous show.
   → Check: add debug print to confirm `_buildFruitTopBar` rebuilds on track change.

4. **What version it "used to work" in** — user says it worked before. Since the format
   has been the same since v1.3.23, either:
   a. It worked with the current format and something else changed, OR
   b. "Used to work" refers to before the Fruit playback screen (when phone `PlaybackPanel`
      was used on web too).
   → Ask user: what exactly is wrong (wrong show? wrong track? no copy at all?
     wrong date format?).

5. **Whether `_buildFruitTopBar` is actually being rendered** — it's in a `Positioned`
   overlay at top of `_buildFruitPlaybackScaffold`. Confirm it's visible and tappable
   (not behind another widget or clipped).

## Immediate safe fix (inconsistency fix, low risk)
Change `_buildFruitCopyButton` call in `_buildFruitTopBar` to use settings-aware date:

```dart
// In playback_screen_fruit_build.dart _buildFruitTopBar(), line ~90
_buildFruitCopyButton(
  context,
  scaleFactor,
  currentShow,
  currentSource,
  AppDateUtils.formatDate(currentShow.date, settings: settingsProvider), // was: dateText
),
```

This aligns web copy with phone copy behavior for date format. Low risk — only affects
users with non-default date settings. Requires `AppDateUtils` import (already in scope
since `Show.formattedDate` and other utils are used).

## Next step to identify root cause
Ask user specifically: **what does the clipboard contain?** (screenshot or paste the
exact text). That will narrow down whether it's:
- Wrong date format
- Wrong show/track info entirely
- Empty / nothing copied
