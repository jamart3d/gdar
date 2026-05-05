# PWA Chrome Android Media Controls — Phase 4: Regression tests

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure the Android Chrome PWA failure mode stays fixed by adding JS tests that cover lifecycle recovery and live-engine routing.

**Scope:** JS tests only.

---

## Task 4: Regression tests for Android Chrome PWA failure mode

**Files:**
- Modify: `apps/gdar_web/web/tests/pwa_strategy_regression.js`
- Modify: `apps/gdar_web/web/tests/mock_harness.js`

- [ ] **Step 1: Add test for handler recovery after hidden/visible cycle**

Create a regression that:
1. Initializes non-hybrid strategy.
2. Simulates `visibilitychange` hidden -> visible.
3. Triggers mock `mediaSession` play/pause action callbacks.
4. Asserts active engine method calls are received.

- [ ] **Step 2: Add test for dynamic engine reference**

Set handlers, then replace `window._gdarAudio` with a new mock engine. Trigger actions and assert calls hit the new engine, not the old captured one.

- [ ] **Step 3: Add test for `resync` partial/full payloads**

Assert no errors and confirm metadata/playback/position writes execute when provided.

- [ ] **Step 4: Commit**

```bash
git add apps/gdar_web/web/tests/pwa_strategy_regression.js apps/gdar_web/web/tests/mock_harness.js
git commit -m "test(web): cover mediasession lifecycle and active-engine routing regressions"
```

