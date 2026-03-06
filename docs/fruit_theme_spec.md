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
- **Vapor Transitions**: Use of `ShaderMask` with linear gradients to "melt" header and modal edges into the content, eliminating sharp visual lines.
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

## 🧱 Aesthetic Governance
- **No Dynamic Tinting**: Strictly forbidden. The Fruit theme must always remain true to its curated palette. Show-based spectral washes or background color overrides used in other themes are disabled to maintain professional color consistency.
- **Borderless Glass**: All glass components (headers, cards, modals) must have `showBorder: false` to avoid sharp geometric lines. Transitions must rely on blur depth and shader masks.

## 📐 Component Specs
- **Cards**: Border radius `14`, Opacity `0.65`, Elevation `0`.
- **Dialogs**: Border radius `24`, Opacity `0.35`, Blur `30`, Elevation `0`.
- **Navigation**: "Vapor" Floating AppBars with `ShaderMask` transitions and no bottom borders.

---
*Implementation Reference: `lib/utils/app_themes.dart`, `lib/providers/theme_provider.dart`, and `lib/ui/widgets/theme/liquid_glass_wrapper.dart`.*
