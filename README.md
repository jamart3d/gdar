# gdar

`gdar` is a Flutter monorepo for a family of Grateful Dead audio players:

- `apps/gdar_mobile` for Android and mobile-first layouts
- `apps/gdar_tv` for Google TV / Android TV
- `apps/gdar_web` for the web and PWA experience

The repo is organized as a Dart workspace with shared UI, playback, data, and
platform logic in reusable packages.

## Highlights

- Gapless MP3 playback built around `just_audio`
- Shared catalog and playback logic in `packages/shakedown_core`
- TV-first D-pad navigation and dual-pane layouts
- Web/PWA Fruit UI with Apple Liquid Glass styling
- Material 3 Expressive mobile styling via shared design packages
- Workspace-wide format, analyze, test, and release tooling via Melos

## Workspace Layout

```text
apps/
  gdar_mobile/   Mobile application target
  gdar_tv/       Google TV / Android TV target
  gdar_web/      Web / PWA target

packages/
  gdar_design/           Shared typography, tokens, and design helpers
  screensaver_tv/        TV screensaver package
  shakedown_core/        Core models, providers, services, assets, widgets
  styles/gdar_android/   Android theme package
  styles/gdar_fruit/     Fruit web theme package
```

## Requirements

- Flutter stable
- Dart `^3.11.0`
- Android SDK for Android builds
- Chrome or another supported browser for local web runs
- Firebase CLI only if you are deploying hosting from this repo

## Quick Start

From the workspace root:

```bash
dart pub get
melos bootstrap
```

Run a target app:

```bash
flutter run -t apps/gdar_mobile/lib/main.dart
flutter run -t apps/gdar_tv/lib/main.dart
flutter run -t apps/gdar_web/lib/main.dart -d chrome
```

If you prefer target-local commands, run them from the app directory under
`apps/`.

## Common Workspace Commands

All commands run from the repo root unless noted otherwise.

```bash
melos run format
melos run analyze
melos run test
melos run clean
melos run icons
```

Useful one-off commands:

```bash
dart scripts/preflight_check.dart --preflight-only
dart scripts/preflight_check.dart --release
dart run scripts/scan_diffs.dart
dart run scripts/size_guard/audit_assets.dart
```

## Platform Targets

### Mobile

- Material 3 Expressive direction
- Shared application id with the TV host
- Built from `apps/gdar_mobile`
- The Play Store Android release is a single AAB built from `apps/gdar_mobile`
  and delivered to both phone and TV device classes

Release bundle:

```text
apps/gdar_mobile/build/app/outputs/bundle/release/app-release.aab
```

### TV

- Dedicated Android TV / Google TV host in `apps/gdar_tv`
- Leanback/D-pad-focused layout and navigation
- TV development has a dedicated host app, but TV is not a separate Play Store
  release artifact
- See `apps/gdar_tv/docs/TV_DEBUGGING.md` for TV-specific debugging flows

### Web / PWA

- Built from `apps/gdar_web`
- Fruit theme and Liquid Glass styling
- Progressive Web App shell and custom web audio engine support

Web build output:

```text
apps/gdar_web/build/web
```

## Architecture

The repo follows a shared clean-architecture split:

- UI: Widgets and screens
- Logic: Providers and interaction orchestration
- Data: Services, repositories, persistence, and assets

State management is based on `provider`, primarily `ChangeNotifier` and
`ProxyProvider`.

Shared code lives in `packages/shakedown_core`, which contains:

- app-level providers such as settings, audio, and show list state
- playback and platform services
- reusable screens and widgets
- bundled catalog and visual assets

## Data and Performance Notes

The main show catalog lives at:

```text
packages/shakedown_core/assets/data/output.optimized_src.json
```

This file is large and must not be parsed synchronously on the UI thread.
Catalog parsing should stay on isolates via `compute()` or equivalent isolate
work.

## Testing and Verification

Primary workspace verification:

```bash
melos run analyze
melos run test
```

Fast environment and health checks:

```bash
dart scripts/preflight_check.dart --preflight-only
dart scripts/preflight_check.dart --release
```

The repo also includes targeted docs and workflows under `docs/` and
`.agent/workflows/` for release, audit, and debugging tasks.

## Build and Release

Build commands should target a specific app directory:

```bash
cd apps/gdar_mobile
flutter build appbundle --release

cd ../gdar_web
flutter build web --release
```

For the current release process and notes, see:

- `docs/PLAY_STORE_RELEASE.txt`
- `.agent/workflows/publish.md`

## Useful Docs

- `docs/MONOREPO_RULES.md`
- `docs/SCREENSAVER_MANUAL.md`
- `docs/WEB_PLAYBACK_DECISION_TREE.md`
- `apps/gdar_tv/docs/TV_DEBUGGING.md`

## Development Notes

- Prefer package imports across package boundaries
- Keep reusable logic in `packages/`, not in app targets
- Run workspace checks from the root
- Keep Fruit web UI separate from Material 3 presentation patterns
