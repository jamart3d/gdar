---
name: wasm_crash_analyzer
description: Pulls unhandled JS DOM rejections and categorizes Skwasm failures.
---

# Wasm Crash Analyzer

**TRIGGERS:** wasm crash, read wasm logs, analyze skwasm, evaluate js failure

This skill interfaces with the custom `web_error_logger.js` injected into the GDAR project to capture unhandled WebAssembly promise rejections and `RuntimeError: function signature mismatch` events that would otherwise freeze the Dart console.

## Usage

When investigating a frozen UI or silent Wasm crash, run the following steps:

### 1. Dump Browser Error Logs
```powershell
// Read the JS console trap file if the local environment writes it to disk,
// or instruct the user to execute the client-side JavaScript snippet to download the log.
```

### 2. Identify the Failure Source
Wasm errors generally fall into three categories in this project:
- **Canvas Blend Mode:** Using `BlendMode.srcIn` or unsupported shading on a Skia rendering context.
- **Null Safety in JS Interop:** Passing non-finite numbers (NaN) or null values into `ImageFilters` or `BackdropFilters`.
- **Shader Compilation:** Complete failure to bind `ui.FragmentProgram` to the Wasm pipeline.

### 3. Generate Workarounds
If the source is identified, conditionally disable that widget tree if `kIsWasm` is true, utilizing the application's fallback visuals (e.g., standard color backgrounds instead of blurred glass filters).

> **Note:** Do not attempt to "fix" the Skwasm engine source. The goal is to bypass the trigger until the Flutter SDK matures.
