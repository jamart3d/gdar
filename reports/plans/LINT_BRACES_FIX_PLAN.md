# Plan: Wrap if/else statements in curly braces
Date: 2026-02-19
Time: 13:35

## Goal Description
Fix the lint error "Statements in an if should be enclosed in a block" in `lib/ui/widgets/settings/tv_screensaver_section.dart`. This ensures consistency with the Dart style guide and the project's coding standards.

## Proposed Changes

### UI Components

---

#### [MODIFY] [tv_screensaver_section.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/widgets/settings/tv_screensaver_section.dart)
- Wrap the `if` and `else if` bodies in curly braces for inactivity timeout logic (lines 66-68 and 71-73).

## Verification Plan

### Automated Tests
- Run `dart analyze lib/ui/widgets/settings/tv_screensaver_section.dart` to ensure the lint error is resolved.
