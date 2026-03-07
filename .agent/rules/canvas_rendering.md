# Canvas Rendering Jitter Rule

When implementing slow-moving animations or precise text rendering using `Canvas.translate()` or `Canvas.drawImage()`, always prevent sub-pixel artifacting (often referred to as "crawling" or "jitter").

1. **Integer Coordinates**: When translating coordinates that may evaluate to fractional pixels during an `update(dt)` loop, explicitly round the values using `.roundToDouble()` or `.round()` on the X and Y coordinates before applying the translation if appropriate. Sub-pixel rendering on hardware displays often attempts to anti-alias across grid boundaries, causing independent letters or pixels to jump inconsistency.
2. **Settings Toggles**: If sub-pixel movement might be desired at higher speeds, wrap the rounding logic in a configuration boolean parameter (e.g., `pixelSnap`) to allow users to toggle the sub-pixel lock logic over their own device's refresh rate capabilities.
