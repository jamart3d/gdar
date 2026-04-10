# Dead Code Removal Plan
Date: 2026-04-10

## Baseline
- Scanner: `dart run scripts/code_hygiene_audit.dart`
- Current dead private candidates: 42
- Important: many candidates are likely false positives from:
  - JS interop annotation strings (for example `@JS('_shakedownAudioStrategy')`)
  - private type/extension names in `part`-split files

## Ranked Queue (Easiest -> Hardest)

## 1. Very Easy (Safe, low behavior risk)
- Goal: remove obvious stubs and naming leftovers with no runtime coupling.
- Candidates:
  - `packages/shakedown_core/lib/services/catalog_service.dart:481 _web_stub`
    Reason: this is a `Box.name` stub string and not behavior-critical.
  - `packages/shakedown_core/lib/models/source.dart:27 _d`
    Reason: not a private symbol; this is JSON key access and should be excluded
    from dead-code scanner, not deleted.
- Action:
  - Keep behavior unchanged.
  - Update scanner to ignore underscore tokens in string literals/JSON keys.

## 2. Easy (Scanner accuracy cleanup)
- Goal: eliminate false positives before deleting production code.
- Candidates:
  - `packages/shakedown_core/lib/audio/web_interop_web.dart:5 _gdarMediaSession`
  - `packages/shakedown_core/lib/services/gapless_player/gapless_player_web.dart`
    `_shakedownAudioStrategy`, `_shakedownAudioReason`
- Action:
  - Do not remove these interop anchors.
  - Update scanner parser to ignore tokens inside string literals and `@JS(...)`.

## 3. Medium (Part-file type-name false positives)
- Goal: validate part-based private helper/type names before deletion.
- Candidate pattern:
  - `_PlaybackScreen*`, `_TrackListScreen*`, `_DevAudioHud*`,
    `_TvScreensaverSection*`, `_ShowListCard*`, `_Steal*Render`
- Action:
  - Treat as likely intentional structure markers.
  - Exclude private type declarations from dead-symbol checks unless they are
    never instantiated/referenced in the same library.

## 4. Hard (Potentially real dead logic)
- Goal: find truly dead private methods/fields with runtime side effects.
- Action:
  - After scanner refinement, rerun and only keep candidates that are:
    - executable members (methods/fields), not type names/constants in strings.
  - Remove in tiny batches (1-3 symbols), run analyze + targeted tests each batch.

## Execution Plan
1. Refine scanner (strings/annotations/type-name filtering).
2. Rerun scanner and regenerate dated hygiene report.
3. Build a deletion list containing only executable-member candidates.
4. Remove lowest-risk batch and verify:
   - `dart run melos run analyze`
   - targeted tests for touched areas
5. Repeat until candidate count stabilizes near intentional baseline.

## Stop Conditions
- If a candidate is tied to web interop, screensaver rendering, or audio engine
  mode-selection, default to keep unless tests prove safe removal.
- Keep Tier 2 audio split (`html5` vs `html5_hybrid`) unchanged by policy.
