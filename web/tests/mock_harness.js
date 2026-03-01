/**
 * GDAR Audio Engine Test Mock Harness
 * Provides minimal mocks for browser APIs to test engine logic.
 */
(function (exports) {
    'use strict';

    // Mock AudioContext
    class MockAudioContext {
        constructor() {
            this.state = 'running';
            this.currentTime = 0;
            this.destination = {};
            this._isResuming = false;
        }
        createGain() {
            return {
                gain: { value: 1.0 },
                connect: () => { }
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
                onended: null
            };
            return src;
        }
        decodeAudioData(buffer) {
            return Promise.resolve({ duration: 300 });
        }
        resume() { return Promise.resolve(); }
        suspend() { return Promise.resolve(); }
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
        }
        play() { this.paused = false; return Promise.resolve(); }
        pause() { this.paused = true; }
        setAttribute() { }
    }

    // Safe Global Mocks for Node/Browser
    const g = typeof window !== 'undefined' ? window : global;

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
    } catch (e) {
        // Fallback for Node built-in navigator (which is a getter-only on some versions)
        Object.defineProperty(g, 'navigator', {
            value: { mediaSession: { setActionHandler: () => { }, metadata: {} } },
            configurable: true,
            enumerable: true,
            writable: true
        });
    }

    // Mock MediaMetadata
    if (!g.MediaMetadata) g.MediaMetadata = class { constructor(args) { Object.assign(this, args); } };

    // Logger Mock
    g._gdarLogger = {
        log: () => { },
        error: () => { },
        warn: () => { }
    };

    // Mock document
    if (!g.document) {
        g.document = {
            addEventListener: () => { },
            removeEventListener: () => { },
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
    if (!g.CustomEvent) g.CustomEvent = class { constructor() { } };
    if (!g.requestAnimationFrame) g.requestAnimationFrame = (cb) => { setTimeout(cb, 16); };

    // Ensure window also exists in Node for IIFEs
    if (typeof window === 'undefined') {
        g.window = g;
    }

})(typeof window !== 'undefined' ? window : global);
