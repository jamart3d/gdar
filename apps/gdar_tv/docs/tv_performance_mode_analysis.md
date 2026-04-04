# TV Performance Mode — Current State Analysis

**Date:** 2026-04-03

## Summary

The `performanceMode` setting (`performance_mode` key) exists as a shared
`bool` across all platforms but is **not exposed in the TV settings UI**.

## How It's Gated

The Performance Mode tile lives in the **Appearance** section and is guarded by:

```dart
// appearance_section_build.dart, line 19-24
if (themeProvider.isFruitAllowed) ...[
  ...
  if (themeProvider.themeStyle != ThemeStyle.fruit)
    _buildPerformanceModeTile(context, settingsProvider),
],
```

`isFruitAllowed` is defined in `theme_provider.dart`:

```dart
bool get isFruitAllowed => testOnlyOverrideFruitAllowed || (kIsWeb && !isTv);
```

Since TV is never web, `isFruitAllowed` is `false` and the entire block
(including the Performance Mode tile) is excluded from the TV settings screen.

## Platform Visibility

| Platform           | Perf Mode tile visible? | Reason                              |
|--------------------|-------------------------|-------------------------------------|
| Web (Fruit style)  | No                      | `themeStyle == fruit` blocks it     |
| Web (Android style)| Yes                     | `isFruitAllowed && style != fruit`  |
| Phone              | No                      | `isFruitAllowed` is false           |
| **TV**             | **No**                  | `isFruitAllowed` is false           |

## TV Default Value

`TvDefaults.performanceMode = false` — so TV always runs with performance
mode off. The key is functional if set programmatically (e.g., via ADB deep
link or `SharedPreferences` manipulation), but there is no user-facing
toggle.

## What performanceMode Gates (When Enabled)

- Liquid glass → forced off
- Glow borders → forced to 0
- Shader backgrounds → disabled
- Complex animations → simplified
- Various widget-level blur/shadow reductions

## Implications for TV Features

Since TV has no perf mode toggle, any TV-specific visual features (e.g.,
background spheres) should use their own dedicated toggle instead of relying
on `performanceMode` as a kill switch.

If multiple TV visual effects accumulate in the future, that would be the
right time to expose a TV-specific performance toggle in the TV settings UI.

## References

- `packages/shakedown_core/lib/providers/theme_provider.dart` — `isFruitAllowed`
- `packages/shakedown_core/lib/ui/widgets/settings/appearance_section_build.dart` — perf mode tile guard
- `packages/shakedown_core/lib/providers/settings_provider_core.dart` — `setPerformanceMode()`
- `packages/shakedown_core/lib/config/default_settings.dart` — `TvDefaults.performanceMode`
