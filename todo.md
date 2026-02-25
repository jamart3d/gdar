# TODO: Fix Google TV White Background Issues

## Completed Investigation
- [x] Trace why screensaver is white in Google TV UI
    - [x] Investigate screensaver implementation files
    - [x] Check shader files for background color logic
    - [x] Check TV-specific logic in `DeviceService` or elsewhere
    - [x] Identify cause: `SplashScreen` hardcoded background & `ThemeProvider` defaulting to Light.

## Pending Tasks
- [ ] Review implementation plan
- [x] Fix Deprecated Color Getters in `lib/steal_screensaver/steal_background.dart`
- [ ] Implement Changes:
    - [ ] Update `lib/ui/screens/splash_screen.dart` to use theme background color.
    - [ ] Update `lib/ui/widgets/tv/tv_dual_pane_layout.dart` to force `Colors.black` scaffold background.
    - [ ] Update `lib/providers/theme_provider.dart` to default to Dark mode on TV.
    - [ ] Update `lib/main.dart` to pass `isTv` to `ThemeProvider`.
- [ ] Verify the fix
    - [ ] Run automated tests.
    - [ ] Manual verification on Google TV.

## TV Screensaver Optimization (Neon Glow)
- [ ] Refactor `StealBanner` neon glow for Google TV performance.
    - **Problem**: The current 3-layer Gaussian blur (shadows) per character is recalculated and re-rendered every frame, causing high GPU load on TVs.
    - **Solution**: Implement a Rasterized Glyph Cache (`Map<String, ui.Image>`).
    - **Method**: 
        1. On first use of a character, draw it with its full glow onto an off-screen `ui.PictureRecorder`.
        2. Rasterize it immediately using `toImageSync()`.
        3. In the `render()` loop, replace `TextPainter.paint` with `canvas.drawImage`.
        4. Apply cycling colors and flickering opacity using a `Paint` object with `ColorFilter.mode(currentColor.withOpacity(opacity), BlendMode.srcIn)`.
    - **Result**: Transforms complex vector generation + 3 blurs into a single, ultra-fast hardware texture blit per character.

## Playback UI Improvements
- [ ] Expose the "Prevent Sleep" setting to all platforms.
    - **Problem**: The screen stays on unexpectedly for web users due to mobile/TV settings being hidden but active.
    - **Solution**: Expose the setting in `PlaybackSection`.
    - **Method**: Add a `TvSwitchListTile` to the `PlaybackSection` that controls the `preventSleep` setting, allowing all users to toggle the wake-lock behavior.
