---
description: Suggests development aliases and setup steps for Windows environments testing Wasm.
---
# Windows Wasm Development Setup

This workflow provides quick setup commands and aliases optimized for running and testing the Flutter app WebAssembly (Wasm) build on Windows, ensuring you can still see the Dart logger messages.

## Wasm Testing Script (Windows)

When testing Wasm on Windows, using `flutter run -d chrome --wasm` is the easiest way because it automatically injects the required Cross-Origin headers (COOP/COEP) *and* attaches the Dart DevTools so you can see your `Logger` output in the terminal.

However, if you need to test the actual **compiled release build** (`build/web`) and still see logs, you have to ensure your local server injects the headers.

### Option 1: The `fruc-wasm` wrapper (Recommended for Debugging)

This uses the standard Flutter toolchain to run Chrome with Wasm enabled, which automatically pipes all `Logger` messages back to your PowerShell console.

Create a file named `fruc-wasm.bat` in your `scripts\` directory or project root:

```bat
@echo off
echo Launching Wasm build on Chrome in debug mode...
flutter run -d chrome --wasm
```

### Option 2: Serving the Production Wasm Build

If you want to test the *compiled* Wasm output (`flutter build web --wasm`) and serve it using `http-server`, you must pass the COOP/COEP headers to the server command.

*(Note: When running the compiled release build this way, Dart `Logger` messages are usually stripped or only visible in the Chrome Developer Tools (F12) console, not your PowerShell window).*

```bat
@echo off
echo Building Wasm release...
cd apps\gdar_web
call flutter build web --wasm

echo Serving Wasm build with headers...
npx http-server build/web -p 8080 -c-1 --cors -s -H "Cross-Origin-Opener-Policy: same-origin" -H "Cross-Origin-Embedder-Policy: require-corp"
```


## Web Error Log (gdarDumpErrors)

Use this when the UI freezes or behaves oddly and audio keeps playing.

1. Open Chrome DevTools (F12).
2. Go to the Console tab.
3. Run:

`js
gdarDumpErrors()
``r

This prints and returns the in-memory error log captured by the app. You can copy the output or paste it into a bug report.

Optional:

`js
gdarClearErrors()
``r

This clears the stored log. Logs are stored in localStorage under the key gdar_web_error_log_v1.

