# Monorepo Rules (gdar)

This document defines the minimum rules for keeping the workspace healthy and
CI predictable.

## CI Contract
- CI must pass with a clean git worktree after all steps finish.
- CI runs: `melos bootstrap`, `dart format --set-exit-if-changed .`,
  `melos run analyze`, `melos run test`.
- Any step that generates files must either:
  - commit the outputs, or
  - be explicitly excluded from the clean-worktree check.

## Workspace Conventions
- All packages/apps use workspace resolution (`resolution: workspace`).
- No `dependency_overrides` unless justified in a tracked issue.
- Lint rules are centralized in the root `analysis_options.yaml`.
- Each package/app should include the root lint config.

## Melos Conventions
- `melos` is the standard entry point for bootstrap, analyze, and test.
- Shared scripts are configured in the root `pubspec.yaml` under the `melos` key.

## Dependency Hygiene
- Run `flutter pub outdated` periodically and triage upgrades.
- Prefer upgrading core/shared packages first, then apps.

## Chromebook Dev Tip (Web)
- Run the dev server in Crostini and open it in ChromeOS Chrome for better
  performance (avoid running Chrome inside Crostini).
- Example (from `apps/gdar_web`):
  `flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0 --profile --no-pub -t lib/main.dart`
