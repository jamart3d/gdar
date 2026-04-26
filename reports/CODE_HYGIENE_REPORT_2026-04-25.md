# GDAR Code Hygiene Report (2026-04-25)

## Summary
The GDAR monorepo shows excellent health in app target modularization (thin `main.dart` files), but suffers from significant structural duplication between platform-specific screen variants and app lifecycle logic.

> [!IMPORTANT]
> **Tooling Note**: Automated `unused_*` detection via `dart-mcp-server` was skipped due to server-side EOF errors. This report focuses on structural duplication and hotspot mapping via manual discovery and diagnostic tooling.

---

## 1. Top Duplication Risks

### DEDUP-1: Screen Variant Parity (90% Overlap)
- **Files**: `show_list_screen.dart` (620 lines) vs `tv_show_list_screen.dart` (569 lines).
- **Issue**: These files share identical data-fetching logic, provider interactions, and list filtering. The differences are almost entirely in the `build` method (D-Pad focus wrappers for TV).
- **Recommendation**: Merge into a single `ShowListScreen` and use a `ResponsiveLayout` or platform-aware builders for the list items.

### DEDUP-2: App Lifecycle & Automation (Duplicated Methods) - **RESOLVED**
- **Files**: `apps/gdar_mobile/lib/main.dart`, `apps/gdar_tv/lib/main.dart`, `apps/gdar_web/lib/main.dart`.
- **Issue**: Identical methods for screensaver launching, deep link handling, and inactivity syncing were copied across all three targets.
- **Resolution**: Extracted shared logic into `GdarAppLifecycleMixin` in `packages/shakedown_core/lib/app/`. All entrypoints have been refactored and tested.

### DEDUP-3: Playback Layouts
- **Files**: `playback_screen_layout_build.dart` vs `tv_playback_screen_layout_build.dart`.
- **Issue**: High similarity in control logic and layout structure.
- **Recommendation**: Unify using the `TvFocusWrapper` as a conditional wrapper or a separate component.

---

## 2. Architecture Hotspots

### HOTSPOT-1: Rendering Logic
- **File**: `packages/shakedown_core/lib/steal_screensaver/steal_graph_render_corner.dart` (976 lines).
- **Issue**: Approaching 1k lines. Contains complex custom painting and math for the screensaver.
- **Status**: Monitor. While large, the logic is highly cohesive. Consider splitting by "Shape Type" if it grows.

### HOTSPOT-2: Legacy Test Bloat
- **File**: `apps/gdar_tv/test/tv_regression_test.dart` (936 lines).
- **Issue**: Contains extensive playback verification logic.
- **Recommendation**: Verify if this is still the active regression target or if logic should be moved to package-level widget tests.

---

## 3. Hygiene & Compliance

- **TODO/FIXME**: None found in active project source.
- **Logger Compliance**: Verified that project scripts and core logic use `logger` instead of `print()`. Found some `print` statements in `tmp/` and legacy tests which are acceptable.
- **Onboarding Cleanup**: Confirmed that the duplicated onboarding screens from the April 11th audit have been successfully removed.

---

## 4. Next Steps
1. [x] Implement `GdarAppLifecycleMixin` to thin out `main.dart` files.
2. [ ] Prototype a unified `ShowListScreen` that handles TV focus conditionally.
3. [ ] Re-run full analyzer once server stability is restored.
