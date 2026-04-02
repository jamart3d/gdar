# VU Meter LED Strip — Design Spec

**Date:** 2026-04-02
**Status:** Approved

---

## Summary

The `'vu'` audio graph mode renders two analog VU meters (L and R) side-by-side with a 10px gap. The meters overlap visually at that gap width. This change widens the gap and inserts a vertical stereo LED VU strip between the two analog meters. The strip gives an at-a-glance digital level read for both channels with peak hold.

---

## File Changed

`packages/shakedown_core/lib/steal_screensaver/steal_graph.dart` only.

---

## Layout Change

In `_renderVu`, change `gap` from `10.0` to `44.0`.

The two existing `_drawVuMeter` calls are unchanged except that their `left` values now use the wider gap:
- Left meter: `cx - _vuWidth - gap / 2`
- Right meter: `cx + gap / 2`

Insert one `_drawLedStrip(canvas, cx, baseY)` call between the two `_drawVuMeter` calls.

---

## LED Strip Dimensions

| Property | Value |
|---|---|
| Width | `28.0` px |
| Height | `_vuHeight` (110.0 px) — same as analog meters |
| Left edge | `cx - 14.0 + drift.dx` |
| Bottom edge | `baseY` — bottom-aligned with analog meters |
| Bottom label reserve | `18.0` px (for "L R" label) |
| Segments | 16 |
| Segment height | `(stripHeight - 18.0 - (16 - 1) * 1.5) / 16` |
| Segment gap | `1.5` px |
| Column gap | `2.0` px |
| Horizontal padding | `3.0` px each side |
| Column width | `(28.0 - 6.0 - 2.0) / 2 = 10.0` px each |

---

## Zone Colors

Reuse existing constants already used by the analog meters:

| Segments (0 = bottom) | Color | Inactive alpha |
|---|---|---|
| 0–9 (green) | `Color(0xFF4AF3C6)` | `0.08` |
| 10–12 (yellow) | `Color(0xFFFFE66D)` | `0.08` |
| 13–15 (red) | `Color(0xFFFF4444)` | `0.08` |

Active segments: `alpha 0.85`. Inactive: `alpha 0.08`.

---

## Peak Hold

Reuses existing `_vuPeakLeft` and `_vuPeakRight` (range 0.0–1.0), maintained by `_updateVuLevels` with `_vuPeakDecayPerSec`. No new state variables.

Peak segment index per channel: `(peakLevel * 15).round().clamp(0, 15)`.

If `peakLevel > 0.02`, draw the peak segment with:
- Fill: inactive alpha (same as normal inactive)
- Stroke: zone color at `alpha 0.6`, `strokeWidth 0.8`

---

## Panel Background

Same frosted rect as `_drawVuMeter`:
```dart
if (!_isFast) {
  // fill: Colors.white alpha 0.05, rounded 4px
  // stroke: Colors.white alpha 0.12 + _beatFlash * 0.06, strokeWidth 1.0
}
```

---

## Bottom Label

`"L"` centered under left column, `"R"` centered under right column.
- Font: `RobotoMono`, size `6`, weight `w600`, color `Color(0xFF445566)`, letter-spacing `1.0`
- Positioned at `baseY - 12` (within the 18px reserved label zone)

---

## Burn-in Drift

Apply `drift.dx` / `drift.dy` from `_burnInDrift()` to the strip position, same as both analog meters.

---

## Data Sources

- Active level: `_vuLeft` / `_vuRight` (same values used by analog needle)
- Peak hold: `_vuPeakLeft` / `_vuPeakRight` (same values used by analog peak dot)
- Beat flash: `_beatFlash` (panel stroke brightening, same as analog meters)
- Fast mode: `_isFast` (skips panel background, same as analog meters)

No new data sources, no new state.
