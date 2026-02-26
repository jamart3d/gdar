# SPLASH_SCREEN_ALIGNMENT_PLAN.md
Date: 2026-02-26
Time: 08:20

# Refine Splash Screen Checklist Alignment

The goal is to ensure the splash screen checklist items are left-aligned relative to each other, while the entire block remains centered on the screen.

## Proposed Changes

### UI Components

#### [MODIFY] [splash_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/screens/splash_screen.dart)

- Change the inner `Column`'s `crossAxisAlignment` from `CrossAxisAlignment.center` to `CrossAxisAlignment.start` (line 186).
- Change the `Row`'s `mainAxisAlignment` inside `_buildChecklistItem` from `MainAxisAlignment.center` to `MainAxisAlignment.start` (line 297).
- Keep `mainAxisSize: MainAxisSize.min` for both the `Column` and the `Row` to ensure the block stays compact and centered by its parent.

## Verification Plan

### Manual Verification
- **Android**: Run the app and observe the splash screen. The checkmarks should be aligned in a vertical column to the left of their labels, and the entire block of checks should be centered on the screen.
- **PWA/Web**: Run `flutter run -d chrome`. Resize the window. The checklist block should remain centered, but the individual items should maintain their left alignment relative to the block's edge.
