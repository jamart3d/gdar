# GDAR Fruit Theme Specification (v1.0)

The "Fruit" theme is a specialized, liquid-glass aesthetic inspired by modern desktop environments. It is the **Exclusive Domain** of the GDAR Web and PWA interface.

## 🏛️ Architectural Policy (Walled Architecture)
- **Web/PWA**: The Fruit theme is the default and preferred aesthetic.
- **Native (Android/iOS)**: Forbidden. These platforms must adhere to Material 3 (Expressive) standards.
- **Google TV**: Forbidden. TV uses a specialized AMOLED-safe true-black theme.

## 🎨 Visual Identity
The Fruit theme emphasizes:
- **Depth**: Multi-layered surfaces with varying opacities.
- **Translucency**: "Liquid Glass" effects using `withValues(alpha: ...)` for background blur simulations.
- **Typography**: Strictly uses the **Apple Inter** typography set for a professional, crisp feel on high-resolution monitors.
- **Interaction**: Subtle hover transforms and the complete removal of standard Material "Splash" ripples (using `NoSplash.splashFactory`).

## 🍬 Color Configurations
The theme supports three distinct "modes" which cycle randomly upon initial activation:

### 1. 🧪 Sophisticate (Indigo/Slate)
- **Primary**: Indigo (`0xFF5C6BC0`)
- **Background (Light)**: Slate/Soft Blue-Gray (`0xFFE0E5EC`)
- **Background (Dark)**: Slate 900 (`0xFF0F172A`)
- **Surface (Dark)**: Slate 800 (`0xFF1E293B`)

### 2. 🌿 Minimalist (Apple Green)
- **Primary**: Apple Green (`0xFF34C759`)
- **Background (Light)**: Pure White
- **Background (Dark)**: System Gray 6 (`0xFF1C1C1E`)

### 3. 🎨 Creative (Apple Pink)
- **Primary**: Apple Pink (`0xFFFF2D55`)
- **Background (Light)**: Warm Tint (`0xFFFFF9F9`)
- **Background (Dark)**: Warm Charcoal (`0xFF1A1A1A`)

## 📐 Component Specs
- **Cards**: Border radius `14`, Opacity `0.65`, Elevation `0`.
- **Dialogs**: Border radius `16`, Opacity `0.8`, Elevation `0`.
- **Navigation**: Transparent AppBars with blur effects (where possible).

---
*Implementation Reference: `lib/utils/app_themes.dart` and `lib/providers/theme_provider.dart`.*
