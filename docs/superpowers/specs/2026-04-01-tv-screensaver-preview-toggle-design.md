# TV Screensaver Preview Toggle — Design Spec

**Date:** 2026-04-01
**Status:** Approved

---

## Summary

The screensaver preview panel in TV settings shows the `StealVisualizer` at a small scale. Currently, audio graph overlays (corner, circular, EKG, etc.) render at settings-screen scale and may not be meaningful in the small preview window. This change adds a `_ToggleRow` control below the Audio Graph mode selector that lets the user switch the preview between **Logo** focus (graph hidden) and **Audio Graph** focus (logo hidden, graph shown scaled to the preview box).

---

## New Setting

**Key:** `oil_preview_show_graph`
**Type:** `bool`
**Default:** `false` (Logo mode)
**Location:** `packages/shakedown_core/lib/providers/settings_provider_screensaver.dart`

Add:
- Getter `bool get oilPreviewShowGraph`
- Mutator `Future<void> toggleOilPreviewShowGraph()`

Persisted via SharedPreferences. Follows the identical pattern of all existing bool prefs in this file.

---

## Settings UI

**File:** `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_section_audio_build.dart`
**Method:** `_buildAudioGraphSection`

After the segmented button block (including the conditional EKG radius/replication/spread steppers), append:

```dart
if (settings.oilAudioGraphMode != 'off') ...[
  const SizedBox(height: 16),
  _ToggleRow(
    label: 'Preview: Audio Graph',
    subtitle: 'Show scaled audio graph in preview instead of logo',
    value: settings.oilPreviewShowGraph,
    onChanged: (_) => settings.toggleOilPreviewShowGraph(),
    colorScheme: colorScheme,
    textTheme: textTheme,
  ),
],
```

**Visibility rule:** The toggle is hidden when `oilAudioGraphMode == 'off'` (nothing graph-related to preview). It is already inside the `oilEnableAudioReactivity` conditional block, so it only shows when reactivity is on.

---

## Preview Panel Behavior

**File:** `packages/shakedown_core/lib/ui/widgets/settings/tv_screensaver_preview_panel.dart`

When building `StealConfig` for the preview, apply two overrides based on `settings.oilPreviewShowGraph`:

| Toggle state | `logoScale` in config | `audioGraphMode` in config |
|---|---|---|
| `false` — Logo (default) | `settings.oilLogoScale` (unchanged) | `'off'` (graph hidden) |
| `true` — Audio Graph | `0.0` (logo hidden) | `settings.oilAudioGraphMode` (unchanged) |

All other `StealConfig` fields are unchanged from the current preview panel construction.

> **Implementation note:** Verify that `StealVisualizer` treats `logoScale: 0.0` as fully hidden. If the logo still renders at minimum size, add a `showLogo` bool to `StealConfig` instead.

**Preview visibility:** Unchanged — the panel shows only when `useOilScreensaver && oilEnableAudioReactivity`.

**Audio reactor:** Active in both modes. No changes to reactor lifecycle.

---

## Audio Graph Scaling

`StealVisualizer` renders on a Flutter custom painter whose canvas is sized to the preview box (constrained by `AspectRatio(16/9)` inside the panel). Graph modes that use `canvas.size` for positioning (corner offset, circular radius, etc.) will auto-scale to the preview dimensions.

If runtime testing shows any graph mode renders oversized or clipped in the preview, a `previewScaleFactor` field can be added to `StealConfig` as a follow-up. That is **out of scope** for this change.

---

## Files Changed

| File | Change |
|---|---|
| `settings_provider_screensaver.dart` | Add `oilPreviewShowGraph` getter + `toggleOilPreviewShowGraph()` |
| `tv_screensaver_section_audio_build.dart` | Add `_ToggleRow` at end of `_buildAudioGraphSection` |
| `tv_screensaver_preview_panel.dart` | Override `logoScale` / `audioGraphMode` in `StealConfig` based on pref |

---

## Out of Scope

- `previewScaleFactor` in `StealConfig` (follow-up only if auto-scaling is insufficient)
- Any changes to the full-screen screensaver behavior
- Web or mobile platforms (preview panel returns `SizedBox.shrink()` on web)
