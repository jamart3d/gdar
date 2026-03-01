---
name: web_debug_suite
description: Tools and techniques for debugging complex Flutter Web audio engines and state.
---

# Web Debug Suite

This skill provides a standardized way to inject diagnostic tools into a Flutter Web project, specifically targeting the JS/Dart interop layer and persistent state.

## Core Features

### 1. Global Engine Tracker
Injects a setter-intercept on `window._gdarAudio` (or any target global) to log exactly which script is assigning the engine and when.

**Implementation (index.html):**
```html
<script>
  (function() {
    let _current = null;
    Object.defineProperty(window, '_targetGlobal', {
      get: function() { return _current; },
      set: function(val) {
        console.log('%c[Tracker] Global set to:', 'color: #ff00ff; font-weight: bold;', val);
        console.trace(); 
        _current = val;
      },
      configurable: true
    });
  })();
</script>
```

### 2. URL-Based LocalStorage Flush
Allows clearing application state via a simple URL parameter `?flush=true`.

**Implementation (Early JS Init):**
```javascript
const urlParams = new URLSearchParams(window.location.search);
if (urlParams.get('flush') === 'true') {
    localStorage.clear();
    console.warn('[Debug] localStorage FLUSHED.');
}
```

## Usage Patterns

1. **When to use**: Use this skill when the app behavior doesn't match the selected settings, suggesting a race condition in JS initialization or stale `localStorage`.
2. **Installation**:
   - Inject the Tracker into `index.html` before any engine scripts.
   - Inject the Flush logic into the primary entry-point JS file (e.g., `hybrid_init.js`).
