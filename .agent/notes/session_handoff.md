# Session Handoff — 2026-04-06

## What Was Done

### TV Screensaver Preview Panel
- Removed `LayoutBuilder` wrapper from `tv_screensaver_preview_panel.dart` so
  config changes propagate to `StealVisualizer` in the same frame (was deferred
  one frame, requiring navigate-away-and-back to see changes).
- Added 6 missing `StealConfig` fields that were not being passed from the
  preview panel builder.
- `logoScale` in preview config is set to `0.0` when "Preview: Audio Graph" is
  ON, so the logo is suppressed.

### Audio Graph Scaling (`steal_graph.dart`)
- Added `_graphScale` getter and `_logicalSize` computed property.
- `render()` wraps the switch in `canvas.save(); canvas.scale(scale, scale);
  canvas.restore()` so all graph modes scale automatically.
- All render files use `_logicalSize` instead of `game.size` for positioning.
- For preview-sized containers (`game.size.x < 600`), uses a 512px reference
  instead of 1280px so graphs fill ~75% of the preview instead of ~30%.

### Logo Suppression (two-layer fix)
- `steal_background.dart` `_updateShaderUniforms`: passes `0.0` to the shader
  when `config.logoScale <= 0.0` (bypasses the `clamp(0.05, 1.1)` guard).
- `steal.frag`: added `logoVisible = step(0.001, uLogoScale)` and multiplies
  `texColor` by it, defeating the shader's own internal `clamp(0.05, 1.0)`.
- `steal_background.dart`: trail render and `_tickTrailBuffer` both early-return
  when `config.logoScale <= 0.0` (no ghost trail accumulation).

### VU Meters (`steal_graph_render_corner.dart`)
- Removed peak-hold indicator dots (`peakLevel` circle block).
- Needle now starts at spindle edge (`spindleRadius = 4.5`) rather than pivot
  centre, so needle and its glow don't bleed through the hub.

### Beat Debug (`steal_graph_render_debug.dart`)
- Added `● BEAT` indicator (lerps dim white → green on `_beatFlash`) alongside
  the FINAL PCM meter label.
- Removed flash-burst dot and winning-algo dot from algorithm bars.
- All `game.size` references replaced with `_logicalSize`.

### Enhanced Beat Detector Settings UI
- `tv_screensaver_section_audio_build.dart`: reduced from 4 tiles to 2.
- `tv_screensaver_section_controls.dart`: `_ReactiveHint` now accepts optional
  `accentColor` for colour-coded status.
- `tv_screensaver_section.dart`: added `_enhancedCaptureStatusColor()` returning
  green/orange/red/null.

## What Is NOT Done / Watch Out For
- Changes are **not committed or pushed** — user did not ask for a save.
- The shader fix (`steal.frag`) has not been tested on device — verify the logo
  truly disappears when "Preview: Audio Graph" is ON.
- Song/track hints are **display-only** and do not feed into beat detection.
  Future work: pass seed BPM from hint catalog to pre-warm the beat grid.
- Beat detection detects **tempo (BPM)** via autocorrelation + grid, but does
  **not** detect musical key or individual notes (would need a chromagram).

## Key Files Changed
| File | Change |
|---|---|
| `steal.frag` | `logoVisible` flag to blank logo at scale 0 |
| `steal_background.dart` | Pass 0.0 to shader; skip trail when logoScale=0 |
| `steal_graph.dart` | `_graphScale` / `_logicalSize`; adaptive reference width |
| `steal_graph_render_corner.dart` | VU needle start offset; remove peak dots |
| `steal_graph_render_debug.dart` | `● BEAT` indicator; remove bar dots |
| `steal_graph_render_ekg.dart` | `_logicalSize` refs |
| `tv_screensaver_preview_panel.dart` | Remove LayoutBuilder; full config fields |
| `tv_screensaver_section*.dart` | Colour-coded status tiles, 2-tile layout |
