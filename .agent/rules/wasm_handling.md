---
trigger: always_on
---
> [!WARNING]
> GDAR currently experiences runtime instability (`RuntimeError: function signature mismatch`) under the Skwasm engine due to complex interactions between DOM manipulation, animated shaders, and canvas rendering.

### 1. Production Build Constraints
*   **Action:** Production builds MUST avoid `--wasm`. Verify `apps/gdar_web/web/index.html` does not contain wasm-loader stubs before a release.
*   **Constraint:** All production web builds must use default (Dart2JS) WebGL compilation until Skwasm stabilizes for advanced `BackdropFilter` and `ShaderMask` usage.

### 2. Experimental Wasm Testing
When running local experiments with `--wasm`:
*   **Constraint:** You must utilize the specialized wasm-shim in `apps/gdar_web/web/flutter_bootstrap.js`.
*   **Troubleshooting:** Wasm crashes are fatal and freeze the UI thread. Do not attempt to recover state within Dart; rely on the external DOM logger (`apps/gdar_web/web/web_error_logger.js`) to capture the stack trace.

### 3. Skwasm Feature Gates
When testing Wasm, the following visual features are known to trigger immediate signature mismatch errors and must be bypassed or gated:
1. **BackdropFilter**: Disable any `LiquidGlass` effects or gaussian blurs.
2. **Custom Shaders**: Complex fragment shaders (e.g., `pulsing_glow.frag`) will crash the engine on load. Fall back to static gradients.
3. **AnimatedOpacity**: Nesting many `AnimatedOpacity` widgets within a `CustomPaint` layer leads to heap corruption.
