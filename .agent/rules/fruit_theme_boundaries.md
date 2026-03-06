# Fruit Theme Architecture Boundaries

The "Fruit" (Liquid Glass) theme is a premium aesthetic designed specifically for Web and PWA environments. It must NOT bleed into native mobile or TV experiences.

### 1. Platform Gating
- **Constraint:** Any widget or layout specific to the "Fruit" theme must be safely gated.
- **Action:** Use `kIsWeb` directly, or abstract the check into a provider (e.g., `themeProvider.themeStyle == ThemeStyle.fruit`).
- **Reason:** Native Android, iOS, and specifically Google TV users expect platform-standard Material 3 interfaces.

### 2. Liquid Glass & Neumorphism
- **Constraint:** Components utilizing `LiquidGlassWrapper`, `NeumorphicWrapper`, or high-blur background filters are exclusive to the Fruit theme.
- **Action:** If a shared component (e.g., a button or card) uses these effects, provide a clean Material 3 fallback when the Fruit theme is inactive.
- **Example:** A `SectionCard` should render as a standard `Card(elevation: 0, color: surfaceContainer)` on TV, but can render with a `LiquidGlassWrapper` on Web.
