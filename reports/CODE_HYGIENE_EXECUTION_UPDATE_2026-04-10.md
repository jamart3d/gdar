# Code Hygiene Execution Update
Date: 2026-04-10

## Requested Scope
- Do: 1, 2, 3, 6
- Skip/defer: 4, 5

## Completed
- Item 1: Scanner false-positive hardening
  - `scripts/code_hygiene_audit.dart` now ignores private-like identifiers
    inside comments, string literals, and `@JS(...)` annotation strings.
  - Dead-candidate pass now skips private type declarations
    (`class/enum/mixin/typedef/extension`).
  - Added tests:
    - `test/scripts/code_hygiene_audit_test.dart`
- Item 2: Trivial dead executable removals
  - After item 1 hardening, dead-private candidates dropped to `0`.
  - No safe executable dead members remained for deletion in this pass.
- Item 3: About-link dedupe
  - Added shared external URL launcher:
    - `openExternalUrl(...)` in
      `packages/shakedown_core/lib/utils/url_launcher_helpers.dart`
    - `launchExternalUrl(...)` in
      `packages/shakedown_core/lib/utils/utils.dart`
  - Removed duplicated `_launchUrl(...)` implementations from:
    - `packages/shakedown_core/lib/ui/screens/about_screen.dart`
    - `packages/shakedown_core/lib/ui/widgets/settings/about_section.dart`
- Item 6: Fruit pending overlay dedupe
  - Reused `FruitNowPlayingPendingOverlay` for car mode by making it
    configurable instead of maintaining two separate animation implementations.
  - Car-mode overlay now delegates to the shared widget with car-mode style
    parameters.

## Deferred / Skipped
- Item 4: deferred (risk/reward poor)
- Item 5: skipped (overkill)

## Metrics Delta (audit script)
- Before this execution:
  - Duplicate groups: `30`
  - Duplicate instances: `60`
  - Dead private candidates: `42`
- After this execution:
  - Duplicate groups: `28`
  - Duplicate instances: `56`
  - Dead private candidates: `0`

## Verification
- `dart format` (MCP) on touched files: clean
- `dart analyze` (MCP) on touched files: no errors
- `test/scripts/code_hygiene_audit_test.dart`: all tests passed
- `dart run scripts/code_hygiene_audit.dart`: rerun complete
