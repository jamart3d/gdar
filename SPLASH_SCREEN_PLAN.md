# SPLASH_SCREEN_PLAN.md
Date: 2026-02-26
Time: 08:05

# Centering and Scaling Splash Screen Checklist

This plan addresses the issue where splash screen checklist items are left-aligned and do not scale properly across different screen sizes (Android and PWA).

## Proposed Changes

### UI Components

#### [MODIFY] [splash_screen.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/screens/splash_screen.dart)

- Remove the fixed width `SizedBox` (440.0) wrapping the checklist items.
- Change the inner `Column`'s `crossAxisAlignment` to `CrossAxisAlignment.center`.
- Use `ConstrainedBox` or a percentage-based width to ensure the checklist remains readable but centered.
- Update `_buildChecklistItem` to use `MainAxisAlignment.center` in its `Row`.
- Wrap the checklist `Column` in a `FittedBox` with `BoxFit.scaleDown` to fulfill the "scale to fit" requirement without overflowing.

## Verification Plan

### Manual Verification
- **Android**: Run the app and observe the splash screen. The "shnids loaded" and "shows ready" checks should be perfectly centered.
- **PWA/Web**: Run `flutter run -d chrome` or use the browser tool to inspect the splash screen. Resize the window to ensure the checks scale down if the screen is too narrow and stay centered.
