/**
 * GDAR Audio Utilities
 *
 * Shared helpers used across all audio engines.
 * Must be loaded before any engine script (see index.html load order).
 */
(function () {
    'use strict';

    /**
     * Returns true if the current device is mobile/tablet and needs a
     * background survival heartbeat to keep audio alive when the tab is hidden.
     *
     * Desktop (Windows, Mac without touch) never needs a heartbeat — Chrome and
     * Firefox keep AudioContext running in background tabs on desktop.
     *
     * Result is cached on window._gdarHeartbeatNeeded after the first call to
     * avoid repeated UA parsing on every state emission.
     */
    window._gdarIsHeartbeatNeeded = function () {
        if (window._gdarHeartbeatNeeded !== undefined) return window._gdarHeartbeatNeeded;
        const ua = navigator.userAgent || '';
        if (/Windows/i.test(ua) || (/Macintosh/i.test(ua) && navigator.maxTouchPoints === 0)) {
            window._gdarHeartbeatNeeded = false;
            return false;
        }
        const result = /Android|iPhone|iPad|iPod/i.test(ua) ||
            (navigator.maxTouchPoints > 0 && /Macintosh/.test(ua));
        window._gdarHeartbeatNeeded = result;
        return result;
    };

})();
