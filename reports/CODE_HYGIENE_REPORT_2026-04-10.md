# Code Hygiene Report
Date: 2026-04-10

## Scope
- apps/
- packages/

## Analyzer Findings (Confirmed)
- `dart run melos run analyze`: no analyzer issues found across workspace packages/apps.

## Duplicate-Risk Candidates
- Scanner summary:
  - Duplicate block groups: 30
  - Duplicate block instances: 61
  - Dead private candidates: 42
- Top groups:
  - `apps/gdar_web/lib/ui/screens/about_screen.dart:166-177`
    and `packages/shakedown_core/lib/ui/screens/about_screen.dart:173-184`
    and `packages/shakedown_core/lib/ui/widgets/settings/about_section.dart:106-117`
  - `packages/shakedown_core/lib/audio/hybrid_audio_engine_web.dart:157-171`
    and `packages/shakedown_core/lib/audio/passive_audio_engine.dart:135-149`
  - `packages/shakedown_core/lib/ui/screens/show_list_screen.dart:179-284`
    and `packages/shakedown_core/lib/ui/screens/tv_show_list_screen.dart:146-251`
  - `apps/gdar_mobile/lib/main.dart:118-126`
    and `apps/gdar_tv/lib/main.dart:101-109`

## Suggested Cuts
- delete: generated duplicate registrations in `hive_registrar.g.dart` should be ignored by audit scope.
- merge: extract shared helpers between `show_list_screen.dart` and `tv_show_list_screen.dart`.
- extract: unify repeated audio-engine logic in `hybrid_audio_engine_web.dart` and `passive_audio_engine.dart`.

## Notes / False Positives
- This run used full shell-based scanner execution outside sandbox (not MCP-only).
- Scanner was refined to aggregate symbol usage by Dart library (main + `part`
  files), reducing dead-private noise:
  - previous run: 1000 candidates
  - current run: 42 candidates
- Duplicate scan now excludes generated `*.g.dart` files to reduce noisy matches.
- Remaining dead-private findings should be reviewed manually before deletion.
