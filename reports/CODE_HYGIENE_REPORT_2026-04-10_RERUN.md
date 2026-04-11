# Code Hygiene Report
Date: 2026-04-10
Run: Rerun snapshot

## Hygiene Score (1-10)
- **7/10**
- Rationale: analyzer is clean across all packages/apps (`No issues found`), but
  duplicate-risk groups (30) and dead-private candidates (42) still represent
  medium cleanup debt.

## Scope
- apps/
- packages/

## Analyzer Findings (Confirmed)
- `dart run melos run analyze`: no analyzer issues found across all 8 packages.

## Duplicate-Risk Candidates
- Scanner summary:
  - Duplicate block groups: 30
  - Duplicate block instances: 60
  - Dead private candidates: 42
- Top groups:
  - `apps/gdar_mobile/lib/main.dart:118-126`
    and `apps/gdar_tv/lib/main.dart:101-109`
  - `packages/shakedown_core/lib/audio/hybrid_audio_engine_web.dart:246-258`
    and `packages/shakedown_core/lib/audio/passive_audio_engine.dart:219-231`
  - `packages/shakedown_core/lib/audio/hybrid_audio_engine_web.dart:333-354`
    and `packages/shakedown_core/lib/audio/passive_audio_engine.dart:304-325`
  - `packages/shakedown_core/lib/ui/screens/about_screen.dart:173-184`
    and `packages/shakedown_core/lib/ui/widgets/settings/about_section.dart:106-117`
  - `packages/shakedown_core/lib/ui/screens/show_list_screen.dart:179-284`
    and `packages/shakedown_core/lib/ui/screens/tv_show_list_screen.dart:146-251`

## Suggested Cuts
- delete: review true-dead private members from the 42-candidate list, delete
  only after per-file ownership confirmation.
- merge: continue consolidating shared UI/helper blocks between TV/non-TV
  variants where behavior is equivalent.
- extract: keep audio engine split (`hybrid_audio_engine_web` vs
  `passive_audio_engine`) when HTML strategy differences are intentional.

## Notes / False Positives
- Audit command rerun:
  - `dart run scripts/code_hygiene_audit.dart`
- Analyzer confirmation rerun:
  - `dart run melos run analyze`
- Delta vs prior 2026-04-10 report:
  - Duplicate groups: `29 -> 30`
  - Duplicate instances: `58 -> 60`
  - Dead private candidates: unchanged at `42`
- Dead-private output still requires manual verification before deletion.
