# Test Fixes Implementation Plan
Date: 2026-02-23 Time: 21:20

This plan addresses the identified test failures in the GDAR project.

## Proposed Changes

### Tests

#### [MODIFY] [audio_provider_test.dart](file:///c:/Users/jeff/StudioProjects/gdar/test/providers/audio_provider_test.dart)
- Stub `mockAudioCacheService.getAlbumArtUri()` to return `null`.

#### [MODIFY] [audio_provider_regression_test.dart](file:///c:/Users/jeff/StudioProjects/gdar/test/providers/audio_provider_regression_test.dart)
- Fix `LateInitializationError` for `audioProvider`.

#### [MODIFY] [screensaver_screen_test.dart](file:///c:/Users/jeff/StudioProjects/gdar/test/screens/screensaver_screen_test.dart)
- Fix `FakeUsedError` for `audioPlayer`.

## Verification Plan
- Run tests individually and then the full suite.
