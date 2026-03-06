# Master Specification: Mobile (Phone/Tablet)

This document consolidates the Design, Flow, and Hardware standards for the GDAR Mobile implementation.

## 1. Visual Identity (Look)
- **Baseline**: Material 3 (Expressive) exclusively.
- **Typography**: Roboto (Native System) priority.
- **Icons**: Material Icons (Rounded) exclusively.
- **Surfaces**: Standard M3 elevation shadows. **NO** backdrop filters or neumorphism on native builds.

## 2. Interaction Model (Flow)
- **Thumb Zone**: Primary controls (Play/Pause, Seek) MUST be in the bottom 40% of the screen.
- **Navigation**: Linear stack via `Navigator`. 
- **Persistence**: Playback panel remains expanded/collapsed across sub-screen navigation.
- **Gestures**: Vertical swipe-to-dismiss for the player; horizontal swipe on mini-player to skip.

## 3. Hardware & OS (Feel)
- **Haptics**: Required on every significant interaction (`selectionClick`, `mediumImpact`, `vibrate`).
- **OLED**: Default to **True Black** (`Colors.black`) for backgrounds in dark mode.
- **Safe Area**: Strict adherence to `SafeArea` for notches and home indicators.
## 4. Architectural Rules (Mandatory)
- **Constraint**: Never use `BackdropFilter`, horizontal/vertical blurs, or neumorphic shadows on mobile native builds.
- **Action**: Place all primary interactive controls within the bottom 40% of screen height.
- **Action**: Implement haptic feedback on every significant interaction.
- **Action**: Respect `SafeArea` on all edges. Use True Black for OLED backgrounds.
