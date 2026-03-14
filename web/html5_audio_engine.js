/**
 * HTML5 Audio Engine (Exact Relisten Gapless Port)
 *
 * This engine maps our project's audio API to the exact logic from
 * RelistenNet/relisten-web's gapless.cjs.
 */
(function () {
    'use strict';

    const _log = (window._gdarLogger || console);
    const isBrowser = typeof window !== 'undefined';
    // Memory-safe prefetch limit for long shows
    const PRELOAD_NUM_TRACKS = 2;

    // ─── Relisten Core (gapless.cjs) ──────────────────────────────────────────
    // Ported from: https://github.com/RelistenNet/relisten-web/blob/master/public/gapless.cjs

    let _audioContext = null;

    function _ensureAudioContext(webAudioIsDisabled) {
        if (webAudioIsDisabled) return null;
        if (!_audioContext && isBrowser && (window.AudioContext || window.webkitAudioContext)) {
            _audioContext = new (window.AudioContext || window.webkitAudioContext)();
            _log.log('[html5] AudioContext created');
        }
        return _audioContext;
    }

    const GaplessPlaybackType = {
        HTML5: 'HTML5',
        WEBAUDIO: 'WEBAUDIO',
    };

    const GaplessPlaybackLoadingState = {
        NONE: 'NONE',
        LOADING: 'LOADING',
        LOADED: 'LOADED',
    };

    class Track {
        constructor({ trackUrl, skipHEAD, queue, idx, metadata }) {
            this.playbackType = GaplessPlaybackType.HTML5;
            this.webAudioLoadingState = GaplessPlaybackLoadingState.NONE;
            this.loadedHEAD = false;
            this.idx = idx;
            this.queue = queue;
            this.trackUrl = trackUrl;
            this.skipHEAD = skipHEAD;
            this.metadata = metadata || {};

            this.onEnded = this.onEnded.bind(this);
            this.onProgress = this.onProgress.bind(this);

            this.audio = new Audio();
            this.audio.onerror = this.audioOnError;
            this.audio.onended = () => this.onEnded('HTML5');
            this.audio.controls = false;
            this.audio.volume = queue.state.volume;
            this.audio.preload = 'none';
            this.audio.src = trackUrl;
            this.audio.crossOrigin = 'anonymous';

            if (queue.state.webAudioIsDisabled) return;

            this.audioContext = _ensureAudioContext(false);
            if (!this.audioContext) return;

            this.gainNode = this.audioContext.createGain();
            if (this.gainNode) this.gainNode.gain.value = queue.state.volume;
            this.webAudioStartedPlayingAt = 0;
            this.webAudioPausedDuration = 0;
            this.webAudioPausedAt = 0;
            this.audioBuffer = null;

            this.bufferSourceNode = this.audioContext.createBufferSource();
            if (this.bufferSourceNode) this.bufferSourceNode.onended = this.onEnded;
        }

        loadHEAD(cb) {
            if (this.loadedHEAD) return cb();
            fetch(this.trackUrl, { method: 'HEAD' }).then((res) => {
                if (res.redirected) this.trackUrl = res.url;
                this.loadedHEAD = true;
                cb();
            }).catch(() => cb());
        }

        loadBuffer(cb) {
            if (this.webAudioLoadingState !== GaplessPlaybackLoadingState.NONE) return;
            this.webAudioLoadingState = GaplessPlaybackLoadingState.LOADING;
            fetch(this.trackUrl)
                .then((res) => res.arrayBuffer())
                .then((res) =>
                    this.audioContext.decodeAudioData(
                        res,
                        (buffer) => {
                            this.webAudioLoadingState = GaplessPlaybackLoadingState.LOADED;
                            this.bufferSourceNode.buffer = this.audioBuffer = buffer;
                            this.bufferSourceNode.connect(this.gainNode);
                            this.queue.loadTrack(this.idx + 1);
                            if (this.isActiveTrack) this.switchToWebAudio();
                            else this.playbackType = GaplessPlaybackType.WEBAUDIO;
                            cb && cb(buffer);
                        },
                        (err) => console.error('error decoding audio data', err)
                    )
                )
                .catch((e) => console.debug('caught fetch error', e));
        }

        switchToWebAudio(forcePause) {
            if (!this.isActiveTrack && !forcePause) return;
            if (this.currentTime !== 0 && isNaN(this.audio.duration)) return;

            if (forcePause) {
                this.bufferSourceNode.playbackRate.value = 0;
                this.pause();
            } else {
                this.bufferSourceNode.playbackRate.value = this.currentTime !== 0 && this.isPaused ? 0 : 1;
            }

            this.connectGainNode();
            this.webAudioStartedPlayingAt = this.audioContext.currentTime - this.currentTime;
            this.bufferSourceNode.start(0, this.currentTime);

            if (this.isPaused) {
                this.webAudioPausedAt = this.audioContext.currentTime;
                this.bufferSourceNode.playbackRate.value = 0;
                try { this.gainNode.disconnect(this.audioContext.destination); } catch (e) { }
                this.bufferSourceNode.onended = null;
            }

            this.audio.pause();
            this.playbackType = GaplessPlaybackType.WEBAUDIO;
        }

        pause() {
            if (this.isUsingWebAudio) {
                if (this.bufferSourceNode.playbackRate.value === 0) return;
                this.webAudioPausedAt = this.audioContext.currentTime;
                this.bufferSourceNode.playbackRate.value = 0;
                try { this.gainNode.disconnect(this.audioContext.destination); } catch (err) { console.error(err); }
                this.bufferSourceNode.onended = null;
            } else {
                this.audio.pause();
            }
        }

        play() {
            if (this.audioBuffer) {
                if (this.isUsingWebAudio) {
                    if (this.bufferSourceNode.playbackRate.value === 1) return;
                    if (this.webAudioPausedAt) {
                        this.webAudioPausedDuration += this.audioContext.currentTime - this.webAudioPausedAt;
                        this.webAudioPausedAt = 0;
                    }
                    if (this.currentTime !== 0) this.seek(this.currentTime);
                    this.connectGainNode();
                    this.bufferSourceNode.playbackRate.value = 1;
                    if (!this.bufferSourceNode.onended) {
                        this.bufferSourceNode.onended = () => this.onEnded('webaudio3');
                    }
                } else {
                    this.switchToWebAudio();
                }
                this.queue.loadTrack(this.idx + 1);
            } else {
                this.audio.preload = 'auto';
                const playPromise = this.audio.play();
                if (playPromise && typeof playPromise.catch === 'function') {
                    playPromise.catch((err) => {
                        if (err.name === 'NotAllowedError') this.queue.onPlayBlocked();
                    });
                }
                if (!this.queue.state.webAudioIsDisabled) {
                    if (this.skipHEAD) this.loadBuffer();
                    else this.loadHEAD(() => this.loadBuffer());
                }
            }
            this.onProgress();
        }

        togglePlayPause() {
            this.isPaused ? this.play() : this.pause();
        }

        preload(HTML5) {
            if (HTML5 && this.audio.preload !== 'auto') {
                this.audio.preload = 'auto';
            } else if (!this.audioBuffer && !this.queue.state.webAudioIsDisabled) {
                if (this.skipHEAD) this.loadBuffer();
                else this.loadHEAD(() => this.loadBuffer());
            }
        }

        seek(to = 0) {
            if (this.isUsingWebAudio) this.seekBufferSourceNode(to);
            else this.audio.currentTime = to;
            this.onProgress();
        }

        seekBufferSourceNode(to) {
            const wasPaused = this.isPaused;
            this.bufferSourceNode.onended = null;
            try { this.bufferSourceNode.stop(); } catch (e) { }

            this.bufferSourceNode = this.audioContext.createBufferSource();
            this.bufferSourceNode.buffer = this.audioBuffer;
            this.bufferSourceNode.connect(this.gainNode);
            this.bufferSourceNode.onended = () => this.onEnded('webaudio2');
            this.webAudioStartedPlayingAt = this.audioContext.currentTime - to;
            this.webAudioPausedDuration = 0;
            this.bufferSourceNode.start(0, to);
            if (wasPaused) {
                this.connectGainNode();
                this.pause();
            }
        }

        connectGainNode() {
            if (this.gainNode && this.audioContext) {
                this.gainNode.connect(this.audioContext.destination);
            }
        }

        audioOnError = (e) => {
            this.queue.onError();
        };

        onEnded(from) {
            _log.log(`[html5] Track ended (source: ${from || 'unknown'})`);

            // Simple Relisten Guard:
            if (!this.isActiveTrack) {
                _log.warn(`[html5] Ignoring onEnded for zombie track (idx: ${this.idx}).`);
                return;
            }

            if (this.bufferSourceNode && this.bufferSourceNode.onended) {
                this.bufferSourceNode.onended = null;
            }
            this.queue.playNext();
            this.queue.onEnded();
        }

        onProgress(isTick = false) {
            if (!this.isActiveTrack) return;
            const remaining = this.duration - this.currentTime;
            const nextTrack = this.queue.nextTrack;
            if (remaining <= 25 && nextTrack && !nextTrack.isLoaded) {
                this.queue.loadTrack(this.idx + 1, true);
            }
            this.queue.onProgress(this);
            if (this.isPaused || isTick) return;
            window.requestAnimationFrame(() => this.onProgress(false));
        }

        setVolume(nextVolume) {
            this.audio.volume = nextVolume;
            if (this.gainNode) this.gainNode.gain.value = nextVolume;
        }

        get isUsingWebAudio() { return this.playbackType === GaplessPlaybackType.WEBAUDIO; }
        get isPaused() {
            if (this.isUsingWebAudio) return this.bufferSourceNode.playbackRate.value === 0;
            return this.audio.paused;
        }
        get currentTime() {
            if (this.isUsingWebAudio) {
                let time = this.audioContext.currentTime - this.webAudioStartedPlayingAt - this.webAudioPausedDuration;
                if (this.webAudioPausedAt) {
                    time -= (this.audioContext.currentTime - this.webAudioPausedAt);
                }
                return Math.max(0, time);
            }
            return this.audio.currentTime;
        }
        get duration() {
            if (this.isUsingWebAudio) return this.audioBuffer.duration;
            return this.audio.duration;
        }
        get isActiveTrack() { return this.queue.currentTrack === this; }
        get isLoaded() { return this.webAudioLoadingState === GaplessPlaybackLoadingState.LOADED; }

        get bufferedAmount() {
            if (this.isUsingWebAudio) return this.audioBuffer ? this.audioBuffer.duration : 0;
            if (this.audio && this.audio.buffered.length > 0) {
                try {
                    return this.audio.buffered.end(this.audio.buffered.length - 1);
                } catch (e) { }
            }
            return 0;
        }

        get completeState() {
            return {
                playing: !this.isPaused,
                index: this.idx,
                position: this.currentTime,
                duration: this.duration,
                playbackType: this.playbackType,
            };
        }
    }

    class Queue {
        constructor(props = {}) {
            const {
                tracks = [],
                onProgress,
                onEnded,
                onPlayNextTrack,
                onPlayPreviousTrack,
                onStartNewTrack,
                webAudioIsDisabled = false,
                onError,
                onPlayBlocked,
            } = props;

            this.props = {
                onProgress,
                onEnded,
                onPlayNextTrack,
                onPlayPreviousTrack,
                onStartNewTrack,
                onError,
                onPlayBlocked,
            };

            this.state = {
                volume: 1,
                currentTrackIdx: 0,
                webAudioIsDisabled,
            };

            this.Track = Track;

            this.tracks = tracks.map(
                (trackUrl, idx) =>
                    new Track({
                        trackUrl,
                        idx,
                        queue: this,
                    })
            );

            if (!_ensureAudioContext(webAudioIsDisabled)) {
                this.disableWebAudio();
            }
        }

        addTrack({ trackUrl, skipHEAD, metadata = {} }) {
            this.tracks.push(
                new Track({
                    trackUrl,
                    skipHEAD,
                    metadata,
                    idx: this.tracks.length,
                    queue: this,
                })
            );
        }

        removeTrack(track) {
            const index = this.tracks.indexOf(track);
            return this.tracks.splice(index, 1);
        }

        togglePlayPause() {
            if (this.currentTrack) this.currentTrack.togglePlayPause();
        }

        play() {
            if (this.currentTrack) this.currentTrack.play();
        }

        pause() {
            if (this.currentTrack) this.currentTrack.pause();
        }

        playPrevious() {
            this.resetCurrentTrack();
            if (this.currentTrack?.currentTime > 8) {
                this.currentTrack.seek(0);
                return;
            }
            if (this.state.currentTrackIdx > 0) {
                this.state.currentTrackIdx--;
            }
            this.resetCurrentTrack();
            this.play();
            if (this.props.onStartNewTrack) this.props.onStartNewTrack(this.currentTrack);
            if (this.props.onPlayPreviousTrack) this.props.onPlayPreviousTrack(this.currentTrack);
        }

        playNext() {
            if (this.state.currentTrackIdx >= this.tracks.length - 1) {
                _log.log('[html5] Already at last track, skipping playNext');
                return;
            }
            this.resetCurrentTrack();
            this.state.currentTrackIdx++;
            this.resetCurrentTrack();
            this.play();
            if (this.props.onStartNewTrack) this.props.onStartNewTrack(this.currentTrack);
            if (this.props.onPlayNextTrack) this.props.onPlayNextTrack(this.currentTrack);
        }

        resetCurrentTrack() {
            if (this.currentTrack) {
                this.currentTrack.seek(0);
                this.currentTrack.pause();
            }
        }

        pauseAll() {
            Object.values(this.tracks).map((track) => {
                track.pause();
            });
        }

        stop() {
            this.pauseAll();
            this.cleanUp();
        }

        cleanUp() {
            Object.values(this.tracks).map((track) => {
                // Kill Web Audio
                if (track.bufferSourceNode) {
                    try { track.bufferSourceNode.stop(); } catch (e) { }
                    track.bufferSourceNode.onended = null;
                    track.bufferSourceNode.buffer = null;
                }
                track.audioBuffer = null;

                // Kill HTML5
                if (track.audio) {
                    track.audio.pause();
                    track.audio.src = '';
                    track.audio.load(); // Force release
                    track.audio.onended = null;
                    track.audio.onerror = null;
                }
            });
            this.tracks = [];
        }

        gotoTrack(idx, playImmediately = false) {
            this.pauseAll();
            this.state.currentTrackIdx = idx;
            this.resetCurrentTrack();
            if (playImmediately) {
                this.play();
                if (this.props.onStartNewTrack) this.props.onStartNewTrack(this.currentTrack);
            }
        }

        loadTrack(idx, loadHTML5) {
            if (this.state.currentTrackIdx + PRELOAD_NUM_TRACKS <= idx) return;
            const track = this.tracks[idx];
            if (track) track.preload(loadHTML5);
        }

        setProps(obj = {}) {
            this.props = Object.assign(this.props, obj);
        }

        onEnded() {
            if (this.props.onEnded) this.props.onEnded();
        }

        onProgress(track) {
            if (this.props.onProgress) this.props.onProgress(track);
        }

        get currentTrack() {
            return this.tracks[this.state.currentTrackIdx];
        }

        get nextTrack() {
            return this.tracks[this.state.currentTrackIdx + 1];
        }

        disableWebAudio() {
            this.state.webAudioIsDisabled = true;
        }

        setVolume(nextVolume) {
            if (nextVolume < 0) nextVolume = 0;
            else if (nextVolume > 1) nextVolume = 1;
            this.state.volume = nextVolume;
            this.tracks.map((track) => track.setVolume(nextVolume));
        }

        onError() {
            if (this.props.onError) this.props.onError();
        }

        onPlayBlocked() {
            if (this.props.onPlayBlocked) this.props.onPlayBlocked();
        }

        resumeAudioContext() {
            const ctx = _ensureAudioContext(this.state.webAudioIsDisabled);
            if (ctx && ctx.state === 'suspended') {
                return ctx.resume();
            }
            return Promise.resolve();
        }
    }

    // ─── GDAR API Bridge ──────────────────────────────────────────────────────

    let _queue = null;
    let _onStateChange = null;
    let _lastStateEmitMs = 0;

    function _emitStateThrottled(track) {
        if (!_onStateChange) return;
        const now = performance.now();
        if (now - _lastStateEmitMs < 250) return;
        _lastStateEmitMs = now;
        _onStateChange(_translateState(track));
    }
    let _onTrackChange = null;
    let _onError = null;
    let _lastIndex = -1;

    function _translateState(track) {
        if (!track) return {
            playing: false,
            index: -1,
            position: 0,
            duration: 0,
            currentTrackBuffered: 0,
            nextTrackBuffered: 0,
            nextTrackTotal: 0,
            playlistLength: (_queue && _queue.tracks) ? _queue.tracks.length : 0,
            processingState: 'idle',
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
                return 'html5 (H5)' + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';
            })()
        };

        const currentTime = track.currentTime || 0;
        const duration = track.duration || 0;
        const timeRemaining = duration - currentTime;

        let nextTrackBuffered = 0;
        const nextTrack = _queue.nextTrack;

        // Requirement: Only report "Next" buffered value when current track has 30s or less to play.
        if (timeRemaining <= 30 && nextTrack) {
            nextTrackBuffered = nextTrack.bufferedAmount || 0;
        }

        // Message Audit: Forwarding real-time buffer progress.
        // For HTML5, gapless is achieved as long as nextTrackBuffered > 0.
        return {
            playing: !track.isPaused,
            index: track.idx,
            position: isFinite(currentTime) ? currentTime : 0,
            duration: isFinite(duration) ? duration : 0,
            currentTrackBuffered: isFinite(track.bufferedAmount) ? track.bufferedAmount : currentTime,
            nextTrackBuffered: isFinite(nextTrackBuffered) ? nextTrackBuffered : 0,
            nextTrackTotal: nextTrack && isFinite(nextTrack.duration) ? nextTrack.duration : 0,
            playlistLength: (_queue && _queue.tracks) ? _queue.tracks.length : 0,
            processingState: 'ready',
            heartbeatActive: (function () {
                if (document.visibilityState === 'visible' && !track.isPaused) return true;
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
                return 'html5 (H5)' + (hbNeeded ? ' [HBN]' : ' [HBO]') + ' v1.1.hb';
            })()
        };
    }

    const api = {
        engineType: 'relisten_html5_gapless',
        init: function () {
            if (_queue) return;
            _queue = new Queue({
                onProgress: (track) => {
                    _emitStateThrottled(track);
                },
                onEnded: () => {
                    _log.log('[html5] Queue.onEnded triggered');
                },
                onStartNewTrack: (track) => {
                    if (_onTrackChange) _onTrackChange({ from: _lastIndex, to: track.idx });
                    _lastIndex = track.idx;
                },
                onError: () => {
                    if (_onError) _onError({ message: 'Relisten engine error' });
                }
            });
            _log.log('[html5] Initialized Exact Relisten Engine');

            // Background survival sync: Ensure prefetching logic runs even when RAF is throttled.
            window.addEventListener('gdar-worker-tick', () => {
                if (_queue && _queue.currentTrack) {
                    _queue.currentTrack.onProgress(true); // Call as tick
                }
            });
        },

        setPlaylist: function (tracks, startIndex) {
            this.init();
            // 1. Explicitly stop and cleanup previous tracks to kill ghost audio
            _queue.stop();

            // 2. Re-initialize tracks
            _queue.tracks = tracks.map((t, idx) => new Track({
                trackUrl: t.url,
                idx: idx,
                queue: _queue,
                metadata: t
            }));
            _queue.state.currentTrackIdx = startIndex || 0;
            _lastIndex = _queue.state.currentTrackIdx;
            _log.log('[html5] Playlist set, startIndex:', _queue.state.currentTrackIdx);
        },

        appendTracks: function (tracks) {
            if (!_queue) return;
            tracks.forEach(t => _queue.addTrack({ trackUrl: t.url, metadata: t }));
        },

        play: function () {
            if (_queue) {
                _queue.resumeAudioContext();
                _queue.play();
            }
        },

        pause: function () {
            if (_queue) _queue.pause();
        },

        stop: function () {
            if (_queue) {
                _queue.stop();
            }
        },

        seek: function (seconds) {
            if (_queue?.currentTrack) _queue.currentTrack.seek(seconds);
        },

        seekToIndex: function (index) {
            _log.log(`[html5] seekToIndex: ${index}`);
            if (_queue) _queue.gotoTrack(index, true);
        },

        setPrefetchSeconds: function (s) { /* No-op */ },

        getState: function () {
            return _translateState(_queue?.currentTrack);
        },

        prepareToPlay: function (index) {
            if (_queue) _queue.loadTrack(index);
            return Promise.resolve();
        },

        syncState: function (index, position, shouldPlay) {
            this.init();
            _queue.state.currentTrackIdx = index;
            if (shouldPlay) {
                _queue.play();
                _queue.currentTrack.seek(position);
            } else {
                _queue.currentTrack.seek(position);
                _queue.pause();
            }
        },

        onStateChange: function (cb) { _onStateChange = cb; },
        onTrackChange: function (cb) { _onTrackChange = cb; },
        onError: function (cb) { _onError = cb; },
        engineType: 'html5'
    };

    window._html5Audio = api;

})();
