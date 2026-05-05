# PWA Chrome Android Media Controls Reliability Plan (Phased Index)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ensure Android Chrome PWA notification play/pause controls remain responsive across backgrounding, resume, and long-running playback.

**Architecture:** Keep the existing central Media Session anchor (`audio_mediasession.js`) and harden the action-handler lifecycle around it. Action callbacks should route to the live active engine, and the anchor should be explicitly re-synced at visibility/lifecycle boundaries where Android may stale state.

**Tech Stack:** Vanilla JS IIFE modules, Media Session API, HTML5 audio/Web Audio hybrid engine, Flutter web shell.

---

## Phases

- **Phase 1 (Safe routing fix):** `2026-04-27-pwa-chrome-android-media-controls-phase-1-routing.md`
- **Phase 2 (Anchor hard sync API):** `2026-04-27-pwa-chrome-android-media-controls-phase-2-anchor-resync.md`
- **Phase 3 (Lifecycle rebind + hidden pulse):** `2026-04-27-pwa-chrome-android-media-controls-phase-3-lifecycle-pulse.md`
- **Phase 4 (Regression tests):** `2026-04-27-pwa-chrome-android-media-controls-phase-4-regression-tests.md`
- **Phase 5 (Manual verification + report template):** `2026-04-27-pwa-chrome-android-media-controls-phase-5-manual-verification.md`

## Companion doc (handoff + verification prompts)

- `2026-04-27-pwa-chrome-android-media-controls-companion.md`

---

## Risks and Guardrails

- Keep child-engine rule intact: child engines must not call `setActionHandlers`.
- Preserve existing strategy routing logic (`hybrid`, `html5`, `webAudio`, `passive`, `standard`).
- Do not change Flutter provider contracts in this plan.
- Ensure `resync` is backward compatible and optional.

---

## Definition of Done

- Android Chrome PWA notification play/pause remains functional after background/foreground lifecycle transitions.
- Non-hybrid action callbacks always target the current active engine.
- Lifecycle rebind + resync path is covered by automated regression tests.
- Manual matrix completed with no control-stall repro.
