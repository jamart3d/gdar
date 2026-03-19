# Performance Mode (Simple Theme) Gates

### 1. Default Behavior (as of 2026-03-19)
`WebDefaults.performanceMode = false` — capable desktop and modern phones boot **Fruit-first** with liquid glass enabled.

Low-power detection (`isLikelyLowPowerWebDevice()` in `utils/web_perf_hint.dart`) opts low-power devices in automatically on first run:
- Mobile UA + `cores <= 2`, or `cores <= 4 && devicePixelRatio < 2.0`
- `SettingsProvider` sets `performanceMode = true` and persists it
- `gdar_web/lib/main.dart` sets `ThemeStyle.android` (not Fruit) for low-power devices

### 2. Visual Prohibitions
When `performanceMode` is `true`, the following MUST be gated/disabled:
- **Blurs**: `BackdropFilter`, `ImageFilter.blur`, translucent blurred layers
- **Shadows**: all `BoxShadow` (except subtle depth in True Black mode when glow > 0)
- **Complex Animations**: large hero transitions, audio-reactive particle systems
- **Glows**: `AnimatedGradientBorder` effects and neon flickers
- **Liquid Glass**: `fruitEnableLiquidGlass` is set `false` automatically

### 3. UI Component Specifics
- **FruitTabBar**: use solid backgrounds/borders instead of glass blurs
- **Settings Headers**: remove translucency and overlapping filters
- **Mini Player**: simplify to flat colors

### 4. Implementation Pattern
```dart
final isSimple = settingsProvider.performanceMode;

decoration: BoxDecoration(
  color: isSimple ? baseColor : baseColor.withValues(alpha: 0.8),
  boxShadow: isSimple ? null : [defaultShadow],
),
```

### 5. Theme Transition Resets
- **Constraint:** Do NOT gate theme initialization or state resets behind `performanceMode`.
- When switching to Fruit theme, `glowMode` and related flags MUST reset regardless of performance mode state. Failing to do so leaves glow stuck in Fruit theme.
- Test theme activation with both `performanceMode` enabled and disabled.
