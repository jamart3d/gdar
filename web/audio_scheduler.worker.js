/**
 * GDAR Audio Scheduler - Web Worker
 * 
 * Runs the timing checks for the WebAudio engine off the main thread.
 * This prevents the browser from aggressively throttling our prefetch and watchdog
 * timers when the tab is hidden or minimized (browsers often throttle 
 * setTimeout/setInterval to 1Hz or worse on background tabs).
 */

let intervalId = null;

self.onmessage = function (e) {
    if (e.data === 'start') {
        if (intervalId) clearInterval(intervalId);

        // Tick every 250ms (4Hz). This is fast enough to catch track endings
        // and schedule prefetching accurately without burning battery.
        intervalId = setInterval(() => {
            self.postMessage('tick');
        }, 250);

    } else if (e.data === 'stop') {
        if (intervalId) {
            clearInterval(intervalId);
            intervalId = null;
        }
    }
};
