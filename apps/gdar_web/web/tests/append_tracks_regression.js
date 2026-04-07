/**
 * Regression: appendTracks must update BOTH sub-engines in the hybrid
 * orchestrator regardless of which engine is currently active.
 *
 * Bug: appendTracks only called _activeEngine.appendTracks(tracks). When WA
 * was active (post-handoff), HTML5 never received appended tracks.  On any
 * subsequent WA→HTML5 handoff (fence, suspension, seek) syncState was called
 * with an index beyond HTML5's playlist, causing _queue.currentTrack to be
 * undefined.  _translateState(undefined) returns index:-1, which Dart maps
 * to _currentIndex=null, blanking the UI and suppressing the
 * processingState.completed trigger that drives auto-random-on-end.
 *
 * Fix: always call _fgEngine.appendTracks AND _bgEngine.appendTracks.
 */
'use strict';

const fs = require('fs');
const path = require('path');

require('./mock_harness.js');

function loadScript(filename) {
    const code = fs.readFileSync(path.join(__dirname, '..', filename), 'utf8');
    eval(code);
}

loadScript('gapless_audio_engine.js');
loadScript('hybrid_html5_engine.js');
loadScript('hybrid_audio_engine.js');

function assert(condition, message) {
    if (!condition) {
        console.error('FAILED:', message);
        process.exit(1);
    }
    console.log('PASSED:', message);
}

const hybrid  = global._hybridAudio;
const waEng   = global._gdarAudio;
const h5Eng   = global._hybridHtml5Audio;

console.log('\n--- appendTracks both-engine regression ---\n');

// ── Test 1: setPlaylist seeds both engines (sanity) ─────────────────────────
hybrid.stop();
hybrid.setPlaylist(
    [{ url: 'http://example.com/t1.mp3', duration: 300 }],
    0,
);

assert(
    waEng.getState().playlistLength === 1,
    'WA engine has 1 track after setPlaylist',
);
assert(
    h5Eng.getState().playlistLength === 1,
    'HTML5 engine has 1 track after setPlaylist',
);

// ── Test 2: appendTracks (HTML5 active — instant-start phase) ───────────────
// At this point the hybrid hasn't completed a WA handoff yet, so _activeEngine
// is still HTML5.  The old code was correct in this path but we verify it too.
hybrid.appendTracks([{ url: 'http://example.com/t2.mp3', duration: 300 }]);

assert(
    waEng.getState().playlistLength === 2,
    'WA engine has 2 tracks after appendTracks (HTML5 active)',
);
assert(
    h5Eng.getState().playlistLength === 2,
    'HTML5 engine has 2 tracks after appendTracks (HTML5 active)',
);
assert(
    hybrid.getState().playlistLength === 2,
    'Hybrid reports 2 tracks after appendTracks',
);

// ── Test 3: appendTracks after simulating WA becoming active ────────────────
// Reset to a clean state, then manually swap the internal active engine to WA
// by calling setPlaylist with pure-WA mode, which forces _swapEngine(_fgEngine).
hybrid.stop();
global.window._shakedownAudioStrategy = 'webaudio'; // force pure-WA path
hybrid.setPlaylist(
    [{ url: 'http://example.com/a1.mp3', duration: 300 }],
    0,
);
global.window._shakedownAudioStrategy = ''; // restore

// Active engine is now WA (_fgEngine). This is the scenario that was broken.
assert(
    hybrid.getState().engineType === 1,
    'Hybrid is in WA mode (engineType 1) for test 3',
);

hybrid.appendTracks([{ url: 'http://example.com/a2.mp3', duration: 300 }]);

assert(
    waEng.getState().playlistLength === 2,
    'WA engine has 2 tracks after appendTracks (WA active) — the fixed path',
);
assert(
    h5Eng.getState().playlistLength === 2,
    'HTML5 engine has 2 tracks after appendTracks (WA active) — the fixed path',
);

// ── Test 4: out-of-bounds index is no longer possible after fix ──────────────
// After setPlaylist(1 track) + appendTracks(1 track), HTML5 must be able to
// report a valid state for index 1 (the appended track).
hybrid.stop();
global.window._shakedownAudioStrategy = 'webaudio';
hybrid.setPlaylist(
    [{ url: 'http://example.com/b1.mp3', duration: 300 }],
    0,
);
global.window._shakedownAudioStrategy = '';
hybrid.appendTracks([{ url: 'http://example.com/b2.mp3', duration: 300 }]);

// Simulate a WA→HTML5 fence handoff: syncState to the appended track index.
h5Eng.syncState(1, 0, false);
const h5State = h5Eng.getState();

assert(
    h5State.index !== -1,
    'HTML5 engine does NOT report index:-1 for appended track after fix',
);

hybrid.stop();
console.log('\n--- appendTracks regression: ALL PASSED ---\n');
