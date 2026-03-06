---
description: Comprehensive code quality, design, TV flow, and spec conformance audit.
---
# Unified Audit Workflow

**TRIGGERS:** audit, checkup, glass, liquid glass, tv audit, spec audit, quality, lint

> [!IMPORTANT]
> **AUTONOMY & PLANNING MODE**: Proceed autonomously end-to-end — read specs, scan code, run analysis, and generate reports without pausing for intermediate permission.

Run the sections relevant to the user's request. If the user just says "audit", run all sections.

---

## Section 1: General Health Check
1. **Analyze**: `mcp_dart-mcp-server_analyze_files`
2. **Test**: `mcp_dart-mcp-server_run_tests`. **(Arlo handles < 5 files locally; for full suites, use Jules).**
3. **Format**: `mcp_dart-mcp-server_dart_format`
4. **Debug Clean**: Scan for `print(` and `logger.` statements.
5. **Dependencies**: `flutter pub outdated`.

## Section 2: Glass & Theme Design Audit
// turbo
1. Scan for raw Material 3 patterns WITHOUT conditional gating:
   - `InkWell`, `ElevatedButton`, or `Card` not wrapped in `if (themeStyle == ThemeStyle.fruit)`.
   - Flag Material shadows (`elevation > 0`) in Fruit mode.
2. Scan for Fruit Mode Coverage:
   - Ensure primary containers have `BackdropFilter` or `LiquidGlassWrapper` path.
3. Rule Enforcement:
   - **Fruit Mode**: No breathing ripples or morphing. Use bounce/scale physics.
   - **Material Mode**: Clean M3 defaults.
   - **Universal**: Flag hardcoded non-semantic colors.

## Section 3: TV Flow & Navigation Audit
// turbo
1. Scan for `deviceService.isTv` gating on key screens.
2. Flag mobile-only artifacts in TV mode (swipe gestures without D-Pad fallback, standard snackbars).
3. Focus & Navigation:
   - Identify manual `FocusNode` instances and ensure D-Pad focusability.
   - Verify remote button handling (`Shortcuts`, `Actions`, `RawKeyboardListener`).
4. Aesthetic & Scale:
   - Verify `effectiveScale` 1.2x multiplier for TV typography.
   - Check focused-state contrast for 10-foot UI.
   - Verify TV Safe Area margins.

## Section 4: Spec Conformance Audit
1. Read all `.agent/specs/` files and build a "Truth Matrix" of hard constraints.
2. Implementation Scan:
   - **Theme Gating**: `LiquidGlassWrapper` only active when `kIsWeb && !isTv`.
   - **Platform Hardware**: `HapticFeedback` gated by `!isTv`.
   - **Scale Multipliers**: 1.35x TV UI, 1.2x TV Dialogs.
   - **Interaction Flows**: `TvInteractionModal` and `TvReloadDialog` on TV only.
3. Categorize findings: Aligned, Drifted, Violation, Undocumented.

## Section 5: Optimization Audit
1. **Size Analysis**: `flutter build appbundle --analyze-size`.
2. **Assets**: Find files > 500KB.
3. **Deep Links**: Scan `AndroidManifest.xml` for intent filters and App Actions.

## Output
1. Generate or update a single `AUDIT_REPORT.md`.
2. Offer "Surgical Fixes" for immediate issues.
3. Offer to update `.agent/specs/` if code represents intentional new truth.
