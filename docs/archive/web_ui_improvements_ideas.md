# Web UI Improvements — Ideas & Tie-ins

> Source of truth: `docs/web_ui_improvements_plan.md`.

## Out-of-Box Ideas (Exploration)
- [ ] (P1) Boundary Sentinel: pre-warm next track at T-10s to guarantee gapless transition.
- [ ] (P0) Persistent MediaSession Anchor: keep `playbackState` and metadata stable across src swaps.
- [ ] (P0) Hybrid Fence: force engine swaps only at boundaries when backgrounded.
- [ ] (P1) Adaptive Prefetch Budget: increase next-track buffer when hidden, cap memory for older tracks.
- [ ] (P2) Show Stitching (Soft): treat a show as a virtual continuity segment without true concatenation.
- [ ] (P2) Fallback Glue Track: inject short silence between tracks if background stability drops.
- [ ] (P1) Time-boxed Recovery: auto-handoff to HTML5 if WebAudio stalls > X seconds.

## Live Playlist Tie-ins (from `.agent/specs/live_playlist_spec.md`)
- [ ] (P1) Session History can seed a “boundary sentinel” prefetch of the *next show* when current show ends.
- [ ] (P1) Use SessionEntry timestamps to prioritize which upcoming show gets background prefetch budget.
- [ ] (P2) Cross-show forward navigation can be treated as a “soft stitch” when Continuous Play is enabled.
- [ ] (P0) If a show is blocked or offline, the sentinel should skip or downgrade prefetch for that entry.
