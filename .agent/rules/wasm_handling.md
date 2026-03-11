---
trigger: "wasm, skwasm, flutter build web, compile"
---

# Wasm Handling Restrictions

> [!WARNING]
> GDAR currently experiences runtime instability (`RuntimeError: function signature mismatch`) under the Skwasm engine due to complex interactions between DOM manipulation, animated shaders, and canvas rendering.

### 1. Production Build Constraints
* **Action:** Never use the `--wasm` flag when building the production web application (`flutter build web`).
* **Constraint:** All production web builds must use default (Dart2JS) WebGL compilation until Skwasm stabilizes for advanced `BackdropFilter` and `ShaderMask` usage.

### 2. Experimental Wasm Testing
If attempting to test or debug the experimental Wasm build locally:
* **Constraint:** You must utilize the custom `web/flutter_bootstrap.js` to initialize the engine.
* **Troubleshooting:** Wasm crashes are fatal and freeze the UI thread. Do not attempt to recover state within Dart; rely on the external DOM logger (`web_error_logger.js`) to capture the stack trace.

### 3. Skwasm Feature Gates
When testing Wasm, the following visual features are known to trigger immediate signature mismatch errors and must be bypassed or gated:
* Wasm strictly prohibits `Colors.transparent` in certain blended paint operations.
* Heavy `BackdropFilter` nesting inside the `ShowListCard`.
* Instantiation of custom Fragment Shaders (`steal.frag`).
