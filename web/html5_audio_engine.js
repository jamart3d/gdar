/**
 * HTML5 Audio Engine
 * Mobile gapless (near-gapless) playback via dual HTMLAudioElement approach.
 * Inspired by RelistenNet/relisten-web's gapless.cjs.
 *
 * Architecture:
 *   - Two <audio> elements: _currentAudio and _nextAudio
 *   - When _currentAudio is N seconds from end, _nextAudio.src is set and
 *     load() / play() is called so it is buffered and ready.
 *   - On _currentAudio 'ended', the two elements are swapped and the next
 *     track (already playing silently / buffered) takes over.
 *   - Relies entirely on the browser's native HTTP streaming — no fetch(),
 *     no ArrayBuffer decoding, minimal RAM usage.
 *   - Media Session API is handled by the browser natively when using
 *     HTMLAudioElement; no manual MediaMetadata calls needed for Chrome/Safari.
 *
 * Exposed globally as window._html5Audio for Dart interop via hybrid_init.js.
 */
(function () {
    'use strict';

    // ─── State ────────────────────────────────────────────────────────────────

    let _playlist = [];
    let _currentIndex = -1;
    let _playing = false;
    let _prefetchSeconds = 30;

    /**
     * Primary HTMLAudioElement — the currently playing track.
     * @type {HTMLAudioElement|null}
     */
    let _currentAudio = null;

    /**
     * Secondary HTMLAudioElement — the next track, pre-loaded and ready.
     * @type {HTMLAudioElement|null}
     */
    let _nextAudio = null;

    /** Whether a swap-on-end transition is in progress. */
    let _isTransitioning = false;
    let _lastEmittedNextBuf = 0;
    let _lastEmittedNextIndex = -1;

    /** Whether _nextAudio is currently being preloaded. */
    let _isPrefetching = false;

    /** The interval ID for the position-polling timer. */
    let _positionTimer = null;

    /** Countdown timer that triggers prefetch N seconds before track end. */
    let _prefetchTimer = null;

    /** Processing state mirroring the GDAR engine's vocabulary. */
    let _loadingState = 'idle';

    // Callbacks registered by Dart (via hybrid_init.js → _gdarAudio).
    let _onStateChange = null;
    let _onTrackChange = null;
    let _onError = null;

    // ─── Audio Element Factory ─────────────────────────────────────────────────

    /**
     * Creates a new HTMLAudioElement configured for streaming playback.
     * Volume is 0 (muted) until the element becomes the active player.
     * @param {boolean} muted
     * @returns {HTMLAudioElement}
     */
    function _createAudio(muted) {
        const audio = new Audio();
        audio.preload = 'auto';
        audio.volume = muted ? 0 : 1;
        audio.crossOrigin = 'anonymous';
        return audio;
    }

    /** Pause and reset an audio element without releasing it. */
    function _resetAudio(audio) {
        if (!audio) return;
        audio.pause();
        audio.src = '';
        audio.volume = 0;
        audio.onended = null;
        audio.onerror = null;
        audio.oncanplaythrough = null;
        audio.onwaiting = null;
        audio.onplaying = null;
        audio.ontimeupdate = null;
    }

    // ─── Position Polling ─────────────────────────────────────────────────────

    function _startPositionTimer() {
        _stopPositionTimer();
        _positionTimer = setInterval(() => _emitState(), 250);
    }

    function _stopPositionTimer() {
        if (_positionTimer) { clearInterval(_positionTimer); _positionTimer = null; }
    }

    // ─── Prefetch ─────────────────────────────────────────────────────────────

    function _cancelPrefetch() {
        if (_prefetchTimer) { clearTimeout(_prefetchTimer); _prefetchTimer = null; }
        _isPrefetching = false;
    }

    /**
     * Schedule preloading the next track so it is buffered by the time
     * the current track ends.  Called every time a track starts.
     */
    function _schedulePrefetch() {
        _cancelPrefetch();
        const nextIndex = _currentIndex + 1;
        if (nextIndex >= _playlist.length) return;

        // We try to have the next track loaded _prefetchSeconds before it's needed.
        // HTMLAudioElement has its own internal buffer so we simply set src early.
        const setupPreload = () => {
            if (!_playing || _currentIndex + 1 !== nextIndex) return;
            _isPrefetching = true;

            if (!_nextAudio) _nextAudio = _createAudio(true);
            _resetAudio(_nextAudio);

            const nextTrack = _playlist[nextIndex];
            if (!nextTrack) return;

            _nextAudio.volume = 0;
            _nextAudio.src = nextTrack.url;
            _nextAudio.load();

            // iOS Safari: prime the audio element with a silent play/pause on first gesture.
            // We rely on the fact that the user has already interacted to play _currentAudio.
            _nextAudio.play().then(() => {
                if (!_playing || _currentIndex + 1 !== nextIndex) {
                    _nextAudio.pause();
                    return;
                }
                // Pause it once we know it can play — we'll resume at full volume on swap.
                _nextAudio.pause();
                _nextAudio.currentTime = 0;
                console.log('[html5 engine] Next track preloaded:', nextIndex, nextTrack.url);
                _emitState();
            }).catch(() => {
                // Autoplay policy blocked silent prime — still set src so browser buffers it.
                console.log('[html5 engine] Silent prime blocked by autoplay policy (expected on iOS)');
            });
        };

        if (!_currentAudio) return;
        const elapsed = _currentAudio.currentTime || 0;
        const duration = _currentAudio.duration || 0;
        const remaining = Math.max(0, duration - elapsed);
        const triggerIn = Math.max(0, (remaining - _prefetchSeconds) * 1000);

        console.log('[html5 engine] Prefetch timer set for', nextIndex, 'in', Math.round(triggerIn / 1000), 's');
        _prefetchTimer = setTimeout(setupPreload, triggerIn);
    }

    // ─── Track Lifecycle ──────────────────────────────────────────────────────

    /**
     * Attaches all event listeners to _currentAudio and begins playback.
     * @param {number} offsetSeconds  Where to start within the track.
     * @param {boolean} shouldPlay    Whether to immediately call .play().
     */
    function _attachCurrentListeners(offsetSeconds, shouldPlay) {
        if (!_currentAudio) return;

        _currentAudio.onwaiting = () => {
            _loadingState = 'buffering';
            _emitState();
        };

        _currentAudio.onplaying = () => {
            _loadingState = 'ready';
            _playing = true;
            _emitState();
        };

        _currentAudio.ontimeupdate = () => {
            if (!_currentAudio) return;
            const elapsed = _currentAudio.currentTime || 0;
            const duration = _currentAudio.duration || 0;
            const remaining = Math.max(0, duration - elapsed);

            // Emit state on every timeupdate so position bar stays smooth
            _emitState();

            // Trigger prefetch if not already running
            if (!_isPrefetching && remaining <= (_prefetchSeconds + 5) && _currentIndex + 1 < _playlist.length) {
                _schedulePrefetch();
            }
        };

        _currentAudio.onended = () => {
            if (_isTransitioning) return;
            _onTrackEndedHtml5();
        };

        _currentAudio.onerror = (e) => {
            const msg = _currentAudio?.error?.message || 'HTMLAudioElement error';
            _emitError('Track ' + _currentIndex + ': ' + msg);
        };

        if (offsetSeconds > 0) {
            _currentAudio.currentTime = offsetSeconds;
        }

        if (shouldPlay) {
            _loadingState = 'loading';
            _currentAudio.play().then(() => {
                _playing = true;
                _loadingState = 'ready';
                _emitState();
                _schedulePrefetch();
                _startPositionTimer();
                _updateMediaSession();
            }).catch(err => {
                _emitError('Play failed: ' + err.message);
            });
        }
    }

    /**
     * Called when HTMLAudioElement fires 'ended'.
     * Swaps _nextAudio into position and continues playback.
     */
    function _onTrackEndedHtml5() {
        _isTransitioning = true;
        const wasIndex = _currentIndex;
        _currentIndex++;
        _cancelPrefetch();
        _isPrefetching = false;

        console.log('[html5 engine] Track ended. Advancing from', wasIndex, 'to', _currentIndex);

        if (_currentIndex >= _playlist.length) {
            // End of playlist.
            _playing = false;
            _loadingState = 'idle';
            _stopPositionTimer();
            _resetAudio(_currentAudio);
            _emitTrackChange(wasIndex, -1);
            _emitState();
            _isTransitioning = false;
            return;
        }

        // Promote _nextAudio → _currentAudio
        const oldAudio = _currentAudio;
        const promoted = (_nextAudio && _nextAudio.src && _nextAudio.src.length > 5) ? _nextAudio : null;

        if (promoted) {
            console.log('[html5 engine] Promoting pre-loaded next track', _currentIndex);

            // To reduce the gap, we start the promoted audio BEFORE fully resetting the old one.
            _currentAudio = promoted;
            _nextAudio = _createAudio(true);

            _currentAudio.volume = 1;
            _currentAudio.muted = false;

            // Re-attach listeners BEFORE playing so we catch the very first 'playing' event.
            _attachCurrentListeners(0, false);

            _currentAudio.play().then(() => {
                _playing = true;
                _loadingState = 'ready';
                _emitTrackChange(wasIndex, _currentIndex);
                _emitState();
                _schedulePrefetch();
                _startPositionTimer();
                _updateMediaSession();
                _isTransitioning = false;

                // Cleanup the old audio after the new one is confirmed playing to bridge the gap.
                if (oldAudio) _resetAudio(oldAudio);
            }).catch(err => {
                _isTransitioning = false;
                if (oldAudio) _resetAudio(oldAudio);
                _emitError('Promoted track play failed: ' + err.message);
            });
        } else {
            // Next track wasn't pre-loaded in time — fall back to a regular load.
            console.log('[html5 engine] Next track not ready, loading fresh:', _currentIndex);
            _resetAudio(oldAudio);
            if (!_nextAudio) _nextAudio = _createAudio(true);
            _currentAudio = _createAudio(false);

            const track = _playlist[_currentIndex];
            if (!track) {
                _isTransitioning = false;
                _emitError('No track at index ' + _currentIndex);
                return;
            }

            _currentAudio.src = track.url;
            _loadingState = 'loading';
            _emitTrackChange(wasIndex, _currentIndex);
            _emitState();

            _attachCurrentListeners(0, true);
            _isTransitioning = false;
        }
    }

    // ─── Media Session API ────────────────────────────────────────────────────

    let _mediaSessionRegistered = false;

    /** Register action handlers once. Called from init(). */
    function _registerMediaSessionHandlers() {
        if (!('mediaSession' in navigator) || _mediaSessionRegistered) return;
        navigator.mediaSession.setActionHandler('play', () => api.play());
        navigator.mediaSession.setActionHandler('pause', () => api.pause());
        navigator.mediaSession.setActionHandler('nexttrack', () => api.seekToIndex(_currentIndex + 1));
        navigator.mediaSession.setActionHandler('previoustrack', () => api.seekToIndex(Math.max(0, _currentIndex - 1)));
        _mediaSessionRegistered = true;
    }

    /** Update metadata only. Called on every track change. */
    function _updateMediaSession() {
        if (!('mediaSession' in navigator)) return;
        const track = _playlist[_currentIndex];
        if (!track) return;
        navigator.mediaSession.metadata = new MediaMetadata({
            title: track.title || '',
            artist: track.artist || '',
            album: track.album || '',
        });
    }

    // ─── Callbacks ────────────────────────────────────────────────────────────

    function _emitState() {
        if (!_onStateChange) return;
        try {
            const audio = _currentAudio;
            const pos = audio ? (audio.currentTime || 0) : 0;
            const dur = audio ? (isNaN(audio.duration) ? 0 : (audio.duration || 0)) : 0;

            let ps = _loadingState;
            if (_currentIndex < 0) ps = 'idle';

            const nextTrackTotal = _playlist[_currentIndex + 1] ? (_playlist[_currentIndex + 1].duration || 0) : 0;
            let nextBuffered = 0;
            let currentBuffered = pos;

            if (audio && audio.buffered.length > 0) {
                currentBuffered = audio.buffered.end(audio.buffered.length - 1);
            } else if (audio && _isTransitioning && _currentIndex === _lastEmittedNextIndex) {
                // Carry over the buffered value during the brief transition window
                // when the browser might report 0 for the newly focused element.
                currentBuffered = Math.max(pos, _lastEmittedNextBuf);
            }

            if (_isPrefetching && _nextAudio && _nextAudio.buffered.length > 0) {
                nextBuffered = _nextAudio.buffered.end(_nextAudio.buffered.length - 1);
            }

            _lastEmittedNextBuf = nextBuffered;
            _lastEmittedNextIndex = _currentIndex + 1;

            _onStateChange({
                playing: _playing,
                index: _currentIndex,
                position: pos,
                duration: dur,
                currentTrackBuffered: Math.min(Math.max(currentBuffered, pos), dur || currentBuffered || pos),
                nextTrackBuffered: Math.min(nextBuffered, nextTrackTotal),
                nextTrackTotal: nextTrackTotal,
                processingState: ps,
            });
        } catch (_) { }
    }

    function _emitTrackChange(from, to) {
        if (_onTrackChange) {
            try { _onTrackChange({ from: from, to: to }); } catch (_) { }
        }
    }

    function _emitError(msg) {
        console.error('[html5 audio]', msg);
        if (_onError) {
            try { _onError({ message: msg }); } catch (_) { }
        }
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    const api = {

        /** Called once at startup. Creates the two audio elements. */
        init: function () {
            if (_currentAudio) return; // already initialised
            _currentAudio = _createAudio(false);
            _nextAudio = _createAudio(true);
            _registerMediaSessionHandlers();
            console.log('[html5 engine] Initialised — dual HTMLAudioElement strategy');
        },

        /** Load a new playlist and begin playback from [startIndex]. */
        setPlaylist: function (tracks, startIndex) {
            _cancelPrefetch();
            _stopPositionTimer();
            _isTransitioning = false;
            _isPrefetching = false;

            if (_currentAudio) _resetAudio(_currentAudio);
            if (_nextAudio) _resetAudio(_nextAudio);

            // Re-create fresh elements to avoid stale event listeners.
            _currentAudio = _createAudio(false);
            _nextAudio = _createAudio(true);

            _playlist = tracks || [];
            _currentIndex = startIndex != null ? startIndex : 0;
            _playing = false;
            _loadingState = 'idle';
            _emitState();
        },

        /** Append additional tracks to the playlist. */
        appendTracks: function (tracks) {
            if (tracks && tracks.length > 0) {
                _playlist = _playlist.concat(tracks);
                _emitState();
            }
        },

        /** Begin or resume playback. */
        play: function () {
            if (!_currentAudio) api.init();
            if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

            if (_currentAudio.src && !_currentAudio.paused) return; // already playing

            if (_currentAudio.src) {
                // Resuming after pause.
                _currentAudio.play().then(() => {
                    _playing = true;
                    _loadingState = 'ready';
                    _emitState();
                    _startPositionTimer();
                }).catch(err => _emitError('Resume failed: ' + err.message));
                return;
            }

            // Fresh track load.
            const track = _playlist[_currentIndex];
            if (!track) return;

            _loadingState = 'loading';
            _emitState();
            _currentAudio.src = track.url;
            _attachCurrentListeners(0, true);
            _emitTrackChange(-1, _currentIndex);
        },

        /** Pause playback. */
        pause: function () {
            if (!_currentAudio || !_playing) return;
            _currentAudio.pause();
            _playing = false;
            _cancelPrefetch();
            _stopPositionTimer();
            _emitState();
        },

        /** Stop playback and reset to idle state. */
        stop: function () {
            _cancelPrefetch();
            _stopPositionTimer();
            if (_currentAudio) _resetAudio(_currentAudio);
            if (_nextAudio) _resetAudio(_nextAudio);
            _playing = false;
            _loadingState = 'idle';
            _isTransitioning = false;
            _isPrefetching = false;
            _emitState();
        },

        /** Seek to [seconds] within the current track. */
        seek: function (seconds) {
            if (!_currentAudio || _currentIndex < 0) return;
            _currentAudio.currentTime = seconds;
            _emitState();
        },

        /** Jump to playlist index [index] and play. */
        seekToIndex: function (index) {
            if (index < 0 || index >= _playlist.length) return;
            _cancelPrefetch();
            _stopPositionTimer();
            _isTransitioning = false;

            const wasPlaying = _playing;
            const oldIndex = _currentIndex;

            _resetAudio(_currentAudio);
            _resetAudio(_nextAudio);
            _currentAudio = _createAudio(false);
            _nextAudio = _createAudio(true);

            _currentIndex = index;
            _playing = false;

            const track = _playlist[index];
            if (!track) { _emitError('No track at index ' + index); return; }

            _currentAudio.src = track.url;
            _loadingState = 'loading';
            _emitTrackChange(oldIndex, index);
            _emitState();

            if (wasPlaying) {
                _attachCurrentListeners(0, true);
            }
        },

        /**
         * Update the prefetch window (seconds before track end to
         * begin loading the next track).
         */
        setPrefetchSeconds: function (s) {
            _prefetchSeconds = Math.max(5, Math.min(120, s));
        },

        /** Returns a snapshot of current engine state (mirrors GDAR engine shape). */
        getState: function () {
            const audio = _currentAudio;
            const pos = audio ? (audio.currentTime || 0) : 0;
            const dur = audio ? (isNaN(audio.duration) ? 0 : (audio.duration || 0)) : 0;
            let currentBuffered = pos;
            if (audio && audio.buffered.length > 0) {
                currentBuffered = audio.buffered.end(audio.buffered.length - 1);
            }
            return {
                playing: _playing,
                index: _currentIndex,
                position: pos,
                duration: dur,
                currentTrackBuffered: Math.min(Math.max(currentBuffered, pos), dur || currentBuffered || pos),
                nextTrackBuffered: 0,
                nextTrackTotal: _playlist[_currentIndex + 1] ? (_playlist[_currentIndex + 1].duration || 0) : 0,
                playlistLength: _playlist.length,
                processingState: _loadingState,
                contextState: 'html5',
            };
        },

        /** Register a callback invoked with engine state updates. */
        onStateChange: function (cb) { _onStateChange = cb; },

        /** Register a callback invoked on track index changes. */
        onTrackChange: function (cb) { _onTrackChange = cb; },

        /** Register a callback invoked on errors. */
        onError: function (cb) { _onError = cb; },
    };

    window._html5Audio = api;

})();
