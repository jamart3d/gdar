# Optimizing Screensaver Smoothness
Date: 2026-02-25 19:25

Address the "crawl" feel reported by the user at low flow speeds by upgrading the rendering quality of textured elements that move at sub-pixel offsets.

## Proposed Changes

### [Steal Screensaver](file:///c:/Users/jeff/StudioProjects/gdar/lib/steal_screensaver)

#### [MODIFY] [steal_banner.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/steal_screensaver/steal_banner.dart)
- Upgrade `FilterQuality` to `high` in `_paintChar`. This ensures that when the rasterized high-res glyphs are scaled down and translated by fractional pixels, the result is sampled using high-quality interpolation (bicubic/Lanczos), which eliminates the "crawl" or "stepping" artifacts typical of bilinear filtering during slow motion or rotation.

#### [MODIFY] [steal_background.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/steal_screensaver/steal_background.dart)
- Upgrade `FilterQuality` to `high` in `_renderTrail`. The ghost slices of the logo move at sub-pixel offsets and suffer from the same sampling artifacts as the text. Enabling high filter quality will ensure the trail effect remains fluid at low speeds.

## Verification Plan

### Automated Tests
- Run existing screensaver tests to ensure no regressions in layout or lifecycle:
  ```powershell
  flutter test test/ui/screens/screensaver_screen_test.dart
  ```

### Manual Verification
1.  **Low Speed Smoothness Check**:
    - Open Settings > TV Screensaver.
    - Set **Flow Speed** to **0.10**.
    - Set **Display Style** to **Ring**.
    - Start Screensaver.
    - Observe the text orbiting slowly. Verify the motion is "buttery smooth" and lacks the horizontal/vertical "crawling" edges.
2.  **Flat Mode Stability**:
    - Change **Display Style** to **Flat**.
    - Verify that the text tracking the logo center doesn't show "chattering" or jitter in the letter edges during movement.
3.  **Trail Quality**:
    - Increase **Logo Trail Intensity** and observe the ghost slices. Verify they sample smoothly without jagged aliasing during slow movements.
