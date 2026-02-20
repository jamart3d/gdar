# Shipit Workflow - v1.0.98+98 (2026-02-19 18:35)

This plan outlines the steps for releasing version 1.0.98+98 of the Shakedown app.

## Proposed Changes

### Configuration & Documentation
#### [MODIFY] [pubspec.yaml](file:///c:/Users/jeff/StudioProjects/gdar/pubspec.yaml)
- Increment version from `1.0.97+97` to `1.0.98+98`.

#### [MODIFY] [RELEASE_NOTES.txt](file:///c:/Users/jeff/StudioProjects/gdar/RELEASE_NOTES.txt)
- Add release notes for 1.0.98 detailing stability fixes and verification results.

## Build & Release Steps
1. **Build AppBundle**: Run `flutter build appbundle --release` to generate the signed production bundle.
2. **Stage changes**: `git add .`
3. **Commit**: `git commit -m "chore: release v1.0.98+98 - Stability hardening and test coverage"`
4. **Push**: `git push`

## Verification Plan

### Automated Tests
- I have already verified the project health with `/checkup`.
- I will verify the build completion by checking for the existence of `build/app/outputs/bundle/release/app-release.aab`.

### Manual Verification
- None required as this is a build phase.
