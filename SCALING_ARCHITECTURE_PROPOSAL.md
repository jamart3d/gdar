# Scaling Architecture Proposal

**Problem:** Current scaling has **3 conflicting layers** causing unpredictable behavior.

---

## Current Messy Architecture 🔴

```
User's Final Font Size = Base × Theme Multiplier × Widget Multiplier × System Scale

Example (Rock Salt, uiScale=true, system=1.3):
22pt × 0.6 (theme) × 1.5 (widget) × 1.3 (system) = 25.74pt
        ↑              ↑               ↑
   app_themes.dart  ShowListCard  Android Settings
```

**Problems:**
1. ❌ Size defined in **3 different places**
2. ❌ Impossible to predict final size
3. ❌ Rock Salt gets special treatment at theme level
4. ❌ `uiScale` toggle duplicates what Media Query already does

---

## Flutter Best Practices ✅

### The Golden Rule
> **Let `MediaQuery.textScaleFactor` handle ALL dynamic scaling. Define base sizes once.**

```dart
// ✅ GOOD: MediaQuery automatically applied
Text(
  'Venue Name',
  style: Theme.of(context).textTheme.titleLarge,  // Base size from theme
)

// ❌ BAD: Manual multipliers fight with MediaQuery
Text(
  'Venue Name', 
  style: Theme.of(context).textTheme.titleLarge?.apply(
    fontSizeFactor: 1.5  // This compounds with system scale!
  ),
)
```

---

## Proposed Clean Architecture

### Option A: Pure Theme-Based (Recommended) ⭐

**Concept:** All sizing in theme, zero scaling in widgets.

#### Implementation

**1. Simplify `app_themes.dart`**
```dart
case 'rock_salt':
  // NO manual downscaling - let Rock Salt be its natural size
  return baseTextTheme.apply(
    fontFamily: 'RockSalt',
    // Still increase line height to prevent clipping
    // But remove fontSize multipliers (0.6x, 0.7x, etc.)
  );
```

**2. Remove widget-level scaling**
```dart
// ShowListCard - BEFORE
final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;
final venueStyle = baseVenueStyle.apply(fontSizeFactor: scaleFactor);

// ShowListCard - AFTER
final venueStyle = baseVenueStyle;  // That's it!
// MediaQuery handles scaling automatically
```

**3. Replace `uiScale` Toggle**
```dart
// Instead of manual 1.5x multiplier, use MediaQuery
final textScale = MediaQuery.textScaleFactorOf(context);

// For spacing that should scale with text:
SizedBox(height: 8.0 * textScale)
```

**Benefits:**
- ✅ Single source of truth (theme)
- ✅ Respects system accessibility settings automatically
- ✅ No compound multiplication
- ✅ Predictable behavior

**Trade-off:**
- ⚠️ Removes `uiScale` toggle (users would use Android's system font size instead)

---

### Option B: Per-Widget Sizing (More Control)

**Concept:** Don't use theme sizes at all - define explicit sizes per widget.

#### Implementation

**1. Create Widget-Specific Size Constants**
```dart
// lib/ui/widgets/show_list_card.dart
class ShowListCardSizes {
  final double venueFontSize;
  final double dateFontSize;
  final double cardHeight;
  final double badgeSize;
  
  const ShowListCardSizes({
    required this.venueFontSize,
    required this.dateFontSize,
    required this.cardHeight,
    required this.badgeSize,
  });
  
  // Named constructors for different scales
  factory ShowListCardSizes.standard() => const ShowListCardSizes(
    venueFontSize: 20.0,
    dateFontSize: 14.0,
    cardHeight: 82.0,
    badgeSize: 20.0,
  );
  
  factory ShowListCardSizes.large() => const ShowListCardSizes(
    venueFontSize: 26.0,
    dateFontSize: 18.0,
    cardHeight: 106.0,
    badgeSize: 24.0,
  );
  
  // Or scale dynamically based on MediaQuery
  factory ShowListCardSizes.fromTextScale(double textScale) {
    final base = ShowListCardSizes.standard();
    return ShowListCardSizes(
      venueFontSize: base.venueFontSize * textScale,
      dateFontSize: base.dateFontSize * textScale,
      cardHeight: base.cardHeight * textScale,
      badgeSize: base.badgeSize * textScale,
    );
  }
}
```

**2. Use in Widget**
```dart
@override
Widget build(BuildContext context) {
  final textScale = MediaQuery.textScaleFactorOf(context);
  final sizes = ShowListCardSizes.fromTextScale(textScale);
  
  final venueStyle = TextStyle(
    fontSize: sizes.venueFontSize,
    fontFamily: settingsProvider.appFont == 'rock_salt' ? 'RockSalt' : null,
    fontWeight: FontWeight.w600,
  );
  
  return Container(
    height: sizes.cardHeight,
    child: Text(widget.show.venue, style: venueStyle),
  );
}
```

**Benefits:**
- ✅ Complete control over sizing
- ✅ Widget-specific optimizations
- ✅ Easy to test different size combinations
- ✅ Clear what size each element is

**Trade-offs:**
- ⚠️ More boilerplate per widget
- ⚠️ Need to maintain size classes
- ⚠️ Less consistency across app

---

### Option C: Hybrid (Best of Both Worlds)

**Concept:** Use theme for **text**, per-widget for **layout** (spacing, heights).

#### Implementation

**1. Theme Handles Text Only**
```dart
// app_themes.dart - Define base text sizes
case 'rock_salt':
  return baseTextTheme.apply(
    fontFamily: 'RockSalt',
    fontSizeFactor: 0.85,  // Slight reduction ONLY
  );
```

**2. Widgets Calculate Layout Dynamically**
```dart
@override
Widget build(BuildContext context) {
  final textScale = MediaQuery.textScaleFactorOf(context);
  final textTheme = Theme.of(context).textTheme;
  
  // Text sizes come from theme
  final venueStyle = textTheme.titleLarge;
  final dateStyle = textTheme.bodyLarge;
  
  // Layout scales with text
  final cardHeight = 82.0 + (textScale - 1.0) * 20.0;  // Grows proportionally
  final spacing = 8.0 * textScale;
  final badgeSize = 20.0 * textScale.clamp(1.0, 1.3);  // Clamped for usability
  
  return Container(
    height: cardHeight,
    child: Column(
      children: [
        Text(widget.show.venue, style: venueStyle),
        SizedBox(height: spacing),
        Text(formattedDate, style: dateStyle),
      ],
    ),
  );
}
```

**Benefits:**
- ✅ Theme provides consistency
- ✅ Widgets adapt layout intelligently
- ✅ Can clamp extreme scales per-widget
- ✅ Balances flexibility and simplicity

---

## Recommendation: **Option C (Hybrid)** ⭐

### Why?

1. **Text consistency:** Theme ensures all text with same style looks identical
2. **Layout flexibility:** Widgets can optimize spacing/heights for their context
3. **Best UX:** Can clamp Rock Salt specifically without affecting other fonts
4. **Gradual migration:** Can refactor widget-by-widget

---

## Implementation Plan

### Phase 1: Simplify Theme (Low Risk)

**File:** [app_themes.dart](file:///home/jam/StudioProjects/gdar/lib/utils/app_themes.dart)

```diff
case 'rock_salt':
-  final theme = baseTextTheme.apply(fontFamily: 'RockSalt');
-  return theme.copyWith(
-    titleLarge: theme.titleLarge?.copyWith(
-        fontSize: (theme.titleLarge?.fontSize ?? 22) * 0.6, height: 1.6),
-    // ... (all the manual scaling)
-  );
+  return baseTextTheme.apply(
+    fontFamily: 'RockSalt',
+    fontSizeFactor: 0.85,  // Slight reduction to compensate for wide characters
+  );
```

**Impact:** Rock Salt will initially appear **larger**, but that's OK - we'll clamp it per-widget next.

---

### Phase 2: Refactor ShowListCard (Medium Risk)

**File:** [show_list_card.dart](file:///home/jam/StudioProjects/gdar/lib/ui/widgets/show_list_card.dart)

#### Step 2.1: Remove Manual `scaleFactor`

```diff
- final double scaleFactor = settingsProvider.uiScale ? 1.5 : 1.0;
+ final textScale = MediaQuery.textScaleFactorOf(context);
+ // Clamp Rock Salt to prevent extreme scaling
+ final effectiveScale = settingsProvider.appFont == 'rock_salt' 
+     ? textScale.clamp(1.0, 1.2)  // Max 1.2x for Rock Salt
+     : textScale;  // No limit for system fonts
```

#### Step 2.2: Apply to Styles

```diff
- final venueStyle = baseVenueStyle
-     .copyWith(...)
-     .apply(fontSizeFactor: scaleFactor);
+ final venueStyle = baseVenueStyle.copyWith(
+     fontWeight: FontWeight.w600,
+     letterSpacing: 0.1,
+     color: colorScheme.onSurface,
+     // fontSizeFactor removed - MediaQuery handles it
+ );
```

#### Step 2.3: Scale Layout Proportionally

```diff
- final double cardHeight = 82.0 * scaleFactor;
+ final double cardHeight = 82.0 + (effectiveScale - 1.0) * 30.0;
+ // At 1.0x: 82pt
+ // At 1.2x: 88pt (+6pt, +7%)
+ // At 1.5x: 97pt (+15pt, +18%)
```

```diff
- SizedBox(height: 2 * scaleFactor),
+ SizedBox(height: 6.0 * effectiveScale),
```

---

### Phase 3: Update Settings (Low Risk)

**Option A:** Remove `uiScale` toggle entirely
- Users use Android's system font size instead
- Simpler, more standard

**Option B:** Repurpose `uiScale` as "Extra Large Text Mode"
```dart
final textScale = MediaQuery.textScaleFactorOf(context);
final boostedScale = settingsProvider.uiScale 
    ? textScale * 1.15  // 15% boost instead of fixed 1.5x
    : textScale;
```

---

## Testing Strategy

### Before Changes
1. Capture baseline screenshots at all 8 configurations
2. Note current card heights, spacing, font sizes

### After Each Phase
1. Re-run `adb_ui_scale_test.py`
2. Compare screenshots pixel-by-pixel
3. Verify:
   - [ ] Text remains readable
   - [ ] No clipping
   - [ ] Consistent card heights
   - [ ] Spacing proportional

### Acceptance Criteria
- No text clipping at any scale (0.85x - 1.30x)
- Card height variance ≤ 10% (currently ~30%)
- ≥ 5 visible shows at extreme scales (currently 4)

---

## Migration Effort Estimate

| Phase | Files Changed | Risk | Time |
|-------|---------------|------|------|
| **Phase 1: Theme** | 1 file | Low | 30 min |
| **Phase 2: ShowListCard** | 1 file | Medium | 1-2 hours |
| **Phase 3: Settings** | 2 files | Low | 30 min |
| **Testing** | - | - | 1 hour |
| **Total** | ~4 files | Medium | **3-4 hours** |

---

## FAQ

### Q: Why not just use `textScaleFactor` everywhere?
**A:** We do! But we need to:
1. Clamp it for Rock Salt specifically (wide font breaks layout)
2. Apply it to spacing/heights (not automatic for non-text widgets)

### Q: What about the `uiScale` toggle users already have?
**A:** Two options:
1. **Remove it:** Simpler, more standard (use Android settings)
2. **Repurpose it:** Make it a "boost" (1.15x multiplier) instead of fixed 1.5x

### Q: Will this break existing user preferences?
**A:** No - if we keep `uiScale` toggle, behavior stays similar (just cleaner internally).

### Q: What about other widgets (PlayerPanel, TrackList, etc.)?
**A:** Apply same pattern:
1. Text sizes from theme
2. Layout (heights, spacing) scaled via `MediaQuery.textScaleFactorOf(context)`
3. Font-specific clamping if needed

---

## Conclusion

**Current:** 3 layers of scaling = unpredictable chaos  
**Proposed:** 1 source (MediaQuery) + per-widget layout intelligence = clean and predictable

**Next Step:** Approve Option C (Hybrid), then execute Phase 1 (theme simplification).
