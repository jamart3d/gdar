/**
 * GDAR Audio Engine Test Mock Harness
 * Provides minimal mocks for browser APIs to test engine logic.
 */
(function (exports) {
    'use strict';

    let __stateCallbacksSuspended = false;
    let __mockPlaybackSeconds = 0;

    // Mock AudioContext
    class MockAudioContext {
        constructor() {
            this.state = 'running';
            this.currentTime = 0;
            this.destination = {};
            this._isResuming = false;
            g.__mockAudioContextInstance = this;
            if (!g.__mockAudioContextInstances) g.__mockAudioContextInstances = [];
            g.__mockAudioContextInstances.push(this);
        }
        createGain() {
            return {
                gain: { value: 1.0 },
                connect: () => { },
                disconnect: () => { }
            };
        }
        createBufferSource() {
            const src = {
                buffer: null,
                start: (time, offset) => {
                    src._startTime = time;
                    src._offset = offset;
                },
                stop: () => { src.onended && src.onended(); },
                connect: () => { },
                onended: null,
                playbackRate: { value: 1 }
            };
            return src;
        }
        decodeAudioData(buffer, successCallback, errorCallback) {
            const decoded = { duration: 300 };
            if (successCallback) successCallback(decoded);
            return Promise.resolve(decoded).then(r => {
                console.log('[MOCK_LOG] decodeAudioData promise resolved internally!');
                return r;
            });
        }
        resume() {
            this.state = 'running';
            return Promise.resolve();
        }
        suspend() {
            this.state = 'suspended';
            return Promise.resolve();
        }
    }

    // Mock Audio Element
    class MockAudio {
        constructor() {
            this.src = '';
            this.currentTime = 0;
            this.duration = 300;
            this.paused = true;
            this.loop = false;
            this.volume = 1.0;
            this.buffered = {
                length: 0,
                end: (i) => 0
            };
            this.style = {};
            if (!g.__mockAudioInstances) g.__mockAudioInstances = [];
            g.__mockAudioInstances.push(this);
        }
        play() { this.paused = false; return Promise.resolve(); }
        pause() { this.paused = true; }
        setAttribute() { }
        removeAttribute() { }
        load() { }
    }

    // Safe Global Mocks for Node/Browser
    const g = typeof window !== 'undefined' ? window : global;

    g.__fetchCalls = [];
    g.__resetFetchCalls = function () {
        g.__fetchCalls = [];
    };

    g.__advanceMockPlayback = function (seconds) {
        __mockPlaybackSeconds += seconds;
        if (g.__mockAudioContextInstances) {
            g.__mockAudioContextInstances.forEach((ctx) => {
                ctx.currentTime += seconds;
            });
        }
        if (g.__mockAudioInstances) {
            g.__mockAudioInstances.forEach((audio) => {
                if (!audio.paused) {
                    audio.currentTime += seconds;
                }
            });
        }
    };

    g.__suspendStateCallbacks = function (enabled) {
        __stateCallbacksSuspended = enabled;
    };

    g.__resumeStateCallbacks = function () {
        __stateCallbacksSuspended = false;
    };

    g.__areStateCallbacksSuspended = function () {
        return __stateCallbacksSuspended;
    };

    g.fetch = function (url, options) {
        g.__fetchCalls.push({ url, options: options || null });
        console.log('[MOCK_LOG] fetch called: ', url);
        return Promise.resolve({
            ok: true,
            headers: { get: (h) => '8' },
            body: {
                getReader: () => {
                    let done = false;
                    return {
                        read: () => {
                            if (done) return Promise.resolve({ done: true });
                            done = true;
                            console.log('[MOCK_LOG] mock stream chunk sent');
                            return Promise.resolve({ done: false, value: new Uint8Array(8) });
                        }
                    };
                }
            },
            arrayBuffer: () => {
                console.log('[MOCK_LOG] arrayBuffer() resolved');
                return Promise.resolve(new ArrayBuffer(8));
            },
            url: url,
            redirected: false,
        });
    };

    g.AudioContext = MockAudioContext;
    g.Audio = MockAudio;
    g.Worker = class { postMessage() { } };

    if (!g.performance) g.performance = { now: () => Date.now() };
    if (!g.localStorage) g.localStorage = { getItem: () => null, setItem: () => { } };

    // Mock navigator.mediaSession
    try {
        if (!g.navigator) g.navigator = {};
        if (!g.navigator.mediaSession) {
            g.navigator.mediaSession = { setActionHandler: () => { }, metadata: {} };
        }
        if (!g.navigator.userAgent) {
            g.navigator.userAgent = 'Mozilla/5.0 (X11; Linux x86_64)';
        }
        if (g.navigator.maxTouchPoints == null) {
            g.navigator.maxTouchPoints = 0;
        }
    } catch (e) {
        // Fallback for Node built-in navigator (which is a getter-only on some versions)
        Object.defineProperty(g, 'navigator', {
            value: {
                mediaSession: { setActionHandler: () => { }, metadata: {} },
                userAgent: 'Mozilla/5.0 (X11; Linux x86_64)',
                maxTouchPoints: 0
            },
            configurable: true,
            enumerable: true,
            writable: true
        });
    }

    g.AbortController = class {
        constructor() { this.signal = {}; }
        abort() { }
    };

    if (!g._gdarIsHeartbeatNeeded) {
        g._gdarIsHeartbeatNeeded = function () {
            try {
                if (
                    typeof g.matchMedia === 'function' &&
                    g.matchMedia('(display-mode: standalone)').matches
                ) {
                    return true;
                }
            } catch (_) { }

            const ua = (g.navigator && g.navigator.userAgent) || '';
            const maxTouchPoints =
                (g.navigator && g.navigator.maxTouchPoints) || 0;

            if (
                /Windows/i.test(ua) ||
                (/Macintosh/i.test(ua) && maxTouchPoints === 0)
            ) {
                return false;
            }

            return (
                /Android|iPhone|iPad|iPod/i.test(ua) ||
                (maxTouchPoints > 0 && /Macintosh/.test(ua))
            );
        };
    }

    if (!g._gdarMediaSession) {
        g._gdarMediaSession = {
            updateMetadata: () => { },
            updatePlaybackState: () => { },
            updatePositionState: () => { },
            setActionHandlers: () => { },
            forceSync: () => { }
        };
    }

    // Mock MediaMetadata
    if (!g.MediaMetadata) g.MediaMetadata = class { constructor(args) { Object.assign(this, args); } };

    // Logger Mock
    g._gdarLogger = {
        log: (...args) => { console.log('[MOCK_LOG]', ...args); },
        error: (...args) => { console.error('[MOCK_LOG]', ...args); },
        warn: (...args) => { console.warn('[MOCK_LOG]', ...args); }
    };

    // Mock document
    if (!g.document) {
        const listeners = {};
        g.document = {
            addEventListener: (type, cb) => {
                if (!listeners[type]) listeners[type] = [];
                listeners[type].push(cb);
            },
            removeEventListener: (type, cb) => {
                if (listeners[type]) {
                    listeners[type] = listeners[type].filter(l => l !== cb);
                }
            },
            dispatchEvent: (event) => {
                const type = event.type;
                if (listeners[type]) {
                    listeners[type].forEach(cb => cb(event));
                }
            },
            createElement: (tag) => {
                if (tag === 'video') return new MockAudio();
                return {};
            },
            body: { appendChild: () => { } },
            visibilityState: 'visible'
        };
    }

    // Mock window methods
    if (!g.addEventListener) g.addEventListener = () => { };
    if (!g.removeEventListener) g.removeEventListener = () => { };
    if (!g.dispatchEvent) g.dispatchEvent = () => { };
    if (!g.matchMedia) {
        g.matchMedia = () => ({
            matches: false,
            addListener: () => { },
            removeListener: () => { }
        });
    }
    if (!g.Event) {
        g.Event = class {
            constructor(type) {
                this.type = type;
            }
        };
    }
    if (!g.CustomEvent) g.CustomEvent = class { constructor() { } };
    if (!g.requestAnimationFrame) g.requestAnimationFrame = (cb) => { setTimeout(cb, 16); };

    // Ensure window also exists in Node for IIFEs
    if (typeof window === 'undefined') {
        g.window = g;
    }
    if (!g.location) {
        g.location = { href: 'http://localhost/' };
    }

})(typeof window !== 'undefined' ? window : global);
