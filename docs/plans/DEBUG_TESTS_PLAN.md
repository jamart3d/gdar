# Debugging Failing Tests Plan
Date: 2026-02-19
Time: 22:30

## Goal Description
Identify and resolve consistent test failures in the Shakedown codebase to ensure stability and reliable CI feedback.

## User Review Required
> [!NOTE]
> All identified issues were verified as regressions or incomplete test mocks. No functional changes to the application's user-facing behavior were required, except for stabilizing internal service states (Audio Cache and Fast Scrollbar).

## Proposed Changes

### UI Widgets Component
#### [MODIFY] [fast_scrollbar.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/widgets/show_list/fast_scrollbar.dart)
- Address "Timer still pending" error in lifecycle tests.
- Implement proper `Timer` management and cancellation in `dispose()`.

### Services Component
#### [MODIFY] [audio_cache_service.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/services/audio_cache_service.dart)
- Address `PathNotFoundException` during cache count refreshes.
- Add defensive checks and `try-catch` blocks to handle transient directory deletions during tests.

### Testing Component
#### [MODIFY] [playback_screen_test.dart](file:///c:/Users/jeff/StudioProjects/gdar/test/screens/playback_screen_test.dart)
- Fix `MockCatalogService` implementation to return correct `ValueListenable` and boolean values for `historyListenable` and `isPlayed`.
- Verify `RenderFlex` overflow resolution.

## Verification Plan

### Automated Tests
- Run specific failing tests:
  - `test/screens/playback_screen_test.dart`
  - `test/screens/show_list_screen_lifecycle_test.dart`
  - `test/services/audio_cache_service_test.dart`
  - `test/services/buffer_agent_test.dart`
- Run full test suite: `flutter test`
