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
    'use strict';

    // Ensure passive and gapless engines exist
    const _fgEngine = window._gdarAudio;
    const _bgEngine = window._passiveAudio;

    if (!_bgEngine || !_fgEngine) {
        console.error('[hybrid engine] Missing required underlying engines');
        return;
    }

    // ─── State ────────────────────────────────────────────────────────────────

    let _playlist = [];
    let _currentIndex = -1;
    let _playing = false;
    let _prefetchSeconds = 30;

    // Track Transition Settings (mapped from UI via Dart -> JS later, defaults here)
    let _transitionMode = 'gapless'; // gap | gapless | crossfade
    let _crossfadeDuration = 3.0; // seconds

    // Mode state
    let _activeEngine = _fgEngine; // Default to Web Audio API
    let _pendingHandoff = false; // true if tab is hidden and we should hand off at next boundary

    // Callbacks registered by Dart
    let _onStateChange = null;
    let _onTrackChange = null;
    let _onError = null;

    // ─── Engine Routing ───────────────────────────────────────────────────────

    // The hybrid engine listens to the active underlying engine and forwards states
    function _forwardState(state) {
        if (!_onStateChange) return;
        state.contextState = 'hybrid_' + (_activeEngine === _bgEngine ? 'background' : 'foreground');
        _onStateChange(state);
    }

    function _forwardTrack(event) {
        if (!_onTrackChange) return;
        _currentIndex = event.to;

        // This is a track boundary! Check if we need to hand off.
        if (_activeEngine === _fgEngine && _pendingHandoff) {
            _executeBackgroundHandoff();
        } else {
            _onTrackChange(event);
        }
    }

    function _forwardError(err) {
        if (_onError) _onError(err);
    }

    _fgEngine.onStateChange(_forwardState);
    _fgEngine.onTrackChange(_forwardTrack);
    _fgEngine.onError(_forwardError);

    _bgEngine.onStateChange(_forwardState);
    _bgEngine.onTrackChange(_forwardTrack);
    _bgEngine.onError(_forwardError);

    // ─── Handoff Logic ────────────────────────────────────────────────────────

    // Handle visibility changes to trigger boundary handoffs
    document.addEventListener('visibilitychange', () => {
        if (document.visibilityState === 'hidden') {
            console.log('[hybrid engine] Tab hidden. Queueing boundary handoff to passive engine.');
            _pendingHandoff = true;
        } else {
            console.log('[hybrid engine] Tab visible. Cancelling pending handoff or restoring foreground engine.');
            _pendingHandoff = false;

            // If we are currently running the passive engine, we should restore immediately
            if (_activeEngine === _bgEngine && _playing) {
                _executeForegroundRestore();
            }
        }
    });

    /**
     * Executes the handoff from Foreground (Web Audio) to Background (Passive HTML5).
     * This is called ONLY at the track boundary if the tab is hidden.
     */
    function _executeBackgroundHandoff() {
        console.log('[hybrid engine] Executing boundary handoff → Passive (Background)');

        // At the track boundary, _gdarAudio has already advanced its internal index
        // Or is about to. We need to stop it and start the passive engine at the new index.
        const targetIndex = _currentIndex;

        _activeEngine.pause();
        _activeEngine = _bgEngine;

        // Sync playlist and state
        _activeEngine.setPlaylist(_playlist, targetIndex);
        _activeEngine.play();
    }

    /**
     * Executes the restore from Background (Passive HTML5) to Foreground (Web Audio).
     * This is called immediately when the tab becomes visible.
     */
    function _executeForegroundRestore() {
        console.log('[hybrid engine] Executing restore → Web Audio API (Foreground)');

        // Capture current state from passive engine
        const state = _bgEngine.getState();
        const pos = state.position || 0;
        const targetIndex = _currentIndex;
        const wasPlaying = _playing;

        _activeEngine.pause();
        _activeEngine = _fgEngine;

        // Sync playlist and state
        _activeEngine.setPlaylist(_playlist, targetIndex);
        try {
            if (wasPlaying) {
                // Web Audio seek handles the decode and resume natively
                _activeEngine.seek(pos);
                _activeEngine.play();
            } else {
                _activeEngine.seek(pos);
            }
        } catch (err) {
            console.error('[hybrid engine] Failed to restore foreground engine:', err);
            // Don't forward this error if it's an abort or context issue to avoid bubbling to Dart
        }
    }


    // ─── Public API ───────────────────────────────────────────────────────────

    const api = {

        init: function () {
            _fgEngine.init();
            _bgEngine.init();
            console.log('[hybrid engine] Initialised');
        },

        setPlaylist: function (tracks, startIndex) {
            _playlist = tracks || [];
            _currentIndex = startIndex != null ? startIndex : 0;
            _playing = false;

            // Determine active engine at start time based on visibility
            _activeEngine = document.visibilityState === 'hidden' ? _bgEngine : _fgEngine;
            _pendingHandoff = document.visibilityState === 'hidden';

            _fgEngine.setPlaylist(tracks, startIndex);
            _bgEngine.setPlaylist(tracks, startIndex);
        },

        appendTracks: function (tracks) {
            if (tracks && tracks.length > 0) {
                _playlist = _playlist.concat(tracks);
                _fgEngine.appendTracks(tracks);
                _bgEngine.appendTracks(tracks);
            }
        },

        play: function () {
            _playing = true;
            _activeEngine.play();
        },

        pause: function () {
            _playing = false;
            _activeEngine.pause();
        },

        stop: function () {
            _playing = false;
            _activeEngine.stop();
            // Stop secondary engine as well just in case
            if (_activeEngine === _fgEngine) _bgEngine.stop();
            else _fgEngine.stop();
        },

        seek: function (seconds) {
            _activeEngine.seek(seconds);
        },

        seekToIndex: function (index) {
            _currentIndex = index;
            _activeEngine.seekToIndex(index);
        },

        setPrefetchSeconds: function (s) {
            _prefetchSeconds = Math.max(5, Math.min(120, s));
            _fgEngine.setPrefetchSeconds(s);
            _bgEngine.setPrefetchSeconds(s);
        },

        /** Extension for Track Transitions (Gapless/Crossfade/Gap) */
        setTrackTransitionMode: function (mode) {
            if (['gap', 'gapless', 'crossfade'].includes(mode)) {
                _transitionMode = mode;
                console.log('[hybrid engine] Transition Mode set to:', mode);
                // Implementation for Crossfade logic inside Web Audio engine would
                // need to be injected or we apply the crossfade settings to _gdarAudio if supported.
            }
        },

        setCrossfadeDuration: function (seconds) {
            _crossfadeDuration = Math.max(1.0, Math.min(12.0, seconds));
            console.log('[hybrid engine] Crossfade Duration set to:', _crossfadeDuration, 's');
        },

        getState: function () {
            const state = _activeEngine.getState();
            state.playing = _playing; // Override to maintain truth
            state.contextState = 'hybrid_' + (_activeEngine === _bgEngine ? 'background' : 'foreground');
            return state;
        },

        onStateChange: function (cb) { _onStateChange = cb; },
        onTrackChange: function (cb) { _onTrackChange = cb; },
        onError: function (cb) { _onError = cb; },
    };

    window._hybridAudio = api;

})();
