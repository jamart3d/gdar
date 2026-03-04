# Improving Screensaver Spacing Plan
Date: 2026-02-27
Time: 08:55 AM

## Problem
The inner ring of the screensaver text is too spread out even at the tightest settings. Character and word spacing have hardcoded buffers and restrictive lower bounds.

## Proposed Changes
1.  **Remove Hardcoded Buffer**: In `steal_banner.dart`, remove the `+ 0.2` word spacing offset.
2.  **Adjust UI Limits**: In `tv_screensaver_section.dart`, lower the minimum letter spacing from `0.8` to `0.5`.

## Verification Path
- Verify with `flutter test`.
- Manual verification via TV settings.
