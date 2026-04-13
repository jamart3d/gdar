# Pending Release Notes
[Unreleased] entries will be moved to CHANGELOG.md during the next /shipit run.

## [Unreleased]

### Fixed
- **Web/PWA** — `flt-glass-pane` underlay (and any other
  `var(--splash-bg)` reader) now tracks runtime dark/light toggles.
  `updateThemeBranding` in `apps/gdar_web/web/index.html` was writing
  `document.body.style.backgroundColor` but leaving the `--splash-bg` CSS
  custom property pinned at its boot-time value, so transparent regions of
  the Fruit UI — most visibly the blurred area below the `FruitTabBar` —
  kept the original light/dark color after an in-app theme toggle. Fix
  adds a single `document.documentElement.style.setProperty('--splash-bg',
  bgColor)` inside `updateThemeBranding`.

- **Web/PWA MediaSession action handlers** — notification / lockscreen /
  Bluetooth-headset play/pause/next/previous/seek buttons are now wired
  for all non-hybrid strategies (`html5`, `webAudio`, `passive`).
  `hybrid_init.js` now installs `navigator.mediaSession` action handlers
  once in the dispatcher, gated on `strategy !== 'hybrid'`, routing each
  callback through the selected engine's real API. `next`/`previous` use
  `getState().index` + `seekToIndex()` (no `next()`/`previous()` methods
  exist on these engines); seek callbacks match the hybrid orchestrator's
  own implementation. Hybrid path unchanged — its `_setupMediaSession()`
  still owns those bindings.
  ⚠️ Pending device confirmation before commit.
