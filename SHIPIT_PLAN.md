# Shipit Workflow - v1.1.0+100 (2026-02-19 19:43)

This plan outlines the steps for releasing version 1.1.0+100 of the Shakedown app, incorporating verified system health and finalized visual enhancements.

## Proposed Changes

### Configuration & Documentation
#### [MODIFY] [pubspec.yaml](file:///c:/Users/jeff/StudioProjects/gdar/pubspec.yaml)
- Increment version from `1.0.98+98` to `1.0.99+99`.

#### [MODIFY] [RELEASE_NOTES.txt](file:///c:/Users/jeff/StudioProjects/gdar/RELEASE_NOTES.txt)
- Add release notes for 1.0.99:
    - **Steal Screensaver**: Sophisticated per-word neon flicker with desynchronized phases (buzz, dropout, recovery).
    - **Checkup Workflow**: Upgraded to use Dart MCP tools for structured analysis and testing.

### Refactoring & Enhancement
#### [MODIFY] [.agent/workflows/checkup.md](file:///c:/Users/jeff/StudioProjects/gdar/.agent/workflows/checkup.md)
- Transitioned to `mcp_dart-mcp-server` tools.

#### [MODIFY] [lib/steal_screensaver/steal_banner.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/steal_screensaver/steal_banner.dart)
- Implemented full neon flicker state machine.

## Build & Release Steps
1. **Build AppBundle**: Run `flutter build appbundle --release`.
2. **Stage changes**: `git add .`
3. **Commit**: `git commit -m "chore: release v1.0.99+99 - Neon flicker effect and MCP workflow upgrade"`
4. **Push**: `git push`

## Verification Plan

### Automated Tests
- `/checkup` (already verified locally).
- Verify build artifact existence.

### Manual Verification
- Visual check of neon flicker in Steal Screensaver.
