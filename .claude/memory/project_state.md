---
name: Project State
description: Current quality score, open work, and recent session outcomes
type: project
---

**Monorepo score: 8.0/10** (as of 2026-03-19). See `docs/monorepo_scorecard_2026-03-19.md`.

Path to 8.5+:
1. Split `SettingsProvider` (1,960+ lines) — use separate `OilSettingsProvider` class or mixin, NOT extensions
2. ~~Extract shared state-emission/error helpers into `audio_utils.js`~~ — done (heartbeat utility, error paths wired)
3. Add TV focus routing + key-event contract tests
4. Add browser integration tests for `kIsWeb` settings branches

**Current release:** `1.2.8+208` — live. See `.agent/notes/pending_release.md` for build/deploy commands.

**All web/audio/hybrid audit findings resolved** as of 2026-03-19. See `docs/web_ui_audio_hybrid_review_2026-03-19.md`.

**Agent rules updated** 2026-03-19 — `.agent/rules/` pruned of stale content (Flame engine, wrong class names), two new rules added (`audio_mode_resolution.md`, `localstorage_hygiene.md`). `CLAUDE.md` at repo root is the session-start guide.

**Why:** Keeps future sessions oriented on what matters without re-reading all docs.
**How to apply:** Use as orientation at session start; re-read the scorecard doc for full detail.
