# Master Specification: Web & PWA (The Fruit Style)

This document consolidates the Aesthetics, Audio Engine, and Design tokens for the GDAR Web implementation.

## 1. Aesthetic Identity (Liquid Glass)
- **Theme**: "Fruit" / "Apple-kosher" look.
- **Tokens**: 14px corner radii, alpha-transparent glass surfaces.
- **Visuals**: `BackdropFilter` (sigma 15.0) on all glass cards.
- **Typography**: Inter Variable Font exclusively.
- **Icons**: Lucide Icons exclusively.
- **Motion**: Spring-based physics for all UI transitions.

## 2. Web Audio Engine
- **Architecture**: Isolated `AudioWorklet` worker for timing-critical logic.
- **Persistence**: robust `localStorage` sync for settings (Crossfade, Engine Mode).
- **Interoperability**: `HybridAudioOrchestrator` handles handoff from Engine 1 (just_audio/video) to Engine 2 (Web Audio).
- **Constraints**: No `ReadableStream` usage. One track per `AudioContext`.

## 3. Adaptive Layout
- **Responsiveness**: Fluid layout that scales from desktop browsers to mobile PWA wrappers.
- **Interactivity**: Mouse-first with full touch support for mobile browsers.

## 4. Architectural Rules (Mandatory)
- **Action**: Use `BackdropFilter` sigma 15.0 on all glass surfaces.
- **Action**: Use Lucide Icons and Inter variable font exclusively.
- **Action**: Use spring physics for all transitions — no Material ripples.
- **Constraint**: Never apply Fruit theme to mobile or TV.
