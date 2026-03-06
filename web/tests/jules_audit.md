# Jules High-Performance Audio Audit

**Mission:** Run this in a headless Chrome instance and show me the logs. Stress-test the GDAR Web Audio engine and verify state persistence. Do not just "check boxes"—try to break the playback sync.

---

### Phase 0: Latest Build Verification
1.  **Navigate** to the app URL.
2.  **Verify Version**: Check the bottom of the Settings sidebar or run `window.shakedownVersion` in the console. Ensure it matches the expected latest version (`1.1.51`).
3.  **Hard Refresh**: Perform a hard refresh (`Cmd+Shift+R` or `Ctrl+F5`) to bypass any service worker caching of old assets.

### Phase 1: The "99% Seek" Gauntlet
1.  **Load** the app and start any show.
2.  **Seek** to the end of the current track (leave ~3 seconds).
3.  **Observe** the transition to the next track.
4.  **Repeat** this 3 times in rapid succession.
5.  **Audit**: Did any track "pop" or have a gap? Are there any `Aborted fetch` errors in the console that aren't expected?

### Phase 2: Survival & Persistence
1.  Navigate to **Settings > Playback**.
2.  Select **Hybrid Engine**.
3.  Set **Crossfade** to `8.0s`.
4.  Set **Handoff Mode** to `Instant`.
5.  **REFRESH** the page (`Cmd+R` / `Ctrl+R`).
6.  **Verify**:
    - Does `localStorage.getItem('flutter.audio_engine_mode')` still say `hybrid`?
    - Does the UI reflect the 8.0s crossfade?
    - Does audio resume correctly if it was playing?

### Phase 3: Visual & Thread Stress
1.  Open the **Playback Panel** (Liquid Glass enabled).
2.  Start playback.
3.  **Resize** the browser window rapidly for 5 seconds.
4.  **Verify**: Does the "Liquid Glass" blur lag? Does the audio stutter?
5.  **Screenshot**: Take a screenshot of the Playback Panel during a transition.

**Report:** Provide the full Console log and any screenshots if glitches occur.
