# FruitTooltip Positioning

## Rule: Always anchor by `bottom`, never `top`

`FruitTooltip._showTooltip()` must use a `bottom` anchor in its `Positioned` overlay entry so the tooltip always grows upward, clear of the chip and cursor.

```dart
// CORRECT
final double bottom = screenHeight - globalTopLeft.dy + 8;
Positioned(left: left, bottom: bottom, child: ...)

// WRONG — do not use top anchor
final double top = globalTopLeft.dy - 44;
Positioned(left: left, top: top, child: ...)
```

### Why

When the tooltip overlay entry overlaps the chip or cursor area, its insertion and `AnimatedOpacity` animation propagate `markNeedsPaint()` up through the render tree. This triggers `MouseTracker.schedulePostFrameCheck()`, which fires a spurious EXIT on the chip's `RenderMouseRegion`. That calls `_cancelShow()` → debounce → `_hideTooltip()` → the tooltip visibly flashes.

The `bottom` anchor prevents this entirely: the tooltip bottom is always `screenHeight - chip.dy + 8px` above the chip, so it can never overlap the chip or the cursor hovering on it.

### Companion rule: RepaintBoundary on animated chip content

Wrap any animated content inside a chip (e.g. `_buildTrafficLightHeartbeat`) in a `RepaintBoundary`. This stops `AnimatedContainer.markNeedsPaint()` from propagating to the parent `RenderMouseRegion` and triggering the same spurious EXIT path.

```dart
RepaintBoundary(
  child: _buildTrafficLightHeartbeat(...),
)
```

### Symptoms of regression

- Tooltip on a chip briefly disappears and reappears on a regular interval (matches an animation timer in the chip, e.g. 900ms heartbeat pulse).
- Only affects chips whose content animates while the tooltip is visible — chips that don't animate (DFT, HD) are unaffected.
