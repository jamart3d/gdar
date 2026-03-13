# Performance Mode (Simple Theme) Gates

### 1. Goal
Performance Mode (Simple Theme) is designed to ensure the application remains fluid on low-power devices (older phones, low-end TV boxes) and efficient in PWA environments.

### 2. Visual Prohibitions
When `performanceMode` is `true`, the following visual effects MUST be gated/disabled:
- **Blurs**: `BackdropFilter`, `ImageFilter.blur`, or any translucent blurred layers.
- **Shadows**: All `BoxShadow` elements (except for extremely subtle depth indicators in True Black mode if intensity is high).
- **Complex Animations**: Large-scale hero transitions or audio-reactive particle systems (the screensaver has its own performance gates).
- **Glows**: `AnimatedGradientBorder` glow effects and intense neon flickers.

### 3. UI Component Specifics
- **FruitTabBar**: Use solid backgrounds/borders instead of glass blurs.
- **Settings Headers**: Remove translucency and overlapping filters.
- **Mini Player**: Simplify to flat colors.

### 4. Implementation Pattern
Always use the `settingsProvider.performanceMode` flag to conditionally render or style widgets:
```dart
final isSimple = settingsProvider.performanceMode;
// ...
decoration: BoxDecoration(
  color: isSimple ? baseColor : baseColor.withValues(alpha: 0.8),
  boxShadow: isSimple ? null : [defaultShadow],
),
### 5. Initialization & State Resets
When transitioning between themes (e.g., Material 3 to Fruit), certain secondary flags (like `glowMode`) may need strict resets to preserve brand integrity.
- **Constraint:** Do NOT gate theme initialization logic or state resets behind `performanceMode`. 
- **Example:** In `ThemeProvider`, the initial reset of `glowMode` when switching to Fruit theme MUST happen regardless of whether `performanceMode` is active. Failing to do so can lead to "Glow Mode" sticking in the Fruit theme when it should be disabled for that look.
- **Testing:** Ensure theme activation tests verify state resets with both `performanceMode` enabled and disabled.
