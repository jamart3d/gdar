# Android (Standard) Theme Specification: GDAR Audio Player

This document defines the **Android (Standard)** visual theme. It utilizes **Material 3 (M3)** with an **Expressive** design direction. This is the mandatory "Look" for native mobile applications and the standard accessible option for the Web/PWA.

## 1. Aesthetic Philosophy: Material 3 Expressive
The Android theme is built on the principles of familiarity, fluid motion, and high-contrast accessibility. The "Expressive" direction leverages large typography, vibrant dynamic color seeding, and organic shapes.

## 2. Visual Tokens

### 2.1 Surfaces & Depth
*   **Shadow System:** Traditional Material elevation shadows (0 to 12dp). Strictly **AVOID** Neumorphism and Backdrop Blurs.
*   **Container Style:** High-contrast solid surfaces or subtle alpha-blended overlays using `ColorScheme.surface` and `ColorScheme.surfaceVariant`.
*   **Corners:** Material 3 baseline rounded corners (Extra Large: 28dp, Medium: 12dp, Large: 16-20dp).

### 2.2 Color System
*   **Dynamic Color:** Deep integration with `DynamicColor` (Android 12+) to seed the UI palette from the user's wallpaper or show metadata.
*   **Tonal Palettes:** Uses full M3 tonal palettes to ensure legibility and accessibility in both Light and Dark modes.

### 2.3 Symbology & Typography
*   **Font Family:** **Roboto** (Native System). Priority is given to system-default fonts for a seamless OS-level feel.
*   **Icon Set:** **Material Icons (Rounded)** exclusively. Targets the standard Android iconography system.

## 3. Dynamic Interaction (Motion)

### 3.1 The "Organic" Rule
*   **Motion:** Follows **Material 3 Motion** system using `emphasized` or `standard` easing curves.
*   **Ink Ripples:** Primary touch feedback mechanism. Every interactive surface must feature high-response organic ripples.

### 3.2 UI Scaling
*   Uses `FontLayoutConfig.getEffectiveScale` to respect user-level accessibility settings (Standard Scaling).

## 4. Implementation Policy
The Android theme is the default and only allowed theme for native mobile builds.

*   **Native Mobile (Phone/Tablet):** **MANDATORY**. All UI elements must strictly follow this expressive Material 3 standard.
*   **Web / PWA:** Available as the **Standard** theme for high accessibility.
*   **TV:** **INCOMPATIBLE**. (TV uses the v135 Legacy standard).

---
*Version: 1.2 (Material 3 Expressive)*  
*Last Updated: 2026-03-02*
