# TODO: Fix Google TV White Background Issues

## Completed Investigation
- [x] Trace why screensaver is white in Google TV UI
    - [x] Investigate screensaver implementation files
    - [x] Check shader files for background color logic
    - [x] Check TV-specific logic in `DeviceService` or elsewhere
    - [x] Identify cause: `SplashScreen` hardcoded background & `ThemeProvider` defaulting to Light.

## Pending Tasks
- [x] Review implementation plan
- [x] Fix Deprecated Color Getters in `lib/steal_screensaver/steal_background.dart`
- [x] Implement Changes:
    - [x] Update `lib/ui/screens/splash_screen.dart` to use theme background color (Verified: uses `Scaffold` which respects `ThemeProvider`'s default dark mode on TV).
    - [x] Update `lib/ui/widgets/tv/tv_dual_pane_layout.dart` to use `Scaffold` with themed background (respects TV Dark Mode).
    - [x] Update `lib/providers/theme_provider.dart` to default to Dark mode on TV.
    - [x] Update `lib/main.dart` to pass `isTv` to `ThemeProvider`.
- [x] Verify the fix
    - [x] Run automated tests.
    - [x] Manual verification on Google TV.

## TV Screensaver Optimization (Neon Glow) [CRITICAL - HIGH PRIORITY]
- [x] **Major Performance Optimization**: Refactor `StealBanner` neon glow for Google TV.
    - **Status**: Previous blur simplifications (1.1.17) still result in excessive GPU load on low-spec Google TV hardware.
    - **Problem**: Real-time Gaussian blurs on character glyphs are too expensive for TV SOCs.
    - **Solution**: Implement a Rasterized Glyph Cache (`Map<String, ui.Image>`).
    - **Method**: 
        1. On first use of a character, draw it with its full glow onto an off-screen `ui.PictureRecorder`.
        2. Rasterize it immediately using `toImageSync()`.
        3. In the `render()` loop, replace `TextPainter.paint` with `canvas.drawImage`.
        4. Apply cycling colors and flickering opacity using a `Paint` object with `ColorFilter.mode(currentColor.withOpacity(opacity), BlendMode.srcIn)`.
    - **Result**: Transforms complex vector generation + 3 blurs into a single, ultra-fast hardware texture blit per character.

    - [x] **Method**: Added a toggle to `TvScreensaverSection` that controls the `preventSleep` setting.

## Web/PWA Optimization
- [ ] **Background Playback Longevity**: Find a way to prevent the browser from throttling the Gapless Engine when the UI is in the background.
    - [ ] Research `Silent Video` looping hacks or `Web Workers` for scheduler persistence.
    - [ ] Audit `gapless_audio_engine.js` for throttling-resilient scheduling.
- [ ] **PWA Rebranding**: Change install name in `web/manifest.json` from `gdar` to `Shakedown`.
- [ ] **Bug: Web Track Skipping**: Fix issue where the JS engine skips a track if it's still buffering when the previous track finishes.
