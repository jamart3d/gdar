# Master Specification: Google TV

This document consolidates the Design, Flow, and Screensaver standards for the GDAR TV implementation.

## 1. Focus & Navigation (Look & Feel)
- **Input**: D-pad navigation only. No touch/mouse assumptions.
- **Visual Focus**: Every interactive element wrapped in `TvFocusWrapper` (1.05x scale + glow).
- **Hierarchy**: Dim inactive panes to 0.2 opacity.
- **Transitions**: Minimal duration (<100ms) with linear transforms. **NO** ripples or spring/bounce animations.

## 2. Layout (The 10-Foot UI)
- **Layout**: Master-Detail (Two-Pane) for large screens.
- **Typography**: Audit headers to use `DisplayMedium` / `DisplayLarge`.
- **Safe Area**: Overscan margins for older panels.

## 3. Performance (Critical)
- **Neon Glow**: Use **Rasterized Glyph Cache** for all glow effects. No real-time Gaussian blurs.
- **Asset Audit**: Prune high-res mobile assets from TV builds to keep app size lean.

## 4. Screensaver
- **Trigger**: Inactivity-based only (no mobile/web implementation).
- **Controls**: "Ghost Menu" accessible via D-pad without full playback UI expansion.
- **Motion**: Fluid simulations (investigating `flutter_gpu`) for the lava lamp effect.

## 5. Architectural Rules (Mandatory)
- **Action**: Wrap every interactive TV element in `TvFocusWrapper` (1.05x scale + glow border).
- **Action**: Dim inactive panes or background elements to 0.2 opacity.
- **Constraint**: Never use tactile/haptic feedback on TV builds.
- **Constraint**: Never use organic ripples or spring animations on TV; stick to direct linear transforms.
