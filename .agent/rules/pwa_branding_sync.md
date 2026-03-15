# PWA Branding Synchronization Rules

### 1. Theme Color Logic
- **Dark Mode + True Black**: `theme_color` MUST be set to `#000000`.
- **Standard Dark Mode**: `theme_color` should track the primary background color of the current theme style (e.g., Sophisticate's dark slate).
- **Light Mode**: `theme_color` should track the scaffold background or primary light surface.

### 2. Background Color Logic
- **PWA `background_color`**: Leave as a static black (`#000000`) for now unless a specific design for the splash screen background is requested.
- **Body Background**: The CSS body background in `index.html` is synchronized via the same `updateThemeBranding` function but currently maps to the same color as the theme color in the Dart implementation.

### 3. Change Detection
- **Settings Listeners**: `ThemeProvider` must listen to `SettingsProvider` changes (specifically `useTrueBlack` and `themeStyle`) to trigger an immediate `_syncPwaBranding` update. This ensures the browser UI responds without a page reload.

### 4. Manifest Parity
- While dynamic updates happen via JS, the static `apps/gdar_web/web/manifest.json` should reflect the most common "Brand Dark" color to ensure a consistent experience during initial load/splash.
