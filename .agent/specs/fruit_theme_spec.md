# Fruit Theme Specification: GDAR Audio Player

This document defines the **Fruit** theme for GDAR Web/PWA. Fruit is the
project's Apple-inspired **Liquid Glass** presentation: tactile, translucent,
and highly responsive, while remaining settings-aware and performance-safe.
Android and TV do not use this visual system.

## 1. Aesthetic Philosophy

Fruit should feel like **one refractive material plane** floating above the
content, not a stack of blurred cards. It prioritizes:

- translucency over opaque layering
- refraction and edge sheen over generic blur
- springy physical response over opacity-only feedback
- clarity and restraint over constant neon effects

Fruit is not Material 3, and it should not fall back to Material patterns when
Fruit effects are reduced or disabled.

## 2. Platform Policy

Fruit is a **Web/PWA-only** theme.

- **Web / PWA:** Full Fruit implementation is allowed.
- **Phone / Tablet native:** Forbidden. Use the Android/Material system.
- **TV:** Forbidden. Use the TV-focused dark system.

## 3. Material Model

### 3.1 Core Surface Rule

Fruit uses a **single-sheet liquid surface model**.

- Large playback chrome should read as one continuous refractive layer.
- Header, sticky now-playing, and inline now-playing states should reuse the
  same material language rather than stack independent blur treatments.
- Nested glass inside glass is an anti-pattern unless there is a strong
  functional reason and the inner layer is visually minimal.

### 3.2 Liquid Glass

- `BackdropFilter` blur is only the base ingredient, not the full effect.
- Fruit surfaces should include subtle **edge sheen**, **inner highlight**, and
  **corner falloff** so the perimeter reads as bending light rather than merely
  softening pixels.
- Borders must remain soft and optical. Avoid hard geometric outlines.
- Default glass should be visually clean and restrained.

### 3.3 Fallback Behavior

When Fruit effects are reduced, the structure stays Fruit:

- no Material 3 components
- no ripples or FAB language
- no substitution of the Fruit shell with generic cards

Reduced mode should preserve layout, spacing, and control hierarchy while
removing expensive optics.

## 4. Motion and Physicality

### 4.1 Interaction Response

- Press interactions should feel like the surface briefly **sinks** and
  rebounds.
- Prefer spring-like motion over opacity-only feedback.
- Scale, depth, highlight compression, and rebound are appropriate.
- Ink-drop/ripple behavior is forbidden.

### 4.2 Transport Transitions

- Play/pause transitions should not feel like a simple icon swap.
- Pending/buffering states should use a **liquid transition**, such as a glyph
  compressing into a highlight core with a specular sweep or shimmer.
- Loading affordances should feel integrated with the glass surface rather than
  pasted on top as generic spinners.

## 5. Typography and Iconography

- **Font family:** `Inter` for Fruit UI.
- **Icon set:** `Lucide Icons` for standard Fruit controls.
- Typography should remain crisp and highly legible against translucent
  surfaces.

## 6. Color Configurations

Fruit offers three curated palette modes selected by the user in settings.

### 6.0 Rating Star Exception

- Playback and catalog rating stars in Fruit must use a fixed **curation yellow**
  (`#FFC107`).
- Rating stars must **not** inherit the active Fruit palette primary color.
- This exception preserves quick curation recognition across all Fruit color
  modes.

### 6.1 Sophisticate

- **Primary:** Indigo (`0xFF5C6BC0`)
- **Background (Light):** Slate / Soft Blue-Gray (`0xFFE0E5EC`)
- **Background (Dark):** Slate 900 (`0xFF0F172A`)
- **Surface (Dark):** Slate 800 (`0xFF1E293B`)

### 6.2 Minimalist

- **Primary:** Apple Green (`0xFF34C759`)
- **Background (Light):** White
- **Background (Dark):** System Gray 6 (`0xFF1C1C1E`)

### 6.3 Creative

- **Primary:** Apple Pink (`0xFFFF2D55`)
- **Background (Light):** Warm Tint (`0xFFFFF9F9`)
- **Background (Dark):** Warm Charcoal (`0xFF1A1A1A`)

## 7. Settings Contract

Fruit must honor the existing Appearance settings.

### 7.1 `fruitEnableLiquidGlass`

- Core Fruit material toggle.
- Enables the liquid surface treatment and related optical effects.
- This is more than blur; it controls the overall refractive presentation.

### 7.2 `performanceMode`

- Hard-disables expensive Fruit effects.
- Must disable or significantly reduce:
  - liquid optics
  - glow
  - spring-heavy motion
- **Exception:** active playback RGB borders remain available in Fruit even when
  `performanceMode` is on.
- In `performanceMode`, Fruit RGB should prefer the animated border itself and
  may reduce outer glow/shadow to keep cost down.
- The UI remains Fruit in structure, but simplified in rendering cost.

### 7.3 `fruitStickyNowPlaying`

- Repositions the now-playing sheet between inline and sticky states.
- Should not create the appearance of multiple independent glass slabs.

### 7.4 `fruitDenseList`

- Changes spacing density only.
- Must not alter the Fruit material model.

### 7.5 `glowMode`

- Supported in Fruit as an **optional expressive accent**.
- It is **not** part of the default native Fruit look.
- In Fruit, glow should be interpreted as subtle edge energy or active-state
  luminance, not a persistent neon border around all surfaces.

### 7.6 `highlightPlayingWithRgb`

- Supported in Fruit as an **optional expressive accent**.
- It is **not** part of the default native Fruit look.
- RGB should be limited to active playback emphasis and should remain more
  restrained than arcade-like by default.
- Fruit RGB must continue to work when `fruitEnableLiquidGlass` is off.
- Fruit RGB must continue to work when `performanceMode` is on.
- When enabled, Fruit RGB applies to active playback surfaces including the
  now-playing player card border.

## 8. Anti-Patterns

The following are considered non-compliant with Fruit:

- stacked glass panels that read like layered plastic
- blur-only "glass" with no optical edge treatment
- opacity-only press feedback on primary controls
- generic spinner replacement for transport pending states
- always-on RGB borders as the default Fruit identity
- strong neumorphic shadows competing with the liquid material read
- Material 3 components or interaction language inside Fruit screens

## 9. Governance

- Default Fruit should feel **native, calm, and premium**.
- Glow and RGB are permitted as user-controlled expressive modes, but they are
  secondary to the liquid material model.
- Any new Fruit component should be evaluated first against:
  - single-sheet hierarchy
  - physical press response
  - contrast on bright and dark backgrounds
  - settings compatibility
  - performance fallback behavior

---

*Version: 1.4 (Single-Sheet Liquid Contract)*  
*Last Updated: 2026-04-02*
