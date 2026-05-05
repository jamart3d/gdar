# PWA Chrome Android Media Controls — Phase 3: Lifecycle rebind + hidden pulse

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rebind handlers and force a MediaSession resync when Android Chrome PWA returns from background; add a lightweight hidden pulse for html5-only strategy so notification state doesn’t go stale.

**Scope:** JS only.

---

## Task 3: Rebind and resync on Android lifecycle boundaries

**Files:**
- Modify: `apps/gdar_web/web/hybrid_init.js`
- Modify: `apps/gdar_web/web/html5_audio_engine.js`
- Test: `apps/gdar_web/web/tests/pwa_strategy_regression.js`

- [ ] **Step 1: Reinstall non-hybrid handlers on `visibilitychange` and `pageshow`**

In `hybrid_init.js`, add one reusable function that calls `setActionHandlers(...)` for non-hybrid mode, then invoke it:
- at initial setup (existing path),
- on `document.visibilitychange` when state becomes `visible`,
- on `window.pageshow`.

- [ ] **Step 2: Force state push after lifecycle return**

When rebinding on visible/pageshow, call anchor `resync(...)` using current engine state:

```js
const s = _activeEngine()?.getState?.() || {};
window._gdarMediaSession.resync({
  playing: !!s.playing,
  positionState: {
    duration: Number(s.duration) || 0,
    position: Number(s.position) || 0,
    playing: !!s.playing
  }
});
```

Include metadata from current playlist item when available.

- [ ] **Step 3: Add lightweight hidden pulse for html5-only strategy**

In `html5_audio_engine.js`, add a 15s timer (hidden + playing only) that calls `_updateMediaSession()`. Stop timer on visible or paused. This mirrors hybrid reliability behavior for html5 strategy without changing audio routing.

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/hybrid_init.js apps/gdar_web/web/html5_audio_engine.js apps/gdar_web/web/tests/pwa_strategy_regression.js
git commit -m "fix(web): rebind and resync mediasession on pwa lifecycle resume"
```

