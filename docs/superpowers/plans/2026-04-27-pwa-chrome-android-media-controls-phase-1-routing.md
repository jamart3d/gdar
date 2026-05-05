# PWA Chrome Android Media Controls — Phase 1: Safe routing fix

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure non-hybrid MediaSession play/pause/etc callbacks always call the live active engine (not a stale captured reference).

**Scope:** JS only. No Flutter/Dart changes.

---

## Task 1: Route non-hybrid actions to live engine

**Files:**
- Modify: `apps/gdar_web/web/hybrid_init.js`
- Test: `apps/gdar_web/web/tests/pwa_strategy_regression.js`

- [ ] **Step 1: Replace closure-bound action handlers with live engine dispatch**

Update non-hybrid `setActionHandlers` callbacks to call `window._gdarAudio` at invocation time (not the captured `selectedEngine` variable), for:
- `play`
- `pause`
- `seek`
- `seekToIndex`
- `next`
- `previous`

- [ ] **Step 2: Add safe helper for active-engine access**

Add a local helper in `hybrid_init.js`:

```js
function _activeEngine() {
  return window._gdarAudio || selectedEngine || null;
}
```

Use this helper inside each action callback and guard missing methods (`?.` or explicit checks).

- [ ] **Step 3: Verify with JS regression**

Run:

```bash
node apps/gdar_web/web/tests/run_tests.js
```

Expected: PWA strategy test still passes and no action callback throws when engine object is swapped.

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/hybrid_init.js apps/gdar_web/web/tests/pwa_strategy_regression.js
git commit -m "fix(web): route mediasession actions to active engine in non-hybrid mode"
```

