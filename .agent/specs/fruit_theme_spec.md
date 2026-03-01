# Design Specification: Fruit Theme & Neumorphism (Web/PWA)

This document specifies the "Fruit" theme and Neumorphism implementation for GDAR, a premium design style inspired by Apple's "liquid glass" and modern "soft UI" aesthetics. It is primarily targeted at Web UI and PWA platforms.

## 1. Core Philosophy
The Fruit theme transitions the UI from an elevation-based depth model (shadows) to a translucency-based depth model (glass/blur). Neumorphism adds a tactile, architectural layer to interactive elements, using light and shadow to simulate physical extrusion or indentation.

## 2. Comparison: Android vs. Fruit

| Feature | Android (Default) | Fruit (Web/PWA Only) |
| :--- | :--- | :--- |
| **Typography** | Varied (User-defined/Default) | **Inter** (Official Static Assets) |
| **Background (Light)** | `#F5F5F5` (Material Gray) | `#F2F2F7` (Apple System Gray 6) |
| **Background (Dark)** | `#000000` (Pitch Black) | `#1C1C1E` (Apple System Gray 6) |
| **Depth Mechanic** | Elevation & Box Shadows | **BackdropFilter (Blur)** & Borders |
| **Translucency** | Static Opacity (0.8 - 0.9) | **Liquid Glass** (0.7 + 15px Blur) |
| **Track Highlight** | Solid Accent Overlay | **Animated RGB Sweep Border** |
| **Tactility** | Material Ink | **Neumorphism** (Convex/Concave) |

## 3. Visual Tokens

### 3.1 Typography
- **Primary Font Family**: `Inter`
- **Asset Sources**: `assets/fonts/Inter-Regular.ttf`, `assets/fonts/Inter-SemiBold.ttf`
- **Usage**: Automatically enforced when `ThemeStyle.fruit` is active. The "App Font" setting is disabled to ensure brand consistency.

### 3.2 Liquid Glass System
The "liquid glass" effect is achieved via the `LiquidGlassWrapper` component.
- **Blur Density**: `ImageFilter.blur(sigmaX: 15.0, sigmaY: 15.0)`
- **Material Opacity**: 
  - Light: `white.withValues(alpha: 0.7)` 
  - Dark: `black.withValues(alpha: 0.7)`
- **Edge Definition**: 0.5px subtle border using `onSurface.withValues(alpha: 0.1)`.

### 3.3 Neumorphism (Soft UI)
Pervasive Neumorphism is applied to UI elements when enabled:
- **Depth:** Created using dual-shadow offsets (Light top-left, Dark bottom-right).
- **Shadow Tokens:**
  - Blur: **16px**
  - Offset: **(6, 6)**
  - Intensity: Adjustable (Default: 1.0x).
- **Interactive Response:**
  - **Convex (Default):** Standard extrusion for buttons and cards.
  - **Concave (Sunken):** Inverted shadows for input fields (Search Bar) and active control basins.
  - **Liquid Glass Highlight:** A subtle internal highlight (inset glow) is applied to the top-left edge of convex elements (buttons) to simulate glassy refraction.
  - **Neumorphic Handle Basin:** The player pull-handle is implemented as a sunken (concave) Neumorphic basin, creating a tactile "carved" slot in the glass.
  - **Static Depth:** Pulse/breathing animations are disabled to maintain architectural solidity.
- **True Black Logic:** Neumorphism is automatically disabled when "True Black" is active to prevent visual artifacts and maintain contrast.

### 3.4 Animated RGB Borders
Used for the active track card in the show list.
- **Type**: `SweepGradient`
- **Colors**: Red -> Yellow -> Green -> Cyan -> Blue -> Purple -> Red.
- **Animation**: Continuous rotation (Speed adjustable in settings).

## 4. Component Specifics

### 4. Component Specifics

### AppBar & Navigation
- **AppBar**: Transparent background. `scrolledUnderElevation` set to `0`.
- **Search Bar**: Concave Neumorphic basin with 28px corner radius.
- **Icons**: Dice, Search, and Settings icons wrapped in circular Neumorphic containers.

### Rating Controls
- **Star Strip**: The 3-star rating group is housed in a single, elongated Neumorphic basin (`concave`).
- **Tactile Affordance**: Empty stars appear as sunken "slots" while filled stars provide a vibrant, recessed glow.
- **Blocked State**: The Red Star is isolated in a circular Neumorphic basin.

### Cards & Dialogs
- **Corner Radius**: **14px** (Refined architectural curve).
- **Elevation**: Set to `0` to avoid shadow interference.
- **Hover State**: Subtle **1.01x scale** transition for interactive cards.

## 5. Implementation Constraints
- **Font Selection**: Disabled in settings when Fruit theme is active.
- **True Black**: Automatically toggled OFF when selecting Fruit theme to ensure Neumorphic depth is visible.
- **Platform Availability**: Optimized for Web/PWA; defaults to Android style on mobile and Google TV for performance.
