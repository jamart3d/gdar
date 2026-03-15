/**
 * GDAR Passive Audio Engine
 * 
 * A minimal engine using a plain <audio> element + MediaSession API only.
 * No AudioContext. No Web Worker. Background longevity is free via the OS
 * treating the MediaSession tab as a media tab (like YouTube Music on web).
 * 
 * No gapless playback. Track transitions have a natural ~200ms gap.
 * 
 * Exposed globally as window._passiveAudio for Dart interop.
 */
(function () {
    'use strict';

    // Safe Logger Utility
    const _log = (window._gdarLogger || console);
    const isBrowser = typeof window !== 'undefined';

    // ─── State ────────────────────────────────────────────────────────────────

    let _playlist = [];
    let _currentIndex = -1;
    let _playing = false;
    let _prefetchSeconds = 30; // Kept for API parity, but largely irrelevant here

    /**
     * Primary HTMLAudioElement — the currently playing track.
     * @type {HTMLAudioElement|null}
     */
    let _audio = null;

    /** Processing state mirroring the GDAR engine's vocabulary. */
    let _loadingState = 'idle';

    /** The interval ID for the position-polling timer. */
    let _positionTimer = null;

    let _isTransitioning = false;

    // Callbacks registered by Dart (via hybrid_init.js → _gdarAudio).
    let _onStateChange = null;
    let _onTrackChange = null;
    let _onError = null;

    let _lastTimeUpdate = 0;

    /** Tracker for the currently active play() promise to avoid interruptions. */
    let _playPromise = null;

    // ─── Audio Element Management ──────────────────────────────────────────────

    function _createAudio() {
        const audio = new Audio();
        audio.preload = 'auto';
        audio.crossOrigin = 'anonymous';
        return audio;
    }

    function _disposeAudio() {
        if (!_audio) return;
        _audio.pause();
        _audio.src = '';
        _audio.onended = null;
        _audio.onerror = null;
        _audio.oncanplaythrough = null;
        _audio.onwaiting = null;
        _audio.onplaying = null;
        _audio.ontimeupdate = null;
        _audio = null;
    }

    // ─── Position Polling ─────────────────────────────────────────────────────

    function _startPositionTimer() {
        _stopPositionTimer();
        _positionTimer = setInterval(() => _emitState(), 250);
    }

    function _stopPositionTimer() {
        if (_positionTimer) { clearInterval(_positionTimer); _positionTimer = null; }
    }

    // ─── Track Lifecycle ──────────────────────────────────────────────────────

    function _attachListeners(offsetSeconds, shouldPlay) {
        if (!_audio) return;

        _audio.onwaiting = () => {
            _loadingState = 'buffering';
            _emitState();
        };

        _audio.onplaying = () => {
            _loadingState = 'ready';
            _playing = true;
            _emitState();
        };

        _audio.ontimeupdate = () => {
            const now = performance.now();
            if (now - _lastTimeUpdate > 250) {
                _emitState();
                _lastTimeUpdate = now;
            }
        };

        _audio.onended = () => {
            if (_isTransitioning) return;
            _onTrackEnded();
        };

        _audio.onerror = (e) => {
            const msg = _audio?.error?.message || 'HTMLAudioElement error';
            _emitError('Track ' + _currentIndex + ': ' + msg);
        };

        if (offsetSeconds > 0) {
            _audio.currentTime = offsetSeconds;
        }

        if (shouldPlay) {
            _loadingState = 'loading';
            _playPromise = _audio.play();
            _playPromise.then(() => {
                _playPromise = null;
                _playing = true;
                _loadingState = 'ready';
                _emitState();
                _startPositionTimer();
                _updateMediaSession();
            }).catch(err => {
                _playPromise = null;
                // Only emit significant errors. 
                // AbortError is expected when pause() interrupts play().
                if (err.name !== 'AbortError' && err.name !== 'NotAllowedError') {
                    _emitError('Play failed: ' + err.message);
                } else {
                    _log.log(`[passive engine] Play promise ${err.name} (handled)`);
                }
            });
        }
    }

    function _onTrackEnded() {
        _isTransitioning = true;
        const wasIndex = _currentIndex;
        _currentIndex++;

        _log.log(`[passive engine] Track ${wasIndex} ended. Advancing to ${_currentIndex}...`);
        const transitionGapStart = performance.now();

        if (_currentIndex >= _playlist.length) {
            // End of playlist.
            _playing = false;
            _loadingState = 'idle';
            _stopPositionTimer();
            _emitTrackChange(wasIndex, -1);
            _emitState();
            _isTransitioning = false;
            return;
        }

        // Just load the next track into the same element and play it
        const track = _playlist[_currentIndex];
        if (!track) {
            _isTransitioning = false;
            _emitError('No track at index ' + _currentIndex);
            return;
        }

        _log.log(`[passive engine] Swapping src to: ${track.url}`);
        _audio.src = track.url;
        _loadingState = 'loading';

        // Let the hybrid layer know we advanced the track index.
        _emitTrackChange(wasIndex, _currentIndex);

        // Very important: if _forwardTrack in the HybridEngine caused us to .stop()
        // we should abort attempting to play.
        if (!_playing && _loadingState === 'idle') {
            _isTransitioning = false;
            return;
        }

        _emitState();

        _playPromise = _audio.play();
        _playPromise.then(() => {
            _playPromise = null;
            const gapMs = performance.now() - transitionGapStart;
            _log.log(`[passive engine] Transition executed successfully. Exact gap: ${gapMs.toFixed(2)}ms`);

            _playing = true;
            _loadingState = 'ready';
            _emitState();
            _startPositionTimer();
            _updateMediaSession();
            _isTransitioning = false;
        }).catch(err => {
            _playPromise = null;
            const gapMs = performance.now() - transitionGapStart;
            _isTransitioning = false;
            if (err.name !== 'AbortError' && err.name !== 'NotAllowedError') {
                _log.error(`[passive engine] Next track play failed after ${gapMs.toFixed(2)}ms:`, err.message);
                _emitError('Next track play failed: ' + err.message);
            }
        });
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
            const pos = _audio ? (_audio.currentTime || 0) : 0;
            const dur = _audio ? (isNaN(_audio.duration) ? 0 : (_audio.duration || 0)) : 0;

            let ps = _loadingState;
            if (_currentIndex < 0) ps = 'idle';

            const nextTrackTotal = _playlist[_currentIndex + 1] ? (_playlist[_currentIndex + 1].duration || 0) : 0;
            let currentBuffered = pos;

            if (_audio && _audio.buffered.length > 0) {
                currentBuffered = _audio.buffered.end(_audio.buffered.length - 1);
            }

            _onStateChange({
                playing: _playing,
                index: _currentIndex,
                position: pos,
                duration: dur,
                currentTrackBuffered: Math.min(Math.max(currentBuffered, pos), dur || currentBuffered || pos),
                nextTrackBuffered: 0, // No prefetch in passive engine
                nextTrackTotal: nextTrackTotal,
                playlistLength: _playlist.length,
                processingState: ps,
                heartbeatActive: (function () {
                    if (document.visibilityState === 'visible') return true;
                    return window._gdarHeartbeat ? window._gdarHeartbeat.isActive() : false;
                })(),
                heartbeatNeeded: (function () {
                    const ua = navigator.userAgent || '';
                    if (/Windows/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints === 0)) return false;
                    const isAndroid = /Android/i.test(ua);
                    const isIOS = /iPhone|iPad|iPod/i.test(ua);
                    const isMacPad = navigator.maxTouchPoints > 0 && /Macintosh/.test(ua);
                    return isAndroid || isIOS || isMacPad;
                })(),
                contextState: (function() {
                    const ua = navigator.userAgent || '';
                    const hbNeeded = (function() {
                        if (/Windows/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints === 0)) return false;
                        const isAndroid = /Android/i.test(ua);
                        const isIOS = /iPhone|iPad|iPod/i.test(ua);
                        const isMacPad = navigator.maxTouchPoints > 0 && /Macintosh/.test(ua);
                        return isAndroid || isIOS || isMacPad;
                    })();
                    return 'passive (H5)' + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';
                })()
            });
        } catch (_) { }
    }

    function _emitTrackChange(from, to) {
        if (_onTrackChange) {
            try { _onTrackChange({ from: from, to: to }); } catch (_) { }
        }
    }

    function _emitError(msg) {
        _log.error('[passive audio]', msg);
        if (_onError) {
            try { _onError({ message: msg }); } catch (_) { }
        }
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    const api = {
        engineType: 'passive_html5',
        init: function () {
            if (_audio) return;
            _audio = _createAudio();
            _registerMediaSessionHandlers();
            _log.log('[passive engine] Initialised');
        },

        setPlaylist: function (tracks, startIndex) {
            _stopPositionTimer();
            _isTransitioning = false;

            _disposeAudio();
            _audio = _createAudio();

            _playlist = tracks || [];
            _currentIndex = startIndex != null ? startIndex : 0;
            _playing = false;
            _loadingState = 'idle';
            _emitState();
        },

        appendTracks: function (tracks) {
            if (tracks && tracks.length > 0) {
                _playlist = _playlist.concat(tracks);
                _emitState();
            }
        },

        play: function () {
            if (!_audio) api.init();
            if (_currentIndex < 0 || _currentIndex >= _playlist.length) return;

            if (_audio.src && !_audio.paused) return; // already playing

            if (_audio.src) {
                // Resuming after pause.
                _playPromise = _audio.play();
                _playPromise.then(() => {
                    _playPromise = null;
                    _playing = true;
                    _loadingState = 'ready';
                    _emitState();
                    _startPositionTimer();
                }).catch(err => {
                    _playPromise = null;
                    if (err.name !== 'AbortError' && err.name !== 'NotAllowedError') {
                        _emitError('Resume failed: ' + err.message);
                    }
                });
                return;
            }

            // Fresh track load.
            const track = _playlist[_currentIndex];
            if (!track) return;

            _loadingState = 'loading';
            _emitState();
            _audio.src = track.url;
            _attachListeners(0, true);
            _emitTrackChange(-1, _currentIndex);
        },

        pause: function () {
            if (!_audio || !_playing) return;
            _audio.pause();
            _playing = false;
            _stopPositionTimer();
            _emitState();
        },

        stop: function () {
            _stopPositionTimer();

            // If we are currently in the middle of a play() request, 
            // the subsequent pause() in _disposeAudio will trigger an AbortError.
            // We've wired up the catch blocks above to ignore it.
            _disposeAudio();

            _playing = false;
            _loadingState = 'idle';
            _isTransitioning = false;
            _emitState();
        },

        seek: function (seconds) {
            if (!_audio || _currentIndex < 0) return;
            _audio.currentTime = seconds;
            _emitState();
        },

        seekToIndex: function (index) {
            if (index < 0 || index >= _playlist.length) return;
            _stopPositionTimer();
            _isTransitioning = false;

            const wasPlaying = _playing;
            const oldIndex = _currentIndex;

            _disposeAudio();
            _audio = _createAudio();

            _currentIndex = index;
            _playing = false;

            const track = _playlist[index];
            if (!track) { _emitError('No track at index ' + index); return; }

            _audio.src = track.url;
            _loadingState = 'loading';
            _emitTrackChange(oldIndex, index);
            _emitState();

            if (wasPlaying) {
                _attachListeners(0, true);
            }
        },

        setPrefetchSeconds: function (s) {
            _prefetchSeconds = Math.max(5, Math.min(120, s));
        },

        getState: function () {
            const pos = _audio ? (_audio.currentTime || 0) : 0;
            const dur = _audio ? (isNaN(_audio.duration) ? 0 : (_audio.duration || 0)) : 0;
            let currentBuffered = pos;

            if (_audio && _audio.buffered.length > 0) {
                currentBuffered = _audio.buffered.end(_audio.buffered.length - 1);
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
                contextState: (function() {
                    const ua = navigator.userAgent || '';
                    const hbNeeded = (function() {
                        if (/Windows/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints === 0)) return false;
                        const isAndroid = /Android/i.test(ua);
                        const isIOS = /iPhone|iPad|iPod/i.test(ua);
                        const isMacPad = navigator.maxTouchPoints > 0 && /Macintosh/.test(ua);
                        return isAndroid || isIOS || isMacPad;
                    })();
                    return 'passive' + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';
                })(),
                heartbeatActive: (function () {
                    if (document.visibilityState === 'visible') return true;
                    return window._gdarHeartbeat ? window._gdarHeartbeat.isActive() : false;
                })(),
                heartbeatNeeded: (function () {
                    const ua = navigator.userAgent || '';
                    if (/Windows/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints === 0)) return false;
                    const isAndroid = /Android/i.test(ua);
                    const isIOS = /iPhone|iPad|iPod/i.test(ua);
                    const isMacPad = navigator.maxTouchPoints > 0 && /Macintosh/.test(ua);
                    return isAndroid || isIOS || isMacPad;
                })(),
            };
        },

        prepareToPlay: function (index) {
            // Passive engine doesn't prefetch or decode ahead-of-time.
            // We just set the playlist/index so it's ready.
            return Promise.resolve();
        },

        syncState: function (index, position, shouldPlay) {
            _stopPositionTimer();
            _isTransitioning = false;
            _disposeAudio();
            _audio = _createAudio();
            _currentIndex = index;
            _playing = false;

            const track = _playlist[index];
            if (!track) return;
            _audio.src = track.url;

            if (shouldPlay) {
                _attachListeners(position || 0, true);
            } else {
                _audio.currentTime = position || 0;
                _loadingState = 'idle';
                _emitState();
            }
        },

        onStateChange: function (cb) { _onStateChange = cb; },
        onTrackChange: function (cb) { _onTrackChange = cb; },
        onError: function (cb) { _onError = cb; },
    };

    window._passiveAudio = api;

})();
