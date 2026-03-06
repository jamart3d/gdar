# Fruit Theme Specification: GDAR Audio Player

This document defines the **Fruit** (Liquid Glass) theme, a premium, tactile, and immersive aesthetic developed for the GDAR ecosystem. It is an **optional visual layer** for the Web UI/PWA, while **Android (Material 3)** remains the default style across all platforms.

## 1. Aesthetic Philosophy
The "Fruit" look centers on depth, translucency, and physical responsiveness. It moves away from Material's elevation-based shadow model towards a model of blurred surfaces and tactile feedback.

## 2. Visual Tokens

### 2.1 Translucency (Liquid Glass)
*   **Backdrop Blur:** Surfaces use `BackdropFilter` with `sigma: 15.0`.
*   **Opacity:** Background alpha is typically `0.7`, allowing underlying colors and shaders (like `StealVisualizer`) to bleed through.
*   **Availability:** Specifically enabled on **Web** platforms when the Fruit theme is active. Disabled on Phone/TV for performance and platform-native feel.

### 2.2 Tactility (Neumorphism)
*   **Shadow System:** Interactive elements (Buttons, Search Bars) use dual-shadow light/dark offsets instead of standard elevation.
*   **Convex (Pop):** Standard buttons and active cards.
*   **Concave (Depressed):** Search fields, inactive inputs, and "active" control regions.
*   **Dynamic Response:** Neumorphic shadows may shift or flatten upon interaction to simulate physical compression.

### 2.3 Symbology & Typography
*   **Font Family:** **Inter** (Hard-enforced). Designed for maximum legibility and architectural clarity.
*   **Icon Set:** **Lucide Icons** exclusively. Known for consistent line weights and a more "modern/premium" aesthetic than standard Material.

## 3. Dynamic Effects

### 3.1 RGB Active Track
*   The currently playing track or selected show features a rotating `SweepGradient` border.
*   Controlled via the user's `glowMode` and `highlightPlayingWithRgb` settings.

### 3.2 Motion & Easing
*   **Spring Physics:** Avoid traditional easing curves. Rely on Apple-style spring physics for transitions.
*   **Tactile Feedback:** Use scale-down/bounce-back animations for button taps instead of ink-drops/ripples.

## 4. Platform Application (The "Walled" Policy)
The Fruit theme is architecturally **walled off** as a **Web and PWA Exclusive**. It is specifically designed to leverage browser-based GPU acceleration and high-fidelity translucency.

*   **Web / PWA (Exclusive Domain):** Full implementation permitted. This is the only environment where `LiquidGlassWrapper`, Neumorphic shadows, and `Inter` typography are active.
*   **Native Mobile (Phone/Tablet):** **STRICTLY FORBIDDEN**. Native builds must adhere to the **Phone UI Design Specification** (Material 3 Baseline) to ensure platform consistency and performance.
*   **TV:** **STRICTLY FORBIDDEN**. TV builds must adhere to the **TV UI Design Specification** (v135 Legacy / Material Dark).

---
*Version: 1.1 (Walled Architecture)*  
*Last Updated: 2026-03-02*
