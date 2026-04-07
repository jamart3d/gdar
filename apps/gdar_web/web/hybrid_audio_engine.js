/**
 * GDAR Hybrid Audio Engine (Foreground: Web Audio, Background: Passive HTML5)
 *
 * Wraps the full Web Audio engine (foreground) and the passive <audio> element (background).
 *
 * Boundary-Only Handoffs:
 * - When visibilitychange fires mid-track, set a _pendingHandoff flag. Don't interrupt.
 * - At the next track boundary (_onTrackBoundary), check the flag. If set, load the next track
 *   into the passive <audio> element and switch to it instead of the Web Audio graph.
 * - If the user returns to the tab before the track ends, clear the flag — stay in foreground mode.
 * - On foreground restore: pause passive element, reconstruct AudioContext at that position,
 *   resume Web Audio.
 */
(function () {
    const _log = (window._gdarLogger || console);
    const isBrowser = typeof window !== 'undefined';

    // Ensure background (Relisten) and foreground (Gapless) engines exist
    const _fgEngine = window._gdarAudio;
    const _bgEngine = window._hybridHtml5Audio;

    /** Dynamic check for pure web audio lock. */
    function _isPureWebAudio() {
        const strategy = window._shakedownAudioStrategy || '';
        if (strategy.toLowerCase() === 'webaudio') {
            _log.log('[hybrid] Strategy locked to Pure WebAudio');
            return true;
        }

        // Defensive Fallback: If init hasn't run yet, check localStorage directly
        try {
            const PREF_KEY = 'flutter.audio_engine_mode';
            const RAW_KEY = 'audio_engine_mode';
            const stored = localStorage.getItem(PREF_KEY) || localStorage.getItem(RAW_KEY);
            if (stored) {
                const val = stored.replace(/"/g, '').toLowerCase();
                const isPure = val === 'webaudio';
                if (isPure) _log.log('[hybrid] Strategy locked to Pure WebAudio via Storage');
                return isPure;
            }
        } catch (_) { }
        return false;
    }

    // Safe Logger Utility

    if (!_bgEngine || !_fgEngine) {
        _log.error('[hybrid engine] Missing required underlying engines');
        return;
    }

    // --- State ----------------------------------------------------------------

    let _playlist = [];
    let _currentIndex = -1;
    let _playing = false;
    let _prefetchSeconds = 30;

    // Track Transition Settings
    let _transitionMode = 'gapless';

    // Advanced Hybrid Settings
    let _backgroundMode = 'html5'; // html5 | heartbeat | video | none
    let _handoffMode = 'buffered';    // buffered | immediate | boundary | none
    let _allowHiddenWebAudio = false;
    let _handoffCrossfadeMs = 0;

    // Mode state
    let _activeEngine = _bgEngine; // Default to HTML5 (Background Engine) for Instant Start
    let _stallTimer = null;
    let _fenceTimer = null; // Bounds the desktop fence so hidden WA doesn't run indefinitely
    let _heartbeatEscalateTimer = null; // Escalates heartbeat → video after 60s on mobile
    let _instantHandoffPending = false;
    let _instantHandoffIndex = -1;
    let _handoffInProgress = false;
    let _lastStateForwardMs = 0;
    let _fenceHandoffPending = false;
    let _lastGapMs = null;
    let _trackBoundaryAtMs = 0; // Stamped when H5 track boundary fires, cleared when WA swap completes
    let _lastHandoffPollCount = 0;
    const _blockedForegroundIdentifiers = new Set();

    // Web Worker for background timing - now managed centrally via audio_scheduler.js
    // let _schedulerWorker = null;

    function _initWorker() {
        // Now handled by window._gdarScheduler.
    }

    // Callbacks registered by Dart
    let _onStateChange = null;
    let _onTrackChange = null;
    let _onError = null;
    let _onPlayBlocked = null;

    function _emitPlayBlocked() {
        if (_onPlayBlocked) {
            try { _onPlayBlocked(); } catch (_) { }
        }
    }

    function _syncHiddenAllowance() {
        try {
            const prefKey = 'flutter.allow_hidden_web_audio';
            const rawKey = 'allow_hidden_web_audio';
            const stored = localStorage.getItem(prefKey) || localStorage.getItem(rawKey);
            const normalized = stored ? stored.replace(/"/g, '').toLowerCase() : '';
            _allowHiddenWebAudio = normalized == 'true';
        } catch (_) {
            _allowHiddenWebAudio = false;
        }
    }

    function _setVolumeSafe(engine, volume) {
        if (engine && typeof engine.setVolume === 'function') {
            engine.setVolume(volume);
        }
    }

    function _archiveIdentifierForTrack(track) {
        try {
            const rawUrl = track && track.url;
            if (!rawUrl) return null;
            const url = new URL(rawUrl, window.location.href);
            const parts = url.pathname.split('/').filter(Boolean);
            const downloadIndex = parts.indexOf('download');
            if (downloadIndex !== -1 && parts.length > downloadIndex + 1) {
                return parts[downloadIndex + 1];
            }
            const itemsIndex = parts.indexOf('items');
            if (itemsIndex !== -1 && parts.length > itemsIndex + 1) {
                return parts[itemsIndex + 1];
            }
        } catch (_) { }
        return null;
    }

    function _errorMessage(err) {
        return String(
            (err && (err.message || err.toString && err.toString())) || '',
        ).toLowerCase();
    }

    function _isAbortError(err) {
        if (!err) return false;
        return err.name === 'AbortError' || _errorMessage(err).includes('abort');
    }

    function _isForegroundPrepBlocked(err) {
        if (err && err.code === 'WA_BLOCKED') {
            return true;
        }
        const message = _errorMessage(err);
        return message.includes('failed to fetch') ||
            message.includes('networkerror') ||
            message.includes('unauthorized') ||
            message.includes('cors') ||
            message.includes('401');
    }

    function _markForegroundBlocked(track, err) {
        const identifier = _archiveIdentifierForTrack(track);
        if (identifier) {
            _blockedForegroundIdentifiers.add(identifier);
            _log.warn(
                `[hybrid] Foreground WebAudio decode blocked for archive source ${identifier}. Staying on HTML5.`,
                err,
            );
        } else {
            _log.warn('[hybrid] Foreground WebAudio decode blocked. Staying on HTML5.', err);
        }
    }

    function _isForegroundBlocked(track) {
        const identifier = _archiveIdentifierForTrack(track);
        return !!identifier && _blockedForegroundIdentifiers.has(identifier);
    }

    function _createForegroundBlockedError(track, cause) {
        const identifier = _archiveIdentifierForTrack(track) || 'unknown';
        const error = new Error(`Foreground decode blocked for ${identifier}`);
        error.code = 'WA_BLOCKED';
        error.cause = cause;
        return error;
    }

    function _stayOnHtml5AfterForegroundFailure(reason, err) {
        _trackBoundaryAtMs = 0;
        _handoffInProgress = false;
        _instantHandoffPending = false;
        if (reason) {
            if (err) {
                _log.warn(`[hybrid] ${reason}. Staying on HTML5.`, err);
            } else {
                _log.log(`[hybrid] ${reason}. Staying on HTML5.`);
            }
        }
        _swapEngine(_bgEngine);
        _fgEngine.stop();
    }

    function _prepareForegroundTrack(index) {
        const track = _playlist[index];
        if (!track) {
            return Promise.reject(new Error('No track at index ' + index));
        }
        if (_isForegroundBlocked(track)) {
            return Promise.reject(_createForegroundBlockedError(track));
        }
        return _fgEngine.prepareToPlay(index).catch(err => {
            if (_isForegroundPrepBlocked(err)) {
                _markForegroundBlocked(track, err);
                throw _createForegroundBlockedError(track, err);
            }
            throw err;
        });
    }

    function _attemptForegroundRestoreFromHtml5(index) {
        const track = _playlist[index];
        if (!track) return;

        if (_isForegroundBlocked(track)) {
            _stayOnHtml5AfterForegroundFailure(
                'Foreground decode unavailable for this archive source at track boundary',
            );
            return;
        }

        _handoffInProgress = true;
        _prepareForegroundTrack(index).then(() => {
            if (!_playing || _currentIndex !== index || _activeEngine !== _bgEngine) {
                _handoffInProgress = false;
                return;
            }
            _executeForegroundRestore(0);
        }).catch(err => {
            if (_isAbortError(err)) {
                _trackBoundaryAtMs = 0;
                _handoffInProgress = false;
                _log.log('[hybrid] Boundary restore prep aborted by seek/index change.');
                return;
            }
            _stayOnHtml5AfterForegroundFailure(
                'Foreground restore prep failed at track boundary',
                err,
            );
        });
    }

    function _logRoutingDecision(source, pure, allowHandoff, useHtml5) {
        _log.log(
            `[hybrid] ${source} route: pure=${pure} allowHandoff=${allowHandoff} ` +
            `useHtml5=${useHtml5} active=${_activeEngine === _bgEngine ? 'H5' : 'WA'} ` +
            `handoffInProgress=${_handoffInProgress}`,
        );
    }

    function _startHandoffCrossfade() {
        const duration = Math.max(0, _handoffCrossfadeMs || 0);
        if (duration === 0) {
            _bgEngine.stop();
            return;
        }

        const start = performance.now();
        _setVolumeSafe(_fgEngine, 0);
        _setVolumeSafe(_bgEngine, 1);

        const tick = () => {
            const elapsed = performance.now() - start;
            const t = Math.min(1, elapsed / duration);
            _setVolumeSafe(_fgEngine, t);
            _setVolumeSafe(_bgEngine, 1 - t);

            if (t < 1) {
                if (document.visibilityState === 'hidden') {
                    setTimeout(tick, 16);
                } else {
                    requestAnimationFrame(tick);
                }
            } else {
                _setVolumeSafe(_fgEngine, 1);
                _bgEngine.stop();
            }
        };

        tick();
    }

    // --- Engine Routing -------------------------------------------------------

    function _forwardState(state, sourceEngine) {
        if (!_onStateChange) return;

        // Critical Fix: Do not let the Web Audio API overwrite the UI with "buffering" events
        // while the HTML5 engine is successfully driving playback during an Instant Start.
        if (sourceEngine !== _activeEngine) return;

        const hasGapUpdate =
            typeof state.lastGapMs === 'number' && Number.isFinite(state.lastGapMs);

        // Preserve the last measured track-transition gap across engine swaps.
        // The active engine can change from HTML5 to Web Audio before the HUD
        // has a chance to repaint, so we keep the most recent non-null gap and
        // reattach it to later state emissions.
        if (hasGapUpdate) {
            _lastGapMs = state.lastGapMs;
        } else if (_lastGapMs != null) {
            state.lastGapMs = _lastGapMs;
        }

        // Sync central MediaSession Anchor
        if (window._gdarMediaSession) {
            window._gdarMediaSession.updatePlaybackState(state.playing);
            window._gdarMediaSession.updatePositionState(state);
        }
        if (_handoffInProgress && !hasGapUpdate) {
            const now = performance.now();
            if (now - _lastStateForwardMs < 250) return;
            _lastStateForwardMs = now;
        }

        // Detect OS-forced suspension
        if (_activeEngine === _fgEngine && state.processingState === 'suspended') {
            _log.log('[hybrid] Forced Suspension detected in Web Audio.');
            state.processingState = 'suspended_by_os';

            if (_playing) {
                _log.warn('[hybrid] Suspension Recovery: Web Audio suspended while playing. Triggering immediate HTML5 handoff.');
                _executeFailureHandoff();
            } else {
                _playing = false; // Stop the local flag
            }
        }

        // STALL RECOVERY: Escape Hatch to HTML5
        // If the Foreground (Web Audio) is stalled for too long (> 5s), swap to HTML5.
        if (_activeEngine === _fgEngine && state.processingState === 'buffering' && _playing) {
            if (!_stallTimer) {
                _log.log('[hybrid] Web Audio stalled. Starting 5s stall timer.');
                _stallTimer = setTimeout(() => {
                    _log.warn('[hybrid] Web Audio STALLED > 5s. Triggering Escape Hatch to HTML5.');
                    _executeFailureHandoff();
                    _stallTimer = null;
                }, 5000);
            }
        } else {
            if (_stallTimer) {
                clearTimeout(_stallTimer);
                _stallTimer = null;
            }
        }

        let __tech = '??';
        if (_activeEngine === _fgEngine) { __tech = '(WA)'; }
        else if (_activeEngine === _bgEngine) { __tech = '(H5B)'; }
        else if (_backgroundMode === 'html5') { __tech = '(H5B)'; }
        else if (_backgroundMode === 'video') { __tech = '(VI)'; }
        else if (_backgroundMode === 'heartbeat') { __tech = '(HBT)'; }
        else { __tech = 'OFF'; }

        const hbNeeded = window._gdarIsHeartbeatNeeded();
        // Keep AE pinned to HTML5 while the restore loop is still settling so
        // the HUD does not advertise WA before the swap has actually completed.
        if (_handoffInProgress && _activeEngine === _fgEngine) {
            __tech = '(H5B)';
        }
        state.heartbeatNeeded = hbNeeded;
        state.contextState = 'hybrid ' + __tech + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';

        // heartbeatActive = actual survival mechanism running (hbt/vid).
        // Not 'visible && playing' — that always fires on Desktop foreground.
        const survivalDisabled = _backgroundMode === 'none';
        state.heartbeatActive = !survivalDisabled &&
            !!(window._gdarHeartbeat && window._gdarHeartbeat.isActive());

        // Hybrid Specific Telemetry
        state.hs = _getHandoffState();
        state.hat = _handoffAttemptCount;
        state.hpd = _lastHandoffPollCount;

        _onStateChange(state);
    }

    function _getHandoffState() {
        if (!_playing) return 'IDLE';
        if (_handoffInProgress) return 'PRB'; // Probing/Restoring
        if (_instantHandoffPending) return 'ARM'; // Armed for switch
        if (_fenceHandoffPending) return 'FNC'; // Desktop fence active
        if (_activeEngine === _fgEngine) return 'DONE'; // Successfully on WA
        return 'IDLE';
    }

    function _forwardTrack(event, sourceEngine) {
        if (!_onTrackChange) return;
        if (sourceEngine !== _activeEngine) return;

        // Sync central MediaSession Anchor Metadata
        const state = sourceEngine.getState();
        if (window._gdarMediaSession && state.index !== -1) {
            // Metadata is already updated by the engines themselves, 
            // but we ensure the playback state is synced here too.
            window._gdarMediaSession.updatePlaybackState(state.playing);
        }
        if (typeof state.lastGapMs === 'number' && Number.isFinite(state.lastGapMs)) {
            // Capture boundary gap immediately from the engine that just
            // transitioned tracks so LG survives even if the subsequent state
            // tick is delayed or a restore attempt starts right away.
            _lastGapMs = state.lastGapMs;
        }

        // Invalidate any background restoration loops for the old track
        _handoffRunId++;
        // Preserve the most recent measured gap until the new boundary gap is
        // published. Clearing here can blank the LG chip during hybrid handoff
        // before the replacement state reaches Flutter.

        // Prevent double forwarding for the same boundary crossing
        if (event.to === _currentIndex) return;

        _currentIndex = event.to;

        // Selection: Transition to the Foreground (Web Audio) for subsequent tracks
        // unless handoff is disabled or the tab is hidden.
        if (_activeEngine === _bgEngine) {
            if (_handoffMode === 'none') {
                _log.log('[hybrid] Track Boundary: Staying in HTML5 (handoff disabled).');
            } else if (document.visibilityState !== 'hidden') {
                _log.log('[hybrid] Track Boundary: Attempting Foreground Restore for the next track.');
                // Stamp the boundary time so _executeForegroundRestore can compute the
                // true audible gap (H5 track-end → WA audio start) for the LG chip.
                _trackBoundaryAtMs = performance.now();
                // We keep _bgEngine as the active engine (reporting 'ready')
                // and use the restore loop to swap to Web Audio ONLY once it's decoded.
                _attemptForegroundRestoreFromHtml5(_currentIndex);
            } else {
                _log.log('[hybrid] Track Boundary: Staying in Background (HTML5) while tab is hidden.');
            }
        } else if (_fenceHandoffPending && _activeEngine === _fgEngine && _playing) {
            _log.log('[hybrid] Track Boundary: Fence triggered. Swapping to background engine now.');
            _fenceHandoffPending = false;
            _attemptHandoff(_currentIndex, true);
        } else {
            // Already in foreground, just ensure background is dead
            _bgEngine.stop();
        }

        _onTrackChange(event);
    }

    function _forwardError(err, sourceEngine) {
        if (sourceEngine === _fgEngine &&
            (_activeEngine !== _fgEngine || _handoffInProgress) &&
            _isForegroundPrepBlocked(err)) {
            _stayOnHtml5AfterForegroundFailure(
                'Suppressing non-fatal foreground Web Audio error during HTML5 playback',
                err,
            );
            return;
        }
        if (_onError) _onError(err);
    }

    _fgEngine.onStateChange((s) => _forwardState(s, _fgEngine));
    _fgEngine.onTrackChange((e) => _forwardTrack(e, _fgEngine));
    _fgEngine.onError((e) => _forwardError(e, _fgEngine));

    _bgEngine.onStateChange((s) => _forwardState(s, _bgEngine));
    _bgEngine.onTrackChange((e) => _forwardTrack(e, _bgEngine));
    _bgEngine.onError((e) => _forwardError(e, _bgEngine));

    function _applyHiddenSurvivalStrategy() {
        _log.log(`[hybrid] Applying hidden survival strategy: ${_backgroundMode}`);
        if (!window._gdarHeartbeat) return;

        if (_backgroundMode === 'heartbeat') {
            window._gdarHeartbeat.startAudioHeartbeat();
            // On mobile browsers, escalate to video heartbeat after 60s if still hidden.
            if (window._gdarIsHeartbeatNeeded()) {
                if (_heartbeatEscalateTimer) clearTimeout(_heartbeatEscalateTimer);
                _heartbeatEscalateTimer = setTimeout(() => {
                    _heartbeatEscalateTimer = null;
                    if (document.visibilityState === 'hidden' && _playing) {
                        _log.warn('[hybrid] Heartbeat escalation: upgrading to video heartbeat after 60s.');
                        window._gdarHeartbeat.startVideoHeartbeat();
                    }
                }, 60000);
            }
            return;
        }
        if (_backgroundMode === 'video') {
            window._gdarHeartbeat.startVideoHeartbeat();
            return;
        }
        if (_backgroundMode === 'html5' && window._gdarIsHeartbeatNeeded()) {
            window._gdarHeartbeat.startAudioHeartbeat();
            return;
        }
        // none does not force heartbeat tricks.
        window._gdarHeartbeat.stopHeartbeat();
    }

    // Handle visibility changes based on selected backgroundMode
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
            _syncHiddenAllowance();
            _log.log(`[hybrid] Tab hidden. backgroundMode: ${_backgroundMode}`);
            _applyHiddenSurvivalStrategy();

            if (_activeEngine === _fgEngine && _playing && !_allowHiddenWebAudio) {
                const allowHandoff = _handoffMode !== 'none';
                const isMobile = window._gdarIsHeartbeatNeeded();

                if (isMobile) {
                    _log.log('[hybrid] Background Handoff: Mobile detected. Pre-emptively swapping to HTML5.');
                    _instantHandoffPending = allowHandoff;
                    _attemptHandoff(_currentIndex, true);
                } else {
                    _log.log('[hybrid] Background Handoff: Desktop detected. Fence enabled: waiting for track boundary (max 10min).');
                    _fenceHandoffPending = true;
                    // Cap the fence so Web Audio doesn't run hidden indefinitely on desktop.
                    if (_fenceTimer) clearTimeout(_fenceTimer);
                    _fenceTimer = setTimeout(() => {
                        if (_fenceHandoffPending && _activeEngine === _fgEngine && _playing) {
                            _log.warn('[hybrid] Fence timed out (10min). Forcing handoff to HTML5.');
                            _fenceHandoffPending = false;
                            _attemptHandoff(_currentIndex, true);
                        }
                        _fenceTimer = null;
                    }, 10 * 60 * 1000);
                }
            }
        } else {
            _log.log('[hybrid] Tab visible. Ensuring survival tricks are off.');
            _fenceHandoffPending = false;
            if (_fenceTimer) { clearTimeout(_fenceTimer); _fenceTimer = null; }
            if (_heartbeatEscalateTimer) { clearTimeout(_heartbeatEscalateTimer); _heartbeatEscalateTimer = null; }
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();

            // Note: Spec 5 says NOT to auto-restore on foreground return.
            // Restoration is deferred to the track boundary.
        }
    });

    function _executeFailureHandoff() {
        if (_activeEngine === _fgEngine && _playing) {
            const state = _fgEngine.getState();
            _log.log(`[hybrid] FAILURE HANDOFF: Swapping to HTML5 at pos ${state.position}`);
            _bgEngine.syncState(state.index, state.position, true);
            _swapEngine(_bgEngine);
            _fgEngine.stop();
        }
    }

    // --- Handoff/Restore Logic ------------------------------------------------

    /**
     * Executes the restore from Background (Passive HTML5) to Foreground (Web Audio).
     * This creates a micro-crossfade for a perfectly seamless handoff.
     */
    function _executeForegroundRestore(pollCount = 0, attemptId) {
        // Use the current handoff ID if not provided (for the starting call)
        const id = attemptId || _handoffRunId;
        _handoffInProgress = true;

        // TERMINATION GUARD: If a new handoff or seek has started, kill this loop immediately.
        if (id !== _handoffRunId) {
            _log.log('[hybrid] Terminating stale handoff loop (ID:', id, ')');
            // Silence any ghost audio the fg engine started during this attempt.
            if (_activeEngine !== _fgEngine) _fgEngine.stop();
            return;
        }

        if (pollCount > 50) { // Give up after 5 seconds
            _handoffInProgress = false;
            _log.error('[hybrid] Handoff FAILED: Foreground never became ready. Staying on HTML5.');
            if (_activeEngine !== _fgEngine) _fgEngine.stop();
            return;
        }

        if (pollCount === 0) {
            _log.log('[hybrid] Starting restore ? Web Audio API (Foreground) loop ID:', id);
            const state = _bgEngine.getState();
            _fgEngine.syncState(state.index, state.position || 0, true);
        }

        // Poll for readiness
        setTimeout(() => {
            // Re-check ID inside the timeout
            if (id !== _handoffRunId) {
                // A newer handoff or track change cancelled this attempt.
                // Stop any fg audio started during this attempt to prevent ghost playback.
                if (_activeEngine !== _fgEngine) _fgEngine.stop();
                return;
            }

            const fgState = _fgEngine.getState();
            const isReady = fgState.playing && fgState.processingState === 'ready';

            if (isReady) {
                const swapStart = performance.now();

                // True audible gap = time from H5 track boundary → WA first audio.
                // Overwrite _lastGapMs so LG shows the full cross-engine silence,
                // not just the H5-internal play() timing.
                if (_trackBoundaryAtMs > 0) {
                    _lastGapMs = performance.now() - _trackBoundaryAtMs;
                    fgState.lastGapMs = _lastGapMs;
                    _trackBoundaryAtMs = 0;
                    _log.log(`[hybrid] LG gap (H5→WA boundary): ${_lastGapMs.toFixed(1)}ms`);
                }

                _lastHandoffPollCount = pollCount;
                _handoffInProgress = false; // Reset flag before swap to ensure FIRST broadcast shows WA

                _swapEngine(_fgEngine);
                _log.log('[hybrid] ACTIVE ENGINE SWAPPED: Now using Web Audio (Foreground)');
                if (_handoffCrossfadeMs > 0) {
                    _startHandoffCrossfade();
                } else {
                    _bgEngine.stop();
                }

                const swapTime = performance.now() - swapStart;
                _log.log(`[hybrid] HANDOFF COMPLETE (ID: ${id}). Settle cycles: ${pollCount}, Swap hitch: ${swapTime.toFixed(2)}ms`);

                // SYNTHETIC BROADCAST to prevent UI desync during 'immediate' handoffs
                // Forces the UI to re-bind to the fresh Web Audio metadata.
                if (_onTrackChange && _currentIndex !== -1) {
                    _onTrackChange({ from: _currentIndex, to: _currentIndex });
                }

                _forwardState(fgState, _fgEngine);
            } else {
                if (pollCount % 10 === 0) {
                    _log.log(`[hybrid] Waiting for foreground... (ID: ${id}, state: ${fgState.processingState})`);
                }
                _executeForegroundRestore(pollCount + 1, id);
            }
        }, pollCount === 0 ? 250 : 100);
    }

    let _handoffRunId = 0;
    let _handoffAttemptCount = 0;

    async function _attemptHandoff(index, shouldPlay) {
        if (shouldPlay === undefined) shouldPlay = _playing;
        if (!shouldPlay) return;
        const track = _playlist[index];
        if (!track) return;
        if (_isForegroundBlocked(track)) {
            _log.log('[hybrid] Foreground decode unavailable for this archive source. Staying on HTML5.');
            _handoffInProgress = false;
            _instantHandoffPending = false;
            _swapEngine(_bgEngine);
            _fgEngine.stop();
            return;
        }

        // --- Handoff Settings Filter ---
        if (_handoffMode === 'none') {
            _log.log('[hybrid] Handoff disabled via handoffMode=none. Staying on HTML5.');
            _handoffInProgress = false;
            _instantHandoffPending = false;
            _swapEngine(_bgEngine);
            _fgEngine.stop();
            return;
        }

        // --- Intensity Filter ---
        // If the track is very short (< 15s), skip handoff and stay on HTML5.
        const isShortTrack = track.duration && track.duration < 15;

        if (isShortTrack) {
            _log.log('[hybrid] Short track detected. Staying on HTML5 for instant start.');
            _handoffInProgress = false;
            _instantHandoffPending = false;
            _swapEngine(_bgEngine);
            _fgEngine.stop();
            return;
        }

        const attemptId = ++_handoffRunId;
        _handoffAttemptCount++;
        _log.log('[hybrid] Launching INSTANT START (HTML5) for index', index);

        _bgEngine.syncState(index, 0, true);
        _swapEngine(_bgEngine);

        // Silently prep foreground
        _handoffInProgress = true;
        setTimeout(() => {
            _prepareForegroundTrack(index).then(() => {
            if (_handoffRunId !== attemptId) return;
            if (_currentIndex !== index) return;

            const bgState = _bgEngine.getState();
            const duration = bgState.duration || 0;

            if (_handoffMode === 'boundary') {
                _log.log('[hybrid] Handoff Mode is boundary. Deferring swap to next track boundary.');
                _instantHandoffPending = false;
                _handoffInProgress = false;

                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _prepareForegroundTrack(index + 1).catch(() => { });
                }
                return;
            }

            // Strategy selection based on Handoff Mode
            if (_handoffMode === 'immediate') {
                _log.log(`[hybrid] Handoff Mode is 'immediate'. Swapping to WebAudio instantly.`);
                _executeForegroundRestore(0, attemptId);
                _instantHandoffPending = false;

                // CRITICAL: Pre-decode the NEXT track in WebAudio now
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _prepareForegroundTrack(index + 1).catch(() => { });
                }
            } else if (duration > 223) { // HTML5_BUFFER_LIMIT
                _log.log(`[hybrid] Track ${index} is LONG (${duration.toFixed(1)}s). Waiting for buffer exhaustion to hand off.`);

                // CRITICAL: Pre-decode the NEXT track in WebAudio now, just in case the handoff
                // happens near the end of the current track.
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _prepareForegroundTrack(index + 1).catch(() => { });
                }

                const onWorkerTick = () => {
                    if (!_instantHandoffPending || index !== _currentIndex || !_playing || _activeEngine !== _bgEngine || attemptId !== _handoffRunId) {
                        window.removeEventListener('gdar-worker-tick', onWorkerTick);
                        return;
                    }

                    const state = _bgEngine.getState();
                    const pos = state.position || 0;
                    const buffered = state.currentTrackBuffered || 0;

                    // If we are within 5 seconds of running out of buffer
                    const timeUntilBufferStarves = buffered - pos;

                    if (timeUntilBufferStarves <= 5.0 && buffered > 0) {
                        window.removeEventListener('gdar-worker-tick', onWorkerTick);
                        _log.log(`[hybrid] HTML5 Buffer Exhausted (${buffered.toFixed(1)}s). Swapping to WebAudio.`);
                        _executeForegroundRestore(0, attemptId);
                        _instantHandoffPending = false;

                        // Clear countdown state
                        if (_onStateChange) {
                            state.processingState = 'ready';
                            _onStateChange(state);
                        }
                    } else if (timeUntilBufferStarves <= 10.0 && timeUntilBufferStarves > 0) {
                        // Send countdown UI hint
                        if (_onStateChange) {
                            state.processingState = 'handoff_countdown';
                            state.position = pos;
                            _onStateChange(state);
                        }
                    }
                };

                window.addEventListener('gdar-worker-tick', onWorkerTick);
            } else {
                _log.log(`[hybrid] Track ${index} fits in initial HTML5 buffer (${duration.toFixed(1)}s). Staying in HTML5.`);
                _instantHandoffPending = false;
                _handoffInProgress = false;

                // CRITICAL: Pre-decode the NEXT track in WebAudio now, so it's ready for a gapless
                // transition when the HTML5 engine reaches the boundary.
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _prepareForegroundTrack(index + 1).catch(() => { });
                }
            }

            }).catch(err => {
            // AbortError is intentional: seekToIndex cancelled the in-flight
            // prepareToPlay. Not a real failure — seekToIndex already reset
            // the pending flags before launching the new attempt.
            const isAbort = err && (err.name === 'AbortError' ||
                (err.message && err.message.toLowerCase().includes('abort')));
            if (isAbort) {
                _log.log('[hybrid] Handoff prepare aborted by seek/index change — expected.');
                return;
            }
            if (err && err.code === 'WA_BLOCKED') {
                _instantHandoffPending = false;
                _handoffInProgress = false;
                _swapEngine(_bgEngine);
                _fgEngine.stop();
                return;
            }
            _log.error('[hybrid] Failed to prepare instant handoff:', err);
            _instantHandoffPending = false;
            _handoffInProgress = false;
            });
        }, 0);
    }

    // --- Engine Swap & MediaSession Sync --------------------------------------

    /**
     * Sole entry point for changing the active engine.
     * After every swap, force-syncs the MediaSession anchor so that
     * play/pause/seek always route through the Hybrid Orchestrator.
     */
    function _swapEngine(engine) {
        if (_activeEngine === engine) return;
        _activeEngine = engine;
        _syncMediaSession();
        // Immediately emit a state event so the Dart HUD reflects the new
        // active engine without waiting for the child engine's next tick.
        _forwardState(engine.getState(), engine);
    }

    function _setupMediaSession() {
        if (window._gdarMediaSession) {
            window._gdarMediaSession.setActionHandlers({
                onPlay: () => api.play(),
                onPause: () => api.pause(),
                onNext: () => api.seekToIndex(_currentIndex + 1),
                onPrevious: () => api.seekToIndex(_currentIndex - 1),
                onSeekTo: (e) => api.seek(e.seekTime)
            });
        }
    }

    /** Force-sync: reset dedup guards, re-register handlers, push current state. */
    function _syncMediaSession() {
        if (!window._gdarMediaSession) return;
        window._gdarMediaSession.forceSync();
        _setupMediaSession();
        const state = _activeEngine.getState();
        window._gdarMediaSession.updatePlaybackState(_playing);
        window._gdarMediaSession.updatePositionState(state);
    }

    // --- Public API -----------------------------------------------------------

    const api = {
        init: function () {
            _fgEngine.init();
            _bgEngine.init();
            if (typeof _fgEngine.onPlayBlocked === 'function') {
                _fgEngine.onPlayBlocked(_emitPlayBlocked);
            }
            if (typeof _bgEngine.onPlayBlocked === 'function') {
                _bgEngine.onPlayBlocked(_emitPlayBlocked);
            }
            if (window._gdarScheduler) window._gdarScheduler.start();
            _setupMediaSession();
        },

        syncState: function (index, position, shouldPlay) {
            _currentIndex = index;
            _playing = shouldPlay;

            if (document.visibilityState === 'hidden') {
                _applyHiddenSurvivalStrategy();
            }

            const pure = _isPureWebAudio();
            const allowHandoff = _handoffMode !== 'none';
            // HTML5 is the instant-start path unless we are locked to pure
            // Web Audio and the selected handoff mode still allows a swap.
            const useHtml5 = !pure || !allowHandoff;
            _logRoutingDecision('syncState', pure, allowHandoff, useHtml5);

            if (useHtml5) {
                _log.log('[hybrid] syncState: Choosing HTML5 (Background) for Instant Start');
                _swapEngine(_bgEngine);
                _instantHandoffPending = shouldPlay && allowHandoff;
                _instantHandoffIndex = index;
            } else {
                _log.log('[hybrid] syncState: Choosing Web Audio (Foreground)');
                _swapEngine(_fgEngine);
                _instantHandoffPending = false;
            }

            _fgEngine.syncState(index, position, false); // ALWAYS force WebAudio strictly to silent sync
            if (shouldPlay && _activeEngine === _fgEngine) _fgEngine.play();

            _bgEngine.syncState(index, position, shouldPlay);

            if (shouldPlay && _instantHandoffPending) {
                _attemptHandoff(index, shouldPlay);
            }
        },

        setPlaylist: function (tracks, startIndex) {
            _playlist = tracks || [];
            _blockedForegroundIdentifiers.clear();
            _currentIndex = startIndex != null ? startIndex : 0;
            _playing = false;
            _handoffRunId = 0;
            _handoffAttemptCount = 0;
            _lastHandoffPollCount = 0;
            _handoffInProgress = false;
            _instantHandoffPending = false;
            _lastGapMs = null;
            _trackBoundaryAtMs = 0;

            // Stop any background heartbeats left over
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();

            // Set both underlying engines
            _fgEngine.setPlaylist(tracks, _currentIndex);
            _bgEngine.setPlaylist(tracks, _currentIndex);

            const pure = _isPureWebAudio();
            const allowHandoff = _handoffMode !== 'none';
            // Same routing rule as syncState(): start on HTML5 unless the
            // runtime is explicitly locked to Web Audio and handoff is allowed.
            const useHtml5 = !pure || !allowHandoff;
            _logRoutingDecision('setPlaylist', pure, allowHandoff, useHtml5);

            if (useHtml5) {
                _log.log('[hybrid] setPlaylist: Choosing HTML5 (Background) for Instant Start');
                _instantHandoffPending = allowHandoff;
                _instantHandoffIndex = _currentIndex;
                _swapEngine(_bgEngine);
            } else {
                _log.log('[hybrid] setPlaylist: Choosing Web Audio (Foreground) for Instant Start');
                _instantHandoffPending = false;
                _swapEngine(_fgEngine);
            }
        },

        appendTracks: function (tracks) {
            if (tracks && tracks.length > 0) {
                _playlist = _playlist.concat(tracks);
                // Always update BOTH engines so handoffs have the complete
                // playlist. If only the active engine is updated, a WA→HTML5
                // fence handoff will land on an out-of-bounds index, causing
                // HTML5 to report index:-1, which blanks the UI and silences
                // the auto-random-on-completion trigger.
                _fgEngine.appendTracks(tracks);
                _bgEngine.appendTracks(tracks);
            }
        },

        play: function () {
            _playing = true;

            // Respect selected hidden-tab survival strategy on hidden startup.
            if (document.visibilityState === 'hidden') {
                _log.log('[hybrid] play(): Hidden startup detected. Applying selected strategy.');
                _applyHiddenSurvivalStrategy();
            }

            const allowHandoff = _handoffMode !== 'none';
            const fgState = _fgEngine.getState();
            const fgReady = fgState.playing && fgState.processingState === 'ready';

            // HYBRID CORE: Always prioritize HTML5 for "Instant Start" if Web Audio is not yet ready/playing
            _logRoutingDecision('play', false, allowHandoff, !fgReady && _activeEngine !== _bgEngine);

            if (!fgReady && _activeEngine !== _bgEngine) {
                _log.log('[hybrid] Startup: Web Audio not ready. Initiating HTML5 Instant Start.');
                _instantHandoffPending = allowHandoff;
                _instantHandoffIndex = _currentIndex;
                _swapEngine(_bgEngine);

                // Sync HTML5 to current position and play
                _bgEngine.syncState(_currentIndex, fgState.position || 0, true);
                if (allowHandoff) {
                    _attemptHandoff(_currentIndex, true);
                }
            } else {
                _activeEngine.play();

                // If setPlaylist or another command primed us for an instant handoff, we must launch it now
                if (_instantHandoffPending && _activeEngine === _bgEngine) {
                    _log.log('[hybrid] play: Launching pending Instant Start handoff');
                    _attemptHandoff(_currentIndex, true);
                }
            }
        },

        pause: function () {
            _playing = false;
            if (_stallTimer) { clearTimeout(_stallTimer); _stallTimer = null; }
            // Cancel any pending restoration loop immediately
            _handoffRunId++;
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();
            _instantHandoffPending = false;
            _handoffInProgress = false;
            _activeEngine.pause();
        },

        stop: function () {
            _playing = false;
            if (_stallTimer) { clearTimeout(_stallTimer); _stallTimer = null; }
            // Increment ID to cancel any pending handoff loop or buffer-check intervals
            _handoffRunId++;
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();
            _instantHandoffPending = false;
            _handoffInProgress = false;
            _lastGapMs = null;
            _activeEngine.stop();
            if (_activeEngine === _fgEngine) _bgEngine.stop();
            else _fgEngine.stop();
        },

        seek: function (seconds) {
            if (_stallTimer) { clearTimeout(_stallTimer); _stallTimer = null; }
            _activeEngine.seek(seconds);
        },

        seekToIndex: function (index) {
            if (_stallTimer) { clearTimeout(_stallTimer); _stallTimer = null; }
            // Increment ID to cancel any pending handoff loop or buffer-check intervals
            _handoffRunId++;
            _instantHandoffPending = false;
            _handoffInProgress = false;
            _trackBoundaryAtMs = 0;
            _currentIndex = index;

            const pure = _isPureWebAudio();
            const allowHandoff = _handoffMode !== 'none';
            if (!pure) {
                _log.log(`[hybrid engine] SeekToIndex(${index}) initializing Instant-Start.`);

                // CRITICAL: STOP WebAudio strictly to prevent simultaneous playback
                // while HTML5 handles the "Instant Start".
                _fgEngine.stop();

                _instantHandoffPending = allowHandoff;
                _instantHandoffIndex = index;
                _swapEngine(_bgEngine);

                _bgEngine.seekToIndex(index);
                _fgEngine.syncState(index, 0, false); // Prepare foreground silently

                if (_playing && allowHandoff) {
                    _attemptHandoff(_instantHandoffIndex);
                }
            } else {
                _activeEngine.seekToIndex(index);
            }
        },

        setPrefetchSeconds: function (s) {
            _prefetchSeconds = Math.max(5, Math.min(120, s));
            _fgEngine.setPrefetchSeconds(s);
            _bgEngine.setPrefetchSeconds(s);
        },

        setTrackTransitionMode: function (mode) {
            if (['gap', 'gapless'].includes(mode)) {
                _transitionMode = mode;
                _log.log('[hybrid engine] Transition Mode:', mode);
            }
        },

        setHybridBackgroundMode: function (mode) {
            const normalized = (mode || '').toLowerCase();
            const mapped = normalized === 'relisten' ? 'html5' : normalized;
            if (['html5', 'heartbeat', 'video', 'none'].includes(mapped)) {
                _backgroundMode = mapped;
                if (_fgEngine.setHybridBackgroundMode) {
                    _fgEngine.setHybridBackgroundMode(mapped);
                }
                if (_bgEngine.setHybridBackgroundMode) {
                    _bgEngine.setHybridBackgroundMode(mapped);
                }
                _syncHiddenAllowance();
                _log.log('[hybrid engine] Background Mode set to:', mapped);

                if (document.visibilityState === 'hidden') {
                    _applyHiddenSurvivalStrategy();
                }
            }
        },

        setBackgroundMode: function (mode) {
            this.setHybridBackgroundMode(mode);
        },

        setHybridHandoffMode: function (mode) {
            if (['buffered', 'immediate', 'boundary', 'none'].includes(mode)) {
                _handoffMode = mode;
                _syncHiddenAllowance();
                _log.log('[hybrid engine] Handoff Mode set to:', mode);
                // If set to none, disable the buffer-exhaustion worker checks
            }
        },

        setHandoffMode: function (mode) {
            this.setHybridHandoffMode(mode);
        },

        getIsHandoffPending: function () {
            return _handoffMode !== 'immediate' && !!_instantHandoffPending;
        },

        setHybridAllowHiddenWebAudio: function (enabled) {
            _allowHiddenWebAudio = !!enabled;
            _log.log('[hybrid engine] Allow hidden Web Audio:', _allowHiddenWebAudio);
        },

        setHandoffCrossfadeMs: function (ms) {
            const next = Math.max(0, Math.min(200, Number(ms) || 0));
            _handoffCrossfadeMs = next;
            _log.log('[hybrid engine] Handoff crossfade ms:', next);
        },


        engineType: 'hybrid_orchestrator',

        getState: function () {
            const state = _activeEngine.getState();
            if (_lastGapMs != null && (state.lastGapMs == null || !Number.isFinite(state.lastGapMs))) {
                state.lastGapMs = _lastGapMs;
            }
            state.playing = _playing;
            state.engineType = _activeEngine === _bgEngine ? 2 : 1;
            let __tech = '??';
            if (_activeEngine === _fgEngine) { __tech = '(WA)'; }
            else if (_activeEngine === _bgEngine) { __tech = '(H5B)'; }
            else if (_backgroundMode === 'html5') { __tech = '(H5B)'; }
            else if (_backgroundMode === 'video') { __tech = '(VI)'; }
            else if (_backgroundMode === 'heartbeat') { __tech = '(HBT)'; }
            else { __tech = 'OFF'; }

            const hbNeeded = window._gdarIsHeartbeatNeeded();
            // Keep AE on H5 during an in-flight restore until the foreground
            // handoff has been forwarded and the flag is cleared.
            if (_handoffInProgress && _activeEngine === _fgEngine) {
                __tech = '(H5B)';
            }
            state.heartbeatNeeded = hbNeeded;
            state.contextState = 'hybrid ' + __tech + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';

            const survivalDisabled = _backgroundMode === 'none';
            state.heartbeatActive = !survivalDisabled &&
                !!(window._gdarHeartbeat && window._gdarHeartbeat.isActive());
            state.hs = _getHandoffState();
            state.hat = _handoffAttemptCount;
            state.hpd = _lastHandoffPollCount;
            return state;
        },

        onStateChange: function (cb) { _onStateChange = cb; },
        onTrackChange: function (cb) { _onTrackChange = cb; },
        onError: function (cb) { _onError = cb; },
        onPlayBlocked: function (cb) { _onPlayBlocked = cb; },
    };


    window._hybridAudio = api;

})();
