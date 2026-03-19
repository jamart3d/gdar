/**
 * GDAR Audio Scheduler (Central Dispatcher)
 * 
 * Manages the Web Worker that provides stable 4Hz (250ms) ticks even when
 * the browser background throttles the main thread's setTimeout/setInterval.
 * 
 * Engines can listen for the 'gdar-worker-tick' event on the window object.
 */
(function () {
    'use strict';

    const _log = (window._gdarLogger || console);
    let _worker = null;
    let _isActive = false;

    function _initWorker() {
        if (_worker) return;
        try {
            // Note: Use absolute path if base href is configured, 
            // but standard relative path usually works fine for workers in the same dir.
            _worker = new Worker('audio_scheduler.worker.js');
            _worker.onmessage = function (e) {
                if (e.data === 'tick') {
                    window.dispatchEvent(new CustomEvent('gdar-worker-tick', {
                        detail: { timestamp: performance.now() }
                    }));
                }
            };
            _log.log('[scheduler] Web Worker initialized.');
        } catch (err) {
            _log.error('[scheduler] Failed to initialize Web Worker:', err.message);
        }
    }

    const api = {
        start: function () {
            _initWorker();
            if (_worker && !_isActive) {
                _worker.postMessage('start');
                _isActive = true;
                _log.log('[scheduler] Background ticks started.');
            }
        },

        stop: function () {
            if (_worker && _isActive) {
                _worker.postMessage('stop');
                _isActive = false;
                _log.log('[scheduler] Background ticks stopped.');
            }
        },

        isActive: function () {
            return _isActive;
        }
    };

    window._gdarScheduler = api;

    // Scheduler is started by hybrid_init.js after the engine strategy is
    // selected. Not needed for 'passive' or 'standard' engines.

})();
