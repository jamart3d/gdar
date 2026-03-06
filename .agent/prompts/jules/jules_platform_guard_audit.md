# Jules Platform Guard & Architectural Audit

**Mission:** Audit the repository (code-level) to ensure strict architectural separation between **Mobile (Phone)**, **TV**, and **Web (Fruit)** platforms. We are verifying "Walled Garden" integrity.

---

### Phase 1: Walled Garden Verification (Web vs. Native)
1.  **Scan `lib/`**: Search for any usage of `LiquidGlassWrapper`, `NeumorphicShadow`, or `sigma: 15.0` that is NOT explicitly gated by `if (kIsWeb)` or equivalent platform checks.
2.  **Audit**: Ensure these premium web-only effects are NOT leaking into standard Material 3 (Phone) widgets.

### Phase 2: TV Focus Integrity
1.  **Scan TV Widgets**: Ensure all interactive elements in TV-specific files use the `TvFocusWrapper`.
2.  **Ripple Check**: Search for `InkWell` or `Material` ripples in TV-specific UI code. This is a VIOLATION of `tv_rules.md`. TV focus must be visual (scale/glow), not organic (ripples).
3.  **Rasterization Cache**: Verify if the `StealBanner` (TV) is using the Rasterized Glyph Cache for neon glows to prevent GPU thrashing on low-end TV SOCs.

### Phase 3: Mobile One-Handed Layout Audit
1.  **Interactives**: Scan mobile-specific playback screens. Verify that primary controls (Play/Pause, Skip) are consistently placed in the bottom 40% of the widget tree/layout.
2.  **SafeArea**: Ensure all mobile scaffolds wrap their child in a `SafeArea` or handle it explicitly for notch/home indicator compatibility.

### Phase 4: Dependency Ripple Audit
1.  **Rules Sync**: Verify that the `.agent/rules/` directory contains no conflicting directives between `mobile_rules.md`, `tv_rules.md`, and `web_audio.md`.

**Report:** Provide a detailed report of any "Platform Leaks" (e.g., Web effects in Phone code) or missing TV focus wrappers.
