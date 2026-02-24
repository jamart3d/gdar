# Shipit Plan: Release 1.1.14+114
Date: 2026-02-24 12:51 PM

## Goal
Release version 1.1.14+114 containing the web background playback stall fix and the web dice playback fix.

## Proposed Changes

### Configuration
#### [MODIFY] [pubspec.yaml](file:///home/jam/StudioProjects/gdar/pubspec.yaml)
- Increment version: `1.1.13+113` -> `1.1.14+114`.

#### [MODIFY] [RELEASE_NOTES.txt](file:///home/jam/StudioProjects/gdar/RELEASE_NOTES.txt)
- Add entries for the web background playback and dice playback fixes.

## Verification Plan
### Automated Tests
- Run `flutter build appbundle --release` (This also triggers a build check).
- Verify 162/162 tests passed in previous step.

### Manual Verification
- Verify the aab exists at `build/app/outputs/bundle/release/app-release.aab`.
