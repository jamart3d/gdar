---
trigger: fruit, web, glass, design, layout
---
# Fruit Design System: Liquid Glass Architecture

This document consolidates all rules for the Web/PWA exclusive "Fruit" theme (Liquid Glass). 

## 1. Visual & Interaction Core
- **The Fruit Boundary**: Strictly forbid all Material 3 language (widgets, ripples, FABs) on Fruit screens.
- **Motion Strategy**: Use **Lucide Icons** exclusively. Typo: **Inter** variable font. All transitions use **spring physics** (no Material ripples).
- **Glass Surfaces**: `BackdropFilter` sigma 15.0+ on all glass layers. Focus on "Vapor" transitions using **ShaderMask**. 
- **Borderless Glass**: All Fruit glass components MUST set `showBorder: false` to ensure visual "melt" into the background.

## 2. Platform Gating & PWA Integrity
- `LiquidGlassWrapper` is strictly gated on `kIsWeb && !dev.isTv`.
- **Do NOT instantiate `LiquidGlassWrapper` on native mobile or desktop** (even if gated internally) — use the `isTrueBlackMode || isLiquidGlassOff || !kIsWeb` check at the widget call-site.
- **Design System Fallback**: If Liquid Glass effects are disabled (performance mode or settings toggle), **keep the Fruit structure** (layout, spacing, controls). Do NOT swap to Material 3 components.

## 3. High-Precision Tooltip Positioning
- `FruitTooltip._showTooltip()` MUST anchor by `bottom`, never `top` (prevents spurious EXIT events on the chip's `RenderMouseRegion`).
- **RepaintBoundary Standard**: Wrap any animated component (e.g., `_buildTrafficLightHeartbeat`) inside a chip in a `RepaintBoundary` to prevent `AnimatedContainer.markNeedsPaint()` from propagating to the parent mouse tracker.

## 4. Background Strategies
- **No Dynamic Tinting**: Strictly disable show-based background overrides on Fruit. Use the curated **Slate/White/Charcoal** base only.
- Final visual intent is **Borderless Glass** on top of a liquid backdrop.
