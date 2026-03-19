# Fruit Theme Architecture Boundaries

The Fruit (Liquid Glass) theme is exclusive to Web/PWA. It must not bleed into native mobile or TV.

### 1. Platform Gating
- Gate Fruit-specific widgets on `kIsWeb` (compile-time) and/or `themeProvider.themeStyle == ThemeStyle.fruit`.
- Native Android, iOS, and TV expect platform-standard Material 3 interfaces.

### 2. LiquidGlassWrapper
- `LiquidGlassWrapper` is gated internally: `isAllowedPlatform = kIsWeb && !dev.isTv`.
- **Do NOT instantiate `LiquidGlassWrapper` on phone or desktop** even if it self-bypasses internally — the widget tree work is unnecessary and the bypass is not guaranteed to stay.
- Correct guard pattern in `fruit_tab_bar.dart`:
  ```dart
  if (isTrueBlackMode || isLiquidGlassOff || !kIsWeb) {
    return content; // phone/desktop: skip wrapper entirely
  }
  return _FruitTabBarShell(child: content); // web only
  ```

### 3. Performance Mode Fallback
When Fruit effects are disabled (performance mode or settings toggle):
- **Keep Fruit structure** — layout, spacing, control hierarchy stay Fruit.
- **Do NOT** swap to Material 3 components, ripples, or FAB patterns.
- `fruitEnableLiquidGlass` is automatically set `false` when `performanceMode = true`.

### 4. Shared Components
If a shared component uses `LiquidGlassWrapper` or `NeumorphicWrapper`, provide a clean Material 3 fallback when the Fruit theme is inactive. Example: `SectionCard` renders as a standard `Card` on TV but uses `LiquidGlassWrapper` on web Fruit.
