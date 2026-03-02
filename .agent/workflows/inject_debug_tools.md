---
description: Inject JS/Dart diagnostic tools into the Web project for debugging engine and state issues.
---
# Inject Debug Tools Workflow

**TRIGGERS:** inject, debug, tracker, instrument, flush

This workflow automates the instrumentation of the Flutter Web project to track global state changes and allow quick state resets.

## 1. Global Engine Tracker (JS Interop)
// turbo
1. Inject the Tracker script into `web/index.html`:
   - Locate the `<head>` or start of `<body>`.
   - Add a script that defines a setter-intercept on `window._gdarAudio` or a user-specified global.
   - Example snippet:
     ```javascript
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
     ```

## 2. URL-Based LocalStorage Flush
// turbo
1. Locate the primary JS entry point (e.g., `web/hybrid_init.js`).
2. Add the URL parameter check:
   ```javascript
   const urlParams = new URLSearchParams(window.location.search);
   if (urlParams.get('flush') === 'true') {
       localStorage.clear();
       console.warn('[Debug] localStorage FLUSHED.');
   }
   ```

## 3. Implementation Verification
1. Verify the files are correctly saved.
2. Inform the user they can debug by appending `?flush=true` to the URL or checking the browser console for `[Tracker]` logs.
