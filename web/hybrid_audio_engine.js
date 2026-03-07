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

    // ─── State ────────────────────────────────────────────────────────────────

    let _playlist = [];
    let _currentIndex = -1;
    let _playing = false;
    let _prefetchSeconds = 30;

    // Track Transition Settings
    let _transitionMode = 'gapless';
    let _crossfadeDuration = 3.0;

    // Advanced Hybrid Settings
    let _backgroundMode = 'relisten'; // relisten | heartbeat | video | none
    let _handoffMode = 'buffered';    // buffered | immediate | none

    // Mode state
    let _activeEngine = _fgEngine; // Default to Web Audio API
    let _stallTimer = null;
    let _instantHandoffPending = false;
    let _instantHandoffIndex = -1;

    // Web Worker for background timing
    let _schedulerWorker = null;

    function _initWorker() {
        if (_schedulerWorker) return;
        try {
            _schedulerWorker = new Worker('audio_scheduler.worker.js');
            _schedulerWorker.onmessage = (e) => {
                if (e.data === 'tick') {
                    // Global heartbeat tick - can be used for any background polling
                    window.dispatchEvent(new CustomEvent('gdar-worker-tick'));
                }
            };
            _schedulerWorker.postMessage('start');
            _log.log('[hybrid] Background scheduler worker started');
        } catch (err) {
            _log.error('[hybrid] Failed to spawn worker:', err.message);
        }
    }

    // Callbacks registered by Dart
    let _onStateChange = null;
    let _onTrackChange = null;
    let _onError = null;

    // ─── Engine Routing ───────────────────────────────────────────────────────

    function _forwardState(state, sourceEngine) {
        if (!_onStateChange) return;

        // Critical Fix: Do not let the Web Audio API overwrite the UI with "buffering" events
        // while the HTML5 engine is successfully driving playback during an Instant Start.
        if (sourceEngine !== _activeEngine) return;

        // Detect OS-forced suspension
        if (_activeEngine === _fgEngine && state.processingState === 'suspended') {
            _log.log('[hybrid] Forced Suspension detected in Web Audio.');
            state.processingState = 'suspended_by_os';
            _playing = false; // Stop the local flag
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

        state.contextState = 'hybrid_' + (_activeEngine === _bgEngine ? 'background' : 'foreground');
        _onStateChange(state);
    }

    function _forwardTrack(event, sourceEngine) {
        if (!_onTrackChange) return;
        if (sourceEngine !== _activeEngine) return;

        // Invalidate any background restoration loops for the old track
        _handoffAttemptId++;

        // Prevent double forwarding for the same boundary crossing
        if (event.to === _currentIndex) return;

        _currentIndex = event.to;

        // Selection: Ensure we transition to the Foreground (Web Audio) engine
        // for subsequent tracks. HTML5 is only used for the very first "Instant Start".
        if (_activeEngine === _bgEngine) {
            if (document.visibilityState !== 'hidden') {
                _log.log('[hybrid] Track Boundary: Attempting Foreground Restore for the next track.');
                // We keep _bgEngine as the active engine (reporting 'ready')
                // and use the restore loop to swap to Web Audio ONLY once it's decoded.
                _executeForegroundRestore(0);
            } else {
                _log.log('[hybrid] Track Boundary: Staying in Background (HTML5) while tab is hidden.');
            }
        } else {
            // Already in foreground, just ensure background is dead
            _bgEngine.stop();
        }

        _onTrackChange(event);
    }

    function _forwardError(err, sourceEngine) {
        if (_onError) _onError(err);
    }

    _fgEngine.onStateChange((s) => _forwardState(s, _fgEngine));
    _fgEngine.onTrackChange((e) => _forwardTrack(e, _fgEngine));
    _fgEngine.onError((e) => _forwardError(e, _fgEngine));

    _bgEngine.onStateChange((s) => _forwardState(s, _bgEngine));
    _bgEngine.onTrackChange((e) => _forwardTrack(e, _bgEngine));
    _bgEngine.onError((e) => _forwardError(e, _bgEngine));

    // Handle visibility changes based on selected backgroundMode
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
            _log.log(`[hybrid] Tab hidden. backgroundMode: ${_backgroundMode}`);

            // Background survival: We NO LONGER swap to HTML5 at the boundary by default.
            // We trust the survival tricks (heartbeat/video) to keep Web Audio alive.
            if (_backgroundMode === 'heartbeat') {
                if (window._gdarHeartbeat) window._gdarHeartbeat.startAudioHeartbeat();
            } else if (_backgroundMode === 'video') {
                if (window._gdarHeartbeat) window._gdarHeartbeat.startVideoHeartbeat();
            }
        } else {
            _log.log('[hybrid] Tab visible. Ensuring survival tricks are off.');
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
            _activeEngine = _bgEngine;
            _fgEngine.stop();
        }
    }

    // ─── Handoff/Restore Logic ────────────────────────────────────────────────

    /**
     * Executes the restore from Background (Passive HTML5) to Foreground (Web Audio).
     * This creates a micro-crossfade for a perfectly seamless handoff.
     */
    function _executeForegroundRestore(pollCount = 0, attemptId) {
        // Use the current handoff ID if not provided (for the starting call)
        const id = attemptId || _handoffAttemptId;

        // TERMINATION GUARD: If a new handoff or seek has started, kill this loop immediately.
        if (id !== _handoffAttemptId) {
            _log.log('[hybrid] Terminating stale handoff loop (ID:', id, ')');
            return;
        }

        if (pollCount > 50) { // Give up after 5 seconds
            _log.error('[hybrid] Handoff FAILED: Foreground never became ready. Staying on HTML5.');
            return;
        }

        if (pollCount === 0) {
            _log.log('[hybrid] Starting restore → Web Audio API (Foreground) loop ID:', id);
            const state = _bgEngine.getState();
            _fgEngine.syncState(state.index, state.position || 0, true);
        }

        // Poll for readiness
        setTimeout(() => {
            // Re-check ID inside the timeout
            if (id !== _handoffAttemptId) return;

            const fgState = _fgEngine.getState();
            const isReady = fgState.playing && fgState.processingState === 'ready';

            if (isReady) {
                const swapStart = performance.now();
                _activeEngine = _fgEngine;
                _log.log('[hybrid] ACTIVE ENGINE SWAPPED: Now using Web Audio (Foreground)');
                _bgEngine.stop();

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

    let _handoffAttemptId = 0;

    async function _attemptHandoff(index, shouldPlay) {
        if (shouldPlay === undefined) shouldPlay = _playing;
        if (!shouldPlay) return;
        const track = _playlist[index];
        if (!track) return;

        // --- Handoff Settings Filter ---
        if (_handoffMode === 'none') {
            _log.log('[hybrid] Handoff disabled via handoffMode=none. Using WebAudio directly.');
            _fgEngine.syncState(index, 0, true);
            _activeEngine = _fgEngine;
            _bgEngine.stop();
            return;
        }

        // --- Intensity Filter ---
        // If the track is very short (< 15s), skip the hybrid HTML5 overhead and just use Web Audio.
        const isShortTrack = track.duration && track.duration < 15;

        if (isShortTrack) {
            _log.log('[hybrid] Skipping HTML5 start for short track (' + track.duration + 's). Using WebAudio directly.');
            _fgEngine.syncState(index, 0, true);
            _activeEngine = _fgEngine;
            _bgEngine.stop();
            return;
        }

        const attemptId = ++_handoffAttemptId;
        _log.log('[hybrid] Launching INSTANT START (HTML5) for index', index);

        _bgEngine.syncState(index, 0, true);
        _activeEngine = _bgEngine;

        // Silently prep foreground
        _fgEngine.prepareToPlay(index).then(() => {
            if (_handoffAttemptId !== attemptId) return;
            if (_currentIndex !== index) return;

            const bgState = _bgEngine.getState();
            const duration = bgState.duration || 0;

            // Strategy selection based on Handoff Mode
            if (_handoffMode === 'immediate') {
                _log.log(`[hybrid] Handoff Mode is 'immediate'. Swapping to WebAudio instantly.`);
                _executeForegroundRestore(0, attemptId);
                _instantHandoffPending = false;

                // CRITICAL: Pre-decode the NEXT track in WebAudio now
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _fgEngine.prepareToPlay(index + 1).catch(() => { });
                }
            } else if (duration > 223) { // HTML5_BUFFER_LIMIT
                _log.log(`[hybrid] Track ${index} is LONG (${duration.toFixed(1)}s). Waiting for buffer exhaustion to hand off.`);

                // CRITICAL: Pre-decode the NEXT track in WebAudio now, just in case the handoff
                // happens near the end of the current track.
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _fgEngine.prepareToPlay(index + 1).catch(() => { });
                }

                const onWorkerTick = () => {
                    if (!_instantHandoffPending || index !== _currentIndex || !_playing || _activeEngine !== _bgEngine || attemptId !== _handoffAttemptId) {
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

                // CRITICAL: Pre-decode the NEXT track in WebAudio now, so it's ready for a gapless
                // transition when the HTML5 engine reaches the boundary.
                if (index + 1 < _playlist.length) {
                    _log.log(`[hybrid] Pre-preparing next track (${index + 1}) in Web Audio...`);
                    _fgEngine.prepareToPlay(index + 1).catch(() => { });
                }
            }

        }).catch(err => {
            _log.error('[hybrid] Failed to prepare instant handoff:', err);
            _instantHandoffPending = false;
        });
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    const api = {
        init: function () {
            _fgEngine.init();
            _bgEngine.init();
            _initWorker();
        },

        syncState: function (index, position, shouldPlay) {
            _currentIndex = index;
            _playing = shouldPlay;

            const pure = _isPureWebAudio();
            // BACKGROUND OPTIMIZATION: We now allow Instant-Start (HTML5) even when hidden,
            // because HTML5 is more robust for background initiates than Web Audio.
            if (!pure) {
                _log.log('[hybrid] syncState: Choosing HTML5 (Background) for Instant Start');
                _activeEngine = _bgEngine;
                _instantHandoffPending = shouldPlay;
                _instantHandoffIndex = index;
            } else {
                _log.log('[hybrid] syncState: Choosing Web Audio (Foreground)');
                _activeEngine = _fgEngine;
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
            _currentIndex = startIndex != null ? startIndex : 0;
            _playing = false;

            // Stop any background heartbeats left over
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();

            // Set both underlying engines
            _fgEngine.setPlaylist(tracks, _currentIndex);
            _bgEngine.setPlaylist(tracks, _currentIndex);

            // Optimization: We now allow "Instant-Start" using the HTML5 engine even when hidden
            // rather than forcing the user to wait for _fgEngine (WebAudio) to download and decode.
            const pure = _isPureWebAudio();
            if (!pure) {
                _log.log('[hybrid] setPlaylist: Choosing HTML5 (Background) for Instant Start');
                _instantHandoffPending = true;
                _instantHandoffIndex = _currentIndex;
                _activeEngine = _bgEngine;
            } else {
                _log.log('[hybrid] setPlaylist: Choosing Web Audio (Foreground)');
                _instantHandoffPending = false;
                _activeEngine = _fgEngine;
            }
        },

        appendTracks: function (tracks) {
            if (tracks && tracks.length > 0) {
                _playlist = _playlist.concat(tracks);
                _activeEngine.appendTracks(tracks);
            }
        },

        play: function () {
            _playing = true;

            // Start heartbeats if tab is already hidden and mode is not 'relisten'
            if (document.visibilityState === 'hidden') {
                _log.log('[hybrid] play(): Hidden startup detected. Priming heartbeats.');
                if (window._gdarHeartbeat) window._gdarHeartbeat.startHeartbeat();
            }

            // HYBRID CORE: Always prioritize HTML5 for "Instant Start" if Web Audio is not yet ready/playing
            const fgState = _fgEngine.getState();
            const fgReady = fgState.playing && fgState.processingState === 'ready';

            if (!fgReady && _activeEngine !== _bgEngine) {
                _log.log('[hybrid] Startup: Web Audio not ready. Initiating HTML5 Instant Start.');
                _instantHandoffPending = true;
                _instantHandoffIndex = _currentIndex;
                _activeEngine = _bgEngine;

                // Sync HTML5 to current position and play
                _bgEngine.syncState(_currentIndex, fgState.position || 0, true);
                _attemptHandoff(_currentIndex, true);
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
            _handoffAttemptId++;
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();
            _instantHandoffPending = false;
            _activeEngine.pause();
        },

        stop: function () {
            _playing = false;
            if (_stallTimer) { clearTimeout(_stallTimer); _stallTimer = null; }
            // Increment ID to cancel any pending handoff loop or buffer-check intervals
            _handoffAttemptId++;
            if (window._gdarHeartbeat) window._gdarHeartbeat.stopHeartbeat();
            _instantHandoffPending = false;
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
            _handoffAttemptId++;
            _instantHandoffPending = false;
            _currentIndex = index;

            const pure = _isPureWebAudio();
            if (!pure) {
                _log.log(`[hybrid engine] SeekToIndex(${index}) initializing Instant-Start.`);

                // CRITICAL: STOP WebAudio strictly to prevent simultaneous playback
                // while HTML5 handles the "Instant Start".
                _fgEngine.stop();

                _instantHandoffPending = true;
                _instantHandoffIndex = index;
                _activeEngine = _bgEngine;

                _bgEngine.seekToIndex(index);
                _fgEngine.syncState(index, 0, false); // Prepare foreground silently

                if (_playing) {
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
            if (['gap', 'gapless', 'crossfade'].includes(mode)) {
                _transitionMode = mode;
                if (mode === 'crossfade') {
                    _log.warn('[hybrid engine] Crossfade mode not yet implemented. Gapless used.');
                }
                _log.log('[hybrid engine] Transition Mode:', mode);
            }
        },

        setCrossfadeDuration: function (seconds) {
            _crossfadeDuration = Math.max(1.0, Math.min(12.0, seconds));
            _log.log('[hybrid engine] Crossfade Duration:', _crossfadeDuration, 's');
        },

        setHybridBackgroundMode: function (mode) {
            if (['relisten', 'heartbeat', 'video', 'none'].includes(mode)) {
                _backgroundMode = mode;
                _log.log('[hybrid engine] Background Mode set to:', mode);
            }
        },

        setHybridHandoffMode: function (mode) {
            if (['buffered', 'immediate', 'none'].includes(mode)) {
                _handoffMode = mode;
                _log.log('[hybrid engine] Handoff Mode set to:', mode);
                // If set to none, disable the buffer-exhaustion worker checks
            }
        },

        engineType: 'hybrid_orchestrator',

        getState: function () {
            const state = _activeEngine.getState();
            state.playing = _playing;
            state.contextState = 'hybrid_' + (_activeEngine === _bgEngine ? 'background' : 'foreground');
            return state;
        },

        onStateChange: function (cb) { _onStateChange = cb; },
        onTrackChange: function (cb) { _onTrackChange = cb; },
        onError: function (cb) { _onError = cb; },
    };


    window._hybridAudio = api;

})();
