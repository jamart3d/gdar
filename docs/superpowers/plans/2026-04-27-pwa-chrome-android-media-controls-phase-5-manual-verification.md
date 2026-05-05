# PWA Chrome Android Media Controls — Phase 5: Manual verification + report output

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Validate Android Chrome installed PWA notification controls in real device scenarios and capture a short verification report.

---

## Task 5: Verification matrix (Android Chrome PWA)

**Files:**
- Create: `reports/YYYY-MM-DD_HH-MM_v<web-version>_android_chrome_pwa_media_controls_verification.md`

- [ ] **Step 1: Manual scenario matrix**

Validate on Android Chrome installed PWA:
1. Foreground play/pause from notification.
2. Background for 2-5 minutes, then notification play/pause.
3. Lock/unlock device, then notification play/pause.
4. Re-open app from recent tasks, then notification play/pause.
5. Track transition while hidden, then pause/resume from notification.

- [ ] **Step 2: Capture expected outcomes**

For each scenario, record:
- Control tap received (`play`/`pause` callback observed in logs),
- Actual engine state changes,
- Notification state icon matches engine state,
- No stuck controls.

- [ ] **Step 3: Run automated JS suite**

```bash
node apps/gdar_web/web/tests/run_tests.js
```

Expected: all existing web JS tests pass, including new regression tests.

- [ ] **Step 4: Create verification report markdown**

Template:

```md
# Android Chrome PWA Media Controls Verification

**Device:** <make/model>
**Android:** <version>
**Chrome:** <version>
**App:** gdar_web <version>
**Install mode:** Installed PWA (standalone) / browser tab
**Strategy:** <hybrid/html5/webaudio/passive/standard>

## Scenarios

- [ ] Foreground play/pause from notification
  - Result:
  - Notes:

- [ ] Background 2-5 minutes, then notification play/pause
  - Result:
  - Notes:

- [ ] Lock/unlock, then notification play/pause
  - Result:
  - Notes:

- [ ] Re-open from recents, then notification play/pause
  - Result:
  - Notes:

- [ ] Track transition while hidden, then pause/resume
  - Result:
  - Notes:

## Verdict

- Pass/Fail:
- Follow-ups:
```

- [ ] **Step 5: Commit the report**

```bash
git add reports
git commit -m "docs(web): add android chrome pwa media controls verification report"
```

