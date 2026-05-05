# PWA Chrome Android Media Controls — Phase 2: Anchor hard sync API

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add an explicit hard-resync entry point on the MediaSession anchor to recover from Android lifecycle staleness without changing the default dedup behavior.

**Scope:** JS anchor + tests only.

---

## Task 2: Add explicit MediaSession hard sync API

**Files:**
- Modify: `apps/gdar_web/web/audio_mediasession.js`
- Test: `apps/gdar_web/web/tests/pwa_strategy_regression.js`

- [ ] **Step 1: Add `resync` helper to anchor**

Add a new API method in `_gdarMediaSession`:

```js
resync: function (state) {
  this.forceSync();
  if (state && state.metadata) this.updateMetadata(state.metadata);
  if (state && typeof state.playing === 'boolean') {
    this.updatePlaybackState(state.playing);
  }
  if (state && state.positionState) this.updatePositionState(state.positionState);
}
```

- [ ] **Step 2: Keep existing behavior unchanged**

Do not change default dedup logic in `updateMetadata` / `updatePlaybackState`; `resync` should be an explicit opt-in hard reset path only.

- [ ] **Step 3: Verify no throw on partial payload**

Add tests that call:
- `resync({ playing: true })`
- `resync({})`
- full payload with metadata + position

All should run without exception and preserve current API compatibility.

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/audio_mediasession.js apps/gdar_web/web/tests/pwa_strategy_regression.js
git commit -m "feat(web): add mediasession anchor resync helper for lifecycle recovery"
```

