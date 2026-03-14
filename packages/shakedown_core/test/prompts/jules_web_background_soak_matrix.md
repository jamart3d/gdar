# Jules Prompt — Web/PWA Long Background Soak Matrix

## Mission
Run a long-session Web/PWA background playback soak test matrix for GDAR and
produce a pass/fail report with reproducible evidence.

Focus:
- Hidden-tab/background longevity
- Track transition continuity (gapless vs near-gapless behavior)
- Resume reliability after long hidden sessions
- Engine/preset stability on modern vs slightly older phones

## Scope
- Platform: Web/PWA only (not Android native app)
- Theme: Fruit (Simple Theme ON/OFF variants where relevant)
- Audio source: Real show playback with at least 10 tracks queued
- Include both:
  - Modern phone profile
  - Slightly older phone profile

## Test Matrix

Run every row in this matrix:

| Tier | Device/Browser | Engine Mode | Hidden Session Preset | Hybrid Handoff | Hybrid Background | Duration Hidden | Expected |
|---|---|---|---|---|---|---|---|
| Modern | Android recent + Chrome | html5 | balanced | buffered | heartbeat | 30 min | No stop; transitions continue |
| Modern | Android recent + Chrome | hybrid | balanced | buffered | heartbeat | 30 min | No stop; restore to fg succeeds |
| Modern | Android recent + Chrome | hybrid | stability | buffered | video | 30 min | No stop; strongest survival |
| Modern | Android recent + Chrome | webAudio | maxGapless | immediate | heartbeat | 30 min | May suspend on some devices; log rate |
| Older | Android older + Chrome | html5 | balanced | buffered | heartbeat | 30 min | Primary recommended stability path |
| Older | Android older + Chrome | hybrid | stability | buffered | video | 30 min | Acceptable if no hard stop |
| Older | Android older + Chrome | passive | stability | buffered | html5 | 30 min | Most robust; acceptable small track gap |
| Older | Android older + Chrome | webAudio | maxGapless | immediate | heartbeat | 30 min | Expected higher suspend risk |

Then rerun the two best candidates from each tier with **120 min hidden**.

## Per-Run Procedure

1. Fresh launch PWA.
2. Set engine mode + preset/modes exactly per row.
3. Start playback and confirm track index increments normally in foreground.
4. Background the app (screen off or switch app/tab) and keep hidden for the
   row duration.
5. Bring app foreground.
6. Record:
   - Still playing (`yes/no`)
   - Track advanced while hidden (`count`)
   - Resume delay to audible playback (seconds)
   - Any `suspended_by_os` / buffering stalls
   - Audible pop/gap/dropout around transitions

## Pass/Fail Criteria

- **Pass**:
  - No hard-stop during hidden session
  - On foreground return, playback recovers within 3 seconds
  - No repeated stalls (>2 consecutive recoveries) in 10 minutes post-return
- **Soft-pass**:
  - One recoverable stall, resumes within 8 seconds
- **Fail**:
  - Playback dead/stuck after return
  - Requires manual restart/reload
  - Frequent transition glitches

## Required Artifacts

- Short log excerpt for each failure/suspend event
- Screen recording snippets for at least one pass and one fail case per tier
- Final ranked recommendation per tier (Top 2)

## Output Format

### 1) Matrix Results
Use this table:

| Tier | Engine | Preset | Hidden Duration | Result | Hidden Progress | Resume Time | Notes |
|---|---|---|---|---|---|---|---|

### 2) Top Recommendations
- Modern phones:
  1. `<mode + preset + modes>`
  2. `<mode + preset + modes>`
- Slightly older phones:
  1. `<mode + preset + modes>`
  2. `<mode + preset + modes>`

### 3) Regression Signals
List any reproducible problems with clear repro steps.

## Guardrails

- Do not change source code during this audit run.
- Keep network conditions stable (document if not).
- If a run is invalid (crash unrelated to audio), rerun once and mark invalid.
