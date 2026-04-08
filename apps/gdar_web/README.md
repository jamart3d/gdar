# GDAR Web

`gdar_web` is the web and PWA host for GDAR. It uses shared application logic
from `packages/shakedown_core` and the Fruit design system from
`packages/styles/gdar_fruit`, while still supporting an Android-style web mode
when explicitly requested.

## What This Target Does

- Runs the browser and PWA experience
- Defaults to the Fruit UI for first-time web launches
- Supports custom web audio engine behavior and PWA packaging
- Can be forced into Android-style UI with a query parameter

## Run Locally

From the workspace root:

```bash
flutter run -t apps/gdar_web/lib/main.dart -d chrome
```

From this directory:

```bash
flutter run -t lib/main.dart -d chrome
```

## UI Modes

Default behavior:

- Fruit UI is the intended web experience
- Android-style UI can be forced with `?ui=android`
- TV behavior can be forced with `?force_tv=true`

Examples:

```text
http://localhost:1234/?ui=android
http://localhost:1234/?force_tv=true
```

## Build

Web release build:

```bash
flutter build web --release
```

Output:

```text
build/web
```

## Related Docs

- `docs/WEB_PLAYBACK_DECISION_TREE.md`
- root `README.md`
- `.agent/specs/web_ui_design_spec.md`
- `.agent/specs/web_ui_audio_engines.md`

## Notes

- Fruit is the primary web visual language
- Fruit fallback behavior should remain Fruit-structured, not switch to
  Material 3 components
- Shared workspace verification still runs from the repo root with Melos
