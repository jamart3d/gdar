---
description: Windows web development setup with WASM disabled until further notice.
---
# Windows Web Development Setup

WASM is disabled for GDAR web work until further notice. This workflow keeps the existing Windows entry points but routes them to the standard web toolchain so Dart logger messages still flow to the terminal.

## Chrome Debug Script (Windows)

For local debugging on Windows, use the standard Chrome launcher:

```bat
@echo off
cd apps\gdar_web
flutter run -d chrome
```

The existing `fruc-wasm.bat` wrapper is retained only as a compatibility alias. It now launches standard web mode and prints a warning that WASM is disabled.

## Production Build

When you need a compiled web build, use the standard release pipeline:

```powershell
cd apps/gdar_web
flutter build web --release
```

## Web Error Log (gdarDumpErrors)

Use this when the UI freezes or behaves oddly and audio keeps playing.

1. Open Chrome DevTools (F12).
2. Go to the Console tab.
3. Run:

```javascript
gdarDumpErrors()
```

This prints and returns the in-memory error log captured by the app. You can copy the output or paste it into a bug report.

Optional:

```javascript
gdarClearErrors()
```

This clears the stored log. Logs are stored in localStorage under the key gdar_web_error_log_v1.
