# Monorepo Architecture Plan

Date: 2026-04-01
Project: GDAR
Status: Proposed

## Goal

Keep the workspace scalable by enforcing an acyclic package graph and clear
ownership boundaries between design, shared features, and app assembly.

## Current Problem

The current monorepo is productive, but one dependency direction is a structural
smell:

- `packages/styles/gdar_fruit` depends on `packages/shakedown_core`

That is backwards for a style package. It makes it harder to move reusable Fruit
presentation code into the style layer because any reverse import from
`shakedown_core` back into `gdar_fruit` would create a package cycle.

## Target Package Graph

Preferred dependency direction:

`packages/gdar_design` -> `packages/shakedown_core`

`packages/gdar_design` -> `packages/styles/gdar_fruit`

`packages/gdar_design` -> `packages/styles/gdar_android`

`packages/shakedown_core` -> `apps/*`

`packages/styles/*` -> `apps/*`

Key rule:

- lower layers must not depend on higher layers
- style packages must not depend on feature packages
- apps are the composition root

## Recommended Package Responsibilities

### `packages/gdar_design`

Purpose: dependency-light shared design layer.

Should own:

- theme enums such as `ThemeStyle`
- color options such as `FruitColorOption`
- typography tokens
- spacing tokens
- shared font configuration
- reusable presentational primitives
- design-system helpers with no feature logic

Should not own:

- providers
- settings persistence
- feature toggles
- screens
- repositories or services

### `packages/shakedown_core`

Purpose: shared feature and application logic layer.

Should own:

- models
- repositories
- services
- providers
- shared feature widgets
- shared screens
- settings sections and feature composition

Should not own:

- app-specific bootstrap code
- theme-skin-specific visual tokens if they can live in design

### `packages/styles/gdar_fruit`

Purpose: Fruit skin implementation.

Should own:

- `ThemeData` construction for Fruit
- Fruit-specific presentational widgets
- Fruit-specific visual wrappers and surfaces
- Fruit-only visual composition that does not know feature logic

Should not own:

- `SettingsProvider`
- app feature sections
- business logic
- persistence

### `packages/styles/gdar_android`

Purpose: Android/Material skin implementation with the same boundary rules as
`gdar_fruit`.

### `apps/gdar_mobile`, `apps/gdar_tv`, `apps/gdar_web`

Purpose: app composition root.

Should own:

- app bootstrap
- provider wiring
- route bootstrapping
- platform entrypoint details
- app-specific assembly of themes and shared features

## Practical Ownership Rule

Use this rule when placing code:

- If code knows about `SettingsProvider`, providers, setting keys, feature
  state, or screen composition, it belongs in `shakedown_core`.
- If code only knows about spacing, typography, color, surfaces, and visual
  presentation, it belongs in `gdar_design` or a style package.

## What This Means For Fruit Settings UI

Example: `packages/shakedown_core/lib/ui/widgets/settings/interface_section.dart`

Best placement:

- keep the section itself in `shakedown_core`
- move reusable Fruit spacing/header primitives into the design layer
- let the section compose those primitives without moving settings logic

This preserves clean ownership:

- feature composition stays in core
- design primitives stay in the design/style layer

## Migration Plan

### Phase 1: Stop Making The Graph Worse

- Do not move feature sections from `shakedown_core` into `gdar_fruit`
- Do not add new `gdar_fruit -> shakedown_core` couplings unless unavoidable
- Keep extracting Fruit presentation helpers in places that do not introduce
  cycles

### Phase 2: Introduce A Shared Design Package

Create `packages/gdar_design`.

Move low-risk shared design artifacts first:

- `ThemeStyle`
- `FruitColorOption`
- font configuration utilities
- typography tokens
- spacing tokens
- reusable Fruit section headers / spacing primitives

Keep the package dependency-light and free of feature logic.

### Phase 3: Repoint Style Packages

After `gdar_design` exists:

- update `gdar_fruit` to depend on `gdar_design` instead of `shakedown_core`
- update `gdar_android` to depend on `gdar_design` if needed
- keep style packages isolated from feature logic

### Phase 4: Repoint Core

Update `shakedown_core` to consume design tokens and primitives from
`gdar_design`.

Do not move feature widgets or providers unless they are truly presentation-only.

### Phase 5: Consolidate App Assembly

Ensure the apps remain the final assembly layer:

- apps depend on `shakedown_core`
- apps depend on style packages
- apps can depend on `gdar_design` directly if needed

## Success Criteria

The migration is successful when:

- no package cycles exist
- style packages no longer depend on `shakedown_core`
- shared feature sections remain in `shakedown_core`
- design tokens and reusable visual primitives live in a lower shared layer
- app packages remain the composition root

## Short Version

Best monorepo shape for GDAR:

1. `gdar_design` for shared design tokens and primitives
2. `shakedown_core` for shared features and logic
3. `gdar_fruit` / `gdar_android` for skin implementations
4. `apps/*` for composition

Best immediate rule:

- keep feature code in core
- move only presentation primitives down into design/style packages

