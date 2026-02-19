# FastScrollbar Test Implementation Plan
Date: 2026-02-19
Time: 22:35

## Goal Description
Add dedicated widget tests for `FastScrollbar` to ensure its complex lifecycle, auto-hide logic, and draggable behavior are correct and stable, especially after the recent timer leak fix.

## User Review Required
> [!NOTE]
> The new tests will use `tester.pumpAndSettle()` and `tester.pump(Duration)` to verify animation states and auto-hide timing. It will also mock `ItemScrollController` and `ItemPositionsListener`.

## Proposed Changes

### Testing Component
#### [NEW] [fast_scrollbar_test.dart](file:///c:/Users/jeff/StudioProjects/gdar/test/widgets/fast_scrollbar_test.dart)
- Test thumb visibility on scroll.
- Test auto-hide timer after 1 second of inactivity.
- Test drag interactions and spring scale animations.
- Test year chip overlay visibility and content.
- Ensure clean disposal with no pending timers.

## Verification Plan

### Automated Tests
- Run the new test: `flutter test test/widgets/fast_scrollbar_test.dart`
- Run the existing lifecycle test to ensure no regressions: `flutter test test/screens/show_list_screen_lifecycle_test.dart`
