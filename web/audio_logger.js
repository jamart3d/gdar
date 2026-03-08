/**
 * GDAR Audio Engine Master Logger
 * 
 * Central registry to control debug logging spam from the 5 audio engines.
 * To enable logging, open the Chrome DevTools console and toggle these booleans,
 * or edit them permanently in this file before running 'flutter run'.
 */
(function () {
    'use strict';

    // Master List of what gets logged
    window._gdarAudioConfig = {
        logTypes: {
            errors: true,         // Critical audio initialization or HTTP errors
            heartbeat: false,     // Background survival heartbeat start/stop events
            buffer: false,        // Heavy spam: fetch progress, decode times, prefetching
            playState: false,     // Essential track starts, stops, and transitions
            gapTiming: false,     // Performance.now() physical gap execution prints
            hybridHandoff: false  // Hybrid foreground/background Orchestration details
        }
    };

    function _shouldLog(args) {
        if (!args || args.length === 0) return true;
        const text = args.join(' ').toLowerCase();

        // 1. Errors
        if (text.includes('error') || text.includes('fail') || text.includes('abort')) return window._gdarAudioConfig.logTypes.errors;

        // 2. Heartbeat
        if (text.includes('heartbeat')) return window._gdarAudioConfig.logTypes.heartbeat;

        // 3. Buffer Spam (Timers, Percentages, Decodes)
        if (text.includes('buffer') || text.includes('fetch') || text.includes('decode') || text.includes('preload') || text.includes('prime') || text.includes('%')) {
            return window._gdarAudioConfig.logTypes.buffer;
        }

        // 4. Gap Timings
        if (text.includes('gap') || text.includes('transition executed')) return window._gdarAudioConfig.logTypes.gapTiming;

        // 5. Hybrid Logic
        if (text.includes('hybrid') || text.includes('override') || text.includes('strategy')) {
            return window._gdarAudioConfig.logTypes.hybridHandoff;
        }

        // 6. Generic Play States (Fallback)
        return window._gdarAudioConfig.logTypes.playState;
    }

    const Logger = {
        log: function (...args) {
            if (_shouldLog(args)) console.log(...args);
        },
        warn: function (...args) {
            if (_shouldLog(args)) console.warn(...args);
        },
        error: function (...args) {
            if (window._gdarAudioConfig.logTypes.errors) console.error(...args);
        },
        time: function (label) {
            if (window._gdarAudioConfig.logTypes.buffer) console.time(label);
        },
        timeEnd: function (label) {
            if (window._gdarAudioConfig.logTypes.buffer) console.timeEnd(label);
        }
    };

    window._gdarLogger = Logger;

})();

