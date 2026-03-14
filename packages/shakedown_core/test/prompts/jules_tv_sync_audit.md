# Jules TV UI Sync & Auto-Play Audit

**Mission:** Verify that the TV UI accurately reflects playback state across show transitions. We are hunting for "Sync Drift" where the highlighted track in the UI does not match the audio engine's actual track.

---

### Phase 1: Auto-Play Ignition
1.  **Navigate**: Load the app on a TV-profile viewport (e.g., 1920x1080).
2.  **Trigger**: Select a random show and start playback.
3.  **Audit**: 
    - Does playback start automatically? 
    - Does the **Playback Bar** (TV) appear immediately?
    - Is the first track correctly highlighted in the **Tracklist Pane** (Dual Pane)?

### Phase 2: The "Endless Show" Transition
1.  **Seek Stress**: Seek to the last 5 seconds of the final track in the current show.
2.  **Observe**: Wait for the show to end.
3.  **Audit**: 
    - Does the next random show load automatically (if `Play Random on Completion` is ON)?
    - **UI Verification**: Does the Tracklist Pane update to show the new show's tracks?
    - **Highlight Check**: Does the highlight move to Track 1 of the *new* show? 

### Phase 3: Tracklist Sync Drift Audit
1.  **Stress Sequence**:
    - During playback, use a **DPad Right** (or equivalent skip) to skip 3 tracks in rapid succession.
    - **Immediate Lock**: Stop skipping and look at the UI.
2.  **Verification**: 
    - Open the console and run `window.audioProvider.currentTrack.title`.
    - **Compare**: Does the visually highlighted track in the list match the console output?
    - If the highlight is stuck on a previous track, this is a SYNC FAIL.

### Phase 4: Dual-Pane Context Persistence
1.  **Navigate Away**: While audio is playing, navigate to **Settings**.
2.  **Navigate Back**: Press **Back/Escape** to return to the Show/Track list.
3.  **Audit**: 
    - Is the currently playing track still correctly highlighted?
    - Does the UI focus return to the playing track or maintain its last position?

**Report:** 
- Pass/Fail on Auto-play.
- Confirmation of correct highlight update during show-to-show transitions.
- Console logs for `currentTrack` mismatch if found.
