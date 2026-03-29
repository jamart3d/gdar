---
trigger: localstorage, flush, web, js, storage, pwa, build web
policy_domain: Web Platform
---
# Web & PWA Platform Directives

### 1. localStorage & Session Hygiene
- **Rule:** Never use `localStorage.clear()`. It wipes all keys for the entire origin, including those not owned by the app.
- **Action:** Only remove specific GDAR-owned keys:
  ```js
  const keysToRemove = Object.keys(localStorage).filter(k =>
      k.startsWith('flutter.') ||
      k === 'audio_engine_mode' || k === 'allow_hidden_web_audio' || k === 'gdar_web_error_log_v1'
  );
  keysToRemove.forEach(k => localStorage.removeItem(k));
  ```
- **Flush Guard**: `hybrid_init.js` implements a one-per-session flush via `sessionStorage('shakedown_flushed')`.

### 2. PWA Branding Synchronization
- **Theme Color Logic**: Dark Mode + True Black MUST be `#000000`. Standard Dark Mode tracks the primary theme background. Light Mode tracks the scaffold background.
- **Background Color**: Leave PWA `background_color` as `#000000` for the splash screen.
- **Change Detection**: `ThemeProvider` updates dynamically via `SettingsProvider` listeners (`useTrueBlack`, `themeStyle`) without page reloads.
- **Manifest Parity**: `manifest.json` should statically reflect the baseline "Brand Dark" color for initial load stability.

### 3. Wasm Engine Handling (Experimental)
> [!WARNING]
> GDAR experiences runtime instability (`RuntimeError: function signature mismatch`) under the Skwasm engine due to complex interactions with `BackdropFilter` and custom shaders.
- **Production constraint:** Production builds MUST avoid `--wasm` and use default Dart2JS WebGL compilation.
- **Wasm feature gates:** During local Wasm testing, you MUST completely disable:
  1. `BackdropFilter` (LiquidGlass, blurs).
  2. Custom Fragment Shaders (e.g., `pulsing_glow.frag`).
  3. Deeply nested `AnimatedOpacity` within `CustomPaint` layers.

### 4. Performance Mode Gates (Low Power Devices)
- **Default State**: Capable devices boot with `performanceMode = false`. Low-power devices (`cores <= 2` or `cores <= 4 && devicePixelRatio < 2.0`) automatically set `performanceMode = true` and fall back to the Android theme.
- **Visual Prohibitions**: When `performanceMode == true`, disable:
  - Blurs (`BackdropFilter`, `ImageFilter.blur`).
  - Complex Shadows (except subtle True Black depth).
  - Glowing borders and complex neon shaders.
- **Implementation Pattern:** `color: isSimple ? baseColor : baseColor.withValues(alpha: 0.8)`
- **Theme Transition Safety**: Do NOT gate theme reset logic behind `performanceMode`. Active glow modes must reset completely regardless of the performance mode state when switching themes.
