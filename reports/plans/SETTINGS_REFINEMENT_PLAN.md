# SETTINGS_REFINEMENT_PLAN.md
Date: 2026-02-26
Time: 08:12

# Hiding Prefetch Setting and Scaling Segmented Button Labels

This plan addresses several UI and settings refinements for the Web/PWA experience.

## Proposed Changes

### UI Components

#### [MODIFY] [playback_section.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/ui/widgets/settings/playback_section.dart)

- **Hide Prefetch**: Remove the `ListTile` containing the "Prefetch Ahead" slider from `_buildWebGaplessSection`.
- **Scale Segmented Button Labels**: Wrap the `Text` widgets in the `ButtonSegment` labels with a `FittedBox` (BoxFit.scaleDown) and ensure `maxLines: 1` to prevent wrapping and ensure visibility.
- **Left Align Block**: Ensure the "Web Audio Engine" section and the `SegmentedButton` are explicitly left-aligned (e.g., via `CrossAxisAlignment.start` and `Align`).

### Business Logic

#### [MODIFY] [settings_provider.dart](file:///c:/Users/jeff/StudioProjects/gdar/lib/providers/settings_provider.dart)

- **Force Prefetch to 30s**: In `_init()`, ensure `_webPrefetchSeconds` is hardcoded to 30 or strictly forced to `DefaultSettings.webPrefetchSeconds` regardless of stored preference, to align with the decision to hide the setting and use a fixed value.

## Verification Plan

### Manual Verification
- **Settings UI**: Open settings and expand the "Playback" section on Web/PWA. The "Prefetch Ahead" slider should no longer be visible.
- **Segmented Buttons**: Observe the "Web Audio Engine" buttons. The labels ("Web Audio", "HTML5", "Standard") should scale down if space is limited, ensuring they don't wrap to multiple lines.
- **Functionality**: Verify that gapless playback still works correctly with the hidden 30s prefetch.
